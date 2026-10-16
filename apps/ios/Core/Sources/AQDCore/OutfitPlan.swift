import Foundation

public enum PlanValidationError: Error, Equatable { case invalidDay, invalidTimezone, invalidOutfit, overlap, invalidRecord }

/// A calendar day in its recorded timezone, independent of later device travel.
public struct LocalPlanDay: Codable, Equatable, Sendable {
    public var year: Int
    public var month: Int
    public var day: Int
    public var timeZoneID: String

    public init(date: Date = Date(), timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = timeZone
        let values = calendar.dateComponents([.year, .month, .day], from: date)
        year = values.year ?? 2000; month = values.month ?? 1; day = values.day ?? 1; timeZoneID = timeZone.identifier
    }

    public init(year: Int, month: Int, day: Int, timeZoneID: String) {
        self.year = year; self.month = month; self.day = day; self.timeZoneID = timeZoneID
    }

    public func date() throws -> Date {
        guard let zone = TimeZone(identifier: timeZoneID) else { throw PlanValidationError.invalidTimezone }
        guard (1...9999).contains(year), (1...12).contains(month), (1...31).contains(day) else { throw PlanValidationError.invalidDay }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
        guard let value = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) else {
            throw PlanValidationError.invalidDay
        }
        let result = calendar.dateComponents([.year, .month, .day], from: value)
        guard result.year == year, result.month == month, result.day == day else { throw PlanValidationError.invalidDay }
        return value
    }

    public var key: String { String(format: "%04d-%02d-%02d", year, month, day) }
}

public enum PlanEntryState: String, Codable, Sendable { case unassigned, planned, worn, skipped }

public struct OutfitPlanEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let planID: UUID
    public let ownerID: UUID
    public var day: LocalPlanDay
    public var occasion: String
    public var outfitID: UUID?
    public var outfitRevision: Int?
    public var state: PlanEntryState
    public var requiresReview: Bool
    public var revision: Int

    public func validated() throws {
        _ = try day.date()
        guard revision > 0, revision < Int.max, occasion.count <= 80,
              (outfitID == nil) == (outfitRevision == nil), outfitRevision.map({ $0 > 0 }) ?? true,
              state != .planned || outfitID != nil else { throw PlanValidationError.invalidRecord }
    }

    public init(id: UUID, planID: UUID, ownerID: UUID, day: LocalPlanDay, occasion: String,
                outfitID: UUID?, outfitRevision: Int?, state: PlanEntryState, requiresReview: Bool = false, revision: Int = 1) {
        self.id = id; self.planID = planID; self.ownerID = ownerID; self.day = day; self.occasion = occasion
        self.outfitID = outfitID; self.outfitRevision = outfitRevision; self.state = state
        self.requiresReview = requiresReview; self.revision = revision
    }
}

public struct OutfitPlanDraft: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let entryID: UUID
    public let planID: UUID
    public let ownerID: UUID
    public let operationID: UUID
    public var day: LocalPlanDay
    public var occasion: String
    public var outfit: Outfit?
    public var unassignedByChoice: Bool?
    public var allowsOverlap: Bool?
    public var baseEntry: OutfitPlanEntry?
    public var parentPlanID: UUID?

    public init(ownerID: UUID, outfit: Outfit? = nil, day: LocalPlanDay = LocalPlanDay(), planID: UUID? = nil) {
        id = UUID(); entryID = UUID(); self.planID = planID ?? UUID(); parentPlanID = planID; operationID = UUID()
        self.ownerID = ownerID; self.outfit = outfit; self.day = day; occasion = ""
    }

    public init(editing entry: OutfitPlanEntry, outfit: Outfit?) {
        id = UUID(); operationID = UUID(); entryID = entry.id; planID = entry.planID; ownerID = entry.ownerID
        day = entry.day; occasion = entry.occasion; self.outfit = outfit; baseEntry = entry
        unassignedByChoice = entry.outfitID == nil
    }

    public func validatedForSave(outfits: [Outfit]) throws {
        _ = try day.date()
        guard parentPlanID == nil || parentPlanID == planID else { throw PlanValidationError.invalidRecord }
        if let baseEntry {
            try baseEntry.validated()
            guard baseEntry.id == entryID, baseEntry.planID == planID, baseEntry.ownerID == ownerID,
                  baseEntry.state == .planned || baseEntry.state == .unassigned else { throw PlanValidationError.invalidRecord }
        }
        guard occasion.count <= 80 else { throw PlanValidationError.invalidRecord }
        guard outfit != nil || unassignedByChoice == true else { throw PlanValidationError.invalidOutfit }
        if let outfit {
            guard outfit.ownerID == ownerID, outfits.contains(outfit) else { throw PlanValidationError.invalidOutfit }
            try outfit.validated()
        }
    }
}
