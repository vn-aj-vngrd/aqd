import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct AgentTripProposalTests {
    private func addPieces(_ fixture: LocalDataFixture) throws {
        let photo = fixture.processed.id
        for (name, category) in [("Linen shorts", PieceCategory.bottoms), ("Wide trousers", .bottoms), ("Sandals", .shoes), ("Sneakers", .shoes), ("Cotton tee", .tops), ("Beach dress", .dresses)] {
            _ = try fixture.store.savePiece(PieceDraft(name: name, category: category, photoID: photo), operationID: UUID())
        }
    }

    @Test func applyingATripSavesOutfitsThemeAndPlannerOnceAndResumesSafely() async throws {
        let fixture = try await LocalDataFixture()
        try addPieces(fixture)
        let model = try AgentModel(store: fixture.store)
        if let leftover = try fixture.store.outfitDraft() { try fixture.store.discardOutfitDraft(id: leftover.id) }
        if let leftover = try fixture.store.themeDraft() { try fixture.store.finishThemeDraft(leftover, discarding: true) }
        if let leftover = try fixture.store.planAuthoringDraft() { try fixture.store.finishPlanAuthoring(leftover, discarding: true) }
        let outfitsBefore = try fixture.store.outfits().count, themesBefore = try fixture.store.themes().count, plansBefore = try fixture.store.planDefinitions().count
        let spec = AgentTripSpec(destination: "Boracay", startDate: "2027-03-10", days: TripIntent.parse("3 day trip to Boracay")?.briefs ?? [])
        let request = AgentMutationRequest(kind: .createTrip, name: "Boracay trip", trip: spec)
        let action = try request.prepare(ownerID: model.conversation.ownerID, pieces: fixture.store.pieces(), outfits: fixture.store.outfits(), themes: fixture.store.themes(),
                                         plans: fixture.store.planDefinitions(), entries: fixture.store.planEntries())
        model.propose(action)
        let proposal = try #require(model.conversation.proposals?.first)
        model.approveProposal(proposal.id, version: proposal.version)
        model.approveProposal(proposal.id, version: proposal.version)
        #expect(model.conversation.proposals?.first?.status == .succeeded)
        #expect(try fixture.store.outfits().count == outfitsBefore + 3)
        #expect(try fixture.store.themes().count == themesBefore + 1)
        #expect(try fixture.store.planDefinitions().count == plansBefore + 1)
        let plan = try #require(fixture.store.planDefinitions().first { $0.name == "Boracay trip" })
        #expect(plan.trip?.destination == "Boracay")
        #expect(try fixture.store.planEntries().filter { $0.planID == plan.id }.count == 3)
    }

    @Test func leavingOutTheThemeAndPlannerSavesOnlyOutfits() async throws {
        let fixture = try await LocalDataFixture()
        try addPieces(fixture)
        let model = try AgentModel(store: fixture.store)
        if let leftover = try fixture.store.outfitDraft() { try fixture.store.discardOutfitDraft(id: leftover.id) }
        if let leftover = try fixture.store.themeDraft() { try fixture.store.finishThemeDraft(leftover, discarding: true) }
        if let leftover = try fixture.store.planAuthoringDraft() { try fixture.store.finishPlanAuthoring(leftover, discarding: true) }
        let themesBefore = try fixture.store.themes().count, plansBefore = try fixture.store.planDefinitions().count
        let spec = AgentTripSpec(destination: "Cebu", startDate: "2027-04-01", days: Array((TripIntent.parse("2 day trip to Cebu")?.briefs ?? []).prefix(2)))
        let action = try AgentMutationRequest(kind: .createTrip, name: "Cebu trip", trip: spec).prepare(
            ownerID: model.conversation.ownerID, pieces: fixture.store.pieces(), outfits: fixture.store.outfits(), themes: fixture.store.themes())
        model.propose(action)
        let proposal = try #require(model.conversation.proposals?.first)
        model.setTripOptions(proposal.id, includeTheme: false, includePlan: false)
        model.approveProposal(proposal.id, version: proposal.version)
        #expect(model.conversation.proposals?.first?.status == .succeeded)
        #expect(try fixture.store.themes().count == themesBefore)
        #expect(try fixture.store.planDefinitions().count == plansBefore)
    }
}
