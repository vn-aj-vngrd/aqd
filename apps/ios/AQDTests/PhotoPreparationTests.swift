import AQDCore
import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import AQD

struct PhotoPreparationTests {
    @Test func invalidMediaThrowsWithoutProducingAPhoto() async {
        let preparer = PhotoPreparer()
        do {
            _ = try await preparer.prepare(data: Data("not an image".utf8))
            Issue.record("Invalid media must not be accepted")
        } catch {
            #expect(error as? PhotoPreparationError == .invalidMedia)
        }
    }

    @Test(arguments: [1, 2, 3, 4, 5, 6, 7, 8])
    func keepsWholePixelExtentAndStripsPrivateMetadata(orientation: Int) async throws {
        let input = try fixture(orientation: orientation)
        let inputProperties = try properties(of: input)
        #expect(inputProperties[kCGImagePropertyGPSDictionary] != nil)
        let photo = try await PhotoPreparer().prepare(data: input)
        let rotated = orientation >= 5
        #expect(photo.pixelWidth == (rotated ? 400 : 640))
        #expect(photo.pixelHeight == (rotated ? 640 : 400))
        let original = try properties(of: photo.originalData)
        #expect((original[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue == photo.pixelWidth)
        #expect((original[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue == photo.pixelHeight)
        let thumbnail = try properties(of: photo.thumbnailData)
        #expect((thumbnail[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue == (rotated ? 200 : 320))
        #expect((thumbnail[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue == (rotated ? 320 : 200))
        for output in [original, thumbnail] {
            #expect(output[kCGImagePropertyGPSDictionary] == nil)
            let exif = output[kCGImagePropertyExifDictionary] as? [CFString: Any]
            #expect(exif?[kCGImagePropertyExifDateTimeOriginal] == nil)
            let orientation = (output[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
            #expect(orientation == 1)
        }
    }

    @Test func rejectsTruncatedAndUnsupportedMedia() async throws {
        let jpeg = try fixture(orientation: 1)
        for input in [Data(jpeg.prefix(jpeg.count / 2)), try fixture(orientation: 1, type: UTType.gif)] {
            do {
                _ = try await PhotoPreparer().prepare(data: input)
                Issue.record("Corrupt or unsupported media must not be accepted")
            } catch {
                let typed = error as? PhotoPreparationError
                #expect(typed == .invalidMedia || typed == .unsupportedMedia)
            }
        }
    }

    @Test func rejectsInputOverCompressedByteBudget() async {
        do {
            _ = try await PhotoPreparer().prepare(data: Data(count: 64 * 1_024 * 1_024 + 1))
            Issue.record("Oversized input must not be accepted")
        } catch {
            #expect(error as? PhotoPreparationError == .inputTooLarge)
        }
    }

    @Test func cancelledRenderDoesNotDecodeMedia() async {
        let preparer = PhotoPreparer()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await preparer.render(data: Data("invalid".utf8), sourcePhotoID: UUID(), recipe: .fit)
        }
        do {
            _ = try await task.value
            Issue.record("Cancelled editor jobs must not render")
        } catch {
            #expect(error is CancellationError)
        }
    }

    @Test func editFitRotationAndTopLeftCrop() async throws {
        let preparer = PhotoPreparer()
        let source = try await preparer.prepare(data: fixture(orientation: 1))
        let fit = try await preparer.render(data: source.originalData, sourcePhotoID: source.id, recipe: .fitOriginal)
        #expect(fit.pixelWidth == 640 && fit.pixelHeight == 400)
        let rotated = try await preparer.render(data: source.originalData, sourcePhotoID: source.id,
                                                recipe: PhotoEditRecipe(quarterTurns: 1))
        #expect(rotated.pixelWidth == 400 && rotated.pixelHeight == 640)
        // Original red left strip becomes the top strip after clockwise rotation.
        let top = try await preparer.render(data: source.originalData, sourcePhotoID: source.id,
            recipe: PhotoEditRecipe(quarterTurns: 1, crop: .init(x: 0, y: 0, width: 1, height: 0.2)))
        #expect(top.pixelWidth == 400 && top.pixelHeight == 128)
        let imageSource = try #require(CGImageSourceCreateWithData(top.renditionData as CFData, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(imageSource, 0, nil))
        let context = try #require(CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8,
            bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        let pixel = try #require(context.data).assumingMemoryBound(to: UInt8.self)
        #expect(pixel[0] > 200 && pixel[1] < 40)
        #expect(try properties(of: top.renditionData)[kCGImagePropertyGPSDictionary] == nil)
        #expect(top.sourcePhotoID == source.id)
    }

    @Test func transparentPixelsSurviveImportThumbnailRotationAndCrop() async throws {
        let preparer = PhotoPreparer()
        let photo = try await preparer.prepare(data: transparentFixture())
        try checkTransparency(photo.originalData); try checkTransparency(photo.thumbnailData)
        let edit = try await preparer.render(data: photo.originalData, sourcePhotoID: photo.id,
            recipe: PhotoEditRecipe(quarterTurns: 1, crop: .init(x: 0.1, y: 0.1, width: 0.8, height: 0.8)))
        try checkTransparency(edit.renditionData); try checkTransparency(edit.thumbnailData)
    }

    @Test @MainActor func transparentPieceAndEditedMediaSurviveExportAndRestore() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let preparer = PhotoPreparer()
        let photo = try await preparer.prepare(data: transparentFixture())
        _ = try store.acceptPhoto(photo)
        let recipe = PhotoEditRecipe(quarterTurns: 1)
        try store.acceptPhotoEdit(try await preparer.render(data: photo.originalData, sourcePhotoID: photo.id, recipe: recipe))
        let draft = PieceDraft(name: "Transparent piece", category: .tops, photoID: photo.id, photoRecipe: recipe)
        _ = try store.savePiece(draft, operationID: UUID())
        let data = try await LocalArchiveService.create(store: store).data
        #expect(data[11] == 2)
        let staged = try await LocalArchiveService.stage(LocalArchivePackage.decode(data))
        defer { try? FileManager.default.removeItem(at: staged.directory) }
        try checkTransparency(staged.store.originalPhoto(id: photo.id))
        try checkTransparency(staged.store.thumbnailPhoto(id: photo.id))
        try checkTransparency(staged.store.photoRendition(id: photo.id, recipe: recipe))
        try checkTransparency(staged.store.photoThumbnail(id: photo.id, recipe: recipe))
    }

