import Foundation
import Testing
@testable import AQDCore

struct PlanAuthoringTests {
    @Test func manualRangeIncludesBothEndsAndRejectsMoreThanTwoWeeks() throws {
        var plan = PlanDefinition(ownerID: UUID(), name: "Two weeks",
            start: LocalPlanDay(year: 2026, month: 1, day: 25, timeZoneID: "Asia/Manila"),
            end: LocalPlanDay(year: 2026, month: 2, day: 7, timeZoneID: "Asia/Manila"))
        let days = try plan.days()
        #expect(days.count == 14)
        #expect(days.first?.key == "2026-01-25")
        #expect(days.last?.key == "2026-02-07")
        plan.end.day = 8
        #expect(throws: PlanAuthoringError.rangeTooLong) { try plan.days() }
        plan.end = plan.start; plan.end.day = 24
        #expect(throws: PlanAuthoringError.invalidRange) { try plan.days() }
    }
    @Test func gapsRequireAnExplicitChoiceAndRebuildRetainsSelectedDateIdentity() throws {
        let day = LocalPlanDay(year: 2026, month: 11, day: 1, timeZoneID: "Asia/Manila")
        var draft = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: UUID(), name: "Manual", start: day, end: day))
        #expect(throws: PlanAuthoringError.intentionalGapRequired) { try draft.validatedForSave(outfits: [], existing: []) }
        let id = draft.slots[0].id
        draft.slots[0].unassignedByChoice = true
        draft.plan.end.day = 2; try draft.rebuildDates()
        #expect(draft.slots.first?.id == id)
        #expect(draft.slots.first?.unassignedByChoice == true)
        draft.slots[1].unassignedByChoice = true
        try draft.validatedForSave(outfits: [], existing: [])
    }
}
