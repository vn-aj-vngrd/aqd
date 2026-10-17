import Foundation

/// Local presentation options shared by theme browsing and query-matched search.
public struct ThemeCollectionQuery: Hashable, Sendable {
    public enum Content: String, CaseIterable, Sendable {
        case all = "All themes", withOutfits = "With outfits", empty = "Empty themes"
    }
    public enum Sort: String, CaseIterable, Sendable {
        case nameAscending = "Name A–Z", nameDescending = "Name Z–A", mostOutfits = "Most outfits"
    }
    public var content: Content
    public var sort: Sort
    public init(content: Content = .all, sort: Sort = .nameAscending) {
        self.content = content; self.sort = sort
    }
    public func apply(to themes: [OutfitTheme]) -> [OutfitTheme] {
        themes.filter {
            switch content {
            case .all: true
            case .withOutfits: !$0.outfitIDs.isEmpty
            case .empty: $0.outfitIDs.isEmpty
            }
        }.sorted {
            if sort == .mostOutfits, $0.outfitIDs.count != $1.outfitIDs.count {
                return $0.outfitIDs.count > $1.outfitIDs.count
            }
            let order = $0.name.localizedStandardCompare($1.name)
            if order == .orderedSame { return $0.id.uuidString < $1.id.uuidString }
            return sort == .nameDescending ? order == .orderedDescending : order == .orderedAscending
        }
    }
}
