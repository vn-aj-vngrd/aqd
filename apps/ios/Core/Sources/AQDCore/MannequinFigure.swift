import Foundation

/// A horizontal landmark of the figure: its height down the canvas and half its width, in unit coordinates.
public struct MannequinBand: Codable, Equatable, Sendable {
    public let y: Double
    public let halfWidth: Double
    public init(y: Double, halfWidth: Double) { self.y = y; self.halfWidth = halfWidth }
}

/// Body landmarks of one figure artwork in unit coordinates of its canvas (x and y from the top-left, 0...1).
/// Pieces are fitted to these, so new art with new anchors moves every fit with no code change.
public struct MannequinAnchors: Codable, Equatable, Sendable {
    public let shoulderY: Double
    public let shoulderLeftX: Double
    public let shoulderRightX: Double
    public let chest: MannequinBand
    public let waist: MannequinBand
    public let hips: MannequinBand
    public let knees: MannequinBand
    public let ankles: MannequinBand
    public let feet: MannequinBand

    public init(shoulderY: Double, shoulderLeftX: Double, shoulderRightX: Double, chest: MannequinBand,
                waist: MannequinBand, hips: MannequinBand, knees: MannequinBand, ankles: MannequinBand,
                feet: MannequinBand) {
        self.shoulderY = shoulderY; self.shoulderLeftX = shoulderLeftX; self.shoulderRightX = shoulderRightX
        self.chest = chest; self.waist = waist; self.hips = hips
        self.knees = knees; self.ankles = ankles; self.feet = feet
    }

    /// Horizontal centre line of the figure.
    public var centreX: Double { (shoulderLeftX + shoulderRightX) / 2 }

    /// Built-in fallback matching the shipped standard art; used when the manifest cannot be read.
    public static let standard = MannequinAnchors(
        shoulderY: 0.16, shoulderLeftX: 0.312, shoulderRightX: 0.688,
        chest: MannequinBand(y: 0.25, halfWidth: 0.146),
        waist: MannequinBand(y: 0.35, halfWidth: 0.108),
        hips: MannequinBand(y: 0.47, halfWidth: 0.166),
        knees: MannequinBand(y: 0.69, halfWidth: 0.13),
        ankles: MannequinBand(y: 0.905, halfWidth: 0.1),
        feet: MannequinBand(y: 0.975, halfWidth: 0.145))

    /// Landmarks run down the canvas in order and stay inside it.
    var isValid: Bool {
        let ys = [shoulderY, chest.y, waist.y, hips.y, knees.y, ankles.y, feet.y]
        let bands = [chest, waist, hips, knees, ankles, feet]
        let ordered = zip(ys, ys.dropFirst()).allSatisfy { $0 < $1 }
        let inside = ys.allSatisfy { (0...1).contains($0) }
            && (0...1).contains(shoulderLeftX) && (0...1).contains(shoulderRightX)
            && shoulderLeftX < shoulderRightX
            && bands.allSatisfy { $0.halfWidth > 0 && $0.halfWidth <= 0.5 }
        return ordered && inside
    }
}

/// One figure artwork: the asset it is drawn from, its width over height, and where the body landmarks are.
public struct MannequinFigureVariant: Codable, Equatable, Sendable {
    public let id: String
    public let imageName: String
    public let aspectRatio: Double
    public let anchors: MannequinAnchors
    public init(id: String, imageName: String, aspectRatio: Double, anchors: MannequinAnchors) {
        self.id = id; self.imageName = imageName; self.aspectRatio = aspectRatio; self.anchors = anchors
    }

    /// The standard figure with the built-in anchors.
    public static let standard = MannequinFigureVariant(
        id: "standard", imageName: "mannequin-standard", aspectRatio: 0.5, anchors: .standard)
}

public enum MannequinManifestError: Error, Equatable, Sendable {
    case malformed
    case empty
    case invalidVariant(String)
}

/// The bundled list of figure variants, decoded from JSON.
public struct MannequinFigureManifest: Codable, Equatable, Sendable {
    public let variants: [MannequinFigureVariant]

    /// Decodes and validates a manifest; a malformed, empty or inconsistent one throws so the caller falls back.
    public static func decode(_ data: Data) throws(MannequinManifestError) -> MannequinFigureManifest {
        let manifest: MannequinFigureManifest
        do {
            manifest = try JSONDecoder().decode(MannequinFigureManifest.self, from: data)
        } catch {
            throw .malformed
        }
        guard !manifest.variants.isEmpty else { throw .empty }
        for variant in manifest.variants where variant.aspectRatio <= 0 || !variant.anchors.isValid {
            throw .invalidVariant(variant.id)
        }
        return manifest
    }

    /// The variant with this id, or the first one when it is unknown.
    public func variant(id: String) -> MannequinFigureVariant {
        variants.first { $0.id == id } ?? variants[0]
    }

    /// The manifest to use: the decoded one, or the built-in standard figure when decoding fails.
    public static func decodedOrStandard(_ data: Data?) -> MannequinFigureManifest {
        guard let data, let manifest = try? decode(data) else {
            return MannequinFigureManifest(variants: [.standard])
        }
        return manifest
    }
}
