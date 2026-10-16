import Foundation

public enum PlanAuthoringError: Error, Equatable { case invalidRange, rangeTooLong, nameRequired, invalidSlots, intentionalGapRequired, unresolvedConflict }

public struct PlanDefinition: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let ownerID: UUID
    public var name: String
    public var start: LocalPlanDay
    public var end: LocalPlanDay
    public var revision: Int

    public init(id: UUID = UUID(), ownerID: UUID, name: String = "", start: LocalPlanDay, end: LocalPlanDay, revision: Int = 1) {
        self.id = id; self.ownerID = ownerID; self.name = name; self.start = start; self.end = end; self.revision = revision
    }
    public func days() throws -> [LocalPlanDay] {
        let first = try start.date(), last = try end.date()
        guard start.timeZoneID == end.timeZoneID, start.key <= end.key,
              let zone = TimeZone(identifier: start.timeZoneID) else { throw PlanAuthoringError.invalidRange }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
        var cursor = first, result: [LocalPlanDay] = []
        while cursor <= last {
            guard result.count < 14 else { throw PlanAuthoringError.rangeTooLong }
            result.append(LocalPlanDay(date: cursor, timeZone: zone))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor), next > cursor else { throw PlanAuthoringError.invalidRange }
            cursor = next
        }
        return result
    }
    public func validated() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, name.count <= 80 else { throw PlanAuthoringError.nameRequired }
        guard revision > 0, revision < Int.max else { throw PlanAuthoringError.invalidSlots }
        _ = try days()
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

    public init(plan: PlanDefinition) throws {
        id = UUID(); operationID = UUID(); self.plan = plan
        slots = try plan.days().map { PlanSlotDraft(day: $0) }; resolutions = []; reviewing = false
    }
    public mutating func rebuildDates() throws {
        let days = try plan.days()
        guard Set(slots.map { $0.day.key }).count == slots.count else { throw PlanAuthoringError.invalidSlots }
        let existing = Dictionary(uniqueKeysWithValues: slots.map { ($0.day.key, $0) })
        slots = days.map { day in
            var slot = existing[day.key] ?? PlanSlotDraft(day: day)
            slot.day = day; return slot
        }
        resolutions = []
    }
    public func conflicts(in entries: [OutfitPlanEntry]) -> [OutfitPlanEntry] {
        let keys = Set(slots.map(\.conflictKey))
        return entries.filter { keys.contains(PlanSlotDraft.key(day: $0.day, occasion: $0.occasion)) }
    }
    public func validatedForSave(outfits: [Outfit], existing: [OutfitPlanEntry]) throws {
        try plan.validated()
        let days = try plan.days()
        guard slots.count == days.count, Set(slots.map(\.id)).count == slots.count,
              slots.map(\.day) == days else { throw PlanAuthoringError.invalidSlots }
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
            guard resolution.existing.state == .planned || resolution.existing.state == .unassigned else { throw PlanAuthoringError.unresolvedConflict }
        }
    }
}

public struct PlanAuthoringReceipt: Codable, Equatable, Sendable {
    public let plan: PlanDefinition
    public let entries: [OutfitPlanEntry]
    public init(plan: PlanDefinition, entries: [OutfitPlanEntry]) { self.plan = plan; self.entries = entries }
}
