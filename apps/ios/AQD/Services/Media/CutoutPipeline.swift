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
    /// The "fit to piece" framing, rendered so the saved photo has its crop rendition ready to display.
    var framed: PreparedPhotoEdit?
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
        let crop = fitToPiece ? bounds.map { PhotoQuality.paddedCrop($0, padding: 0.04) } : nil
        var framed: PreparedPhotoEdit?
        if let crop, case let recipe = PhotoEditRecipe(crop: crop), (try? recipe.validated()) != nil {
            framed = try await PhotoPreparer().render(data: png, sourcePhotoID: prepared.id, recipe: recipe)
        }
        return CutoutOutcome(prepared: prepared, crop: crop, hints: hints, framed: framed)
    }
}
