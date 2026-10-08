import Foundation

/// Coordinates describe the upright original after clockwise quarter-turns.
/// Nil crop means Fit: presentation padding is never baked into image pixels.
public struct PhotoEditRecipe: Codable, Equatable, Sendable {
    public struct NormalizedRect: Codable, Equatable, Sendable {
        public let x: Double
        public let y: Double
        public let width: Double
        public let height: Double

        public init(x: Double, y: Double, width: Double, height: Double) {
            self.x = x; self.y = y; self.width = width; self.height = height
        }
    }

    public enum ValidationError: Error, Equatable, Sendable { case invalidRecipe }
    public let quarterTurns: Int
    public let crop: NormalizedRect?
    public static let fit = PhotoEditRecipe()
    public static let fitOriginal = fit

    public init(quarterTurns: Int = 0, crop: NormalizedRect? = nil) {
        self.quarterTurns = quarterTurns
        self.crop = crop
    }

    public func validated() throws {
        guard (0...3).contains(quarterTurns) else { throw ValidationError.invalidRecipe }
        if let crop {
            guard [crop.x, crop.y, crop.width, crop.height].allSatisfy(\.isFinite),
                  crop.x >= 0, crop.y >= 0, crop.width > 0, crop.height > 0,
                  crop.width <= 1, crop.height <= 1,
                  crop.x + crop.width <= 1, crop.y + crop.height <= 1 else {
                throw ValidationError.invalidRecipe
            }
        }
    }

    /// Largest 3:4 rectangle inside the rotated image, reduced by zoom.
    /// Position is the fraction of available travel, not the image center.
    public static func portrait(originalWidth: Int, originalHeight: Int, quarterTurns: Int = 0,
                                zoom: Double = 1, positionX: Double = 0.5, positionY: Double = 0.5) throws -> Self {
        guard originalWidth > 0, originalHeight > 0, (0...3).contains(quarterTurns),
              zoom.isFinite, (1...8).contains(zoom),
              positionX.isFinite, positionY.isFinite,
              (0...1).contains(positionX), (0...1).contains(positionY) else {
            throw ValidationError.invalidRecipe
        }
        let w = Double(quarterTurns % 2 == 0 ? originalWidth : originalHeight)
        let h = Double(quarterTurns % 2 == 0 ? originalHeight : originalWidth)
        let cropW = min(w, h * 0.75) / zoom / w
        let cropH = min(h, w / 0.75) / zoom / h
        let result = Self(quarterTurns: quarterTurns, crop: .init(
            x: positionX * (1 - cropW), y: positionY * (1 - cropH), width: cropW, height: cropH))
        try result.validated()
        return result
    }
}

public typealias NormalizedPhotoCrop = PhotoEditRecipe.NormalizedRect
