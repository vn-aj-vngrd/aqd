import AQDCore
import Foundation
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor
struct FitJournalPersistenceTests {
    private func seed(_ store: PieceStore) async throws -> (Outfit, WardrobePiece) {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32)) }
        let photo = try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 0.9)))
        _ = try store.acceptPhoto(photo)
        let piece = try store.savePiece(PieceDraft(name: "Snapshot shirt", category: .tops, photoID: photo.id), operationID: UUID())
        var draft = OutfitDraft(ownerID: try store.todayConfiguration().ownerID); draft.name = "Remember this"; draft.select(piece.id)
        try store.saveOutfitDraft(draft); let outfit = try store.saveOutfit(draft); try store.acknowledgeOutfitReceipt(draft)
        return (outfit, piece)
    }
    @Test func outfitOnlyMemoryRetainsSnapshotAfterSourceDeletionAndNeverChangesWear() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var unknown = false
        let store = try PieceStore(directory: directory, afterOutfitSave: { if unknown { throw CocoaError(.fileReadUnknown) } })
        let (outfit, piece) = try await seed(store)
        var draft = FitDraft(ownerID: outfit.ownerID)
        draft.value.note = "A note alone is not a fit"
        try store.saveFitDraft(draft)
        #expect(throws: FitValidationError.contentRequired) { try store.saveFit(draft) }
        draft.value.outfit = try FitOutfitSnapshot(outfit: outfit, pieces: [piece])
        draft.value.day = LocalPlanDay(year: 2026, month: 1, day: 1, timeZoneID: "Asia/Manila")
        draft.value.note = String(repeating: "👨‍👩‍👧‍👦", count: 501)
        try store.saveFitDraft(draft)
        #expect(throws: FitValidationError.noteTooLong) { try store.saveFit(draft) }
        #expect(try store.fitDraft()?.value.note.count == 501)
        draft.value.note = "Keep this date"
        try store.saveFitDraft(draft)
        unknown = true
        #expect(throws: (any Error).self) { try store.saveFit(draft) }
        let saved = try store.saveFit(draft); try store.finishFitDraft(draft)
        unknown = false
        let deletion = try store.outfitDeletionReview(id: outfit.id); _ = try store.applyOutfitMutation(deletion)
        #expect(try store.fitMemories() == [saved])
        var edit = FitDraft(ownerID: outfit.ownerID, base: saved); edit.value.note = "Snapshot retained"; edit.value.day.day = 2
        try store.saveFitDraft(edit); let updated = try store.saveFit(edit); try store.finishFitDraft(edit)
        #expect(updated.id == saved.id && updated.outfit == saved.outfit && updated.day.key == "2026-01-02")
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.fitMemories() == [updated])
        let request = FitDeletionRequest(memory: updated)
        try reopened.deleteFit(request); try reopened.deleteFit(request)
        #expect(try reopened.fitMemories().isEmpty)
        #expect(try reopened.wearRecords().isEmpty && reopened.planEntries().isEmpty)
        #expect(try reopened.piece(id: piece.id) != nil)
    }
    @Test func journalWearActionUsesTheFitDateAndDuplicateConsentWithoutChangingMemory() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let (outfit, piece) = try await seed(store)
        var draft = FitDraft(ownerID: outfit.ownerID)
        draft.value.outfit = try FitOutfitSnapshot(outfit: outfit, pieces: [piece])
        draft.value.day = LocalPlanDay(year: 2026, month: 1, day: 1, timeZoneID: "Asia/Manila")
        try store.saveFitDraft(draft); let memory = try store.saveFit(draft); try store.finishFitDraft(draft)
        let state = AppState(store: store)
        state.recordWear(from: memory)
        let first = try #require(state.wearEditor)
        #expect(first.draft.day == memory.day)
        await first.save(); let actual = try #require(first.saved); first.finish()
        state.recordWear(from: memory)
        let second = try #require(state.wearEditor)
        #expect(second.duplicate == actual)
        await second.save(useExisting: true); #expect(second.saved == actual); second.finish()
        #expect(try store.wearRecords() == [actual])
        #expect(try store.fitMemories() == [memory])
        try store.deleteFit(FitDeletionRequest(memory: memory))
        #expect(try store.wearRecords() == [actual] && store.planEntries().isEmpty)
        state.store = nil
    }

    @Test func editedFitPhotoRequiresPreparedBytesAndRetainsOnlyLiveRecipes() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let (outfit, piece) = try await seed(store)
        var draft = FitDraft(ownerID: outfit.ownerID); draft.value.photoID = piece.photoID
        try store.saveFitDraft(draft); let saved = try store.saveFit(draft); try store.finishFitDraft(draft)
        var edit = FitDraft(ownerID: outfit.ownerID, base: saved); edit.value.photoRecipe = PhotoEditRecipe(quarterTurns: 1)
        try store.saveFitDraft(edit)
        #expect(throws: (any Error).self) { try store.saveFit(edit) }
        let original = try store.originalPhoto(id: piece.photoID)
        let prepared = try await PhotoPreparer().render(data: original, sourcePhotoID: piece.photoID, recipe: edit.value.photoRecipe)
        try store.acceptPhotoEdit(prepared)
        try store.reconcilePendingPhotoCleanup()
        #expect(try store.photoRendition(id: piece.photoID, recipe: edit.value.photoRecipe) == prepared.renditionData)
        let updated = try store.saveFit(edit); try store.finishFitDraft(edit)
        try store.reconcilePendingPhotoCleanup()
        #expect(try store.photoRendition(id: piece.photoID, recipe: updated.photoRecipe) == prepared.renditionData)
        try store.deleteFit(FitDeletionRequest(memory: updated)); try store.reconcilePendingPhotoCleanup()
        #expect(try store.originalPhoto(id: piece.photoID) == original)
        #expect(throws: (any Error).self) { try store.photoRendition(id: piece.photoID, recipe: updated.photoRecipe) }
        #expect(try store.wearRecords().isEmpty)
    }

}
