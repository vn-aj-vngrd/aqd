import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers
import Vision

/// Issue30 owns garment-quality, latency and memory qualification before activation.
enum BackgroundRemovalQualification { static let enabled = false }

enum BackgroundPhotoError: Error { case unavailable, noForeground, invalidResult, staleSource }

/// One local Vision operation at a time. Cancellation abandons output, even if
/// the synchronous Vision calculation takes longer to return.
actor PhotoBackgroundRemover {
    static let shared = PhotoBackgroundRemover()
    func remove(data: Data) async throws -> PreparedPhoto {
        try Task.checkCancellation()
        let encoded: Data = try autoreleasepool {
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(data: data, options: [:])
            try handler.perform([request]); try Task.checkCancellation()
            guard let result = request.results?.first, !result.allInstances.isEmpty else { throw BackgroundPhotoError.noForeground }
            let buffer = try result.generateMaskedImage(ofInstances: result.allInstances, from: handler, croppedToInstancesExtent: false)
            let cutout = CIImage(cvPixelBuffer: buffer)
            let ground = CIImage(color: CIColor(red: 0.94, green: 0.94, blue: 0.93)).cropped(to: cutout.extent)
            let fullExtent = cutout.composited(over: ground)
            let context = CIContext(options: [.cacheIntermediates: false])
            guard let image = context.createCGImage(fullExtent, from: fullExtent.extent) else { throw BackgroundPhotoError.invalidResult }
            let bytes = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(bytes, UTType.jpeg.identifier as CFString, 1, nil) else { throw BackgroundPhotoError.invalidResult }
            CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.95] as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { throw BackgroundPhotoError.invalidResult }
            return bytes as Data
        }
        try Task.checkCancellation()
        return try await PhotoPreparer().prepare(data: encoded)
    }
}
