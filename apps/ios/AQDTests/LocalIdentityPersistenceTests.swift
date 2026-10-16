import AQDCore
import Foundation
import Testing
import UIKit
import SwiftData
@testable import AQD

@Suite(.serialized) @MainActor
struct LocalIdentityPersistenceTests {
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
