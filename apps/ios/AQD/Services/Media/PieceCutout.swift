import AQDCore
import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum CutoutError: Error { case invalidImage, emptyResult, encodingFailed }

/// Editable keep/remove mask for a piece photo at a bounded working resolution.
/// 255 keeps a pixel and 0 removes it. Coordinates are mask pixels with the origin at the top left.
final class CutoutMask {
    let width: Int
    let height: Int
    private let context: CGContext

    init?(width: Int, height: Int, keeping: Bool = true) {
        guard width > 0, height > 0,
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                                      space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        self.width = width
        self.height = height
        self.context = context
        context.setShouldAntialias(true)
        context.interpolationQuality = .high
        fill(keeping: keeping)
    }

    var image: CGImage? { context.makeImage() }

    func fill(keeping: Bool) {
        context.setFillColor(gray: keeping ? 1 : 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }

    /// Replace the mask with `source`, scaled to this mask's size.
    func load(_ source: CGImage) {
        context.setFillColor(gray: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
    }

    /// Paint a round brush stroke between two points.
    func paint(from start: CGPoint, to end: CGPoint, radius: CGFloat, keep: Bool) {
        context.setStrokeColor(gray: keep ? 1 : 0, alpha: 1)
        context.setFillColor(gray: keep ? 1 : 0, alpha: 1)
        context.setLineWidth(max(1, radius * 2))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.move(to: CGPoint(x: start.x, y: CGFloat(height) - start.y))
        context.addLine(to: CGPoint(x: end.x, y: CGFloat(height) - end.y))
        context.strokePath()
    }

    /// A copy with everything outside `keep` (normalized, top-left origin) removed.
    func trimmed(to keep: CGRect) -> CGImage? {
        guard let copy = CutoutMask(width: width, height: height), let source = image else { return nil }
        copy.context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
        let rect = CGRect(x: keep.minX * CGFloat(width), y: (1 - keep.maxY) * CGFloat(height),
                          width: keep.width * CGFloat(width), height: keep.height * CGFloat(height))
        copy.context.setFillColor(gray: 0, alpha: 1)
        for outside in Self.outside(of: rect, in: CGRect(x: 0, y: 0, width: width, height: height)) { copy.context.fill(outside) }
        return copy.image
    }

    private static func outside(of inner: CGRect, in bounds: CGRect) -> [CGRect] {
        [CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: max(0, inner.minY - bounds.minY)),
         CGRect(x: bounds.minX, y: inner.maxY, width: bounds.width, height: max(0, bounds.maxY - inner.maxY)),
         CGRect(x: bounds.minX, y: inner.minY, width: max(0, inner.minX - bounds.minX), height: inner.height),
         CGRect(x: inner.maxX, y: inner.minY, width: max(0, bounds.maxX - inner.maxX), height: inner.height)]
    }
}

enum CutoutRenderer {
    static let context = CIContext(options: [.cacheIntermediates: false])
    private static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)

    /// `image` with pixels removed wherever `mask` is dark. Mask luminance becomes alpha, scaled to the image;
    /// `feather` softens the mask edge by that many mask pixels.
    static func composite(_ image: CIImage, mask: CGImage, feather: CGFloat = 0) -> CIImage {
        var raw = CIImage(cgImage: mask)
        if feather > 0 {
            raw = raw.clampedToExtent().applyingGaussianBlur(sigma: Double(feather)).cropped(to: CIImage(cgImage: mask).extent)
        }
        let scaled = raw.transformed(by: CGAffineTransform(scaleX: image.extent.width / raw.extent.width,
                                                           y: image.extent.height / raw.extent.height))
            .transformed(by: CGAffineTransform(translationX: image.extent.minX, y: image.extent.minY))
        let alpha = scaled.applyingFilter("CIMaskToAlpha")
        return image.applyingFilter("CIBlendWithAlphaMask", parameters: [kCIInputBackgroundImageKey: CIImage.empty(),
                                                                         kCIInputMaskImageKey: alpha])
            .cropped(to: image.extent)
    }

    /// Bounding box of the kept pixels (alpha above `threshold`), normalized with a top-left origin.
    static func keptBounds(of mask: CGImage, threshold: UInt8 = 24) -> CGRect? {
        let width = mask.width, height = mask.height
        var pixels = [UInt8](repeating: 0, count: width * height)
        guard let gray = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                                   space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        gray.draw(mask, in: CGRect(x: 0, y: 0, width: width, height: height))
        var minX = width, minY = height, maxX = -1, maxY = -1
        // The buffer is stored top row first.
        for y in 0..<height {
            let row = y * width
            for x in 0..<width where pixels[row + x] > threshold {
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }
        return CGRect(x: CGFloat(minX) / CGFloat(width), y: CGFloat(minY) / CGFloat(height),
                      width: CGFloat(maxX - minX + 1) / CGFloat(width), height: CGFloat(maxY - minY + 1) / CGFloat(height))
    }

    /// Fraction of pixels kept, 0...1.
    static func coverage(of mask: CGImage) -> Double {
        let width = mask.width, height = mask.height
        var pixels = [UInt8](repeating: 0, count: width * height)
        guard let gray = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                                   space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return 0 }
        gray.draw(mask, in: CGRect(x: 0, y: 0, width: width, height: height))
        return Double(pixels.reduce(0) { $0 + Int($1) }) / (255 * Double(pixels.count))
    }

    /// The kept box as a normalized rectangle (top-left origin), or nil when nothing is kept.
    static func normalizedBounds(of mask: CGImage) -> PhotoEditRecipe.NormalizedRect? {
        keptBounds(of: mask).map { .init(x: $0.minX, y: $0.minY, width: $0.width, height: $0.height) }
    }

    /// The alpha channel of `image` as a gray keep-mask the same size, so a saved cutout can be refined later.
    static func alphaMask(of image: CGImage) -> CGImage? {
        let width = image.width, height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(data: &bytes, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                                      space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width,
                       space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }

    /// Full-resolution PNG of `original` through `mask`, the same pixel size as the original so the crop stays a recipe.
    static func exportPNG(original: Data, mask: CGImage, background: CutoutBackground = .transparent, feather: CGFloat = 0) throws -> Data {
        guard let source = CGImageSourceCreateWithData(original as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else { throw CutoutError.invalidImage }
        guard keptBounds(of: mask) != nil else { throw CutoutError.emptyResult }
        var result = composite(CIImage(cgImage: cgImage), mask: mask, feather: feather)
        if let color = background.color {
            result = result.composited(over: CIImage(color: color).cropped(to: result.extent))
        }
        guard let output = context.createCGImage(result, from: result.extent, format: .RGBA8, colorSpace: colorSpace) else { throw CutoutError.encodingFailed }
        let bytes = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(bytes, UTType.png.identifier as CFString, 1, nil) else { throw CutoutError.encodingFailed }
        CGImageDestinationAddImage(destination, output, nil)
        guard CGImageDestinationFinalize(destination) else { throw CutoutError.encodingFailed }
        return bytes as Data
    }
}

/// What sits behind the piece in the saved photo.
enum CutoutBackground: String, CaseIterable {
    case transparent = "Transparent", white = "White", softGray = "Soft gray"

    var color: CIColor? {
        switch self {
        case .transparent: nil
        case .white: CIColor(red: 1, green: 1, blue: 1)
        case .softGray: CIColor(red: 0.94, green: 0.94, blue: 0.93)
        }
    }
}
