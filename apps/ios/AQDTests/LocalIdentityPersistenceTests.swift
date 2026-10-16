import AQDCore
import Foundation
import Testing
import UIKit
import SwiftData
@testable import AQD

@Suite(.serialized) @MainActor
struct LocalIdentityPersistenceTests {
    @Test func unchangedProfileDisablesSaveAndSuccessfulChangeClosesEditor() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        var initial = LocalIdentityDraft(ownerID: try store.todayConfiguration().ownerID)
        initial.name = "Test"; initial.caption = "A little of what I wear."
        try store.saveIdentityDraft(initial)
        let saved = try store.saveIdentity(initial)
        try store.finishIdentityDraft(initial)
        let state = AppState(store: store)
        state.openIdentity()
        let editor = try #require(state.identityEditor)
        #expect(!editor.canSave)
        editor.update { $0.name = "Changed" }
        #expect(editor.canSave)
        editor.update { $0.name = saved.name ?? "" }
        #expect(!editor.canSave)
        editor.update { $0.caption = "New caption" }
        #expect(editor.canSave)
        await editor.save()
        #expect(state.identityEditor == nil)
        #expect(try store.identityDraft() == nil)
        #expect(try store.localIdentity()?.caption == "New caption")
        #expect(try store.wearRecords().isEmpty)
        state.store = nil
    }

    @Test func successfulImportAloneSignalsPhotoReview() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let state = AppState(store: store)
        state.openIdentity()
        let model = try #require(state.identityEditor)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32)) }
        model.importPhoto(try #require(image.jpegData(compressionQuality: 0.9)))
        let deadline = Date().addingTimeInterval(10)
        while model.importing && Date() < deadline { try await Task.sleep(for: .milliseconds(10)) }
        try #require(!model.importing)
        let accepted = try #require(model.draft.photoID)
        #expect(model.completedPhotoImportID == accepted)
        model.removePhoto()
        #expect(model.completedPhotoImportID == accepted)
        model.importPhoto(Data([1, 2, 3]))
        while model.importing && Date() < deadline { try await Task.sleep(for: .milliseconds(10)) }
        #expect(!model.importing && model.error != nil && model.draft.photoID == nil)
        #expect(model.completedPhotoImportID == accepted)
    }
    @Test func secondaryChromeTracksOnlyTheCurrentRootAndReturnsAfterBack() throws {
        let state = AppState(store: try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)))
        state.selection = 1; state.closetPath = [.piece(UUID())]
        #expect(state.isRootTabBarHidden)
        state.selection = 0
        #expect(!state.isRootTabBarHidden)
        let page = UUID(); state.secondaryPageOwners[page] = 4
        state.selection = 4
        #expect(state.isRootTabBarHidden)
        state.secondaryPageOwners.removeValue(forKey: page)
        #expect(!state.isRootTabBarHidden)
        state.profileSettings = true
        #expect(state.isRootTabBarHidden)
        state.profileSettings = false
        #expect(!state.isRootTabBarHidden)
        state.selection = 1; state.closetPath = []
        #expect(!state.isRootTabBarHidden)
    }
    @Test func captionPersistsReopensClearsAndCancelledEditsRetainSavedValue() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        var draft = LocalIdentityDraft(ownerID: try store.todayConfiguration().ownerID)
        draft.name = "Van"; draft.caption = "Getting dressed, my way."
        try store.saveIdentityDraft(draft)
        let saved = try store.saveIdentity(draft)
        #expect(try store.saveIdentity(draft) == saved)
        try store.finishIdentityDraft(draft)
        #expect(try PieceStore(directory: directory).localIdentity()?.caption == draft.caption)
        var cancelled = LocalIdentityDraft(ownerID: saved.ownerID, base: saved)
        cancelled.caption = "Unsaved caption"
        try store.saveIdentityDraft(cancelled)
        try store.finishIdentityDraft(cancelled, discarding: true)
        #expect(try store.localIdentity()?.caption == saved.caption)
        var clear = LocalIdentityDraft(ownerID: saved.ownerID, base: saved); clear.caption = ""
        try store.saveIdentityDraft(clear); _ = try store.saveIdentity(clear); try store.finishIdentityDraft(clear)
        #expect(try PieceStore(directory: directory).localIdentity()?.caption == "")
    }

    @Test func overLimitCaptionAndOtherEditsSurviveRestartUntilCorrected() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        var draft = LocalIdentityDraft(ownerID: try store.todayConfiguration().ownerID)
        draft.caption = String(repeating: "a", count: 161)
        draft.name = "Retain alongside caption"
        try store.saveIdentityDraft(draft)
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.identityDraft() == draft)
        #expect(throws: (any Error).self) { try reopened.saveIdentity(draft) }
        #expect(try reopened.localIdentity() == nil)
        draft.caption = "Corrected"
        try reopened.saveIdentityDraft(draft)
        let saved = try reopened.saveIdentity(draft)
        #expect(saved.caption == "Corrected" && saved.name == draft.name)
    }

    @Test func absentIdentityClearsAndRetriesWithoutChangingWardrobeOrHistory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var fail = false, unknown = false
        let store = try PieceStore(directory: directory,
            beforeOutfitSave: { if fail { throw CocoaError(.fileWriteNoPermission) } },
            afterOutfitSave: { if unknown { throw CocoaError(.fileReadUnknown) } })
        let owner = try store.todayConfiguration().ownerID
        var draft = LocalIdentityDraft(ownerID: owner)
        draft.name = " Van "
        try store.saveIdentityDraft(draft)
        fail = true
        #expect(throws: (any Error).self) { try store.saveIdentity(draft) }
        #expect(try store.localIdentity() == nil)
        #expect(try store.identityDraft() == draft)
        fail = false; unknown = true
        #expect(throws: (any Error).self) { try store.saveIdentity(draft) }
        let saved = try store.saveIdentity(draft)
        #expect(saved.name == "Van" && saved.revision == 1)
        try store.finishIdentityDraft(draft)
        var cleared = LocalIdentityDraft(ownerID: owner, base: saved); cleared.name = "  "
        try store.saveIdentityDraft(cleared)
        unknown = false
        let absent = try store.saveIdentity(cleared)
        #expect(absent.name == nil && absent.photoID == nil && absent.revision == 2)
        #expect(try store.pieces().isEmpty && store.wearRecords().isEmpty && store.planEntries().isEmpty)
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.localIdentity() == absent)
        #expect(try reopened.savedIdentity(for: cleared) == absent)
    }
    @Test func sharedAvatarIsRetainedUntilEverySavedAndDraftOwnerReleasesIt() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32)) }
        let prepared = try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 0.9)))
        _ = try store.acceptPhoto(prepared)
        let piece = try store.savePiece(PieceDraft(name: "Shared source", category: .tops, photoID: prepared.id), operationID: UUID())
        var draft = LocalIdentityDraft(ownerID: try store.todayConfiguration().ownerID); draft.photoID = prepared.id
        try store.saveIdentityDraft(draft); let saved = try store.saveIdentity(draft); try store.finishIdentityDraft(draft)
        var remove = LocalIdentityDraft(ownerID: saved.ownerID, base: saved); remove.photoID = nil
        try store.saveIdentityDraft(remove)
        try store.reconcilePendingPhotoCleanup()
        #expect(try store.originalPhoto(id: prepared.id) == prepared.originalData)
        try store.finishIdentityDraft(remove, discarding: true)
        #expect(try store.localIdentity() == saved)
        let removal = LocalIdentityDraft(ownerID: saved.ownerID, base: saved)
        var cleared = removal; cleared.photoID = nil
        try store.saveIdentityDraft(cleared); _ = try store.saveIdentity(cleared); try store.finishIdentityDraft(cleared)
        try store.reconcilePendingPhotoCleanup()
        #expect(try store.originalPhoto(id: prepared.id) == prepared.originalData)
        let impact = try store.pieceDeletionImpact(id: piece.id)
        try store.deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: UUID(), impact: impact)
        try store.reconcilePendingPhotoCleanup()
        #expect(throws: (any Error).self) { try store.originalPhoto(id: prepared.id) }
    }

    @Test func v14MigrationPreservesExistingPlanWithoutInventingIdentity() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let today = TodayConfiguration(ownerID: UUID())
        let day = LocalPlanDay(year: 2026, month: 1, day: 1, timeZoneID: "Asia/Manila")
        let entry = OutfitPlanEntry(id: UUID(), planID: UUID(), ownerID: today.ownerID, day: day, occasion: "Retain", outfitID: nil, outfitRevision: nil, state: .unassigned)
        do {
            let schema = Schema(versionedSchema: LocalSchemaV14.self)
            let configuration = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [configuration]); let context = ModelContext(container)
            context.insert(StoredTodayConfiguration(today)); context.insert(try StoredLocalExperience(LocalExperience(enteredPrivateSpace: true)))
            context.insert(try StoredOutfitPlanEntry(entry)); try context.save()
        }
        try Data("AQD-piece-store:14".utf8).write(to: directory.appendingPathComponent("schema-version"))
        let store = try PieceStore(directory: directory)
        #expect(try store.localIdentity() == nil)
        #expect(try store.planEntries() == [entry])
    }

    @Test func retainedIdentityTaskExcludesOtherRecoveredEditors() throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        try store.saveEntryState(PrivateEntryState(alreadyEntered: true))
        var draft = LocalIdentityDraft(ownerID: try store.todayConfiguration().ownerID); draft.name = "Resume"
        try store.saveIdentityDraft(draft)
        try store.saveStyleDraft(StylePreferenceDraft(source: .profile, baseRevision: 0))
        let state = AppState(store: store)
        #expect(state.identityEditor?.draft == draft)
        #expect(state.styleEditor == nil && state.outfitEditor == nil && state.planEditor == nil)
        state.store = nil
    }

}