    private func transparentFixture() throws -> Data {
        let context = try #require(CGContext(data: nil, width: 64, height: 64, bitsPerComponent: 8,
            bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.clear(CGRect(x: 0, y: 0, width: 64, height: 64))
        context.setFillColor(CGColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 16, y: 16, width: 32, height: 32))
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, try #require(context.makeImage()), [kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2026:10:07 12:00:00"]] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination)); return data as Data
    }
    private func checkTransparency(_ data: Data) throws {
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        #expect(CGImageSourceGetType(source) as String? == UTType.png.identifier)
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        #expect(properties[kCGImagePropertyGPSDictionary] == nil)
        #expect((properties[kCGImagePropertyExifDictionary] as? [CFString: Any])?[kCGImagePropertyExifDateTimeOriginal] == nil)
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let context = try #require(CGContext(data: nil, width: 64, height: 64, bitsPerComponent: 8,
            bytesPerRow: 256, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: 64, height: 64))
        let pixels = try #require(context.data).assumingMemoryBound(to: UInt8.self)
        #expect(pixels[3] == 0)
        #expect(pixels[(32 * 64 + 32) * 4 + 3] == 255)
    }

    private func properties(of data: Data) throws -> [CFString: Any] {
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        #expect(CGImageSourceGetType(source) as String? == UTType.jpeg.identifier)
        return try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
    }

    private func fixture(orientation: Int, type: UTType = .jpeg) throws -> Data {
        let context = try #require(CGContext(
            data: nil, width: 640, height: 400, bitsPerComponent: 8,
            bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0, green: 1, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 640, height: 400))
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 160, height: 400))
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, [
            kCGImagePropertyOrientation: orientation,
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 12.5,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 45.5,
                kCGImagePropertyGPSLongitudeRef: "E"
            ],
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2026:10:07 12:00:00"]
        ] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }
}
