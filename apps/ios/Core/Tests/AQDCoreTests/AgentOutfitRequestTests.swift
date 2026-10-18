import Foundation
import Testing
@testable import AQDCore

struct AgentOutfitRequestTests {
    private func piece(_ category: PieceCategory, availability: PieceAvailability = .available) -> WardrobePiece {
        WardrobePiece(id: UUID(), name: category.rawValue, category: category, photoID: UUID(), availability: availability)
    }

    @Test func aProposalMissingAPinnedPieceOrUsingAnUnavailableOneIsRejected() throws {
        let owner = UUID(), top = piece(.tops), bottom = piece(.bottoms), laundry = piece(.shoes, availability: .laundry)
        let pieces = [top, bottom, laundry]
        let missingPin = AgentMutationRequest(kind: .createOutfit, name: "Look", pieceIDs: [top.id, bottom.id], pinnedIDs: [laundry.id])
        #expect(throws: (any Error).self) { try missingPin.prepare(ownerID: owner, pieces: pieces) }
        let unavailable = AgentMutationRequest(kind: .createOutfit, name: "Look", pieceIDs: [top.id, laundry.id])
        #expect(throws: (any Error).self) { try unavailable.prepare(ownerID: owner, pieces: pieces) }
        let valid = AgentMutationRequest(kind: .createOutfit, name: "Look", pieceIDs: [top.id, bottom.id], occasion: "Dinner", pinnedIDs: [top.id])
        guard case .outfit(let draft) = try valid.prepare(ownerID: owner, pieces: pieces) else { Issue.record("Expected an outfit"); return }
        #expect(draft.occasion == "Dinner" && draft.pinnedPieceIDs == [top.id])
    }

    @Test func relabelKeepsPiecesAndRefusesOutfitOnlyFieldsOnAThemeTarget() throws {
        let owner = UUID(), top = piece(.tops)
        let outfit = Outfit(id: UUID(), ownerID: owner, name: "Old", pieceIDs: [top.id])
        let theme = OutfitTheme(id: UUID(), ownerID: owner, name: "Quiet", description: "", outfitIDs: [outfit.id], revision: 1)
        let rename = AgentMutationRequest(kind: .relabel, targetID: outfit.id, name: "Sunday", occasion: "Brunch")
        guard case .outfit(let draft) = try rename.prepare(ownerID: owner, pieces: [top], outfits: [outfit], themes: [theme]) else { Issue.record("Expected an outfit"); return }
        #expect(draft.pieceIDs == [top.id] && draft.name == "Sunday" && draft.occasion == "Brunch" && draft.outfitID == outfit.id)
        let mood = AgentMutationRequest(kind: .relabel, targetID: theme.id, mood: "Calm")
        #expect(throws: (any Error).self) { try mood.prepare(ownerID: owner, pieces: [top], outfits: [outfit], themes: [theme]) }
    }
}
