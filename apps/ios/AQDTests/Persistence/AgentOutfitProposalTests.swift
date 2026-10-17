import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct AgentOutfitProposalTests {
    @Test func applyingTheSameApprovalTwiceSavesOneOutfitWithAReceipt() async throws {
        let fixture = try await LocalDataFixture()
        let model = try AgentModel(store: fixture.store)
        let before = try fixture.store.outfits().count
        let request = AgentMutationRequest(kind: .createOutfit, name: "Agent look", pieceIDs: [fixture.piece.id], occasion: "Coffee")
        let action = try request.prepare(ownerID: model.conversation.ownerID, pieces: fixture.store.pieces())
        model.propose(action)
        let proposal = try #require(model.conversation.proposals?.first)
        model.approveProposal(proposal.id, version: proposal.version)
        model.approveProposal(proposal.id, version: proposal.version)
        #expect(try fixture.store.outfits().count == before + 1)
        let saved = try #require(fixture.store.outfits().first { $0.name == "Agent look" })
        #expect(saved.occasion == "Coffee")
        #expect(model.conversation.proposals?.first?.receipt?.recordID == saved.id)
    }
}
