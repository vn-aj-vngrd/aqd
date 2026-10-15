import Foundation
import Testing
@testable import AQDCore

struct OutfitPlanTests {
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
