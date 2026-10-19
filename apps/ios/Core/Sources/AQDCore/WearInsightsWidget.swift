import Foundation

/// What a Wear insights widget on Today shows: one period and any mix of metrics, in the owner's order.
public struct WearInsightsOptions: Codable, Equatable, Sendable {
    public enum Period: String, Codable, CaseIterable, Sendable {
        case week, month, last30, lastMonth
        public var title: String {
            switch self { case .week: "This week"; case .month: "This month"; case .last30: "Last 30 days"; case .lastMonth: "Last month" }
        }
    }
    public enum Metric: String, Codable, CaseIterable, Sendable {
        case summary, mostWorn, unworn, categories, outfits, streak
        public var title: String {
            switch self {
            case .summary: "Summary"
            case .mostWorn: "Most worn pieces"
            case .unworn: "Not worn yet"
            case .categories: "Wear by category"
            case .outfits: "Top outfits"
            case .streak: "Wear streak"
            }
        }
        public var symbol: String {
            switch self {
            case .summary: "chart.bar"
            case .mostWorn: "arrow.up.right"
            case .unworn: "moon.zzz"
            case .categories: "square.grid.2x2"
            case .outfits: "tshirt"
            case .streak: "flame"
            }
        }
    }
    public var period: Period
    public var metrics: [Metric]
    public init(period: Period = .month, metrics: [Metric] = [.summary, .mostWorn, .unworn]) { self.period = period; self.metrics = metrics }
    public func validated() throws {
        guard !metrics.isEmpty, Set(metrics).count == metrics.count else { throw TodayLayoutError.invalidContent }
    }
}

/// Numbers behind a Wear insights widget, computed only from recorded wear. Plans and estimates never count.
public struct WearInsightsReport: Equatable, Sendable {
    public struct Ranked: Equatable, Sendable, Identifiable { public let id: UUID; public let name: String; public let count: Int }
    public struct CategoryShare: Equatable, Sendable { public let category: PieceCategory; public let count: Int }

    public let start: LocalPlanDay
    public let end: LocalPlanDay
    public let days: Int
    public let occasions: Int
    public let piecesUsed: Int
    public let activePieces: Int
    public let mostWorn: [Ranked]
    public let unworn: [Ranked]
    public let unwornCount: Int
    public let categories: [CategoryShare]
    public let outfits: [Ranked]
    public let streak: Int
    public var isEmpty: Bool { occasions == 0 }

    public static func range(_ period: WearInsightsOptions.Period, today: LocalPlanDay) -> (start: LocalPlanDay, end: LocalPlanDay) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: today.timeZoneID) ?? .current
        let zone = calendar.timeZone
        guard let now = try? today.date() else { return (today, today) }
        func day(_ date: Date) -> LocalPlanDay { LocalPlanDay(date: date, timeZone: zone) }
        switch period {
        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (day(start), today)
        case .month:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (day(start), today)
        case .last30:
            return (day(calendar.date(byAdding: .day, value: -29, to: now) ?? now), today)
        case .lastMonth:
            guard let current = calendar.dateInterval(of: .month, for: now)?.start, let previous = calendar.date(byAdding: .month, value: -1, to: current),
                  let last = calendar.date(byAdding: .day, value: -1, to: current) else { return (today, today) }
            return (day(previous), day(last))
        }
    }

    public static func make(period: WearInsightsOptions.Period, today: LocalPlanDay, pieces: [WardrobePiece], outfits: [Outfit], records: [OutfitWearRecord]) -> WearInsightsReport {
        let (start, end) = range(period, today: today)
        let inRange = records.filter { $0.day.key >= start.key && $0.day.key <= end.key }
        var pieceCounts: [UUID: Int] = [:], names: [UUID: String] = [:], categoryCounts: [PieceCategory: Int] = [:], outfitCounts: [UUID: Int] = [:]
        for record in inRange {
            for piece in record.pieces {
                pieceCounts[piece.id, default: 0] += 1; names[piece.id] = piece.name; categoryCounts[piece.category, default: 0] += 1
            }
            if let id = record.outfitID { outfitCounts[id, default: 0] += 1 }
        }
        func ranked(_ counts: [UUID: Int], name: (UUID) -> String?) -> [Ranked] {
            counts.compactMap { id, count in name(id).map { Ranked(id: id, name: $0, count: count) } }
                .sorted { $0.count == $1.count ? $0.name < $1.name : $0.count > $1.count }
        }
        let active = pieces.filter { !$0.isArchived }
        let unworn = active.filter { pieceCounts[$0.id] == nil }.map { Ranked(id: $0.id, name: $0.name, count: 0) }.sorted { $0.name < $1.name }
        let dayKeys = Set(inRange.map(\.day.key))
        // Streak: consecutive recorded days ending today, or yesterday when today is still empty.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: today.timeZoneID) ?? .current
        let allKeys = Set(records.map(\.day.key))
        var streak = 0
        if var cursor = try? today.date() {
            if !allKeys.contains(LocalPlanDay(date: cursor, timeZone: calendar.timeZone).key), let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) { cursor = yesterday }
            while allKeys.contains(LocalPlanDay(date: cursor, timeZone: calendar.timeZone).key), let previous = calendar.date(byAdding: .day, value: -1, to: cursor) {
                streak += 1; cursor = previous
            }
        }
        let outfitNames = Dictionary(uniqueKeysWithValues: outfits.map { ($0.id, $0.name) })
        return WearInsightsReport(
            start: start, end: end, days: dayKeys.count, occasions: inRange.count, piecesUsed: pieceCounts.count, activePieces: active.count,
            mostWorn: Array(ranked(pieceCounts) { names[$0] }.prefix(3)), unworn: Array(unworn.prefix(3)), unwornCount: unworn.count,
            categories: PieceCategory.allCases.compactMap { category in categoryCounts[category].map { CategoryShare(category: category, count: $0) } }.sorted { $0.count > $1.count },
            outfits: Array(ranked(outfitCounts) { outfitNames[$0] }.prefix(3)), streak: streak)
    }
}
