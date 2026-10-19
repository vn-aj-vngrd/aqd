import Foundation
import Testing
@testable import AQDCore

struct AgentSaveSummaryTests {
    private let owner = UUID()
    @Test func outfitAndThemeSummariesNameTheRecordAndCounts() throws {
        var outfit = OutfitDraft(ownerID: owner); outfit.name = "Office day"
        #expect(AgentReviewedAction.outfit(outfit).savesSummary == "Saves a new outfit “Office day” with 0 pieces.")
        var theme = ThemeDraft(ownerID: owner); theme.name = "Beach"; theme.outfitIDs = [UUID()]
        #expect(AgentReviewedAction.theme(theme).savesSummary == "Saves a new theme “Beach” with 1 outfit.")
    }
    @Test func profileListsOnlyTheFieldsThatChange() {
        var draft = LocalIdentityDraft(ownerID: owner); draft.name = "Van"
        #expect(AgentReviewedAction.profile(draft).savesSummary == "Updates your profile name.")
        draft.caption = "Slow style"
        #expect(AgentReviewedAction.profile(draft).savesSummary == "Updates your profile name and bio.")
    }
    @Test func availabilityAndWearSummariesAreExact() throws {
        let piece = WardrobePiece(id: UUID(), name: "Black blazer", category: .layers, photoID: UUID(), details: PieceDetails(), availability: .available)
        #expect(AgentReviewedAction.availability(AgentAvailabilityChange(piece: piece, value: .laundry)).savesSummary == "Marks “Black blazer” as laundry.")
        let day = LocalPlanDay(year: 2026, month: 10, day: 19, timeZoneID: "Asia/Manila")
        let wear = OutfitWearDraft(ownerID: owner, pieces: [piece], day: day)
        #expect(AgentReviewedAction.wear(wear).savesSummary.hasPrefix("Records that you wore 1 piece on "))
    }
}
