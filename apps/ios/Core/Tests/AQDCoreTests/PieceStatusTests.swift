import Foundation
import Testing
@testable import AQDCore

struct PieceStatusTests {
    private func piece(_ availability: PieceAvailability, archived: Bool = false) -> WardrobePiece {
        WardrobePiece(id: UUID(), name: "Tee", category: .tops, photoID: UUID(), availability: availability,
                      revision: 1, isArchived: archived, createdAt: Date(), updatedAt: Date())
    }

    @Test func eachAvailabilityHasOneName() {
        #expect(PieceStatus(piece(.available)).title == "Available")
        #expect(PieceStatus(piece(.unavailable)).title == "Unavailable")
        #expect(PieceStatus(piece(.laundry)).title == "In the laundry")
    }

    @Test func archivedWinsOverAvailability() {
        #expect(PieceStatus(piece(.laundry, archived: true)) == .archived)
    }

    @Test func onlyPiecesNeedingAttentionAreNotable() {
        #expect(!PieceStatus.available.isNotable)
        #expect(PieceStatus.unavailable.isNotable)
        #expect(PieceStatus.laundry.isNotable)
        #expect(PieceStatus.archived.isNotable)
    }

    @Test func laundryToggleGoesThereAndBack() {
        #expect(PieceStatus.laundryToggle(from: .available) == .laundry)
        #expect(PieceStatus.laundryToggle(from: .unavailable) == .laundry)
        #expect(PieceStatus.laundryToggle(from: .laundry) == .available)
    }
}
