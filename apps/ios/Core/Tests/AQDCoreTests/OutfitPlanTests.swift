import Foundation
import Testing
@testable import AQDCore

struct OutfitPlanTests {
    @Test func closeBaselinesSurviveCodingAndDetectRevertedDateSelections() throws {
        let owner = UUID(), day = LocalPlanDay(year: 2026, month: 10, day: 17, timeZoneID: "Asia/Manila")
        var plan = OutfitPlanDraft(ownerID: owner, day: day)
        #expect(!plan.hasChanges)
        plan.day = LocalPlanDay(year: 2026, month: 10, day: 18, timeZoneID: "Asia/Manila")
        #expect(plan.hasChanges)
        plan.day = day
        #expect(!plan.hasChanges)
        let encoded = try JSONEncoder().encode(plan)
        #expect(try JSONDecoder().decode(OutfitPlanDraft.self, from: encoded).hasChanges == false)
        var legacy = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacy.removeValue(forKey: "initialDay")
        #expect(try JSONDecoder().decode(OutfitPlanDraft.self, from: JSONSerialization.data(withJSONObject: legacy)).hasChanges)
        var trip = TripConfiguration()
        trip.activities = ["Museum", "Dinner"]
        var author = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: owner, start: day, end: day, trip: trip))
        author.tripActivitiesText = "Museum, Dinner"
        #expect(!author.hasChanges)
        author.tripActivitiesText = "Museum, Lunch"
        #expect(author.hasChanges)
        // A recovered untouched fit uses its opening day, not the date it is resumed.
        var fit = FitDraft(ownerID: owner)
        fit.initialDay = day; fit.value.day = day
        #expect(try JSONDecoder().decode(FitDraft.self, from: JSONEncoder().encode(fit)).hasChanges == false)
        fit.value.day = LocalPlanDay(year: 2026, month: 10, day: 18, timeZoneID: "Asia/Manila")
        #expect(fit.hasChanges)
        var wear = OutfitWearDraft(ownerID: owner, pieces: [], day: day)
        #expect(!wear.hasChanges)
        wear.day = LocalPlanDay(year: 2026, month: 10, day: 18, timeZoneID: "Asia/Manila")
        #expect(wear.hasChanges)
        wear.day = day
        #expect(try JSONDecoder().decode(OutfitWearDraft.self, from: JSONEncoder().encode(wear)).hasChanges == false)
    }

    @Test func localDayDoesNotShiftWithDeviceTimezoneAndRejectsNonexistentDates() throws {
        let value = LocalPlanDay(year: 2026, month: 3, day: 8, timeZoneID: "America/New_York")
        let encoded = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(LocalPlanDay.self, from: encoded).key == "2026-03-08")
        #expect(value.timeZoneID == "America/New_York")
        _ = try value.date()
        #expect(throws: PlanValidationError.invalidDay) { try LocalPlanDay(year: 2026, month: 2, day: 30, timeZoneID: "Asia/Manila").date() }
        #expect(throws: PlanValidationError.invalidTimezone) { try LocalPlanDay(year: 2026, month: 2, day: 1, timeZoneID: "Unknown/Zone").date() }
    }

    @Test func aPlanMayBeUnassignedButAReviewedAssignmentMustBeCurrentAndOwned() throws {
        let owner = UUID()
        var draft = OutfitPlanDraft(ownerID: owner)
        #expect(throws: PlanValidationError.invalidOutfit) { try draft.validatedForSave(outfits: []) }
        draft.unassignedByChoice = true
        try draft.validatedForSave(outfits: [])
        let outfit = Outfit(id: UUID(), ownerID: owner, name: "Weekend", pieceIDs: [UUID()])
        draft.outfit = outfit
        try draft.validatedForSave(outfits: [outfit])
        #expect(throws: PlanValidationError.invalidOutfit) { try draft.validatedForSave(outfits: []) }
        let other = Outfit(id: outfit.id, ownerID: UUID(), name: "Other owner", pieceIDs: outfit.pieceIDs)
        #expect(throws: PlanValidationError.invalidOutfit) { try draft.validatedForSave(outfits: [other]) }
    }
}
