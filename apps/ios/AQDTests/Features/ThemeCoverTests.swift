import AQDCore
import Foundation
import Testing
@testable import AQD

struct ThemeCoverTests {
    private func outfit(_ pieces: [UUID]) -> Outfit {
        Outfit(id: UUID(), ownerID: UUID(), name: "Look", pieceIDs: pieces)
    }

    @Test func coverDrawsDistinctPiecesRoundRobinAcrossOutfits() {
        let shirt = UUID(), pants = UUID(), shoes = UUID(), belt = UUID(), dress = UUID()
        let first = outfit([shirt, pants, shoes]), second = outfit([shirt, belt, dress])
        let ids = ThemeCover.coverPieceIDs([first, second])
        #expect(ids == [shirt, pants, belt, shoes], "the shared shirt appears once and both outfits contribute")
        _ = dress
        #expect(Set(ids).count == ids.count)
    }

    @Test func coverStopsAtTheLimitAndHandlesEmptyThemes() {
        let pieces = (0..<6).map { _ in UUID() }
        #expect(ThemeCover.coverPieceIDs([outfit(pieces)], limit: 4) == Array(pieces.prefix(4)))
        #expect(ThemeCover.coverPieceIDs([]).isEmpty)
    }
}
