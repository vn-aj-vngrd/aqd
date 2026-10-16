import Foundation
import Testing
@testable import AQDCore

struct TodaySourcesTests {
    private let owner = UUID()
    private let today = LocalPlanDay(year: 2026, month: 10, day: 16, timeZoneID: "Asia/Manila")
    @Test func completedMonthAndLocaleWeekDoNotIncludeFutureWear() throws {
        let month = try TodaySources.completedMonth(before: today)
        #expect(month.key == "2026-09-01")
        let bounds = try TodaySources.week(containing: today, through: today, firstWeekday: 2)
        #expect(bounds.start.key == "2026-10-12")
        #expect(bounds.end.key == today.key)
        let previous = try TodaySources.completedMonth(before: LocalPlanDay(year: 2026, month: 1, day: 1, timeZoneID: "Asia/Manila"))
        #expect(previous.key == "2025-12-01")
    }
    @Test func planWindowsUseEachEntryZoneAndKeepDistinctOccasions() throws {
        let instant = try today.date()
        let entries = [entry(day: today), entry(day: today), entry(day: LocalPlanDay(year: 2026, month: 10, day: 23, timeZoneID: "Asia/Manila"))]
        let result = try TodaySources.upcoming(entries, now: instant, days: 7)
        #expect(Set(result.map(\.id)) == Set(entries.prefix(2).map(\.id)))
        #expect(try TodaySources.upcoming(entries, now: instant, days: 14).count == 3)
    }
    @Test func leastRecentUsesActualRecordsAndExcludesUnavailablePieces() {
        let first = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let second = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let pieces = [piece(second), piece(first), piece(UUID(), availability: .laundry)]
        #expect(TodaySources.wearAgain(pieces: pieces, records: [], through: today)?.id == first)
        #expect(TodaySources.wearAgain(pieces: [], records: [], through: today) == nil)
    }
    private func entry(day: LocalPlanDay) -> OutfitPlanEntry {
        OutfitPlanEntry(id: UUID(), planID: UUID(), ownerID: owner, day: day, occasion: "", outfitID: nil, outfitRevision: nil, state: .unassigned)
    }
    private func piece(_ id: UUID, availability: PieceAvailability = .available) -> WardrobePiece {
        WardrobePiece(id: id, name: "Owned", category: .tops, photoID: UUID(), availability: availability)
    }
}
