import Foundation

/// Calendar queries over acknowledged local records. Reading never creates records.
public enum TodaySources {
    public static func completedMonth(before day: LocalPlanDay) throws -> LocalPlanDay {
        _ = try day.date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: day.timeZoneID) ?? .current
        guard let first = calendar.date(from: DateComponents(year: day.year, month: day.month, day: 1)),
              let previous = calendar.date(byAdding: .month, value: -1, to: first) else { throw PlanValidationError.invalidDay }
        return LocalPlanDay(date: previous, timeZone: calendar.timeZone)
    }
    public static func week(containing day: LocalPlanDay, through today: LocalPlanDay, firstWeekday: Int = Calendar.current.firstWeekday) throws -> (start: LocalPlanDay, end: LocalPlanDay) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: day.timeZoneID) ?? .current
        let date = try day.date()
        let offset = (calendar.component(.weekday, from: date) - firstWeekday + 7) % 7
        guard let start = calendar.date(byAdding: .day, value: -offset, to: date),
              let end = calendar.date(byAdding: .day, value: 6, to: start) else { throw PlanValidationError.invalidDay }
        let startDay = LocalPlanDay(date: start, timeZone: calendar.timeZone)
        let endDay = LocalPlanDay(date: end, timeZone: calendar.timeZone)
        return (startDay, endDay.key > today.key ? today : endDay)
    }
    public static func upcoming(_ entries: [OutfitPlanEntry], now: Date = Date(), days: Int = 7, planID: UUID? = nil) throws -> [OutfitPlanEntry] {
        guard days == 7 || days == 14 else { throw PlanValidationError.invalidDay }
        return try entries.filter { entry in
            if let planID, entry.planID != planID { return false }
            _ = try entry.day.date()
            guard let zone = TimeZone(identifier: entry.day.timeZoneID) else { throw PlanValidationError.invalidTimezone }
            var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
            guard let end = calendar.date(byAdding: .day, value: days, to: now) else { throw PlanValidationError.invalidDay }
            return entry.day.key >= LocalPlanDay(date: now, timeZone: zone).key && entry.day.key < LocalPlanDay(date: end, timeZone: zone).key
        }.sorted { $0.day.key == $1.day.key ? $0.id.uuidString < $1.id.uuidString : $0.day.key < $1.day.key }
    }
    public static func wearAgain(pieces: [WardrobePiece], records: [OutfitWearRecord], through today: LocalPlanDay) -> WardrobePiece? {
        let eligible = pieces.filter { !$0.isArchived && $0.availability == .available }
        let past = records.filter { $0.day.key <= today.key }
        let dates = Dictionary(eligible.map { piece in
            (piece.id, past.filter { $0.pieces.contains { $0.id == piece.id } }.map(\.day.key).max() ?? "")
        }, uniquingKeysWith: { first, _ in first })
        return eligible.sorted {
            let a = dates[$0.id, default: ""], b = dates[$1.id, default: ""]
            return a == b ? $0.id.uuidString < $1.id.uuidString : a < b
        }.first
    }
}
