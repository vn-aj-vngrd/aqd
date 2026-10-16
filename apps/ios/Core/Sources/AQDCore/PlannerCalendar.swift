import Foundation

public enum PlannerCalendarMode: String, CaseIterable, Sendable { case week = "Week", month = "Month" }

public enum PlannerCalendar {
    public static func days(containing day: LocalPlanDay, mode: PlannerCalendarMode, calendar original: Calendar = .current) throws -> [LocalPlanDay] {
        var calendar = original
        guard let zone = TimeZone(identifier: day.timeZoneID) else { throw PlanValidationError.invalidTimezone }
        calendar.timeZone = zone
        let date = try day.date()
        let component: Calendar.Component = mode == .week ? .weekOfYear : .month
        guard let interval = calendar.dateInterval(of: component, for: date),
              let start = calendar.dateInterval(of: .weekOfYear, for: interval.start)?.start,
              let end = calendar.dateInterval(of: .weekOfYear, for: interval.end.addingTimeInterval(-1))?.end else {
            throw PlanValidationError.invalidDay
        }
        var cursor = start, result: [LocalPlanDay] = []
        while cursor < end {
            guard result.count < 42 else { throw PlanValidationError.invalidDay }
            result.append(LocalPlanDay(date: cursor, timeZone: zone))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor), next > cursor else { throw PlanValidationError.invalidDay }
            cursor = next
        }
        return result
    }

    public static func move(_ day: LocalPlanDay, mode: PlannerCalendarMode, by amount: Int, calendar original: Calendar = .current) throws -> LocalPlanDay {
        var calendar = original
        guard let zone = TimeZone(identifier: day.timeZoneID) else { throw PlanValidationError.invalidTimezone }
        calendar.timeZone = zone
        guard let date = calendar.date(byAdding: mode == .week ? .weekOfYear : .month, value: amount, to: try day.date()) else {
            throw PlanValidationError.invalidDay
        }
        return LocalPlanDay(date: date, timeZone: zone)
    }
}

public struct PlanEntryDeletionRequest: Codable, Equatable, Sendable {
    public let operationID: UUID
    public let entryID: UUID
    public let expectedRevision: Int
    public init(entry: OutfitPlanEntry, operationID: UUID = UUID()) {
        self.operationID = operationID; entryID = entry.id; expectedRevision = entry.revision
    }
}
