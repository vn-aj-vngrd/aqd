import CoreGraphics
import Foundation
import ImageIO
import Testing
import UIKit
@testable import AQD

struct PieceCutoutTests {
    private func redImage(_ size: Int = 40) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format).image { context in
            UIColor.red.setFill(); context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        }
        return image.pngData()!
    }

    private func decode(_ data: Data) throws -> CGImage {
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        return try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    }

    /// Alpha of the pixel at (x, y) counted from the top left.
    private func alpha(_ image: CGImage, _ x: Int, _ y: Int) -> UInt8 {
        var pixel = [UInt8](repeating: 0, count: 4)
        let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: -x, y: -(image.height - 1 - y), width: image.width, height: image.height))
        return pixel[3]
    }

    private func bandMask() throws -> CutoutMask {
        let mask = try #require(CutoutMask(width: 40, height: 40, keeping: false))
        mask.paint(from: CGPoint(x: 14, y: 20), to: CGPoint(x: 26, y: 20), radius: 6, keep: true)
        return mask
    }

    private func bandImage() throws -> CGImage {
        let mask = try bandMask()
        return try #require(mask.image)
    }

    @Test func brushErasesAndRestoresPixels() throws {
        let mask = try #require(CutoutMask(width: 40, height: 40))
        func coverage() throws -> Double { CutoutRenderer.coverage(of: try #require(mask.image)) }
        #expect(try coverage() > 0.99)
        mask.paint(from: CGPoint(x: 0, y: 20), to: CGPoint(x: 40, y: 20), radius: 10, keep: false)
        let erased = try coverage()
        #expect(erased < 0.6 && erased > 0.3)
        mask.paint(from: CGPoint(x: 0, y: 20), to: CGPoint(x: 40, y: 20), radius: 10, keep: true)
        #expect(try coverage() > 0.99)
    }

    @Test func keptBoundsFollowTheBrushWithATopLeftOrigin() throws {
        let band = try bandImage()
        let found = CutoutRenderer.keptBounds(of: band)
        let bounds = try #require(found)
        #expect(abs(bounds.minX - 8.0 / 40) < 0.06 && abs(bounds.maxX - 32.0 / 40) < 0.06)
        #expect(abs(bounds.minY - 14.0 / 40) < 0.06 && abs(bounds.maxY - 26.0 / 40) < 0.06)
        let blank = try #require(CutoutMask(width: 8, height: 8, keeping: false))
        let blankImage = try #require(blank.image)
        #expect(CutoutRenderer.keptBounds(of: blankImage) == nil)
    }

    @Test func trimRemovesEverythingOutsideTheRectangle() throws {
        let mask = try #require(CutoutMask(width: 40, height: 40))
        let trimmed = try #require(mask.trimmed(to: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)))
        let found = CutoutRenderer.keptBounds(of: trimmed)
        let bounds = try #require(found)
        #expect(abs(bounds.minX - 0.25) < 0.05 && abs(bounds.maxX - 0.75) < 0.05)
        #expect(abs(bounds.minY - 0.25) < 0.05 && abs(bounds.maxY - 0.75) < 0.05)
    }

    @Test func exportIsATransparentPNGAtTheOriginalSize() throws {
        let png = try CutoutRenderer.exportPNG(original: redImage(), mask: try bandImage(), fitPadding: nil)
        let image = try decode(png)
        #expect(image.width == 40 && image.height == 40)
        #expect(alpha(image, 1, 1) == 0, "background pixels are transparent")
        #expect(alpha(image, 20, 20) == 255, "the kept piece is opaque")
    }

    @Test func fitToPieceCropsToTheKeptArea() throws {
        let png = try CutoutRenderer.exportPNG(original: redImage(), mask: try bandImage(), fitPadding: 0)
        let image = try decode(png)
        #expect(image.width < 40 && image.height < 20 && image.width > image.height)
        #expect(alpha(image, image.width / 2, image.height / 2) == 255)
    }

    @Test func exportRefusesAnEmptyMask() throws {
        let blank = try #require(CutoutMask(width: 8, height: 8, keeping: false))
        let empty = try #require(blank.image)
        #expect(throws: CutoutError.self) { try CutoutRenderer.exportPNG(original: redImage(), mask: empty, fitPadding: nil) }
    }
}
