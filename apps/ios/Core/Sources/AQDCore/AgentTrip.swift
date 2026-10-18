import Foundation

/// What the Agent asks for when the owner plans a trip. Pieces are chosen by `TripOutfitComposer`, never by invented IDs.
public struct AgentTripSpec: Codable, Equatable, Sendable {
    public var destination: String
    public var activities: [String]
    /// First day, YYYY-MM-DD. Without it the looks are saved but nothing is placed on the Planner.
    public var startDate: String?
    public var days: [TripDayBrief]
    public init(destination: String, activities: [String] = [], startDate: String? = nil, days: [TripDayBrief]) {
        self.destination = destination; self.activities = activities; self.startDate = startDate; self.days = days
    }
}

public struct AgentTripDay: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID { outfit.outfitID }
    public let label: String
    public let day: LocalPlanDay?
    public let outfit: OutfitDraft
}

/// A reviewable trip: one new outfit per day, an optional theme that groups them and an optional Planner trip.
/// Applying saves the pieces in a fixed order, every step with its own receipt, so a retry never duplicates a record.
public struct AgentTripDraft: Codable, Equatable, Sendable {
    public let id: UUID
    public let ownerID: UUID
    public var name: String
    public var destination: String
    public let days: [AgentTripDay]
    public let theme: ThemeDraft
    /// Present only when the trip has dates. Slots are filled with the saved outfits when applying.
    public let plan: PlanAuthoringDraft?
    public var includeTheme: Bool
    public var includePlan: Bool

    public var canPlan: Bool { plan != nil }

    public init(ownerID: UUID, name: String, spec: AgentTripSpec, pieces: [WardrobePiece], outfits: [Outfit], themes: [OutfitTheme],
                existing: [OutfitPlanEntry], timeZone: TimeZone) throws {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, title.count <= 80, spec.destination.count <= 160, !spec.days.isEmpty else { throw PlanValidationError.invalidRecord }
        let picks = try TripOutfitComposer.compose(briefs: spec.days, pieces: pieces)
        var built: [OutfitDraft] = []
        for (brief, ids) in zip(spec.days, picks) {
            var draft = OutfitDraft(ownerID: ownerID)
            draft.name = String("\(title): \(brief.label)".prefix(80))
            let occasion = brief.occasion.trimmingCharacters(in: .whitespacesAndNewlines)
            draft.occasion = occasion.isEmpty ? nil : String(occasion.prefix(80))
            draft.pinnedPieceIDs = brief.pinnedIDs.isEmpty ? nil : brief.pinnedIDs
            try draft.applyManualSelection(ids, pieces: pieces)
            try draft.validatedForSave(pieces: pieces)
            built.append(draft)
        }
        var themeDraft = ThemeDraft(ownerID: ownerID)
        let taken = Set(themes.map { OutfitTheme.nameKey($0.name) })
        var themeName = title, suffix = 2
        while taken.contains(OutfitTheme.nameKey(themeName)) { themeName = String("\(title) \(suffix)".prefix(80)); suffix += 1 }
        themeDraft.name = themeName
        themeDraft.description = String((spec.destination.isEmpty ? "Looks for \(title)" : "Looks for \(spec.destination)").prefix(160))
        themeDraft.outfitIDs = built.map(\.outfitID)

        var dates: [LocalPlanDay?] = Array(repeating: nil, count: built.count)
        var planDraft: PlanAuthoringDraft?
        if let start = spec.startDate {
            let parts = start.split(separator: "-", omittingEmptySubsequences: false).compactMap { Int($0) }
            guard parts.count == 3 else { throw PlanValidationError.invalidDay }
            let first = LocalPlanDay(year: parts[0], month: parts[1], day: parts[2], timeZoneID: timeZone.identifier)
            guard first.key == start else { throw PlanValidationError.invalidDay }
            var calendar = Calendar(identifier: .gregorian); calendar.timeZone = timeZone
            let begin = try first.date()
            let range = try (0..<built.count).map { offset -> LocalPlanDay in
                guard let date = calendar.date(byAdding: .day, value: offset, to: begin) else { throw PlanValidationError.invalidDay }
                return LocalPlanDay(date: date, timeZone: timeZone)
            }
            dates = range
            let definition = PlanDefinition(ownerID: ownerID, name: title, start: range[0], end: range[range.count - 1],
                                            trip: TripConfiguration(destination: spec.destination, activities: spec.activities))
            var draft = try PlanAuthoringDraft(plan: definition)
            for index in draft.slots.indices {
                let brief = spec.days[index]
                draft.slots[index].occasion = String((brief.occasion.isEmpty ? brief.label : brief.occasion).prefix(80))
            }
            // Catch Planner conflicts now, with outfits shaped exactly like the ones that will be saved.
            var rehearsal = draft
            let stand = zip(built, picks).map { Outfit(id: $0.outfitID, ownerID: ownerID, name: $0.trimmedName, pieceIDs: $1, occasion: $0.occasion) }
            for index in rehearsal.slots.indices { rehearsal.slots[index].outfit = stand[index]; rehearsal.slots[index].unassignedByChoice = false }
            rehearsal.reviewing = true
            try rehearsal.validatedForSave(outfits: stand, existing: existing)
            planDraft = draft
        }
        self.id = UUID(); self.ownerID = ownerID; self.name = title; destination = spec.destination
        self.days = zip(zip(spec.days, built), dates).map { AgentTripDay(label: $0.0.label, day: $1, outfit: $0.1) }
        theme = themeDraft; plan = planDraft
        includeTheme = true; includePlan = planDraft != nil
    }

    /// The Planner draft once the day outfits exist, or nil when the owner left the Planner out.
    public func resolvedPlan(saved: [Outfit]) throws -> PlanAuthoringDraft? {
        guard includePlan, var draft = plan, draft.slots.count == days.count else { return nil }
        for index in draft.slots.indices {
            guard let match = saved.first(where: { $0.id == days[index].outfit.outfitID }) else { throw PlanValidationError.invalidOutfit }
            draft.slots[index].outfit = match; draft.slots[index].unassignedByChoice = false
        }
        draft.reviewing = true
        return draft
    }
}
