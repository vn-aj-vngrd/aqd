import AVFoundation
import ImageIO
import PhotosUI
import SwiftUI
import UIKit

actor MediaPreparation {
  /// Downsample before decoding so large phone photos do not fill memory at native size.
  func prepare(_ data: Data) throws -> Data {
    guard data.count <= 30 * 1024 * 1024,
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let image = CGImageSourceCreateThumbnailAtIndex(
        source, 0,
        [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceThumbnailMaxPixelSize: 1600,
          kCGImageSourceCreateThumbnailWithTransform: true,
        ] as CFDictionary),
      data.count > 0
    else { throw MediaError.invalidImage }
    let normalized = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(
        normalized, "public.jpeg" as CFString, 1, nil)
    else { throw MediaError.invalidImage }
    CGImageDestinationAddImage(
      destination, image, [kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary)
    guard CGImageDestinationFinalize(destination), normalized.length <= 5 * 1024 * 1024 else {
      throw MediaError.invalidImage
    }
    return normalized as Data
  }
}
enum MediaError: LocalizedError {
  case invalidImage
  var errorDescription: String? {
    "This photo couldn’t be prepared. Choose another or add the piece without a photo. Your details are kept."
  }
}

struct CameraCapture: UIViewControllerRepresentable {
  let choose: (Data?) -> Void
  func makeCoordinator() -> Coordinator { Coordinator(choose: choose) }
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = context.coordinator
    return picker
  }
  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
  final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate
  {
    let choose: (Data?) -> Void
    init(choose: @escaping (Data?) -> Void) { self.choose = choose }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { choose(nil) }
    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      choose((info[.originalImage] as? UIImage)?.jpegData(compressionQuality: 0.9))
    }
  }
}
