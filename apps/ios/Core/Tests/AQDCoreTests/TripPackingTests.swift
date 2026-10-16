import Foundation
import Testing
@testable import AQDCore

struct TripPackingTests {
    @Test func packingDeduplicatesOwnedPiecesAndReportsUnassignedDates() throws {
        let owner = UUID()
        let day = LocalPlanDay(year: 2026, month: 10, day: 18, timeZoneID: "Asia/Seoul")
        var second = day; second.day = 19
        let plan = PlanDefinition(ownerID: owner, name: "Seoul", start: day, end: second, trip: TripConfiguration(destination: "Seoul", activities: ["Walking"]))
        let shirt = WardrobePiece(id: UUID(), name: "Shirt", category: .tops, photoID: UUID())
        let shoes = WardrobePiece(id: UUID(), name: "Shoes", category: .shoes, photoID: UUID())
        let outfit = Outfit(id: UUID(), ownerID: owner, name: "Walk", pieceIDs: [shirt.id, shoes.id])
        let assigned = OutfitPlanEntry(id: UUID(), planID: plan.id, ownerID: owner, day: day, occasion: "Walking",
            outfitID: outfit.id, outfitRevision: 1, state: .planned)
        let another = OutfitPlanEntry(id: UUID(), planID: plan.id, ownerID: owner, day: day, occasion: "Dinner",
            outfitID: outfit.id, outfitRevision: 1, state: .planned)
        let summary = try TripPackingSummary(plan: plan, entries: [assigned, another], outfits: [outfit], pieces: [shirt, shoes], checkedIDs: [shirt.id])
        #expect(summary.items.count == 2)
        #expect(summary.items.first { $0.id == shirt.id }?.uses == 2)
        #expect(summary.items.first { $0.id == shirt.id }?.checked == true)
        #expect(summary.gaps.count == 1)
        #expect(summary.gaps.first?.day == second)
    }
}
