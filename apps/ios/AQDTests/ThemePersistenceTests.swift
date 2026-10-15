import AQDCore
import Foundation
import SwiftData
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor
struct ThemePersistenceTests {
    private func outfit(_ store: PieceStore) async throws -> Outfit {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in
            UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32))
        }
        let photo = try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 0.9)))
        _ = try store.acceptPhoto(photo)
        let piece = try store.savePiece(PieceDraft(name: "Shirt", category: .tops, photoID: photo.id), operationID: UUID())
        var draft = OutfitDraft(ownerID: try store.todayConfiguration().ownerID)
        draft.name = "Weekend look"; draft.select(piece.id)
        try store.saveOutfitDraft(draft)
        let saved = try store.saveOutfit(draft)
        try store.acknowledgeOutfitReceipt(draft)
        return saved
    }

    @Test func createEmptyThemesAssignTwiceRenameAndRestartRetainOutfit() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        let saved = try await outfit(#require(store))
        var first = ThemeDraft(ownerID: saved.ownerID)
        first.name = "Weekend"
        try #require(store).saveThemeDraft(first)
        let theme = try #require(store).saveTheme(first)
        #expect(theme.outfitIDs.isEmpty)
        #expect(try #require(store).saveTheme(first) == theme)
        try #require(store).finishThemeDraft(first)
        var second = ThemeDraft(ownerID: saved.ownerID)
        second.name = "Work"
        try #require(store).saveThemeDraft(second)
        let other = try #require(store).saveTheme(second)
        try #require(store).finishThemeDraft(second)
        let state = AppState(store: try #require(store))
        state.buildOutfit(editing: saved)
        let editor = try #require(state.outfitEditor)
        editor.update { $0.themeIDs = [theme.id, other.id] }
        await editor.save()
        let updated = try #require(editor.saved)
        editor.finish()
        #expect(try #require(store).themes().allSatisfy { $0.outfitIDs == [saved.id] })
        let currentThemes = try #require(store).themes()
        let currentTheme = try #require(currentThemes.first { $0.id == theme.id })
        var renamed = ThemeDraft(editing: currentTheme)
        renamed.name = "Days off"
        try #require(store).saveThemeDraft(renamed)
        _ = try #require(store).saveTheme(renamed)
        try #require(store).finishThemeDraft(renamed)
        state.store = nil; store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).themes().map(\.name) == ["Days off", "Work"])
        #expect(try #require(store).outfit(id: saved.id) == updated)
        // Opening an edit carries existing membership, rather than silently clearing it.
        let reopened = AppState(store: try #require(store))
        reopened.buildOutfit(editing: updated)
        #expect(Set(try #require(reopened.outfitEditor).draft.themeIDs ?? []) == [theme.id, other.id])
        reopened.outfitEditor = nil; reopened.store = nil; store = nil
    }

    @Test func deniedThemeWriteKeepsDraftAndCaseInsensitiveNameIsUnique() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var deny = false
        let store = try PieceStore(directory: directory, beforeOutfitSave: { if deny { throw CocoaError(.fileWriteNoPermission) } })
        var draft = ThemeDraft(ownerID: try store.todayConfiguration().ownerID)
        draft.name = "Weekend"
        try store.saveThemeDraft(draft)
        deny = true
        #expect(throws: (any Error).self) { try store.saveTheme(draft) }
        #expect(try store.themes().isEmpty)
        #expect(try store.themeDraft() == draft)
        deny = false
        let saved = try store.saveTheme(draft)
        try store.finishThemeDraft(draft)
        var duplicate = ThemeDraft(ownerID: saved.ownerID)
        duplicate.name = " WEEKEND "
        try store.saveThemeDraft(duplicate)
        #expect(throws: ThemeValidationError.duplicateName) { try store.saveTheme(duplicate) }
        try store.finishThemeDraft(duplicate, discarding: true)
        #expect(try store.themes() == [saved])
    }
    @Test func deletingOneThemeRetainsOtherMembershipAndFavoriteThroughUnknownRetry() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var loseAck = false, deny = false
        let store = try PieceStore(directory: directory,
            beforeOutfitSave: { if deny { throw CocoaError(.fileWriteNoPermission) } },
            afterOutfitSave: { if loseAck { throw CocoaError(.fileReadUnknown) } })
        let saved = try await outfit(store)
        _ = try store.applyOutfitMutation(OutfitMutationRequest(outfit: saved, action: .favorite(true)))
        let favorite = try #require(try store.outfit(id: saved.id))
        var themes: [OutfitTheme] = []
        for name in ["Weekend", "Work"] {
            var draft = ThemeDraft(ownerID: favorite.ownerID)
            draft.name = name; draft.outfitIDs = [favorite.id]
            try store.saveThemeDraft(draft); themes.append(try store.saveTheme(draft)); try store.finishThemeDraft(draft)
        }
        let request = ThemeDeletionRequest(theme: themes[0])
        deny = true
        #expect(throws: (any Error).self) { try store.deleteTheme(request) }
        #expect(try store.themes().count == 2)
        deny = false; loseAck = true
        #expect(throws: (any Error).self) { try store.deleteTheme(request) }
        try store.deleteTheme(request)
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.themes() == [themes[1]])
        #expect(try reopened.outfit(id: saved.id) == favorite)
        #expect(try reopened.isThemeDeletionAcknowledged(request))
        let conflicting = ThemeDeletionRequest(theme: themes[1], operationID: request.operationID)
        #expect(throws: PieceStore.StoreError.operationConflict) { try reopened.deleteTheme(conflicting) }
    }

    @Test func changedThemeRejectsOldDeleteReview() throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        var draft = ThemeDraft(ownerID: try store.todayConfiguration().ownerID)
        draft.name = "Weekend"; try store.saveThemeDraft(draft)
        let first = try store.saveTheme(draft); try store.finishThemeDraft(draft)
        let request = ThemeDeletionRequest(theme: first)
        var edit = ThemeDraft(editing: first); edit.name = "Days off"
        try store.saveThemeDraft(edit); let updated = try store.saveTheme(edit); try store.finishThemeDraft(edit)
        #expect(throws: PieceStore.StoreError.staleRevision) { try store.deleteTheme(request) }
        #expect(try store.themes() == [updated])
    }

    @Test func v9MigrationRetainsAcknowledgedPieceDeletionReview() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let today = TodayConfiguration(ownerID: UUID()), operation = UUID(), pieceID = UUID()
        let impact = PieceDeletionImpact(pieceID: pieceID, pieceRevision: 1, outfitRevisions: [:], themeRevisions: [:], futurePlanRevisions: [:])
        do {
            let schema = Schema(versionedSchema: LocalSchemaV9.self)
            let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            context.insert(StoredTodayConfiguration(today)); context.insert(try StoredLocalExperience(LocalExperience(enteredPrivateSpace: true)))
            context.insert(StoredPieceDeletion(operationID: operation, itemID: pieceID, expectedRevision: 1, pendingPhotoIDs: []))
            context.insert(try StoredPieceDeletionReview(operationID: operation, impact: impact)); try context.save()
        }
        try Data("AQD-piece-store:9".utf8).write(to: directory.appendingPathComponent("schema-version"))
        let store = try PieceStore(directory: directory)
        #expect(try store.isPieceDeletionAcknowledged(id: pieceID, expectedRevision: 1, operationID: operation, impact: impact))
        #expect(try store.themes().isEmpty)
    }
}
