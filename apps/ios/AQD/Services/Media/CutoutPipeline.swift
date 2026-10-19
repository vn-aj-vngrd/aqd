import AQDCore
import CoreGraphics
import Foundation
import ImageIO

/// A finished cutout, ready to become the draft photo: the full-size derived photo, the non-destructive
/// "fit to piece" crop, and quality hints for the person.
struct CutoutOutcome: Sendable {
    let prepared: PreparedPhoto
    let crop: PhotoEditRecipe.NormalizedRect?
    let hints: [PhotoQualityHint]
}

enum CutoutPipeline {
    private struct Box: @unchecked Sendable { let mask: CGImage }

    /// Apply `mask` to the original at full resolution. The result keeps the original's pixel size.
    static func render(original: Data, mask: CGImage, background: CutoutBackground, feather: CGFloat, fitToPiece: Bool) async throws -> CutoutOutcome {
        let box = Box(mask: mask)
        let png = try await Task.detached(priority: .userInitiated) {
            try CutoutRenderer.exportPNG(original: original, mask: box.mask, background: background, feather: feather)
        }.value
        let prepared = try await PhotoPreparer().prepare(data: png)
        let bounds = CutoutRenderer.normalizedBounds(of: mask)
        let hints = PhotoQuality.assess(pixelWidth: prepared.pixelWidth, pixelHeight: prepared.pixelHeight, subjectFound: true,
                                        keptBounds: bounds, coverage: CutoutRenderer.coverage(of: mask))
        return CutoutOutcome(prepared: prepared, crop: fitToPiece ? bounds.map { PhotoQuality.paddedCrop($0, padding: 0.04) } : nil, hints: hints)
    }
}
