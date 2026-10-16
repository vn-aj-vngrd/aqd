import Foundation

public enum PlanAuthoringError: Error, Equatable { case invalidRange, rangeTooLong, nameRequired, invalidSlots, intentionalGapRequired, unresolvedConflict }

public enum RoutineRepetition: String, Codable, CaseIterable, Sendable { case rotate = "Rotate selected outfits", repeatFirst = "Repeat a favorite" }
public struct RoutineConfiguration: Codable, Equatable, Sendable {
    public var weekdays: [Int]
    public var occasion: String
    public var preferredOutfitIDs: [UUID]
    public var repetition: RoutineRepetition
    public init(weekdays: [Int] = [2, 3, 4, 5, 6], occasion: String = "", preferredOutfitIDs: [UUID] = [], repetition: RoutineRepetition = .rotate) {
        self.weekdays = weekdays; self.occasion = occasion; self.preferredOutfitIDs = preferredOutfitIDs; self.repetition = repetition
    }
    public func validated() throws {
        guard !weekdays.isEmpty, Set(weekdays).count == weekdays.count, weekdays.allSatisfy({ (1...7).contains($0) }),
              occasion.count <= 80, Set(preferredOutfitIDs).count == preferredOutfitIDs.count else { throw PlanAuthoringError.invalidSlots }
    }
}
public enum RoutineEditScope: String, Codable, Sendable { case entry, future, whole }

public struct PlanDefinition: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let ownerID: UUID
    public var name: String
    public var start: LocalPlanDay
    public var end: LocalPlanDay
    public var revision: Int
    public var routine: RoutineConfiguration?
    public var trip: TripConfiguration?

    public init(id: UUID = UUID(), ownerID: UUID, name: String = "", start: LocalPlanDay, end: LocalPlanDay, revision: Int = 1, routine: RoutineConfiguration? = nil, trip: TripConfiguration? = nil) {
        self.id = id; self.ownerID = ownerID; self.name = name; self.start = start; self.end = end; self.revision = revision; self.routine = routine; self.trip = trip
    }
    public func days() throws -> [LocalPlanDay] {
        let first = try start.date(), last = try end.date()
        guard start.timeZoneID == end.timeZoneID, start.key <= end.key,
              let zone = TimeZone(identifier: start.timeZoneID) else { throw PlanAuthoringError.invalidRange }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
        if let routine {
            try routine.validated()
            guard let limit = calendar.date(byAdding: .month, value: 3, to: first), last < limit else { throw PlanAuthoringError.rangeTooLong }
        }
        var cursor = first, result: [LocalPlanDay] = [], calendarDayCount = 0
        while cursor <= last {
            if routine == nil && calendarDayCount >= 14 { throw PlanAuthoringError.rangeTooLong }
            if routine?.weekdays.contains(calendar.component(.weekday, from: cursor)) ?? true {
                result.append(LocalPlanDay(date: cursor, timeZone: zone))
            }
            calendarDayCount += 1
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor), next > cursor else { throw PlanAuthoringError.invalidRange }
            cursor = next
        }
        return result
    }
    public func validated() throws {
        guard routine == nil || trip == nil else { throw PlanAuthoringError.invalidSlots }
        try trip?.validated()
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, name.count <= 80 else { throw PlanAuthoringError.nameRequired }
        guard revision > 0, revision < Int.max else { throw PlanAuthoringError.invalidSlots }
        guard try !days().isEmpty else { throw PlanAuthoringError.invalidRange }
    }
}

