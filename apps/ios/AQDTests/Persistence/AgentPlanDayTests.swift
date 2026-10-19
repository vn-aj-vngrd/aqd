import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct AgentPlanDayTests {
    private func draft(_ fixture: LocalDataFixture, owner: UUID, days: Int) throws -> PlanAuthoringDraft {
        let start = LocalPlanDay(year: 2026, month: 11, day: 2, timeZoneID: "Asia/Manila"), end = LocalPlanDay(year: 2026, month: 11, day: 1 + days, timeZoneID: "Asia/Manila")
        var plan = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: owner, name: "Agent days", start: start, end: end))
        for index in plan.slots.indices { plan.slots[index].outfit = fixture.outfit }
        plan.reviewing = true
        return plan
    }
    private func setUp() async throws -> (LocalDataFixture, AgentModel) {
        let fixture = try await LocalDataFixture()
        if let leftover = try fixture.store.planAuthoringDraft() { try fixture.store.finishPlanAuthoring(leftover, discarding: true) }
        return (fixture, try AgentModel(store: fixture.store))
    }

    @Test func leftOutDaysAreNotPlannedAndTheRestAreSavedTogether() async throws {
        let (fixture, model) = try await setUp()
        let plan = try draft(fixture, owner: model.conversation.ownerID, days: 3)
        model.propose(.plan(plan))
        let proposal = try #require(model.conversation.proposals?.last)
        let second = plan.slots[1].day.key
        model.setPlanDay(proposal.id, day: second, included: false)
        #expect(model.conversation.proposals?.last?.leftOutDays == [second])
        model.approveProposal(proposal.id, version: 1)
        let entries = try fixture.store.planEntries().filter { $0.planID == plan.plan.id }
        #expect(entries.count == 3 && entries.filter { $0.outfitID != nil }.count == 2)
        #expect(entries.first { $0.day.key == second }?.outfitID == nil)
        #expect(model.conversation.proposals?.last?.status == .succeeded)
    }

    @Test func atLeastOneDayAlwaysStaysIn() async throws {
        let (fixture, model) = try await setUp()
        let plan = try draft(fixture, owner: model.conversation.ownerID, days: 2)
        model.propose(.plan(plan))
        let proposal = try #require(model.conversation.proposals?.last)
        model.setPlanDay(proposal.id, day: plan.slots[0].day.key, included: false)
        model.setPlanDay(proposal.id, day: plan.slots[1].day.key, included: false)
        #expect(model.conversation.proposals?.last?.leftOutDays == [plan.slots[0].day.key])
        model.setPlanDay(proposal.id, day: plan.slots[0].day.key, included: true)
        #expect(model.conversation.proposals?.last?.leftOutDays == nil)
    }

    @Test func aDayLeftOutOfAnEditKeepsItsEarlierOutfit() async throws {
        let (fixture, model) = try await setUp()
        let owner = model.conversation.ownerID
        let created = try draft(fixture, owner: owner, days: 2)
        model.propose(.plan(created))
        model.approveProposal(try #require(model.conversation.proposals?.last).id, version: 1)
        let saved = try #require(try fixture.store.planDefinitions().first { $0.id == created.plan.id })
        let entries = try fixture.store.planEntries().filter { $0.planID == saved.id }
        var edit = try PlanAuthoringDraft(editing: saved, entries: entries, outfits: try fixture.store.outfits(), scope: .whole, anchorEntryID: nil)
        for index in edit.slots.indices { edit.slots[index].outfit = nil; edit.slots[index].unassignedByChoice = true }
        edit.slots[0].outfit = fixture.outfit; edit.slots[0].unassignedByChoice = false
        edit.reviewing = true
        let kept = edit.leavingOut([edit.slots[1].day.key])
        #expect(kept.slots[1].outfit?.id == fixture.outfit.id && kept.slots[0].outfit?.id == fixture.outfit.id)
    }

    @Test func plainDayWordsNameDaysOfAPlan() {
        let days = (2...8).map { LocalPlanDay(year: 2026, month: 11, day: $0, timeZoneID: "Asia/Manila") }
        #expect(AgentPlanDayWord.key("2026-11-05", in: days) == "2026-11-05" && AgentPlanDayWord.key("2026-12-05", in: days) == nil)
        #expect(AgentPlanDayWord.key("wednesday", in: days) == "2026-11-04")
        #expect(AgentPlanDayWord.key("someday", in: days) == nil)
    }
}
