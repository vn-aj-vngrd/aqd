import Foundation

public struct WearPeriodSummary: Equatable, Sendable {
    public let start: LocalPlanDay
    public let end: LocalPlanDay
    public let occasions: Int
    public let dailyOccasions: [Int: Int]
    public let itemOccurrences: Int
    public let counts: [UUID: Int]
    public let activeCount: Int
    public let usedActiveCount: Int
    public var utilization: Double? { occasions > 0 && activeCount > 0 ? Double(usedActiveCount) / Double(activeCount) : nil }

    public init(month: LocalPlanDay, pieces: [WardrobePiece], records: [OutfitWearRecord]) throws {
        _ = try month.date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: month.timeZoneID) ?? .current
        start = LocalPlanDay(year: month.year, month: month.month, day: 1, timeZoneID: month.timeZoneID)
        guard let days = calendar.range(of: .day, in: .month, for: try start.date()) else { throw PlanValidationError.invalidDay }
        end = LocalPlanDay(year: month.year, month: month.month, day: days.count, timeZoneID: month.timeZoneID)
        let firstKey = start.key, lastKey = end.key
        let selected = records.filter { $0.day.key >= firstKey && $0.day.key <= lastKey }
        occasions = selected.count
        dailyOccasions = Dictionary(grouping: selected, by: { $0.day.day }).mapValues { $0.count }
        var counts: [UUID: Int] = [:]
        for record in selected { for piece in record.pieces { counts[piece.id, default: 0] += 1 } }
        self.counts = counts; itemOccurrences = selected.reduce(0) { $0 + $1.pieces.count }
        let active = Set(pieces.filter { !$0.isArchived }.map(\.id))
        activeCount = active.count; usedActiveCount = active.filter { counts[$0, default: 0] > 0 }.count
    }
}
