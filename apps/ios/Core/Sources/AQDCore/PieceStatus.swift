import Foundation

/// One name and symbol for where a piece stands, so every screen words it the same way.
public enum PieceStatus: Equatable, Sendable {
    case available, unavailable, laundry, archived

    public init(_ piece: WardrobePiece) {
        if piece.isArchived { self = .archived; return }
        switch piece.availability {
        case .available: self = .available
        case .unavailable: self = .unavailable
        case .laundry: self = .laundry
        }
    }

    public var title: String {
        switch self {
        case .available: "Available"
        case .unavailable: "Unavailable"
        case .laundry: "In the laundry"
        case .archived: "Archived"
        }
    }

    public var symbol: String {
        switch self {
        case .available: "checkmark.circle"
        case .unavailable: "xmark.circle"
        case .laundry: "washer"
        case .archived: "archivebox"
        }
    }

    /// Only a piece that needs attention earns a mark on its grid card.
    public var isNotable: Bool { self != .available }

    /// The availability a quick laundry toggle moves a piece to.
    public static func laundryToggle(from availability: PieceAvailability) -> PieceAvailability {
        availability == .laundry ? .available : .laundry
    }
}
