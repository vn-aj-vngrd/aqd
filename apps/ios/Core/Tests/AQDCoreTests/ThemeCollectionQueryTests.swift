import Foundation
import Testing
@testable import AQDCore

struct ThemeCollectionQueryTests {
    private let owner = UUID()
    @Test func contentFiltersPartitionThemesWithoutChangingMembership() {
        let empty = OutfitTheme(ownerID: owner, name: "Empty")
        let populated = OutfitTheme(ownerID: owner, name: "Weekends", outfitIDs: [UUID(), UUID()])
        let themes = [populated, empty]
        #expect(ThemeCollectionQuery(content: .empty).apply(to: themes) == [empty])
        #expect(ThemeCollectionQuery(content: .withOutfits).apply(to: themes) == [populated])
        #expect(ThemeCollectionQuery().apply(to: themes) == [empty, populated])
        #expect(populated.outfitIDs.count == 2)
    }
    @Test func sortingUsesMembershipCountsAndStableNameOrderForTies() {
        let a = OutfitTheme(ownerID: owner, name: "Alpha", outfitIDs: [UUID()])
        let b = OutfitTheme(ownerID: owner, name: "Beta", outfitIDs: [UUID()])
        let c = OutfitTheme(ownerID: owner, name: "Weekend", outfitIDs: [UUID(), UUID()])
        #expect(ThemeCollectionQuery(sort: .nameDescending).apply(to: [a, c, b]) == [c, b, a])
        #expect(ThemeCollectionQuery(sort: .mostOutfits).apply(to: [b, a, c]) == [c, a, b])
        #expect(ThemeCollectionQuery(content: .empty, sort: .mostOutfits).apply(to: [a, b, c]).isEmpty)
    }
}
