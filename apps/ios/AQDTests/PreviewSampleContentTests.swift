#if DEBUG
import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor
struct PreviewSampleContentTests {
    @Test func allWidgetsAreActuallySavedWithBackupAndRepeatWithoutChangingOtherRecords() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory.appendingPathComponent("store"))
        let output = directory.appendingPathComponent("receipts")
        _ = try await PreviewSampleContent.populate(store: store, outputDirectory: output)
        let base = try store.todayConfiguration(), pieces = try store.pieces(), outfits = try store.outfits(), fits = try store.fitMemories()
        let result = try await PreviewSampleContent.addAllWidgets(store: store, outputDirectory: output)
        #expect(result.addedKinds.count == 9)
        let reopened = try PieceStore(directory: store.localDirectory)
        let saved = try reopened.todayConfiguration()
        #expect(saved == result.configuration)
        #expect(Array(saved.instances.prefix(3)) == base.instances)
        #expect(Set(saved.instances.map(\.kind)) == Set(TodayWidgetKind.allCases))
        #expect(try reopened.todayPersonalCards().count == 2)
        #expect(try reopened.pieces() == pieces && reopened.outfits() == outfits && reopened.fitMemories() == fits)
        #expect(try reopened.wearRecords().isEmpty)
        #expect(try reopened.todayDraft() == nil)
        let backup = output.appendingPathComponent(try #require(result.backup))
        #expect(try FileManager.default.attributesOfItem(atPath: backup.path)[.protectionKey] as? FileProtectionType == .complete)
        let stamp = try reopened.mutationStamp()
        let repeated = try await PreviewSampleContent.addAllWidgets(store: reopened, outputDirectory: output)
        #expect(repeated.addedKinds.isEmpty && repeated.backup == nil)
        #expect(try reopened.mutationStamp() == stamp)
    }

    @Test func realisticContextsPreserveEditedAndRetainedSamplesAndRepeatWithoutWrites() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: root.appendingPathComponent("store"))
        let output = root.appendingPathComponent("receipts")
        _ = try await PreviewSampleContent.populate(store: store, outputDirectory: output, legacyDescriptions: true)
        let oldPlans = try store.planEntries(), oldFits = try store.fitMemories()
        let editedPlanBase = try #require(oldPlans.first { $0.id == PreviewSampleContent.id(302) })
        var editedPlan = OutfitPlanDraft(editing: editedPlanBase, outfit: try store.outfits().first { $0.id == editedPlanBase.outfitID })
        editedPlan.occasion = "My own appointment"
        try store.savePlanDraft(editedPlan); _ = try store.savePlan(editedPlan); try store.finishPlanDraft(editedPlan)
        let editedFitBase = try #require(oldFits.first { $0.id == PreviewSampleContent.id(402) })
        var editedFit = FitDraft(ownerID: editedFitBase.ownerID, base: editedFitBase); editedFit.value.note = "My own memory"
        try store.saveFitDraft(editedFit); _ = try store.saveFit(editedFit); try store.finishFitDraft(editedFit)
        let pendingPlanBase = try #require(oldPlans.first { $0.id == PreviewSampleContent.id(301) })
        let pendingPlan = OutfitPlanDraft(editing: pendingPlanBase, outfit: try store.outfits().first { $0.id == pendingPlanBase.outfitID })
        try store.savePlanDraft(pendingPlan)
        let pendingFitBase = try #require(oldFits.first { $0.id == PreviewSampleContent.id(401) })
        let pendingFit = FitDraft(ownerID: pendingFitBase.ownerID, base: pendingFitBase); try store.saveFitDraft(pendingFit)
        let pieces = try store.pieces(), outfits = try store.outfits(), plans = try store.planEntries(), fits = try store.fitMemories()
        let result = try await PreviewSampleContent.refreshContexts(store: store, outputDirectory: output)
        #expect(result.updatedPlans.count == 5 && result.updatedFits.count == 6)
        #expect(try store.pieces() == pieces && store.outfits() == outfits && store.wearRecords().isEmpty)
        #expect(try store.planDraft() == pendingPlan && store.fitDraft() == pendingFit)
        for value in try store.planEntries() {
            let prior = try #require(plans.first { $0.id == value.id })
            if result.updatedPlans.contains(value.id) {
                var expected = prior; expected.occasion = value.occasion; expected.revision += 1
                #expect(value == expected && !value.occasion.hasPrefix("Sample"))
            } else { #expect(value == prior) }
        }
        for value in try store.fitMemories() {
            let prior = try #require(fits.first { $0.id == value.id })
            if result.updatedFits.contains(value.id) {
                var expected = prior; expected.note = value.note; expected.revision += 1
                #expect(value == expected && value.note.localizedCaseInsensitiveContains("not recorded wear"))
            } else { #expect(value == prior) }
        }
        let backup = output.appendingPathComponent(try #require(result.backup))
        #expect(try FileManager.default.attributesOfItem(atPath: backup.path)[.protectionKey] as? FileProtectionType == .complete)
        let stamp = try store.mutationStamp()
        let repeatResult = try await PreviewSampleContent.refreshContexts(store: store, outputDirectory: output)
        #expect(repeatResult.updatedPlans.isEmpty && repeatResult.updatedFits.isEmpty && repeatResult.backup == nil)
        #expect(try store.mutationStamp() == stamp)
    }
    @Test func contextRefreshFailureLeavesAllRecordsUnchanged() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var fail = false
        let store = try PieceStore(directory: root.appendingPathComponent("store"), beforeOutfitSave: { if fail { throw CocoaError(.fileWriteNoPermission) } })
        let output = root.appendingPathComponent("receipts")
        _ = try await PreviewSampleContent.populate(store: store, outputDirectory: output, legacyDescriptions: true)
        let plans = try store.planEntries(), fits = try store.fitMemories(), stamp = try store.mutationStamp()
        fail = true
        await #expect(throws: (any Error).self) { try await PreviewSampleContent.refreshContexts(store: store, outputDirectory: output) }
        #expect(try store.planEntries() == plans && store.fitMemories() == fits && store.mutationStamp() == stamp)
    }
    @Test func contextRefreshReconcilesLostAcknowledgmentAndFreshSamplesNeedNoUpgrade() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var lose = false
        let store = try PieceStore(directory: root.appendingPathComponent("store"), afterOutfitSave: { if lose { throw CocoaError(.fileReadUnknown) } })
        let output = root.appendingPathComponent("receipts")
        _ = try await PreviewSampleContent.populate(store: store, outputDirectory: output, legacyDescriptions: true)
        lose = true
        let result = try await PreviewSampleContent.refreshContexts(store: store, outputDirectory: output)
        #expect(result.updatedPlans.count == 7 && result.updatedFits.count == 8)
        let second = try PieceStore(directory: root.appendingPathComponent("fresh"))
        _ = try await PreviewSampleContent.populate(store: second, outputDirectory: root.appendingPathComponent("fresh-receipts"))
        let fresh = try await PreviewSampleContent.refreshContexts(store: second, outputDirectory: root.appendingPathComponent("fresh-receipts"))
        #expect(fresh.updatedPlans.isEmpty && fresh.updatedFits.isEmpty && fresh.backup == nil)
    }
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
