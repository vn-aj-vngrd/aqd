import Foundation
import Testing
@testable import AQDCore

struct AgentMutationTests {
    @Test func profileProposalPreservesPhotoAndUnchangedFieldsUntilApproved() throws {
        let owner = UUID(), photo = UUID()
        let base = LocalProfileIdentity(ownerID: owner, name: "Van", photoID: photo, revision: 3, caption: "My fits")
        let request = AgentMutationRequest(kind: .updateProfile, caption: "Everyday looks")
        let action = try request.prepare(ownerID: owner, identity: base)
        guard case .profile(let draft) = action else { Issue.record("Expected profile review"); return }
        #expect(draft.base == base && draft.name == "Van" && draft.photoID == photo)
        #expect(try draft.result().caption == "Everyday looks")
        let proposal = AgentActionProposal(action: action)
        #expect(proposal.status == .proposed && proposal.receipt == nil)
    }
}

extension AgentMutationTests {
    @Test func pieceEditPreservesMediaAndOtherMetadata() throws {
        let piece = WardrobePiece(id: UUID(), name: "Shirt", category: .tops, photoID: UUID(), details: PieceDetails(color: "Blue", brand: "Original"), revision: 4)
        let request = AgentMutationRequest(kind: .editPiece, targetID: piece.id, name: "Work shirt", color: "Navy")
        guard case .piece(let change) = try request.prepare(ownerID: UUID(), pieces: [piece]) else { Issue.record("Expected piece"); return }
        #expect(change.draft.name == "Work shirt" && change.draft.details.color == "Navy")
        #expect(change.draft.photoID == piece.photoID && change.draft.details.brand == "Original" && change.draft.baseRevision == 4)
    }
    @Test func invalidDatesAndInventedTargetsCannotBecomeReviews() throws {
        let owner = UUID(), id = UUID()
        let outfit = Outfit(id: id, ownerID: owner, name: "Everyday", pieceIDs: [UUID()])
        #expect(throws: (any Error).self) { try AgentMutationRequest(kind: .editOutfit, targetID: UUID(), name: "Changed").prepare(ownerID: owner, outfits: [outfit]) }
        for date in ["2026-02-30", "26-1-2", "2026-10-01-extra"] {
            #expect(throws: (any Error).self) { try AgentMutationRequest(kind: .createPlan, name: "Trip", assignments: [AgentPlanAssignment(date: date, outfitID: id)]).prepare(ownerID: owner, outfits: [outfit]) }
        }
    }
    @Test func planReviewRequiresEveryDayAndRetainsExactAssignments() throws {
        let owner = UUID(), id = UUID()
        let piece = WardrobePiece(id: UUID(), name: "Shirt", category: .tops, photoID: UUID())
        let outfit = Outfit(id: id, ownerID: owner, name: "Everyday", pieceIDs: [piece.id])
        let gap = AgentMutationRequest(kind: .createPlan, name: "Week", assignments: [.init(date: "2026-10-19", outfitID: id), .init(date: "2026-10-21", outfitID: id)])
        #expect(throws: (any Error).self) { try gap.prepare(ownerID: owner, pieces: [piece], outfits: [outfit]) }
        let complete = AgentMutationRequest(kind: .createPlan, name: "Week", assignments: [.init(date: "2026-10-19", outfitID: id), .init(date: "2026-10-20", outfitID: id)])
        guard case .plan(let draft) = try complete.prepare(ownerID: owner, pieces: [piece], outfits: [outfit]) else { Issue.record("Expected plan"); return }
        #expect(draft.slots.map { $0.day.key } == ["2026-10-19", "2026-10-20"])
        #expect(draft.slots.allSatisfy { $0.outfit?.id == id } && draft.reviewing)
    }
    @Test func unavailablePieceCannotEnterAnOutfitAndForeignOutfitCannotEnterATheme() throws {
        let owner = UUID()
        let piece = WardrobePiece(id: UUID(), name: "Laundry shirt", category: .tops, photoID: UUID(), availability: .laundry)
        #expect(throws: (any Error).self) { try AgentMutationRequest(kind: .createOutfit, name: "Look", pieceIDs: [piece.id]).prepare(ownerID: owner, pieces: [piece]) }
        let foreign = Outfit(id: UUID(), ownerID: UUID(), name: "Other owner's look", pieceIDs: [piece.id])
        #expect(throws: (any Error).self) { try AgentMutationRequest(kind: .createTheme, name: "Week", outfitIDs: [foreign.id]).prepare(ownerID: owner, outfits: [foreign]) }
    }
    @Test func storedToolProposalKeepsRequestAndLegacyProposalDecodes() throws {
        let request = AgentMutationRequest(kind: .updateProfile, name: "Van")
        var proposal = AgentActionProposal(action: try request.prepare(ownerID: UUID()))
        proposal.toolRequest = request
        let data = try JSONEncoder().encode(proposal)
        #expect(try JSONDecoder().decode(AgentActionProposal.self, from: data).toolRequest == request)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any]); object.removeValue(forKey: "toolRequest")
        #expect(try JSONDecoder().decode(AgentActionProposal.self, from: JSONSerialization.data(withJSONObject: object)).toolRequest == nil)
    }
}
