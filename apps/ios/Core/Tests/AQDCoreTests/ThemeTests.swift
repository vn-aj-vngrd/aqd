import Foundation
import Testing
@testable import AQDCore

struct ThemeTests {
    @Test func emptyThemeAndIndependentMultipleMembershipsAreValid() throws {
        let owner = UUID(), outfitID = UUID()
        let outfit = Outfit(id: outfitID, ownerID: owner, name: "Look", pieceIDs: [UUID()])
        var first = ThemeDraft(ownerID: owner)
        first.name = "Weekend"
        try first.validatedForSave(themes: [], outfits: [])
        first.outfitIDs = [outfitID]
        var second = ThemeDraft(ownerID: owner)
        second.name = "Work"; second.outfitIDs = [outfitID]
        try first.validatedForSave(themes: [], outfits: [outfit])
        try second.validatedForSave(themes: [], outfits: [outfit])
        #expect(first.outfitIDs == second.outfitIDs)
    }

    @Test func namesAreTrimmedCaseInsensitiveAndMembershipMustBeOwned() throws {
        let owner = UUID()
        let existing = OutfitTheme(ownerID: owner, name: "Weekend")
        var draft = ThemeDraft(ownerID: owner)
        draft.name = "  WEEKEND  "
        #expect(throws: ThemeValidationError.duplicateName) { try draft.validatedForSave(themes: [existing], outfits: []) }
        draft.name = "Work"; draft.outfitIDs = [UUID()]
        #expect(throws: ThemeValidationError.invalidMembership) { try draft.validatedForSave(themes: [existing], outfits: []) }
        var edit = ThemeDraft(editing: existing)
        edit.name = " WEEKEND "
        try edit.validatedForSave(themes: [existing], outfits: [])
        #expect(edit.themeID == existing.id)
        #expect(edit.baseRevision == existing.revision)
    }
}
