import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct ClosetActionTests {
    private func loaded() async throws -> (AppState, LocalDataFixture) {
        let fixture = try await LocalDataFixture()
        let state = AppState(store: fixture.store)
        state.reloadPieces(); state.reloadOutfits(); state.reloadThemes()
        // The fixture keeps unfinished drafts for erase tests; Closet actions start from a settled closet.
        if let pending = try fixture.store.themeDraft() { try fixture.store.finishThemeDraft(pending, discarding: true) }
        if let draft = try fixture.store.outfitDraft() { try fixture.store.discardOutfitDraft(id: draft.id) }
        state.activeEditor = nil
        return (state, fixture)
    }

    @Test func laundryMovesAPieceIntoTheFilterAndBack() async throws {
        let (state, fixture) = try await loaded()
        let store = fixture.store
        #expect(try store.pieces(category: nil, archived: false, availability: .laundry, sort: .name).isEmpty)

        let washing = try #require(state.toggleLaundry(fixture.piece))
        #expect(washing.availability == .laundry)
        #expect(try store.pieces(category: nil, archived: false, availability: .laundry, sort: .name).map(\.id) == [fixture.piece.id])
        #expect(state.pieces.first { $0.id == fixture.piece.id }?.availability == .laundry, "the Closet list reloads")

        let back = try #require(state.toggleLaundry(washing))
        #expect(back.availability == .available)
        #expect(try store.pieces(category: nil, archived: false, availability: .laundry, sort: .name).isEmpty)
    }

    @Test func aStaleCardNeverOverwritesANewerChange() async throws {
        let (state, fixture) = try await loaded()
        _ = state.toggleLaundry(fixture.piece)
        #expect(state.toggleLaundry(fixture.piece) == nil, "the old revision is refused")
        #expect(state.collectionError != nil)
        #expect(try fixture.store.piece(id: fixture.piece.id)?.availability == .laundry)
    }

    @Test func archivedPiecesAreLeftAlone() async throws {
        let (state, fixture) = try await loaded()
        let archived = try fixture.store.setArchived(id: fixture.piece.id, archived: true, expectedRevision: fixture.piece.revision, operationID: UUID())
        #expect(state.toggleLaundry(archived) == nil)
        #expect(try fixture.store.piece(id: fixture.piece.id)?.availability == .available)
    }

    @Test func favoritingAnOutfitFromACardPersists() async throws {
        let (state, fixture) = try await loaded()
        #expect(state.toggleFavorite(fixture.outfit))
        let favorite = try #require(state.outfits.first { $0.id == fixture.outfit.id })
        #expect(favorite.isFavorite)
        #expect(state.toggleFavorite(favorite))
        #expect(state.outfits.first { $0.id == fixture.outfit.id }?.isFavorite == false)
    }

    @Test func bulkLaundryThenAvailableChangesEveryChosenPiece() async throws {
        let (state, fixture) = try await loaded()
        let result = state.setAvailability(.laundry, for: [fixture.piece])
        #expect(result == AppState.BulkResult(changed: 1, failed: 0))
        let washing = try #require(state.pieces.first)
        #expect(washing.availability == .laundry)
        #expect(state.setAvailability(.laundry, for: [washing]) == AppState.BulkResult(changed: 0, failed: 0), "already there is a no-op")
        #expect(state.setAvailability(.available, for: [washing]).changed == 1)
        #expect(try fixture.store.piece(id: fixture.piece.id)?.availability == .available)
    }

    @Test func bulkChangeReportsStalePiecesWithoutLosingTheRest() async throws {
        let (state, fixture) = try await loaded()
        _ = state.toggleLaundry(fixture.piece)
        let result = state.setAvailability(.unavailable, for: [fixture.piece])
        #expect(result == AppState.BulkResult(changed: 0, failed: 1))
        #expect(state.collectionError != nil)
        #expect(try fixture.store.piece(id: fixture.piece.id)?.availability == .laundry)
    }

    @Test func bulkArchiveMovesPiecesToArchivedAndKeepsThemRestorable() async throws {
        let (state, fixture) = try await loaded()
        #expect(state.archive([fixture.piece]).changed == 1)
        #expect(state.pieces.isEmpty && state.archivedPieces.map(\.id) == [fixture.piece.id])
        #expect(try fixture.store.piece(id: fixture.piece.id)?.isArchived == true)
        #expect(state.archive(state.archivedPieces) == AppState.BulkResult(), "archived pieces are skipped")
    }

    @Test func duplicatingAnOutfitOpensANewDraftWithTheSamePieces() async throws {
        let (state, fixture) = try await loaded()
        state.duplicateOutfit(fixture.outfit)
        let editor = try #require(state.outfitEditor)
        #expect(editor.draft.pieceIDs == fixture.outfit.pieceIDs)
        #expect(editor.draft.name == "\(fixture.outfit.displayName) copy")
        #expect(editor.draft.outfitID != fixture.outfit.id && editor.draft.baseRevision == 0)
        #expect(editor.draft.themeIDs?.count == 1, "it joins the same themes")
        #expect(state.outfits.count == 1, "nothing is saved until the owner saves")
    }

    @Test func removingAnOutfitFromAThemeKeepsTheOutfit() async throws {
        let (state, fixture) = try await loaded()
        let theme = try #require(state.themes.first)
        #expect(state.remove(fixture.outfit, from: theme))
        #expect(state.themes.first?.outfitIDs.isEmpty == true)
        #expect(try fixture.store.themeDraft() == nil, "no draft is left behind")
        #expect(state.outfits.contains { $0.id == fixture.outfit.id }, "the outfit itself stays")
        #expect(state.themeError == nil)
    }

    @Test func removingFromAThemeIsRefusedWhileAThemeDraftIsUnfinished() async throws {
        let (state, fixture) = try await loaded()
        let theme = try #require(state.themes.first)
        try fixture.store.saveThemeDraft(ThemeDraft(ownerID: theme.ownerID))
        #expect(!state.remove(fixture.outfit, from: theme))
        #expect(state.themeError != nil)
        #expect(state.themes.first?.outfitIDs == theme.outfitIDs, "nothing changed")
    }

    @Test func aBulkChangeKeepsTheWritesThatSucceededWhenOneIsStale() async throws {
        let (state, fixture) = try await loaded()
        let second = try fixture.store.savePiece(PieceDraft(name: "Second tee", category: .tops, photoID: fixture.processed.id, photoRecipe: fixture.piece.photoRecipe), operationID: UUID())
        state.reloadPieces()
        _ = state.toggleLaundry(fixture.piece)
        let result = state.setAvailability(.unavailable, for: [fixture.piece, second])
        #expect(result == AppState.BulkResult(changed: 1, failed: 1))
        #expect(try fixture.store.piece(id: second.id)?.availability == .unavailable, "the fresh piece changed")
        #expect(try fixture.store.piece(id: fixture.piece.id)?.availability == .laundry, "the stale piece was left as the newer write set it")
        #expect(state.collectionError != nil)
    }

    @Test func duplicatingWhileAnotherOutfitDraftIsOpenSaysSoInsteadOfSwitching() async throws {
        let (state, fixture) = try await loaded()
        var draft = OutfitDraft(ownerID: fixture.outfit.ownerID)
        draft.name = "Unfinished"
        try fixture.store.saveOutfitDraft(draft)
        state.duplicateOutfit(fixture.outfit)
        #expect(state.outfitEditor == nil)
        #expect(state.outfitError != nil)
        #expect(try fixture.store.outfitDraft()?.name == "Unfinished", "the unfinished draft is untouched")
    }
}
