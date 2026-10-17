import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct AgentActionPersistenceTests {
    @Test func anUnknownThemeSaveReconcilesOneDomainReceiptAfterRestart() throws {
        var acknowledgments = 0
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory, afterOutfitSave: {
            acknowledgments += 1
            if acknowledgments == 3 { throw CocoaError(.fileReadUnknown) }
        })
        let model = try AgentModel(store: store)
        var draft = ThemeDraft(ownerID: model.conversation.ownerID); draft.name = "Quiet weekends"
        model.propose(.theme(draft))
        let proposal = try #require(model.conversation.proposals?.first)
        #expect(try store.themes().isEmpty)
        model.approveProposal(proposal.id, version: 2)
        #expect(try store.themes().isEmpty)
        model.approveProposal(proposal.id, version: 1)
        #expect(try store.themes().count == 1)
        #expect(model.conversation.proposals?.first?.receipt == nil)
        model.delete(try #require(model.history.first))
        #expect(!model.hasPendingOperation)
        model.approveProposal(proposal.id, version: 1)
        #expect(model.conversation.proposals?.first?.status == .succeeded)
        let reopened = try AgentModel(store: PieceStore(directory: directory))
        reopened.approveProposal(proposal.id, version: 1)
        #expect(reopened.conversation.proposals?.first?.status == .succeeded)
        #expect(try reopened.store.themes().count == 1)
        reopened.approveProposal(proposal.id, version: 1)
        #expect(try reopened.store.themes().count == 1)
        #expect(reopened.conversation.proposals?.first?.status == .succeeded)
        #expect(!reopened.hasPendingOperation)
    }
    @Test func cancelledTwoWeekReviewWritesNoCalendarAndApprovedVersionCreatesExactlyFourteenEntries() throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let model = try AgentModel(store: store), owner = model.conversation.ownerID
        var draft = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: owner, name: "Two weeks", start: LocalPlanDay(year: 2026, month: 10, day: 16, timeZoneID: "Asia/Manila"), end: LocalPlanDay(year: 2026, month: 10, day: 29, timeZoneID: "Asia/Manila")))
        for i in draft.slots.indices { draft.slots[i].unassignedByChoice = true }; draft.reviewing = true
        model.propose(.plan(draft)); let cancelled = try #require(model.conversation.proposals?.last)
        model.cancelProposal(cancelled.id); model.approveProposal(cancelled.id, version: 1)
        #expect(try store.planEntries().isEmpty)
        #expect(model.conversation.proposals?.first?.status == .cancelled)
        model.propose(.plan(draft)); let approved = try #require(model.conversation.proposals?.last)
        model.approveProposal(approved.id, version: 1)
        #expect(try store.planEntries().count == 14)
        #expect(model.conversation.proposals?.last?.receipt?.recordID == draft.plan.id)
        model.approveProposal(approved.id, version: 1)
        #expect(try store.planEntries().count == 14 && store.wearRecords().isEmpty)
    }
}
