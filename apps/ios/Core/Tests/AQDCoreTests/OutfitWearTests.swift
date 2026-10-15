import Foundation
import Testing
@testable import AQDCore

struct OutfitWearTests {
    private func piece(_ name: String) -> WardrobePiece {
        WardrobePiece(id: UUID(), name: name, category: .tops, photoID: UUID())
    }
    @Test func sameItemSetAndDayDeduplicateIndependentlyOfSelectionOrder() throws {
        let first = piece("Shirt"), second = piece("Layer"), owner = UUID()
        let day = LocalPlanDay(year: 2026, month: 1, day: 1, timeZoneID: "Asia/Manila")
        let one = OutfitWearDraft(ownerID: owner, pieces: [first, second], day: day)
        let two = OutfitWearDraft(ownerID: owner, pieces: [second, first], day: day)
        #expect(one.duplicateKey == two.duplicateKey)
        let saved = OutfitWearRecord(id: UUID(), ownerID: owner, day: day, outfitID: nil, pieces: [WearPieceSnapshot(first), WearPieceSnapshot(second)])
        #expect(saved.duplicateKey == one.duplicateKey)
        try saved.validated()
        let encoded = try JSONEncoder().encode(saved)
        let text = String(decoding: encoded, as: UTF8.self)
        #expect(!text.contains("photoID"))
        #expect(!text.contains("notes"))
    }
    @Test func actualWearRejectsFutureDaysAndStalePieces() throws {
        let item = piece("Shirt")
        var draft = OutfitWearDraft(ownerID: UUID(), pieces: [item], day: LocalPlanDay(year: 2099, month: 1, day: 1, timeZoneID: "Asia/Manila"))
        let now = try LocalPlanDay(year: 2026, month: 10, day: 16, timeZoneID: "Asia/Manila").date()
        #expect(throws: WearValidationError.futureDay) { try draft.validatedForSave(pieces: [item], now: now) }
        draft.day = LocalPlanDay(year: 2026, month: 1, day: 1, timeZoneID: "Asia/Manila")
        #expect(throws: WearValidationError.stalePieces) { try draft.validatedForSave(pieces: [], now: now) }
        try draft.validatedForSave(pieces: [item], now: now)
    }
}
