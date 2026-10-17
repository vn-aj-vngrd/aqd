import AQDCore
import Foundation
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor
struct BackgroundPhotoTests {
    private func photo(_ color: UIColor) async throws -> PreparedPhoto {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in color.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32)) }
        return try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 0.9)))
    }
    @Test func derivedPhotoKeepsOriginalAcrossSaveReopenResetAndLastOwnerCleanup() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), store = try PieceStore(directory: directory)
        let original = try await photo(.blue), removed = try await photo(.white)
        _ = try store.acceptPhoto(original)
        let derived = try store.acceptBackgroundPhoto(removed, originalID: original.id)
        let draft = PieceDraft(name: "Original remains", category: .tops, photoID: derived)
        let operation = UUID(); try store.saveDraft(draft, operationID: operation)
        let piece = try store.savePiece(draft, operationID: operation)
        try store.acknowledgePiecePresentation(draftID: draft.id, operationID: operation)
        try store.reconcilePendingPhotoCleanup()
        #expect(try store.backgroundOriginalID(for: derived) == original.id)
        #expect(try store.originalPhoto(id: original.id) == original.originalData)
        let reopened = try PieceStore(directory: directory)
        let state = AppState(store: reopened)
        state.editPiece(piece); let model = try #require(state.capture)
        #expect(model.hasProcessedPhoto)
        #expect(await model.applyPhotoReset(.fitOriginal, sourceID: derived, previousRecipe: .fitOriginal))
        #expect(model.draft.photoID == original.id)
        #expect(try reopened.pieces().first?.photoID == derived)
        model.save()
        #expect(model.saved?.photoID == original.id)
        model.leave(); try reopened.reconcilePendingPhotoCleanup()
        #expect(try reopened.originalPhoto(id: original.id) == original.originalData)
        #expect(throws: (any Error).self) { try reopened.originalPhoto(id: derived) }
    }
    @Test func staleProposalCannotReplaceChangedDraftOrStageItsMedia() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), store = try PieceStore(directory: directory)
        let original = try await photo(.blue), proposed = try await photo(.white)
        let state = AppState(store: store)
        _ = try store.acceptPhoto(original)
        let model = CaptureModel(state: state, draft: PieceDraft(name: "Keep", category: .tops, photoID: original.id), operationID: UUID())
        model.persistDraft()
        let oldInput = try model.backgroundInput()
        model.update(\.name, value: "Changed name")
        #expect(!model.acceptBackground(proposed, input: oldInput))
        #expect(model.draft.photoID == original.id && model.draft.name == "Changed name")
        #expect(throws: (any Error).self) { try store.originalPhoto(id: proposed.id) }
        let current = try model.backgroundInput()
        #expect(model.acceptBackground(proposed, input: current))
        try store.reconcilePendingPhotoCleanup()
        #expect(try store.originalPhoto(id: original.id) == original.originalData)
        model.discard()
        try store.reconcilePendingPhotoCleanup()
        #expect(throws: (any Error).self) { try store.originalPhoto(id: proposed.id) }
        #expect(throws: (any Error).self) { try store.originalPhoto(id: original.id) }
    }
}
