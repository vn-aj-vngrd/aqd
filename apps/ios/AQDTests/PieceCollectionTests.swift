import AQDCore
import Foundation
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor
struct PieceCollectionTests {
    private func seed(_ store: PieceStore) async throws -> (WardrobePiece, WardrobePiece, Outfit) {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in
            UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32))
        }
        let photo = try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 0.9)))
        _ = try store.acceptPhoto(photo)
        let one = try store.savePiece(PieceDraft(name: "Shirt", category: .tops, photoID: photo.id,
            details: PieceDetails(priorWearCount: 4)), operationID: UUID())
        let two = try store.savePiece(PieceDraft(name: "Boots", category: .shoes, photoID: photo.id), operationID: UUID())
        var draft = OutfitDraft(ownerID: try store.todayConfiguration().ownerID)
        draft.name = "Weekend"; draft.select(one.id); draft.select(two.id)
        try store.saveOutfitDraft(draft)
        let outfit = try store.saveOutfit(draft)
        try store.acknowledgeOutfitReceipt(draft)
        return (one, two, outfit)
    }

    @Test func archiveAndRestoreRetainReferencesAndFlagFuturePlans() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let (one, _, outfit) = try await seed(store)
        let day = LocalPlanDay(year: 2099, month: 1, day: 1, timeZoneID: "Asia/Manila")
        let plan = OutfitPlanDraft(ownerID: outfit.ownerID, outfit: outfit, day: day)
        try store.savePlanDraft(plan); _ = try store.savePlan(plan); try store.finishPlanDraft(plan)
        let archived = try store.setArchived(id: one.id, archived: true, expectedRevision: one.revision, operationID: UUID())
        #expect(try store.pieces(archived: true) == [archived])
        let state = AppState(store: store)
        #expect(!state.pieces.contains { $0.id == archived.id })
        #expect(state.ownedPieces.first { $0.id == archived.id } == archived)
        #expect(state.ownedPieces.first { $0.id == archived.id }?.photoID == one.photoID)
        state.store = nil
        #expect(try store.outfit(id: outfit.id) == outfit)
        let affected = try #require(try store.planEntries().first)
        #expect(affected.requiresReview)
        #expect(affected.outfitID == outfit.id)
        #expect(affected.day == day)
        _ = try store.setArchived(id: one.id, archived: false, expectedRevision: archived.revision, operationID: UUID())
        #expect(try store.planEntries() == [affected])
    }

    @Test func availabilityRetriesExactOutcomeAndPreservesUnknownWrite() async throws {
        var lostAck = false
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory, afterOutfitSave: { if lostAck { throw CocoaError(.fileReadUnknown) } })
        let (one, _, _) = try await seed(store)
        let operation = UUID(); lostAck = true
        #expect(throws: (any Error).self) {
            try store.setAvailability(id: one.id, value: .laundry, expectedRevision: one.revision, operationID: operation)
        }
        let saved = try store.setAvailability(id: one.id, value: .laundry, expectedRevision: one.revision, operationID: operation)
        #expect(saved.revision == one.revision + 1)
        #expect(saved.availability == .laundry)
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.piece(id: one.id) == saved)
        #expect(throws: PieceStore.StoreError.operationConflict) {
            try reopened.setAvailability(id: one.id, value: .available, expectedRevision: one.revision, operationID: operation)
        }
    }

    @Test func wearSortUsesActualHistoryAndExplicitPriorEstimates() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let (one, two, outfit) = try await seed(store)
        let draft = OutfitWearDraft(ownerID: outfit.ownerID, pieces: [two],
            day: LocalPlanDay(year: 2026, month: 1, day: 1, timeZoneID: "Asia/Manila"))
        try store.saveWearDraft(draft); _ = try store.saveWear(draft); try store.finishWearDraft(draft)
        #expect(try store.pieces(sort: .mostWorn).map(\.id) == [one.id, two.id])
        #expect(try store.pieces(sort: .leastWorn).map(\.id) == [two.id, one.id])
        #expect(try store.pieces(sort: .lastWorn).map(\.id) == [two.id, one.id])
        let state = AppState(store: store)
        state.buildOutfit(pieceID: one.id, suggest: true)
        #expect(state.outfitEditor?.draft.stage == .suggest)
        #expect(state.outfitEditor?.draft.pinnedPieceIDs == [one.id])
        state.store = nil
    }
    @Test func chooserKeepsSelectedPiecesVisibleAcrossCategoryAndQuery() {
        let one = WardrobePiece(id: UUID(), name: "Shirt", category: .tops, photoID: UUID())
        let two = WardrobePiece(id: UUID(), name: "Boots", category: .shoes, photoID: UUID())
        let pieces = [one, two]
        #expect(OwnedPieceChooser.visiblePieces(in: pieces, selected: [one.id], category: .shoes, query: "Boots") == pieces)
        #expect(OwnedPieceChooser.visiblePieces(in: pieces, selected: [one.id], category: .shoes, query: "No match") == [one])
        #expect(OwnedPieceChooser.visiblePieces(in: pieces, selected: [], category: .shoes, query: "Boots") == [two])
        #expect(OwnedPieceChooser.visiblePieces(in: pieces, selected: [], category: nil, query: " ") == pieces)
    }

    @Test func savedReceiptEditAcknowledgesBeforeOpeningSameOutfitIdentity() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let (piece, _, _) = try await seed(store)
        let state = AppState(store: store)
        state.buildOutfit(pieceID: piece.id)
        let editor = try #require(state.outfitEditor)
        editor.update { $0.name = "Receipt edit" }
        await editor.save()
        let saved = try #require(editor.saved)
        editor.editSavedOutfit()
        #expect(state.outfitEditor == nil)
        #expect(try store.outfitDraft() == nil)
        #expect(state.pendingOutfitEditID == saved.id)
        state.openPendingOutfitCapture()
        let edit = try #require(state.outfitEditor)
        #expect(edit.draft.outfitID == saved.id)
        #expect(edit.draft.baseRevision == saved.revision)
        #expect(edit.draft.name == saved.name)
        #expect(edit.draft.operationID != editor.draft.operationID)
        edit.update { $0.name = "Edited again" }; await edit.save()
        #expect(edit.saved?.id == saved.id)
        #expect(edit.saved?.revision == saved.revision + 1)
        state.outfitEditor = nil; state.store = nil
    }
}
