import AQDCore
import Foundation
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
}
