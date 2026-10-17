import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct ClosetActionTests {
    private func loaded() async throws -> (AppState, LocalDataFixture) {
        let fixture = try await LocalDataFixture()
        let state = AppState(store: fixture.store)
        state.reloadPieces(); state.reloadOutfits()
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
}
