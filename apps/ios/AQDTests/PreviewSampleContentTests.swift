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
