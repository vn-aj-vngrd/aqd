import AQDCore
import Foundation
import SwiftData
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor
struct ClosetSearchTests {
    private func seed(_ store: PieceStore) async throws -> (WardrobePiece, WardrobePiece, Outfit, OutfitTheme) {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in
            UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32))
        }
        let photo = try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 0.9)))
        _ = try store.acceptPhoto(photo)
        let first = try store.savePiece(PieceDraft(name: "Cotton shirt", category: .tops, photoID: photo.id,
            details: PieceDetails(color: "Blue", brand: "Local")), operationID: UUID())
        let second = try store.savePiece(PieceDraft(name: "Red shoes", category: .shoes, photoID: photo.id), operationID: UUID())
        let archived = try store.setArchived(id: second.id, archived: true, expectedRevision: second.revision, operationID: UUID())
        var draft = OutfitDraft(ownerID: try store.todayConfiguration().ownerID)
        draft.name = "Blue afternoon"; draft.mood = "Relaxed"; draft.select(first.id)
        try store.saveOutfitDraft(draft)
        let outfit = try store.saveOutfit(draft)
        try store.acknowledgeOutfitReceipt(draft)
        var theme = ThemeDraft(ownerID: outfit.ownerID)
        theme.name = "Blue days"; theme.description = "Slow weekends"; theme.outfitIDs = [outfit.id]
        try store.saveThemeDraft(theme)
        let saved = try store.saveTheme(theme)
        try store.finishThemeDraft(theme)
        return (first, archived, outfit, saved)
    }
    @Test func searchIsScopedAndMetadataAndArchivedMatchesRemainExplicit() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let (piece, archived, outfit, theme) = try await seed(store)
        #expect(try store.searchCloset(query: " BLUE ", scope: .pieces) == .pieces([piece]))
        #expect(try store.searchCloset(query: "red", scope: .pieces) == .pieces([archived]))
        #expect(try store.searchCloset(query: "blue", scope: .outfits) == .outfits([outfit]))
        #expect(try store.searchCloset(query: "relaxed", scope: .outfits) == .outfits([outfit]))
        #expect(try store.searchCloset(query: "weekends", scope: .themes) == .themes([theme]))
        #expect(try store.searchCloset(query: "blue", scope: .outfits, favoritesOnly: true) == .outfits([]))
        _ = try store.applyOutfitMutation(OutfitMutationRequest(outfit: outfit, action: .favorite(true)))
        let favorite = try #require(try store.outfit(id: outfit.id))
        #expect(try store.searchCloset(query: "blue", scope: .outfits, favoritesOnly: true, themeID: theme.id) == .outfits([favorite]))
    }
    @Test func supersededSearchCannotReplaceTheLatestScopeAndQuery() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let (_, archived, _, _) = try await seed(store)
        let model = ClosetSearchModel(store: store)
        let old = Task { @MainActor in await model.search(ClosetSearchInput(query: "blue", scope: .pieces)) }
        await Task.yield()
        let latest = ClosetSearchInput(query: "red", scope: .pieces)
        await model.search(latest, debounce: false)
        await old.value
        #expect(model.input == latest)
        #expect(model.results == .pieces([archived]))
        #expect(!model.loading)
        #expect(model.error == nil)
        await model.search(ClosetSearchInput(query: "   ", scope: .themes), debounce: false)
        #expect(model.results == nil)
        #expect(!model.closetEmpty)
    }
    @Test func unreadableRecordsProduceSearchFailureRatherThanFalseEmptyResults() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        _ = try await seed(store)
        do {
            let schema = Schema(versionedSchema: LocalSchemaV17.self)
            let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            let rows = try context.fetch(FetchDescriptor<StoredPiece>())
            let row = try #require(rows.first)
            row.category = "Unreadable category"
            try context.save()
        }
        let model = ClosetSearchModel(store: store)
        await model.search(ClosetSearchInput(query: "No match", scope: .pieces), debounce: false)
        #expect(model.results == nil)
        #expect(model.error != nil)
        #expect(!model.loading)
    }

    @Test func preferenceReceiptOpensTheRealClosetRatherThanAnOldSearch() async throws {
        let state = AppState(store: try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)))
        state.openStyle(source: .profile)
        let editor = try #require(state.styleEditor)
        editor.update { draft in
            for step in 0..<4 { draft.answers.choose("No preference", at: step) }
            draft.answers.body.decline(); draft.answers.colors.declined = true; draft.page = 6
        }
        await editor.save()
        try #require(editor.saved != nil)
        state.closetSearchActive = true; state.closetSearchQuery = "Old filter"; state.closetScope = "Outfits"
        editor.finish(openCloset: true)
        #expect(state.styleEditor == nil)
        #expect(!state.closetSearchActive)
        #expect(state.closetSearchQuery.isEmpty)
        #expect(state.closetScope == "Pieces")
        #expect(state.closetPath.isEmpty)
        #expect(state.selection == 1)
        #expect(try #require(state.store).localExperience().pendingStyleReceipt == nil)
        state.store = nil
    }

    @Test func explicitClosetNavigationClearsSearchAndSelectsTheActualSavedIdentity() throws {
        let state = AppState(store: try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)))
        state.closetSearchActive = true; state.closetSearchQuery = "Old query"
        let id = UUID()
        state.openClosetDestination(scope: "Outfits", route: .outfit(id))
        #expect(!state.closetSearchActive)
        #expect(state.closetSearchQuery.isEmpty)
        #expect(state.selection == 1)
        #expect(state.closetScope == "Outfits")
        #expect(state.closetPath == [.outfit(id)])
        #expect(!state.closetSearchRestoresSource)
        state.store = nil
    }
}
