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

    /// SF Symbol a slot shows while its photo loads, is missing or fails to decode, so a slot is never blank.
    public static func placeholderSymbol(for category: PieceCategory) -> String {
        switch category {
        case .tops, .layers, .dresses: "tshirt"
        case .bottoms: "figure.walk"
        case .shoes: "shoeprints.fill"
        case .accessories: "eyeglasses"
        }
    }

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

public enum MannequinStep: CaseIterable, Sendable {
    case up, down, left, right, larger, smaller
}

public struct MannequinOffset: Equatable, Sendable {
    public var dx: Double, dy: Double
    public init(dx: Double = 0, dy: Double = 0) { self.dx = dx; self.dy = dy }
}

/// Transient, per-piece nudges while the mannequin is open: drag offset, pinch scale and accessories dropped
/// from the tray. Nothing here is persisted; a fresh value is the default placement.
public struct MannequinAdjustments: Equatable, Sendable {
    public static let moveStep = 0.03
    public static let scaleStep = 0.1
    public static let scaleRange = 0.5...2.0

    private var offsets: [UUID: MannequinOffset] = [:]
    private var scales: [UUID: Double] = [:]
    private var drops: [UUID: MannequinOffset] = [:]

    public init() {}

    public var isAdjusted: Bool { !(offsets.isEmpty && scales.isEmpty && drops.isEmpty) }

    public func offset(for id: UUID) -> MannequinOffset { offsets[id] ?? MannequinOffset() }
    public func scale(for id: UUID) -> Double { scales[id] ?? 1 }
    /// Centre of an accessory dropped on the figure, in unit coordinates; nil while it is in the tray.
    public func dropCentre(for id: UUID) -> MannequinOffset? { drops[id] }

    public mutating func drag(_ id: UUID, dx: Double, dy: Double) {
        let current = offset(for: id)
        offsets[id] = MannequinOffset(dx: min(1, max(-1, current.dx + dx)), dy: min(1, max(-1, current.dy + dy)))
    }

    public mutating func setScale(_ id: UUID, _ value: Double) {
        scales[id] = min(Self.scaleRange.upperBound, max(Self.scaleRange.lowerBound, value))
    }

    public mutating func drop(_ id: UUID, atX x: Double, y: Double) {
        drops[id] = MannequinOffset(dx: x, dy: y)
        offsets[id] = nil
    }

    public mutating func step(_ id: UUID, _ step: MannequinStep) {
        switch step {
        case .up: drag(id, dx: 0, dy: -Self.moveStep)
        case .down: drag(id, dx: 0, dy: Self.moveStep)
        case .left: drag(id, dx: -Self.moveStep, dy: 0)
        case .right: drag(id, dx: Self.moveStep, dy: 0)
        case .larger: setScale(id, scale(for: id) + Self.scaleStep)
        case .smaller: setScale(id, scale(for: id) - Self.scaleStep)
        }
    }

    public mutating func reset() { self = MannequinAdjustments() }
}

extension MannequinLayout {
    /// Size of an accessory once it sits on the figure, in unit coordinates.
    public static let droppedAccessorySize = MannequinFrame(x: 0, y: 0, width: 0.2, height: 0.12)

    /// Tray pieces still waiting in the tray, in outfit order.
    public func trayIDs(adjustments: MannequinAdjustments) -> [UUID] {
        tray.filter { adjustments.dropCentre(for: $0) == nil }
    }

    /// A piece's frame on the figure with the adjustments applied; nil while it is in the tray.
    public func frame(of id: UUID, adjustments: MannequinAdjustments) -> MannequinFrame? {
        guard let placement = placements.first(where: { $0.id == id }) else { return nil }
        let base: MannequinFrame
        if let frame = placement.frame {
            base = frame
        } else if let centre = adjustments.dropCentre(for: id) {
            let size = Self.droppedAccessorySize
            base = MannequinFrame(x: min(max(centre.dx - size.width / 2, 0), 1 - size.width),
                                  y: min(max(centre.dy - size.height / 2, 0), 1 - size.height),
                                  width: size.width, height: size.height)
        } else {
            return nil
        }
        let scale = adjustments.scale(for: id)
        let offset = adjustments.offset(for: id)
        let width = base.width * scale, height = base.height * scale
        return MannequinFrame(x: base.x + base.width / 2 - width / 2 + offset.dx,
                              y: base.y + base.height / 2 - height / 2 + offset.dy,
                              width: width, height: height)
    }
}