public struct PlanSlotDraft: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var day: LocalPlanDay
    public var occasion: String
    public var outfit: Outfit?
    public var unassignedByChoice: Bool
    public init(id: UUID = UUID(), day: LocalPlanDay, occasion: String = "", outfit: Outfit? = nil, unassignedByChoice: Bool = false) {
        self.id = id; self.day = day; self.occasion = occasion; self.outfit = outfit; self.unassignedByChoice = unassignedByChoice
    }
    public var conflictKey: String { Self.key(day: day, occasion: occasion) }
    public static func key(day: LocalPlanDay, occasion: String) -> String {
        day.key + ":" + day.timeZoneID + ":" + occasion.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

public enum PlanConflictChoice: String, Codable, Sendable { case keepBoth, replace }
public struct PlanConflictResolution: Codable, Equatable, Sendable {
    public let existing: OutfitPlanEntry
    public let choice: PlanConflictChoice
    public init(existing: OutfitPlanEntry, choice: PlanConflictChoice) { self.existing = existing; self.choice = choice }
}

public struct PlanAuthoringDraft: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let operationID: UUID
    public var plan: PlanDefinition
    public var slots: [PlanSlotDraft]
    public var resolutions: [PlanConflictResolution]
    public var reviewing: Bool
    public var basePlan: PlanDefinition?
    public var baseEntries: [OutfitPlanEntry]?
    public var editScope: RoutineEditScope?
    public var anchorEntryID: UUID?
    public var usesRules: Bool?
    public var tripActivitiesText: String?

    public init(plan: PlanDefinition) throws {
        id = UUID(); operationID = UUID(); self.plan = plan
        slots = try plan.days().map { PlanSlotDraft(day: $0, occasion: plan.routine?.occasion ?? "") }; resolutions = []; reviewing = false
    }
    public init(editing plan: PlanDefinition, entries: [OutfitPlanEntry], outfits: [Outfit], scope: RoutineEditScope, anchorEntryID: UUID?) throws {
        id = UUID(); operationID = UUID(); self.plan = plan; basePlan = plan; baseEntries = entries
        editScope = scope; self.anchorEntryID = anchorEntryID; slots = []; resolutions = []; reviewing = false
        for entry in editableBaseEntries {
            slots.append(PlanSlotDraft(id: entry.id, day: entry.day, occasion: entry.occasion,
                outfit: outfits.first { $0.id == entry.outfitID }, unassignedByChoice: entry.outfitID == nil))
        }
        try rebuildDates()
    }
    public var editableBaseEntries: [OutfitPlanEntry] {
        let anchor = baseEntries?.first { $0.id == anchorEntryID }
        return (baseEntries ?? []).filter { entry in
            guard entry.state == .planned || entry.state == .unassigned else { return false }
            switch editScope ?? .whole {
            case .entry: return entry.id == anchorEntryID
            case .future: return anchor.map { entry.day.key >= $0.day.key } ?? false
            case .whole: return true
            }
        }
    }
    private func targetDays() throws -> [LocalPlanDay] {
        var days = try plan.days()
        if basePlan != nil {
            let anchor = baseEntries?.first { $0.id == anchorEntryID }
            if editScope == .future || editScope == .entry {
                guard let anchor else { throw PlanAuthoringError.invalidSlots }
                days = days.filter { editScope == .entry ? $0.key == anchor.day.key : $0.key >= anchor.day.key }
            }
            let editableDays = Set(editableBaseEntries.map { $0.day.key })
            let completedDays = Set((baseEntries ?? []).filter { $0.state == .worn || $0.state == .skipped }.map { $0.day.key })
            days = days.filter { !completedDays.contains($0.key) || editableDays.contains($0.key) }
        }
        return days
    }
    public mutating func rebuildDates() throws {
        let days = try targetDays()
        guard Set(slots.map(\.id)).count == slots.count else { throw PlanAuthoringError.invalidSlots }
        let existing = Dictionary(grouping: slots, by: { $0.day.key })
        slots = days.flatMap { day in
            let current = existing[day.key] ?? [PlanSlotDraft(day: day, occasion: plan.routine?.occasion ?? "")]
            return current.map { value in var value = value; value.day = day; return value }
        }
        resolutions = []
    }
    public var removedEntryIDs: [UUID] {
        let retained = Set(slots.map(\.id))
        return editableBaseEntries.filter { !retained.contains($0.id) }.map(\.id)
    }
    public func conflicts(in entries: [OutfitPlanEntry]) -> [OutfitPlanEntry] {
        let keys = Set(slots.map(\.conflictKey))
        let replacing = Set(editableBaseEntries.map(\.id))
        return entries.filter { !replacing.contains($0.id) && keys.contains(PlanSlotDraft.key(day: $0.day, occasion: $0.occasion)) }
    }
    public func validatedForSave(outfits: [Outfit], existing: [OutfitPlanEntry]) throws {
        try plan.validated()
        let days = try targetDays()
        guard Set(slots.map { $0.day.key }) == Set(days.map(\.key)), Set(slots.map(\.id)).count == slots.count,
              slots.allSatisfy({ slot in days.contains(slot.day) }) else { throw PlanAuthoringError.invalidSlots }
        if let basePlan {
            try basePlan.validated()
            let base = baseEntries ?? []
            guard basePlan.id == plan.id, basePlan.ownerID == plan.ownerID, basePlan.revision == plan.revision,
                  editScope != nil, Set(base.map(\.id)).count == base.count,
                  base.allSatisfy({ $0.planID == plan.id && $0.ownerID == plan.ownerID }) else { throw PlanAuthoringError.invalidSlots }
            if editScope == .entry, plan != basePlan { throw PlanAuthoringError.invalidSlots }
            for entry in base { try entry.validated() }
            let retained = base.filter { entry in !editableBaseEntries.contains { $0.id == entry.id } }
            guard retained.allSatisfy({ $0.day.timeZoneID == plan.start.timeZoneID && $0.day.key >= plan.start.key && $0.day.key <= plan.end.key }) else { throw PlanAuthoringError.invalidSlots }
            let editable = Set(editableBaseEntries.map(\.id))
            let protected = Set(base.filter { !editable.contains($0.id) }.map(\.id))
            guard Set(slots.map(\.id)).isDisjoint(with: protected) else { throw PlanAuthoringError.invalidSlots }
        }
        if basePlan == nil {
            guard baseEntries == nil, editScope == nil, anchorEntryID == nil else { throw PlanAuthoringError.invalidSlots }
        }
        let baseByID = Dictionary(uniqueKeysWithValues: editableBaseEntries.map { ($0.id, $0) })
        for group in Dictionary(grouping: slots, by: \.conflictKey).values where group.count > 1 {
            guard group.allSatisfy({ slot in
                baseByID[slot.id].map { PlanSlotDraft.key(day: $0.day, occasion: $0.occasion) == slot.conflictKey } ?? false
            }) else { throw PlanAuthoringError.unresolvedConflict }
        }
        for slot in slots {
            guard slot.occasion.count <= 80 else { throw PlanAuthoringError.invalidSlots }
            if let outfit = slot.outfit {
                guard outfit.ownerID == plan.ownerID, outfits.contains(outfit) else { throw PlanValidationError.invalidOutfit }
            } else if !slot.unassignedByChoice { throw PlanAuthoringError.intentionalGapRequired }
        }
        let conflicts = conflicts(in: existing)
        guard Set(resolutions.map { $0.existing.id }).count == resolutions.count,
              resolutions.count == conflicts.count,
              conflicts.allSatisfy({ entry in resolutions.contains { $0.existing == entry } }) else { throw PlanAuthoringError.unresolvedConflict }
        for resolution in resolutions where resolution.choice == .replace {
            guard (resolution.existing.state == .planned || resolution.existing.state == .unassigned),
                  basePlan == nil || resolution.existing.planID != plan.id else { throw PlanAuthoringError.unresolvedConflict }
        }
    }
}

public struct PlanAuthoringReceipt: Codable, Equatable, Sendable {
    public let plan: PlanDefinition
    public let entries: [OutfitPlanEntry]
    public init(plan: PlanDefinition, entries: [OutfitPlanEntry]) { self.plan = plan; self.entries = entries }
}
