import Foundation
import Testing
@testable import AQDCore

struct WearInsightsWidgetTests {
    private let owner = UUID()
    private func piece(_ name: String, _ category: PieceCategory) -> WardrobePiece {
        WardrobePiece(id: UUID(), name: name, category: category, photoID: UUID())
    }
    private func record(_ day: LocalPlanDay, _ pieces: [WardrobePiece], outfit: UUID? = nil) -> OutfitWearRecord {
        OutfitWearRecord(id: UUID(), ownerID: owner, day: day, outfitID: outfit, pieces: pieces.map(WearPieceSnapshot.init))
    }
    private let today = LocalPlanDay(year: 2026, month: 10, day: 18, timeZoneID: "Asia/Manila")
    private func day(_ value: Int) -> LocalPlanDay { LocalPlanDay(year: 2026, month: 10, day: value, timeZoneID: "Asia/Manila") }

    @Test func reportCountsOnlyRecordedWearInTheChosenPeriod() {
        let tee = piece("Tee", .tops), jeans = piece("Jeans", .bottoms), coat = piece("Coat", .layers), unused = piece("Unused", .shoes)
        let outfit = Outfit(id: UUID(), ownerID: owner, name: "Coffee run", pieceIDs: [tee.id, jeans.id], createdAt: Date(), updatedAt: Date())
        let records = [record(day(18), [tee, jeans], outfit: outfit.id), record(day(17), [tee, coat]), record(day(2), [jeans]),
                       record(LocalPlanDay(year: 2026, month: 9, day: 30, timeZoneID: "Asia/Manila"), [coat])]
        let report = WearInsightsReport.make(period: .month, today: today, pieces: [tee, jeans, coat, unused], outfits: [outfit], records: records)
        #expect(report.occasions == 3 && report.days == 3 && report.piecesUsed == 3)
        #expect(report.mostWorn.contains { $0.name == "Tee" && $0.count == 2 })
        #expect(report.unworn.map(\.name) == ["Unused"] && report.unwornCount == 1)
        #expect(report.outfits.first?.name == "Coffee run")
        #expect(report.streak == 2)
        let last = WearInsightsReport.make(period: .lastMonth, today: today, pieces: [tee, jeans, coat], outfits: [], records: records)
        #expect(last.occasions == 1 && last.mostWorn.first?.name == "Coat")
    }

    @Test func anEmptyPeriodIsEmptyAndHasNoStreak() {
        let report = WearInsightsReport.make(period: .week, today: today, pieces: [], outfits: [], records: [])
        #expect(report.isEmpty && report.streak == 0 && report.mostWorn.isEmpty)
    }

    @Test func optionsNeedUniqueMetricsAndOnlyBelongOnTheInsightsWidget() throws {
        try WearInsightsOptions().validated()
        #expect(throws: TodayLayoutError.invalidContent) { try WearInsightsOptions(metrics: []).validated() }
        #expect(throws: TodayLayoutError.invalidContent) { try WearInsightsOptions(metrics: [.summary, .summary]).validated() }
        let wrong = TodayWidgetInstance(kind: .todayLook, options: TodayWidgetOptions(insights: WearInsightsOptions()))
        #expect(throws: TodayLayoutError.invalidContent) { try wrong.validatedContent(ownerID: owner) }
        let right = TodayWidgetInstance(kind: .wearInsights, options: TodayWidgetOptions(insights: WearInsightsOptions(period: .week, metrics: [.streak, .summary])))
        try right.validatedContent(ownerID: owner)
    }
}
