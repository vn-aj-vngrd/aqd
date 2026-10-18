import Foundation

public enum AgentMutationKind: String, Codable, CaseIterable, Sendable {
    case addPiece, editPiece, createOutfit, editOutfit, createTheme, editTheme, createPlan, editPlan, recordWear, setAvailability, updateProfile, relabel, createTrip
    public var requiredSources: [AgentDataSource] {
        switch self {
        case .createOutfit, .editOutfit: [.pieces, .outfits]
        case .createTheme, .editTheme: [.themes, .outfits]
        case .relabel: [.outfits, .themes, .pieces]
        case .createPlan, .editPlan: [.planner, .outfits, .pieces]
        case .createTrip: [.pieces, .outfits, .themes, .planner]
        case .recordWear: [.wear, .pieces]
        case .setAvailability, .editPiece, .addPiece: [.pieces]
        case .updateProfile: [.profile]
        }
    }
}

public struct AgentPlanAssignment: Codable, Equatable, Sendable {
    public let date: String
    public let outfitID: UUID
    public init(date: String, outfitID: UUID) { self.date = date; self.outfitID = outfitID }
}

/// Untrusted model arguments become an immutable, validated review. This never writes records.
public struct AgentMutationRequest: Codable, Equatable, Sendable {
    public var kind: AgentMutationKind
    public var targetID: UUID?
    public var name: String?
    public var caption: String?
    public var color: String?
    public var brand: String?
    public var pieceIDs: [UUID]
    public var outfitIDs: [UUID]
    public var date: String?
    public var assignments: [AgentPlanAssignment]
    public var availability: PieceAvailability?
    public var occasion: String?
    public var mood: String?
    public var themeDescription: String?
    public var pinnedIDs: [UUID]?
    public var category: String?
    /// Inclusive range a new plan must cover completely; days arrive in batches and are only reviewed once none are missing.
    public var rangeStart: String?
    public var rangeEnd: String?
    public var attachmentID: UUID?
    public var trip: AgentTripSpec?
    public init(kind: AgentMutationKind, targetID: UUID? = nil, name: String? = nil, caption: String? = nil, color: String? = nil, brand: String? = nil,
                pieceIDs: [UUID] = [], outfitIDs: [UUID] = [], date: String? = nil,
                assignments: [AgentPlanAssignment] = [], availability: PieceAvailability? = nil,
                occasion: String? = nil, mood: String? = nil, themeDescription: String? = nil, pinnedIDs: [UUID]? = nil,
                category: String? = nil, attachmentID: UUID? = nil, rangeStart: String? = nil, rangeEnd: String? = nil, trip: AgentTripSpec? = nil) {
        self.kind = kind; self.targetID = targetID; self.name = name; self.caption = caption; self.color = color; self.brand = brand
        self.pieceIDs = pieceIDs; self.outfitIDs = outfitIDs; self.date = date; self.assignments = assignments; self.availability = availability
        self.occasion = occasion; self.mood = mood; self.themeDescription = themeDescription; self.pinnedIDs = pinnedIDs
        self.category = category; self.attachmentID = attachmentID; self.rangeStart = rangeStart; self.rangeEnd = rangeEnd; self.trip = trip
    }
    private static func day(_ text: String, timeZone: TimeZone) throws -> LocalPlanDay {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false).compactMap { Int($0) }
        guard parts.count == 3 else { throw PlanValidationError.invalidDay }
        let result = LocalPlanDay(year: parts[0], month: parts[1], day: parts[2], timeZoneID: timeZone.identifier)
        guard result.key == text else { throw PlanValidationError.invalidDay }; _ = try result.date(); return result
    }
    /// Days of the requested range that no assignment covers yet; nil when the request names no range. Throws when the range is invalid or too long.
    public func missingDays(timeZone: TimeZone = .current) throws -> [String]? {
        guard let rangeStart, let rangeEnd else { return nil }
        let range = try PlanDefinition(ownerID: UUID(), name: "Range", start: Self.day(rangeStart, timeZone: timeZone), end: Self.day(rangeEnd, timeZone: timeZone)).days().map(\.key)
        let covered = Set(assignments.map(\.date))
        return range.filter { !covered.contains($0) }
    }
    public func prepare(ownerID: UUID, pieces: [WardrobePiece] = [], outfits: [Outfit] = [], themes: [OutfitTheme] = [],
                        plans: [PlanDefinition] = [], entries: [OutfitPlanEntry] = [], identity: LocalProfileIdentity? = nil,
                        timeZone: TimeZone = .current) throws -> AgentReviewedAction {
        guard pieceIDs.count <= 24, outfitIDs.count <= 24, assignments.count <= 14,
              Set(pieceIDs).count == pieceIDs.count, Set(outfitIDs).count == outfitIDs.count,
              (name?.count ?? 0) <= 80, (caption?.count ?? 0) <= 160,
              (occasion?.count ?? 0) <= 80, (mood?.count ?? 0) <= 80, (themeDescription?.count ?? 0) <= 160 else { throw PlanValidationError.invalidRecord }
        func day(_ text: String) throws -> LocalPlanDay { try Self.day(text, timeZone: timeZone) }
        // A relabel edits the name, occasion, mood or description of whichever saved record the ID names.
        var kind = kind
        if kind == .relabel {
            guard name != nil || occasion != nil || mood != nil || themeDescription != nil else { throw PlanValidationError.invalidRecord }
            kind = outfits.contains { $0.id == targetID } ? .editOutfit : .editTheme
        }
        let relabeling = self.kind == .relabel
        switch kind {
        case .addPiece:
            guard let attachmentID else { throw PlanValidationError.invalidRecord }
            // Guesses only: an unknown category or empty name stays blank for the user to classify in the editor.
            let guess = category?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
            let type = PieceCategory.allCases.first { $0.rawValue.lowercased() == guess || String($0.rawValue.lowercased().dropLast()) == guess }
            var draft = PieceDraft(name: name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", category: type)
            draft.details.color = color ?? ""; draft.details.brand = brand ?? ""
            try draft.details.validated()
            return .piece(AgentPieceChange(draft: draft, attachmentID: attachmentID))
        case .editPiece:
            guard let piece = pieces.first(where: { $0.id == targetID && !$0.isArchived }), name != nil || color != nil || brand != nil else { throw PlanValidationError.invalidRecord }
            var draft = PieceDraft(itemID: piece.id, name: piece.name, category: piece.category, photoID: piece.photoID, baseRevision: piece.revision,
                details: piece.details, availability: piece.availability, photoRecipe: piece.photoRecipe)
            if let name { draft.name = name }; if let color { draft.details.color = color }; if let brand { draft.details.brand = brand }
            try draft.validated(); return .piece(AgentPieceChange(draft: draft))
        case .createOutfit, .editOutfit:
            var draft: OutfitDraft
            if kind == .editOutfit {
                guard let value = outfits.first(where: { $0.id == targetID && $0.ownerID == ownerID }) else { throw PlanValidationError.invalidRecord }
                draft = OutfitDraft(editing: value)
            } else { draft = OutfitDraft(ownerID: ownerID) }
            if let name { draft.name = name }
            if let occasion { draft.occasion = occasion }; if let mood { draft.mood = mood }
            if let pinnedIDs { draft.pinnedPieceIDs = pinnedIDs }
            if !pieceIDs.isEmpty { try draft.applyManualSelection(pieceIDs, pieces: pieces) }
            else { try draft.reviewCurrentPieces(pieces) }
            guard relabeling || draft.pieceIDs.allSatisfy({ id in pieces.contains { $0.id == id && !$0.isArchived && $0.availability == .available } }) else { throw OutfitValidationError.unavailablePiece }
            try draft.validatedForSave(pieces: pieces); return .outfit(draft)
        case .createTheme, .editTheme:
            var draft: ThemeDraft
            if kind == .editTheme {
                guard let value = themes.first(where: { $0.id == targetID && $0.ownerID == ownerID }) else { throw PlanValidationError.invalidRecord }
                draft = ThemeDraft(editing: value)
            } else { draft = ThemeDraft(ownerID: ownerID) }
            if let name { draft.name = name }
            if let themeDescription { draft.description = themeDescription }
            if relabeling, occasion != nil || mood != nil { throw PlanValidationError.invalidRecord }
            if !outfitIDs.isEmpty { draft.outfitIDs = outfitIDs }
            try draft.validatedForSave(themes: themes, outfits: outfits); return .theme(draft)
        case .createPlan, .editPlan:
            guard !assignments.isEmpty else { throw PlanAuthoringError.invalidSlots }
            let days = try assignments.map { try day($0.date) }
            guard Set(days.map(\.key)).count == days.count else { throw PlanAuthoringError.invalidSlots }
            if let missing = try missingDays(timeZone: timeZone), !missing.isEmpty || days.contains(where: { $0.key < rangeStart ?? "" || $0.key > rangeEnd ?? "" }) { throw PlanAuthoringError.invalidSlots }
            var draft: PlanAuthoringDraft
            if kind == .editPlan {
                guard let value = plans.first(where: { $0.id == targetID && $0.ownerID == ownerID }), value.routine == nil, value.trip == nil else { throw PlanValidationError.invalidRecord }
                draft = try PlanAuthoringDraft(editing: value, entries: entries.filter { $0.planID == value.id }, outfits: outfits, scope: .whole, anchorEntryID: nil)
                // Preserve existing slots and dates; only the explicitly supplied assignments change.
            } else {
                draft = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: ownerID, name: name ?? "", start: days.min { $0.key < $1.key }!, end: days.max { $0.key < $1.key }!))
            }
            if let name { draft.plan.name = name }
            for (assignment, day) in zip(assignments, days) {
                guard let i = draft.slots.firstIndex(where: { $0.day == day }),
                      let outfit = outfits.first(where: { $0.id == assignment.outfitID && $0.ownerID == ownerID }),
                      outfit.pieceIDs.allSatisfy({ id in pieces.contains { $0.id == id && !$0.isArchived && $0.availability == .available } }) else { throw PlanAuthoringError.invalidSlots }
                draft.slots[i].outfit = outfit; draft.slots[i].unassignedByChoice = false
            }
            draft.reviewing = true; try draft.validatedForSave(outfits: outfits, existing: entries); return .plan(draft)
        case .createTrip:
            guard let trip, trip.days.count <= TripOutfitComposer.maximumDays else { throw PlanValidationError.invalidRecord }
            return .trip(try AgentTripDraft(ownerID: ownerID, name: name ?? "", spec: trip, pieces: pieces, outfits: outfits, themes: themes, existing: entries, timeZone: timeZone))
        case .recordWear:
            guard let date, Set(pieceIDs).isSubset(of: Set(pieces.map(\.id))) else { throw WearValidationError.piecesRequired }
            let draft = OutfitWearDraft(ownerID: ownerID, pieces: pieces.filter { pieceIDs.contains($0.id) }, day: try day(date))
            try draft.validatedForSave(pieces: pieces); return .wear(draft)
        case .setAvailability:
            guard let availability, let piece = pieces.first(where: { $0.id == targetID && !$0.isArchived }) else { throw PlanValidationError.invalidRecord }
            return .availability(AgentAvailabilityChange(piece: piece, value: availability))
        case .relabel: throw PlanValidationError.invalidRecord
        case .updateProfile:
            guard name != nil || caption != nil, identity == nil || identity?.ownerID == ownerID else { throw PlanValidationError.invalidRecord }
            var draft = LocalIdentityDraft(ownerID: ownerID, base: identity)
            if let name { draft.name = name }; if let caption { draft.caption = caption }
            _ = try draft.result(); guard draft.hasChanges else { throw PlanValidationError.invalidRecord }; return .profile(draft)
        }
    }
}
