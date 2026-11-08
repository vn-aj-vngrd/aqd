import Foundation

/// Where a piece sits on the 2D mannequin.
public enum MannequinSlot: Equatable, Sendable {
    case torso, legs, feet, tray

    /// Slot for a category; accessories wait in the tray beside the figure.
    public static func slot(for category: PieceCategory) -> MannequinSlot {
        switch category {
        case .tops, .layers: .torso
        case .bottoms: .legs
        case .dresses: .torso
        case .shoes: .feet
        case .accessories: .tray
        }
    }
}

/// A rectangle in unit coordinates of the figure canvas: x and y from the top-left, 0...1 on both axes.
public struct MannequinFrame: Equatable, Sendable {
    public let x: Double, y: Double, width: Double, height: Double
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
}

public struct MannequinPlacement: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let category: PieceCategory
    public let slot: MannequinSlot
    /// Nil for tray pieces, which have no spot on the figure.
    public let frame: MannequinFrame?
    /// Back-to-front position among all placements: a higher value is drawn in front.
    public let zIndex: Int
}

public struct MannequinLayout: Equatable, Sendable {
    public let placements: [MannequinPlacement]

    /// Piece IDs of the accessory tray, in outfit order.
    public var tray: [UUID] { placements.filter { $0.slot == .tray }.map(\.id) }
    /// Piece IDs of every placement from back to front.
    public var drawOrder: [UUID] { placements.sorted { $0.zIndex < $1.zIndex }.map(\.id) }

    /// Back-to-front order: bottoms, dresses, tops, layers, then shoes at the feet.
    private static func rank(_ category: PieceCategory) -> Int {
        switch category {
        case .bottoms: 0
        case .dresses: 1
        case .tops: 2
        case .layers: 3
        case .shoes: 4
        case .accessories: 5
        }
    }

    private static func frame(for category: PieceCategory) -> MannequinFrame? {
        switch category {
        case .tops: MannequinFrame(x: 0.22, y: 0.15, width: 0.56, height: 0.34)
        case .layers: MannequinFrame(x: 0.18, y: 0.14, width: 0.64, height: 0.38)
        case .dresses: MannequinFrame(x: 0.22, y: 0.15, width: 0.56, height: 0.60)
        case .bottoms: MannequinFrame(x: 0.26, y: 0.46, width: 0.48, height: 0.42)
        case .shoes: MannequinFrame(x: 0.20, y: 0.89, width: 0.60, height: 0.11)
        case .accessories: nil
        }
    }

    /// Places ordered pieces; equal ranks keep outfit order with the later piece in front.
    public static func place(_ pieces: [(UUID, PieceCategory)]) -> MannequinLayout {
        let ordered = pieces.enumerated().sorted { (rank($0.element.1), $0.offset) < (rank($1.element.1), $1.offset) }
        let placements = ordered.enumerated().map { z, entry in
            MannequinPlacement(id: entry.element.0, category: entry.element.1, slot: .slot(for: entry.element.1),
                               frame: frame(for: entry.element.1), zIndex: z)
        }
        // The tray keeps outfit order, which the sort above preserves within the accessories rank.
        return MannequinLayout(placements: placements)
    }
}
