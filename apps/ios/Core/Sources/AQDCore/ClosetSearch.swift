import Foundation

public enum ClosetSearchScope: String, CaseIterable, Hashable, Sendable { case pieces = "Pieces", outfits = "Outfits", themes = "Themes" }
public enum ClosetSearchResults: Equatable, Sendable {
    case pieces([WardrobePiece])
    case outfits([Outfit])
    case themes([OutfitTheme])
    public var count: Int {
        switch self { case .pieces(let values): values.count; case .outfits(let values): values.count; case .themes(let values): values.count }
    }
    public var isEmpty: Bool { count == 0 } // swiftlint:disable:this empty_count -- defines isEmpty for this enum
}
