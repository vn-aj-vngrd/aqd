import CoreImage
import Foundation
import ImageIO
import Vision

enum BackgroundPhotoError: Error { case unavailable, noForeground, invalidResult, staleSource }

/// A detected subject mask: gray pixels the size of the source image, white where the piece is.
struct DetectedMask: @unchecked Sendable { let image: CGImage }

/// One local Vision operation at a time. Cancellation abandons output, even if the synchronous
/// Vision calculation takes longer to return. This is Apple's on-device subject lift, the same
/// model Photos uses; there is no separate Apple Intelligence background-removal API to call.
actor PhotoBackgroundRemover {
    static let shared = PhotoBackgroundRemover()

    func detectMask(data: Data) throws -> DetectedMask {
        try Task.checkCancellation()
        return try autoreleasepool {
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(data: data, options: [:])
            try handler.perform([request])
            try Task.checkCancellation()
            guard let result = request.results?.first, !result.allInstances.isEmpty else { throw BackgroundPhotoError.noForeground }
            let buffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
            let mask = CIImage(cvPixelBuffer: buffer)
            guard let image = CutoutRenderer.context.createCGImage(mask, from: mask.extent, format: .RGBA8,
                                                                    colorSpace: CGColorSpace(name: CGColorSpace.sRGB)) else {
                throw BackgroundPhotoError.invalidResult
            }
            return DetectedMask(image: image)
        }
    }
}
