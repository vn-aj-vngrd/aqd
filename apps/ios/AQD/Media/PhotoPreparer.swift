import AQDCore
import CoreImage
import CryptoKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct PreparedPhoto: Sendable {
    let id: UUID
    /// Upright, metadata-minimized JPEG of the entire source pixel extent.
    let originalData: Data
    let thumbnailData: Data
    let pixelWidth: Int
    let pixelHeight: Int
}

struct PreparedPhotoEdit: Sendable {
    let renditionData: Data
    let thumbnailData: Data
    let pixelWidth: Int
    let pixelHeight: Int
    let sourcePhotoID: UUID
    let recipe: PhotoEditRecipe
    let recipeDigest: String
}

enum PhotoPreparationError: Error, Equatable, Sendable {
    case invalidMedia
    case unsupportedMedia
    case inputTooLarge
    case pixelLimitExceeded
    case encodingFailed
}

/// Local computation only. The store owns private files and draft replacement.
/// ImageIO/CoreGraphics handles never cross this actor's boundary.
actor PhotoPreparer {
    // Reject before decoding: 64 MiB compressed input, 40 million source pixels,
    // and 32,768 pixels per axis. A 40 MP 8-bit RGBA surface uses 160 MB;
    // higher-depth sources and ImageIO transform/codec buffers can use more.
    // This is a conservative input budget, not a measured peak-memory guarantee;
    // device profiling is required.
    // Calls on one preparer are serialized (no suspension during decoding).
    private static let maximumInputBytes = 64 * 1_024 * 1_024
    private static let maximumPixels = 40_000_000
    private static let maximumDimension = 32_768

    func prepare(data: Data) throws -> PreparedPhoto {
        guard data.count <= Self.maximumInputBytes else {
            throw PhotoPreparationError.inputTooLarge
        }
        return try autoreleasepool {
            guard !data.isEmpty,
                  let source = CGImageSourceCreateWithData(data as CFData, [
                    kCGImageSourceShouldCache: false
                  ] as CFDictionary),
                  CGImageSourceGetStatus(source) == .statusComplete,
                  CGImageSourceGetCount(source) > 0 else {
                throw PhotoPreparationError.invalidMedia
            }
            guard let type = CGImageSourceGetType(source) as String?,
                  [UTType.jpeg.identifier, UTType.png.identifier,
                   UTType.heic.identifier, UTType.heif.identifier].contains(type),
                  CGImageSourceGetCount(source) == 1 else {
                // Do not silently accept a frame of animated/multipage media.
                throw PhotoPreparationError.unsupportedMedia
            }
            // ImageIO can report complete and synthesize missing JPEG pixels
            // after a truncated scan. Require the JPEG end-of-image marker,
            // rather than accepting that decoder recovery as an original.
            if type == UTType.jpeg.identifier,
               !data.suffix(2).elementsEqual([0xFF, 0xD9]) {
                throw PhotoPreparationError.invalidMedia
            }
            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                    as? [CFString: Any],
                  let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
                  let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
                  width > 0, height > 0 else {
                throw PhotoPreparationError.invalidMedia
            }
            guard width <= Self.maximumDimension, height <= Self.maximumDimension,
                  width <= Self.maximumPixels / height else {
                throw PhotoPreparationError.pixelLimitExceeded
            }
            let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
            guard (1...8).contains(orientation) else {
                throw PhotoPreparationError.invalidMedia
            }
            let swapsAxes = (5...8).contains(orientation)
            let expectedWidth = swapsAxes ? height : width
            let expectedHeight = swapsAxes ? width : height
            // ImageIO applies all eight EXIF rotations/reflections. Setting the
            // limit to the full source extent means no intentional downsampling.
            guard let upright = transformedImage(source: source, maximumSize: max(width, height)),
                  upright.width == expectedWidth, upright.height == expectedHeight,
                  CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else {
                // Never substitute a silently reduced/cropped original.
                throw PhotoPreparationError.invalidMedia
            }
            try Task.checkCancellation()
            let original = try jpegData(image: upright)
            try Task.checkCancellation()
            guard let thumbnail = transformedImage(source: source, maximumSize: min(320, max(width, height))) else {
                throw PhotoPreparationError.invalidMedia
            }
            return PreparedPhoto(
                id: UUID(), originalData: original,
                thumbnailData: try jpegData(image: thumbnail),
                pixelWidth: upright.width, pixelHeight: upright.height
            )
        }
    }

    nonisolated static func recipeDigest(_ recipe: PhotoEditRecipe) throws -> String {
        try recipe.validated()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return SHA256.hash(data: try encoder.encode(recipe)).map { String(format: "%02x", $0) }.joined()
    }

    func render(data: Data, sourcePhotoID: UUID, recipe: PhotoEditRecipe) throws -> PreparedPhotoEdit {
        try Task.checkCancellation()
        try recipe.validated()
        // Reuse import validation and budgets; source bytes are never modified.
        let normalized = try prepare(data: data)
        try Task.checkCancellation()
        return try autoreleasepool {
            guard let source = CGImageSourceCreateWithData(normalized.originalData as CFData, nil),
                  let original = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw PhotoPreparationError.invalidMedia
            }
            let orientations: [CGImagePropertyOrientation] = [.up, .right, .down, .left]
            var image = CIImage(cgImage: original).oriented(orientations[recipe.quarterTurns])
            let extent = image.extent
            image = image.transformed(by: CGAffineTransform(translationX: -extent.minX, y: -extent.minY))
            let w = image.extent.width, h = image.extent.height
            if let crop = recipe.crop {
                // Quantize inward to whole pixels and keep at least one pixel for tiny crops.
                let x = min(w - 1, floor(crop.x * w)), top = min(h - 1, floor(crop.y * h))
                let width = min(w - x, max(1, floor(crop.width * w)))
                let height = min(h - top, max(1, floor(crop.height * h)))
                image = image.cropped(to: CGRect(x: x, y: h - top - height, width: width, height: height))
            }
            try Task.checkCancellation()
            guard let pixels = CIContext(options: [.cacheIntermediates: false]).createCGImage(image, from: image.extent) else {
                throw PhotoPreparationError.encodingFailed
            }
            let rendition = try jpegData(image: pixels)
            try Task.checkCancellation()
            guard let output = CGImageSourceCreateWithData(rendition as CFData, nil),
                  let thumbnail = transformedImage(source: output, maximumSize: min(320, max(pixels.width, pixels.height))) else {
                throw PhotoPreparationError.encodingFailed
            }
            return PreparedPhotoEdit(renditionData: rendition, thumbnailData: try jpegData(image: thumbnail),
                pixelWidth: pixels.width, pixelHeight: pixels.height, sourcePhotoID: sourcePhotoID,
                recipe: recipe, recipeDigest: try Self.recipeDigest(recipe))
        }
    }

    private func transformedImage(source: CGImageSource, maximumSize: Int) -> CGImage? {
        CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumSize,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceShouldAllowFloat: false
        ] as CFDictionary)
    }

    private func jpegData(image: CGImage) throws -> Data {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output, UTType.jpeg.identifier as CFString, 1, nil
        ) else {
            throw PhotoPreparationError.encodingFailed
        }
        // Encode pixels into a fresh destination, never copy source metadata.
        // ImageIO retains useful image color information; EXIF/GPS, capture
        // timestamps, device identifiers and source thumbnails are not copied.
        CGImageDestinationAddImage(destination, image, [
            kCGImageDestinationLossyCompressionQuality: 0.95,
            kCGImagePropertyOrientation: 1
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw PhotoPreparationError.encodingFailed
        }
        return output as Data
    }
}
