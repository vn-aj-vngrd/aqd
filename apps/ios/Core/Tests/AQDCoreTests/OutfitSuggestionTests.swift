import Foundation
import Testing
@testable import AQDCore

struct OutfitSuggestionTests {
    private func piece(_ category: PieceCategory, availability: PieceAvailability = .available) -> WardrobePiece {
        WardrobePiece(id: UUID(), name: category.rawValue, category: category, photoID: UUID(), availability: availability)
    }

    @Test func readinessUsesCategoriesAndAvailabilityRatherThanItemCount() throws {
        let top = piece(.tops), bottom = piece(.bottoms), shoes = piece(.shoes), accessory = piece(.accessories)
        #expect(OutfitReadiness(pieces: [top], pinnedIDs: [top.id]).missingCategories == [.bottoms, .shoes])
        #expect(OutfitReadiness(pieces: [top, bottom, shoes], pinnedIDs: [top.id]).isReady)
        #expect(!OutfitReadiness(pieces: [accessory, piece(.accessories), piece(.accessories)], pinnedIDs: [accessory.id]).isReady)
        #expect(!OutfitReadiness(pieces: [top, bottom, piece(.shoes, availability: .laundry)], pinnedIDs: [top.id]).isReady)
        let dress = piece(.dresses)
        #expect(OutfitReadiness(pieces: [dress, shoes], pinnedIDs: [dress.id]).isReady)
    }

    @Test func proposalsAndReplacementPreservePinsNameAndThemes() throws {
        let top = piece(.tops), bottom = piece(.bottoms), shoes = piece(.shoes), replacement = piece(.shoes)
        let pieces = [top, bottom, shoes, replacement]
        var draft = OutfitDraft(ownerID: UUID())
        draft.name = "My look"; draft.select(top.id); draft.pin(top.id); draft.themeIDs = [UUID()]
        let themes = draft.themeIDs
        try draft.applyProposal([top.id, bottom.id, shoes.id], pieces: pieces)
        try draft.replace(shoes.id, with: replacement.id, pieces: pieces)
        #expect(draft.pieceIDs == [top.id, bottom.id, replacement.id])
        #expect(draft.name == "My look")
        #expect(draft.themeIDs == themes)
        #expect(throws: OutfitSuggestionError.pinnedPiece) { try draft.replace(top.id, with: replacement.id, pieces: pieces) }
        #expect(throws: OutfitSuggestionError.invalidProposal) { try draft.applyProposal([bottom.id, shoes.id], pieces: pieces) }
        #expect(throws: OutfitSuggestionError.invalidProposal) { try draft.applyProposal([top.id, UUID()], pieces: pieces) }
    }

    @Test func replacingAPieceInAPartialManualLookDoesNotRequireACompleteRecommendation() throws {
        let first = piece(.shoes), second = piece(.shoes)
        var draft = OutfitDraft(ownerID: UUID())
        draft.name = "Partial look"; draft.select(first.id)
        try draft.replace(first.id, with: second.id, pieces: [first, second])
        #expect(draft.pieceIDs == [second.id])
        try draft.validatedForSave(pieces: [first, second])
    }

    @Test func changedPieceRevisionInvalidatesAReviewedProposal() throws {
        let top = piece(.tops), bottom = piece(.bottoms), shoes = piece(.shoes)
        var draft = OutfitDraft(ownerID: UUID())
        draft.name = "Review"; draft.select(top.id); draft.pin(top.id)
        try draft.applyProposal([top.id, bottom.id, shoes.id], pieces: [top, bottom, shoes])
        let edited = WardrobePiece(id: top.id, name: "Changed shirt", category: .tops, photoID: top.photoID, revision: 2)
        #expect(throws: OutfitValidationError.stalePieces) { try draft.validatedForSave(pieces: [edited, bottom, shoes]) }
    }
}
