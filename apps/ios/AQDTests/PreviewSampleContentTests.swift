#if DEBUG
import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor
struct PreviewSampleContentTests {
    @Test func samplesAddAtomicallyAndRepeatWithoutChangingIdentityDraftsOrWear() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: root.appendingPathComponent("store"))
        let owner = try store.todayConfiguration().ownerID
        var identity = LocalIdentityDraft(ownerID: owner); identity.name = "Keep me"; identity.caption = "My own caption"
        try store.saveIdentityDraft(identity); let saved = try store.saveIdentity(identity); try store.finishIdentityDraft(identity)
        var draft = OutfitDraft(ownerID: owner); draft.name = "Unfinished personal look"
        try store.saveOutfitDraft(draft)
        let output = root.appendingPathComponent("receipts")
        let receipt = try await PreviewSampleContent.populate(store: store, outputDirectory: output)
        #expect(receipt.added == ["pieces": 12, "outfits": 6, "themes": 4, "plans": 7, "fits": 8])
        #expect(try store.localIdentity() == saved && store.outfitDraft() == draft)
        #expect(try store.wearRecords().isEmpty)
        #expect(try store.pieces().count == 12 && store.outfits().count == 6 && store.fitMemories().count == 8)
        #expect(try store.themes().filter(\.outfitIDs.isEmpty).count == 1)
        let backupURL = output.appendingPathComponent(try #require(receipt.backup))
        #expect(FileManager.default.fileExists(atPath: backupURL.path))
        #expect(try FileManager.default.attributesOfItem(atPath: backupURL.path)[.protectionKey] as? FileProtectionType == .complete)
        let reopened = try PieceStore(directory: root.appendingPathComponent("store"))
        let repeated = try await PreviewSampleContent.populate(store: reopened, outputDirectory: output)
        #expect(repeated == receipt)
        #expect(try reopened.pieces().count == 12 && reopened.planEntries().count == 7)
        #expect(try reopened.localIdentity() == saved && reopened.outfitDraft() == draft)
    }
    @Test func transparentRefreshPreservesEditedPiecesDraftsAndReferencesAndRepeatsWithoutChanges() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: root.appendingPathComponent("store"))
        let output = root.appendingPathComponent("receipts")
        _ = try await PreviewSampleContent.populate(store: store, outputDirectory: output)
        let edited = try #require(try store.piece(id: PreviewSampleContent.id(1)))
        var edit = PieceDraft(itemID: edited.id, name: "My edited sample", category: edited.category,
            photoID: edited.photoID, baseRevision: edited.revision, details: edited.details)
        edit.photoRecipe = edited.photoRecipe
        _ = try store.savePiece(edit, operationID: UUID())
        let pending = try #require(try store.piece(id: PreviewSampleContent.id(2)))
        let draft = PieceDraft(itemID: pending.id, name: pending.name, category: pending.category,
            photoID: pending.photoID, baseRevision: pending.revision, details: pending.details)
        let operation = UUID(); try store.saveDraft(draft, operationID: operation)
        let before = try store.pieces(), outfits = try store.outfits(), plans = try store.planEntries(), fits = try store.fitMemories()
        let receipt = try await PreviewSampleContent.refreshTransparentPhotos(store: store, outputDirectory: output)
        #expect(receipt.updated.count == 10)
        #expect(Set(receipt.skipped) == [edited.id, pending.id])
        #expect(try store.piece(id: edited.id) == before.first { $0.id == edited.id })
        #expect(try store.piece(id: pending.id) == pending)
        #expect(try store.recoverableDraft(itemID: pending.id) == RecoverablePieceDraft(draft: draft, operationID: operation))
        #expect(try store.outfits() == outfits && store.planEntries() == plans && store.fitMemories() == fits && store.wearRecords().isEmpty)
        let current = try store.pieces()
        for piece in current where receipt.updated.contains(piece.id) {
            #expect(piece.revision == 2)
            #expect(piece.photoID != before.first { $0.id == piece.id }?.photoID)
            #expect(try store.originalPhoto(id: piece.photoID).starts(with: [137, 80, 78, 71, 13, 10, 26, 10]))
        }
        let backup = output.appendingPathComponent(try #require(receipt.backup))
        #expect(try FileManager.default.attributesOfItem(atPath: backup.path)[.protectionKey] as? FileProtectionType == .complete)
        let repeated = try await PreviewSampleContent.refreshTransparentPhotos(store: store, outputDirectory: output)
        #expect(repeated.updated.isEmpty && repeated.backup == nil)
        #expect(try store.pieces() == current)
    }
    @Test func failedTransparentPhotoCommitPreservesEveryPieceAndRetryUpdatesOnce() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var fail = false
        let store = try PieceStore(directory: root.appendingPathComponent("store"), beforeOutfitSave: { if fail { throw CocoaError(.fileWriteNoPermission) } })
        let output = root.appendingPathComponent("receipts")
        _ = try await PreviewSampleContent.populate(store: store, outputDirectory: output)
        let before = try store.pieces()
        fail = true
        await #expect(throws: (any Error).self) { try await PreviewSampleContent.refreshTransparentPhotos(store: store, outputDirectory: output) }
        #expect(try store.pieces() == before)
        fail = false
        let receipt = try await PreviewSampleContent.refreshTransparentPhotos(store: store, outputDirectory: output)
        #expect(receipt.updated.count == 12)
        #expect(try store.pieces().count == 12)
    }
    @Test func transparentRefreshReconcilesALostCommitAcknowledgmentWithoutRepeatingWrites() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var loseAcknowledgment = false
        let store = try PieceStore(directory: root.appendingPathComponent("store"), afterOutfitSave: { if loseAcknowledgment { throw CocoaError(.fileReadUnknown) } })
        let output = root.appendingPathComponent("receipts")
        _ = try await PreviewSampleContent.populate(store: store, outputDirectory: output)
        loseAcknowledgment = true
        let receipt = try await PreviewSampleContent.refreshTransparentPhotos(store: store, outputDirectory: output)
        #expect(receipt.updated.count == 12)
        let pieces = try store.pieces(), stamp = try store.mutationStamp()
        let repeated = try await PreviewSampleContent.refreshTransparentPhotos(store: store, outputDirectory: output)
        #expect(repeated.updated.isEmpty && repeated.backup == nil)
        #expect(try store.pieces() == pieces && store.mutationStamp() == stamp)
    }
    @Test func failedGraphCommitPreservesExistingDataAndCanRetryWithoutDuplicates() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: root.appendingPathComponent("store"), beforeOutfitSave: { throw CocoaError(.fileWriteNoPermission) })
        await #expect(throws: (any Error).self) {
            try await PreviewSampleContent.populate(store: store, outputDirectory: root.appendingPathComponent("receipts"))
        }
        #expect(try store.pieces().isEmpty && store.outfits().isEmpty && store.fitMemories().isEmpty && store.planEntries().isEmpty)
        let reopened = try PieceStore(directory: root.appendingPathComponent("store"))
        _ = try await PreviewSampleContent.populate(store: reopened, outputDirectory: root.appendingPathComponent("receipts"))
        #expect(try reopened.pieces().count == 12 && reopened.themes().count == 4)
    }
}
#endif
