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
    @Test func officeRoutineUsesThreeCalendarMonthsAndKeepsCompletedEntriesOutOfEdits() throws {
        let owner = UUID()
        let start = LocalPlanDay(year: 2026, month: 10, day: 1, timeZoneID: "Asia/Manila")
        var plan = PlanDefinition(ownerID: owner, name: "Office", start: start,
            end: LocalPlanDay(year: 2026, month: 12, day: 31, timeZoneID: "Asia/Manila"),
            routine: RoutineConfiguration(weekdays: [2, 3, 4, 5, 6]))
        #expect(try plan.days().count == 66)
        plan.end = LocalPlanDay(year: 2027, month: 1, day: 1, timeZoneID: start.timeZoneID)
        #expect(throws: PlanAuthoringError.rangeTooLong) { try plan.days() }
        plan.end = LocalPlanDay(year: 2026, month: 10, day: 2, timeZoneID: start.timeZoneID)
        let completed = OutfitPlanEntry(id: UUID(), planID: plan.id, ownerID: owner, day: start, occasion: "Office",
            outfitID: UUID(), outfitRevision: 1, state: .worn)
        var nextDay = start; nextDay.day = 2
        let upcoming = OutfitPlanEntry(id: UUID(), planID: plan.id, ownerID: owner, day: nextDay, occasion: "Office",
            outfitID: nil, outfitRevision: nil, state: .unassigned)
        let draft = try PlanAuthoringDraft(editing: plan, entries: [completed, upcoming], outfits: [], scope: .whole, anchorEntryID: nil)
        #expect(draft.slots.map(\.id) == [upcoming.id])
        #expect(draft.editableBaseEntries == [upcoming])
    }
    @Test func rebuildingDatesRetainsDistinctOccasionsAndRejectsUnreviewedDuplicateSlots() throws {
        let day = LocalPlanDay(year: 2026, month: 10, day: 1, timeZoneID: "Asia/Manila")
        var draft = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: UUID(), name: "Occasions", start: day, end: day))
        draft.slots[0].occasion = "Office"; draft.slots[0].unassignedByChoice = true
        draft.slots.append(PlanSlotDraft(day: day, occasion: "Dinner", unassignedByChoice: true))
        let ids = draft.slots.map(\.id)
        try draft.rebuildDates()
        #expect(draft.slots.map(\.id) == ids)
        try draft.validatedForSave(outfits: [], existing: [])
        draft.slots.append(PlanSlotDraft(day: day, occasion: " Office ", unassignedByChoice: true))
        #expect(throws: PlanAuthoringError.unresolvedConflict) { try draft.validatedForSave(outfits: [], existing: []) }
    }
}
