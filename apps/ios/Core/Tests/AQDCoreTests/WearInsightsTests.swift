import Foundation
import Testing
@testable import AQDCore

struct WearInsightsTests {
    @Test func monthUsesRecordedDatesAndActiveDenominatorExcludingEstimates() throws {
        let owner = UUID()
        var details = PieceDetails(); details.priorWearCount = 20
        let shirt = WardrobePiece(id: UUID(), name: "Shirt", category: .tops, photoID: UUID(), details: details)
        let jeans = WardrobePiece(id: UUID(), name: "Jeans", category: .bottoms, photoID: UUID())
        let archived = WardrobePiece(id: UUID(), name: "Archived", category: .tops, photoID: UUID(), isArchived: true)
        func record(_ month: Int, _ day: Int, _ pieces: [WardrobePiece]) -> OutfitWearRecord {
            OutfitWearRecord(id: UUID(), ownerID: owner, day: LocalPlanDay(year: 2026, month: month, day: day, timeZoneID: "Asia/Manila"), outfitID: nil, pieces: pieces.map(WearPieceSnapshot.init))
        }
        let records = [record(9, 30, [jeans]), record(10, 1, [shirt, archived]), record(10, 31, [shirt]), record(11, 1, [jeans])]
        let month = LocalPlanDay(year: 2026, month: 10, day: 16, timeZoneID: "Asia/Manila")
        let summary = try WearPeriodSummary(month: month, pieces: [shirt, jeans, archived], records: records)
        #expect(summary.start.key == "2026-10-01" && summary.end.key == "2026-10-31")
        #expect(summary.occasions == 2 && summary.itemOccurrences == 3)
        #expect(summary.usedActiveCount == 1 && summary.activeCount == 2)
        #expect(summary.utilization == 0.5)
        #expect(summary.counts[shirt.id] == 2 && summary.counts[jeans.id] == nil)
        #expect(PieceWearSummary(piece: shirt, records: records).total == 22)
        let empty = try WearPeriodSummary(month: month, pieces: [shirt], records: [])
        #expect(empty.utilization == nil)
        let zeroDenominator = try WearPeriodSummary(month: month, pieces: [], records: records)
        #expect(zeroDenominator.utilization == nil && zeroDenominator.occasions == 2)
    }
}
