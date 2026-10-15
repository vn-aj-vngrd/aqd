import AQDCore
import Foundation
import SwiftData
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor
struct PieceDeletionImpactTests {
    private func seed(_ store: PieceStore) async throws -> (WardrobePiece, Outfit, Outfit, OutfitTheme) {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in
            UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32))
        }
        let photo = try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 0.9)))
        _ = try store.acceptPhoto(photo)
        let piece = try store.savePiece(PieceDraft(name: "Shirt", category: .tops, photoID: photo.id), operationID: UUID())
        let other = try store.savePiece(PieceDraft(name: "Jeans", category: .bottoms, photoID: photo.id), operationID: UUID())
        var results: [Outfit] = []
        for ids in [[piece.id], [piece.id, other.id]] {
            var draft = OutfitDraft(ownerID: try store.todayConfiguration().ownerID)
            draft.name = "Look \(results.count + 1)"
            for id in ids { draft.select(id) }
            try store.saveOutfitDraft(draft); results.append(try store.saveOutfit(draft)); try store.acknowledgeOutfitReceipt(draft)
        }
        var theme = ThemeDraft(ownerID: results[0].ownerID)
        theme.name = "Weekend"; theme.outfitIDs = results.map(\.id)
        try store.saveThemeDraft(theme); let savedTheme = try store.saveTheme(theme); try store.finishThemeDraft(theme)
        for outfit in results {
            var plan = OutfitPlanDraft(ownerID: outfit.ownerID, outfit: outfit,
                day: LocalPlanDay(year: 2099, month: 1, day: 1, timeZoneID: "Asia/Manila"))
            plan.occasion = outfit.name
            try store.savePlanDraft(plan); _ = try store.savePlan(plan); try store.finishPlanDraft(plan)
        }
        return (piece, results[0], results[1], savedTheme)
    }

    @Test func deletionReviewsExactCascadeAndPreservesSnapshotsOnRetryAndReopen() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let (piece, empty, surviving, theme) = try await seed(store)
        let wear = OutfitWearDraft(ownerID: empty.ownerID, outfitID: empty.id, pieces: [piece])
        try store.saveWearDraft(wear); let history = try store.saveWear(wear); try store.finishWearDraft(wear)
        let impact = try store.pieceDeletionImpact(id: piece.id), operation = UUID()
        #expect(impact.outfitRevisions.count == 2)
        #expect(impact.themeRevisions == [theme.id: theme.revision])
        #expect(impact.futurePlanRevisions.count == 2)
        #expect(throws: PieceStore.StoreError.staleRevision) {
            try store.deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: UUID())
        }
        try store.deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: operation, impact: impact)
        try store.deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: operation, impact: impact)
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.piece(id: piece.id) == nil)
        #expect(try reopened.outfit(id: empty.id) == nil)
        let kept = try #require(try reopened.outfit(id: surviving.id))
        #expect(kept.pieceIDs == surviving.pieceIDs.filter { $0 != piece.id })
        #expect(try reopened.themes().first?.outfitIDs == [surviving.id])
        #expect(try reopened.planEntries().allSatisfy { $0.outfitID == nil && $0.state == .unassigned && $0.requiresReview && $0.day.key == "2099-01-01" })
        #expect(try reopened.wearRecords() == [history])
        #expect(try reopened.isPieceDeletionAcknowledged(id: piece.id, expectedRevision: piece.revision, operationID: operation, impact: impact))
    }

    @Test func changedDependenciesRejectOldReviewWithoutPartialWrites() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let (piece, _, surviving, _) = try await seed(store)
        let impact = try store.pieceDeletionImpact(id: piece.id)
        _ = try store.applyOutfitMutation(OutfitMutationRequest(outfit: surviving, action: .favorite(true)))
        #expect(throws: PieceStore.StoreError.staleRevision) {
            try store.deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: UUID(), impact: impact)
        }
        #expect(try store.piece(id: piece.id) == piece)
        #expect(try store.outfits().count == 2)
        #expect(try store.planEntries().allSatisfy { $0.outfitID != nil && !$0.requiresReview })
    }
    @Test func v8MigrationPreservesExistingCollectionWithoutDeletionProofs() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let today = TodayConfiguration(ownerID: UUID())
        let piece = WardrobePiece(id: UUID(), name: "Legacy shirt", category: .tops, photoID: UUID())
        let outfit = Outfit(id: UUID(), ownerID: today.ownerID, name: "Legacy look", pieceIDs: [piece.id])
        do {
            let schema = Schema(versionedSchema: LocalSchemaV8.self)
            let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            context.insert(StoredTodayConfiguration(today)); context.insert(try StoredLocalExperience(LocalExperience(enteredPrivateSpace: true)))
            context.insert(StoredPiece(piece)); context.insert(StoredPhoto(id: piece.photoID, pixelWidth: 24, pixelHeight: 32))
            context.insert(try StoredOutfit(outfit)); try context.save()
        }
        try Data("AQD-piece-store:8".utf8).write(to: directory.appendingPathComponent("schema-version"))
        let store = try PieceStore(directory: directory)
        #expect(try store.outfit(id: outfit.id) == outfit)
        #expect(try store.piece(id: piece.id) == piece)
        #expect(try store.pieceDeletionImpact(id: piece.id).outfitRevisions == [outfit.id: outfit.revision])
    }
}
