import AQDCore
import Foundation
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor
struct PendingReceiptTests {
    private func photo() async throws -> PreparedPhoto {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32), format: format).image { context in
            UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32))
        }
        return try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 0.9)))
    }

    private func savedButUnacknowledged(recipe: PhotoEditRecipe, organizationCategoryID: String? = nil) async throws -> (PieceStore, PieceDraft, UUID) {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let prepared = try await photo()
        let photoID = try store.acceptPhoto(prepared)
        if recipe.crop != nil {
            try store.acceptPhotoEdit(try await PhotoPreparer().render(data: prepared.originalData, sourcePhotoID: photoID, recipe: recipe))
        }
        var draft = PieceDraft(name: "Cotton shirt", category: .tops, photoID: photoID)
        draft.photoRecipe = recipe
        draft.details.organizationCategoryID = organizationCategoryID
        let operation = UUID()
        try store.saveDraft(draft, operationID: operation)
        _ = try store.savePiece(draft, operationID: operation, retainForPresentation: true)
        return (store, draft, operation)
    }

    @Test(arguments: [
        PhotoEditRecipe.fit,
        PhotoEditRecipe(crop: .init(x: 0, y: 0, width: 1, height: 1)),
        PhotoEditRecipe(crop: .init(x: 0.1, y: 0.1, width: 0.6, height: 0.8))
    ])
    func anUnacknowledgedSaveStillOpensAndAcknowledges(recipe: PhotoEditRecipe) async throws {
        let (store, draft, operation) = try await savedButUnacknowledged(recipe: recipe)
        let recovered = try #require(try store.newPieceDraft())
        #expect(try store.pendingSavedPiece(for: recovered) != nil)
        try store.acknowledgePiecePresentation(draftID: draft.id, operationID: operation)
        #expect(try store.newPieceDraft() == nil)
    }

    /// Regression: choosing a category chip sets the organization category on the draft, which the store does not persist.
    @Test func aChosenCategoryDoesNotMakeAnUnacknowledgedReceiptInvalid() async throws {
        let (store, draft, operation) = try await savedButUnacknowledged(recipe: .fit, organizationCategoryID: "tops")
        let recovered = try #require(try store.newPieceDraft())
        #expect(try store.pendingSavedPiece(for: recovered)?.name == "Cotton shirt")
        try store.acknowledgePiecePresentation(draftID: draft.id, operationID: operation)
        #expect(try store.newPieceDraft() == nil)
    }

    @Test func aChosenCategoryAssignmentSurvivesSavingAndReopening() async throws {
        let (store, draft, operation) = try await savedButUnacknowledged(recipe: .fit, organizationCategoryID: "tops")
        #expect(try store.piece(id: draft.itemID)?.details.organizationCategoryID == "tops")
        #expect(try store.piece(id: draft.itemID)?.details.tags.isEmpty == true, "the reserved entry never shows as a user tag")
        try store.acknowledgePiecePresentation(draftID: draft.id, operationID: operation)
        let reopened = try PieceStore(directory: store.localDirectory)
        #expect(try reopened.pieces().first?.details.organizationCategoryID == "tops")
    }

    @Test func addPieceFinishesAStaleReceiptQuietlyAndOpensABlankDraft() async throws {
        let (store, _, _) = try await savedButUnacknowledged(recipe: .fit)
        let state = AppState(store: store)
        state.addPiece()
        let capture = try #require(state.capture)
        #expect(capture.saved == nil, "no receipt screen is shown")
        #expect(capture.draft.name.isEmpty && capture.draft.photoID == nil)
        #expect(try store.newPieceDraft() == nil || state.capture?.draft.baseRevision == nil)
        #expect(try store.pieces().contains { $0.name == "Cotton shirt" })
    }
}
