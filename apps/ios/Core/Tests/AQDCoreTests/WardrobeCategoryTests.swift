import Foundation
import Testing
@testable import AQDCore

@Suite struct WardrobeCategoryTests {
    @Test func defaultsCoverEveryTypeAndCustomCategoriesKeepStableIdentity() throws {
        try WardrobeCategory.validate(WardrobeCategory.defaults)
        #expect(Set(WardrobeCategory.defaults.map(\.type)) == Set(PieceCategory.allCases))
        #expect(WardrobeCategory.defaults.first?.name == "Shirts")
        let custom = WardrobeCategory(name: "Work shirts", type: .tops)
        let restored = try JSONDecoder().decode(WardrobeCategory.self, from: JSONEncoder().encode(custom))
        #expect(restored == custom)
        #expect(throws: WardrobeCategoryError.self) { try WardrobeCategory.validate([custom, WardrobeCategory(name: "WORK SHIRTS", type: .layers)]) }
        #expect(throws: WardrobeCategoryError.self) { try WardrobeCategory.validate([]) }
    }
    @Test func categoryReferenceIsOptionalForLegacyDetailsAndSurvivesDraftRoundTrip() throws {
        var details = PieceDetails(color: "Blue")
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(details)) as? [String: Any])
        json.removeValue(forKey: "organizationCategoryID")
        let legacy = try JSONDecoder().decode(PieceDetails.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(legacy.organizationCategoryID == nil)
        details.organizationCategoryID = "shirts-work"
        let draft = PieceDraft(name: "Office shirt", category: .tops, details: details)
        #expect(try JSONDecoder().decode(PieceDraft.self, from: JSONEncoder().encode(draft)).details.organizationCategoryID == "shirts-work")
    }
}
