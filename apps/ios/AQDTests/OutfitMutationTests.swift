import AQDCore
import Foundation
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor
struct OutfitMutationTests {
    private func seed(_ store: PieceStore) async throws -> (Outfit, WardrobePiece) {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in
            UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32))
        }
        let photo = try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 0.9)))
        _ = try store.acceptPhoto(photo)
        let piece = try store.savePiece(PieceDraft(name: "Shirt", category: .tops, photoID: photo.id), operationID: UUID())
        var draft = OutfitDraft(ownerID: try store.todayConfiguration().ownerID)
        draft.name = "Look"; draft.select(piece.id)
        try store.saveOutfitDraft(draft)
        let outfit = try store.saveOutfit(draft)
        try store.acknowledgeOutfitReceipt(draft)
        return (outfit, piece)
    }
    @Test func favoriteHasOneRevisionAndUnknownRetryAcknowledgesTheSameChange() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var loseAck = false
        let store = try PieceStore(directory: directory, afterOutfitSave: { if loseAck { throw CocoaError(.fileReadUnknown) } })
        let (outfit, _) = try await seed(store)
        let request = OutfitMutationRequest(outfit: outfit, action: .favorite(true))
        loseAck = true
        #expect(throws: (any Error).self) { try store.applyOutfitMutation(request) }
        let result = try store.applyOutfitMutation(request)
        #expect(try store.outfitMutationReceipt(for: request) == result)
        let saved = try #require(try store.outfit(id: outfit.id))
        #expect(saved.isFavorite)
        #expect(saved.revision == 2)
        #expect(try store.applyOutfitMutation(request) == .saved(saved))
        #expect(try store.outfit(id: outfit.id)?.revision == 2)
    }
    @Test func reviewedDeletionRemovesMembershipAndUnassignsPlanButKeepsPiecesAndWear() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let (outfit, piece) = try await seed(store)
        var theme = ThemeDraft(ownerID: outfit.ownerID)
        theme.name = "Weekend"; theme.outfitIDs = [outfit.id]
        try store.saveThemeDraft(theme); _ = try store.saveTheme(theme); try store.finishThemeDraft(theme)
        let plan = OutfitPlanDraft(ownerID: outfit.ownerID, outfit: outfit)
        try store.savePlanDraft(plan); let entry = try store.savePlan(plan); try store.finishPlanDraft(plan)
        let wear = OutfitWearDraft(ownerID: outfit.ownerID, outfitID: outfit.id, pieces: [piece])
        try store.saveWearDraft(wear); let history = try store.saveWear(wear); try store.finishWearDraft(wear)
        let review = try store.outfitDeletionReview(id: outfit.id)
        guard case .delete(let dependencies) = review.action else { Issue.record("Expected deletion review"); return }
        #expect(dependencies.themeRevisions.count == 1)
        #expect(dependencies.planRevisions.count == 1)
        #expect(try store.applyOutfitMutation(review) == .deleted(outfit.id))
        #expect(try store.applyOutfitMutation(review) == .deleted(outfit.id))
        #expect(try store.outfit(id: outfit.id) == nil)
        #expect(try store.themes().first?.outfitIDs.isEmpty == true)
        let retained = try #require(store.planEntries().first)
        #expect(retained.id == entry.id)
        #expect(retained.day == entry.day)
        #expect(retained.occasion == entry.occasion)
        #expect(retained.state == .unassigned)
        #expect(retained.outfitID == nil)
        #expect(try store.piece(id: piece.id) == piece)
        #expect(try store.wearRecords() == [history])
    }
    @Test func aChangedDeletionImpactRequiresFreshReviewAndCannotPartiallyDelete() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let (outfit, _) = try await seed(store)
        let oldReview = try store.outfitDeletionReview(id: outfit.id)
        var theme = ThemeDraft(ownerID: outfit.ownerID)
        theme.name = "Added later"; theme.outfitIDs = [outfit.id]
        try store.saveThemeDraft(theme); let saved = try store.saveTheme(theme); try store.finishThemeDraft(theme)
        #expect(throws: PieceStore.StoreError.staleRevision) { try store.applyOutfitMutation(oldReview) }
        #expect(try store.outfit(id: outfit.id) == outfit)
        #expect(try store.themes() == [saved])
        #expect(try store.outfitMutationReceipt(for: oldReview) == nil)
        let current = try store.outfitDeletionReview(id: outfit.id)
        _ = try store.applyOutfitMutation(current)
        #expect(try store.outfit(id: outfit.id) == nil)
    }
}
