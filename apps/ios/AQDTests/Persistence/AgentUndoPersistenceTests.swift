import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct AgentUndoPersistenceTests {
    private func setUp() async throws -> (LocalDataFixture, AgentModel) {
        let fixture = try await LocalDataFixture()
        // Unsaved drafts left by the fixture would legitimately block an approval; start from clean editors.
        if let leftover = try fixture.store.outfitDraft() { try fixture.store.discardOutfitDraft(id: leftover.id) }
        if let leftover = try fixture.store.themeDraft() { try fixture.store.finishThemeDraft(leftover, discarding: true) }
        if let leftover = try fixture.store.wearDraft() { try fixture.store.finishWearDraft(leftover, discarding: true) }
        if let leftover = try fixture.store.planAuthoringDraft() { try fixture.store.finishPlanAuthoring(leftover, discarding: true) }
        if let leftover = try fixture.store.identityDraft() { try fixture.store.finishIdentityDraft(leftover, discarding: true) }
        return (fixture, try AgentModel(store: fixture.store))
    }
    private func approve(_ model: AgentModel, _ action: AgentReviewedAction) throws -> AgentActionProposal {
        model.propose(action)
        let proposal = try #require(model.conversation.proposals?.last)
        model.approveProposal(proposal.id, version: 1)
        return try #require(model.conversation.proposals?.last)
    }
    private func newOutfit(_ fixture: LocalDataFixture, _ owner: UUID, name: String) throws -> OutfitDraft {
        var draft = OutfitDraft(ownerID: owner); draft.name = name; draft.select(fixture.piece.id)
        try draft.reviewCurrentPieces([fixture.piece])
        return draft
    }

    @Test func aNewOutfitCanBeRemovedAgainWhileNothingUsesIt() async throws {
        let (fixture, model) = try await setUp()
        let applied = try approve(model, .outfit(try newOutfit(fixture, model.conversation.ownerID, name: "Agent look")))
        #expect(applied.status == .succeeded && model.canUndo(applied))
        let count = try fixture.store.outfits().count
        model.undoProposal(applied.id)
        #expect(try fixture.store.outfits().count == count - 1 && model.conversation.proposals?.last?.receipt?.undoneAt != nil)
    }

    @Test func aNewOutfitThatANewThemeNowUsesCannotBeRemovedFromUnderIt() async throws {
        let (fixture, model) = try await setUp()
        let applied = try approve(model, .outfit(try newOutfit(fixture, model.conversation.ownerID, name: "Agent look")))
        let outfitID = try #require(applied.receipt?.recordID)
        var theme = ThemeDraft(ownerID: model.conversation.ownerID); theme.name = "Mine"; theme.outfitIDs = [outfitID]
        try fixture.store.saveThemeDraft(theme); _ = try fixture.store.saveTheme(theme); try fixture.store.finishThemeDraft(theme)
        #expect(!model.canUndo(applied))
        model.undoProposal(applied.id)
        #expect(try fixture.store.outfit(id: outfitID) != nil && model.error != nil)
    }

    @Test func anOutfitEditPutsTheOldNameAndOccasionBack() async throws {
        let (fixture, model) = try await setUp()
        var draft = OutfitDraft(editing: fixture.outfit); draft.name = "Renamed by Agent"; draft.occasion = "Gala"
        try draft.reviewCurrentPieces([fixture.piece])
        let applied = try approve(model, .outfit(draft))
        #expect(try fixture.store.outfit(id: fixture.outfit.id)?.name == "Renamed by Agent" && model.canUndo(applied))
        model.undoProposal(applied.id)
        let restored = try #require(try fixture.store.outfit(id: fixture.outfit.id))
        #expect(restored.name == fixture.outfit.name && restored.occasion == fixture.outfit.occasion)
    }

    @Test func aThemeCreatedByTheAgentIsRemovedAndAnEditedOneIsRestored() async throws {
        let (fixture, model) = try await setUp()
        var created = ThemeDraft(ownerID: model.conversation.ownerID); created.name = "Agent theme"; created.outfitIDs = [fixture.outfit.id]
        let first = try approve(model, .theme(created))
        let themes = try fixture.store.themes().count
        model.undoProposal(first.id)
        #expect(try fixture.store.themes().count == themes - 1)

        let existing = try #require(try fixture.store.themes().first)
        var edit = ThemeDraft(editing: existing); edit.name = "Edited by Agent"
        let second = try approve(model, .theme(edit))
        #expect(try fixture.store.themes().first { $0.id == existing.id }?.name == "Edited by Agent")
        model.undoProposal(second.id)
        #expect(try fixture.store.themes().first { $0.id == existing.id }?.name == existing.name)
    }

    @Test func aRecordedWearIsUndoneAndAnEditedProfileIsRestored() async throws {
        let (fixture, model) = try await setUp()
        let owner = model.conversation.ownerID
        let day = LocalPlanDay(year: 2026, month: 3, day: 3, timeZoneID: "Asia/Manila")
        let wornBefore = try fixture.store.wearRecords().count
        let wear = try approve(model, .wear(OutfitWearDraft(ownerID: owner, outfitID: fixture.outfit.id, pieces: [fixture.piece], day: day)))
        #expect(try fixture.store.wearRecords().count == wornBefore + 1 && model.canUndo(wear))
        model.undoProposal(wear.id)
        #expect(try fixture.store.wearRecords().count == wornBefore)

        if try fixture.store.localIdentity() == nil {
            var first = LocalIdentityDraft(ownerID: owner); first.name = "Angelika"
            try fixture.store.saveIdentityDraft(first); _ = try fixture.store.saveIdentity(first); try fixture.store.finishIdentityDraft(first)
        }
        let base = try #require(try fixture.store.localIdentity())
        var edit = LocalIdentityDraft(ownerID: owner, base: base); edit.name = "Someone Else"
        let profile = try approve(model, .profile(edit))
        #expect(try fixture.store.localIdentity()?.name == "Someone Else" && model.canUndo(profile))
        model.undoProposal(profile.id)
        #expect(try fixture.store.localIdentity()?.name == base.name)
    }

    @Test func aPlanTheAgentCreatedIsRemovedWithItsEntries() async throws {
        let (fixture, model) = try await setUp()
        let day = LocalPlanDay(year: 2026, month: 11, day: 2, timeZoneID: "Asia/Manila")
        var draft = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: model.conversation.ownerID, name: "Agent week", start: day, end: day))
        draft.slots[0].outfit = fixture.outfit; draft.reviewing = true
        let before = try fixture.store.planEntries().count
        let applied = try approve(model, .plan(draft))
        #expect(try fixture.store.planEntries().count == before + 1 && model.canUndo(applied))
        model.undoProposal(applied.id)
        #expect(try fixture.store.planEntries().count == before)
        #expect(try fixture.store.planDefinitions().contains { $0.name == "Agent week" } == false)
    }

    @Test func aTripUndoRemovesThePlanThemeAndOutfitsTogetherOrNotAtAll() async throws {
        let (fixture, model) = try await setUp()
        let owner = model.conversation.ownerID
        let outfit = try fixture.store.saveOutfitAndReceipt(try newOutfit(fixture, owner, name: "Trip day"))
        var theme = ThemeDraft(ownerID: owner); theme.name = "Trip theme"; theme.outfitIDs = [outfit.id]
        let savedTheme = try fixture.store.saveThemeAndFinish(theme)
        let undo = AgentUndo.trip([.outfitCreate(id: outfit.id, appliedRevision: outfit.revision), .themeCreate(id: savedTheme.id, appliedRevision: savedTheme.revision)])
        var proposal = AgentActionProposal(action: .availability(AgentAvailabilityChange(piece: fixture.piece, value: .available)))
        proposal.status = .succeeded; proposal.receipt = AgentActionReceipt(recordID: outfit.id, kind: "trip", undo: undo)
        model.conversation.proposals = [proposal]
        #expect(model.canUndo(proposal))
        model.undoProposal(proposal.id)
        #expect(try fixture.store.outfit(id: outfit.id) == nil && fixture.store.themes().allSatisfy { $0.id != savedTheme.id })
        #expect(model.conversation.proposals?.first?.receipt?.undoneAt != nil)
    }

    @Test func undoIsRefusedForEveryKindOnceTheRecordWasEditedAfterwards() async throws {
        let (fixture, model) = try await setUp()
        var draft = OutfitDraft(editing: fixture.outfit); draft.name = "By Agent"
        try draft.reviewCurrentPieces([fixture.piece])
        let applied = try approve(model, .outfit(draft))
        var again = OutfitDraft(editing: try #require(try fixture.store.outfit(id: fixture.outfit.id))); again.name = "By hand"
        try again.reviewCurrentPieces([fixture.piece])
        try fixture.store.saveOutfitDraft(again); _ = try fixture.store.saveOutfit(again); try fixture.store.acknowledgeOutfitReceipt(again)
        #expect(!model.canUndo(applied))
        model.undoProposal(applied.id)
        #expect(try fixture.store.outfit(id: fixture.outfit.id)?.name == "By hand")
    }
}

private extension PieceStore {
    func saveOutfitAndReceipt(_ draft: OutfitDraft) throws -> Outfit {
        try saveOutfitDraft(draft); let value = try saveOutfit(draft); try acknowledgeOutfitReceipt(draft); return value
    }
    func saveThemeAndFinish(_ draft: ThemeDraft) throws -> OutfitTheme {
        try saveThemeDraft(draft); let value = try saveTheme(draft); try finishThemeDraft(draft); return value
    }
}
