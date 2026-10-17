import SwiftUI
import UIKit

struct NativeCamera: UIViewControllerRepresentable {
    /// `.piece` lays a thirds grid and a frame over the live view so a flat-lay lands centered and fully in shot.
    enum Guide { case none, piece }
    var guide = Guide.none
    let onPhoto: (Data) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPhoto: onPhoto, onCancel: onCancel) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        if guide == .piece { picker.cameraOverlayView = PieceGuideOverlay(frame: picker.view.bounds) }
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onPhoto: (Data) -> Void
        let onCancel: () -> Void
        init(onPhoto: @escaping (Data) -> Void, onCancel: @escaping () -> Void) {
            self.onPhoto = onPhoto
            self.onCancel = onCancel
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { onCancel() }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let image = info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 1) else {
                onCancel()
                return
            }
            onPhoto(data)
        }
    }
}

/// Touch-transparent guide: thirds grid, a centered piece frame and one line of advice.
private final class PieceGuideOverlay: UIView {
    private let caption = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        caption.text = "Lay the piece flat and fill the frame"
        caption.font = .preferredFont(forTextStyle: .footnote)
        caption.textColor = .white
        caption.textAlignment = .center
        caption.isAccessibilityElement = false
        addSubview(caption)
    }

    @available(*, unavailable) required init?(coder: NSCoder) { nil }

    private var area: CGRect { bounds.insetBy(dx: 0, dy: bounds.height * 0.12) }

    override func layoutSubviews() {
        super.layoutSubviews()
        caption.frame = CGRect(x: 20, y: area.minY + 8, width: bounds.width - 40, height: 20)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let box = area
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.35).cgColor)
        context.setLineWidth(0.5)
        for step in 1...2 {
            let x = box.minX + box.width * CGFloat(step) / 3, y = box.minY + box.height * CGFloat(step) / 3
            context.move(to: CGPoint(x: x, y: box.minY)); context.addLine(to: CGPoint(x: x, y: box.maxY))
            context.move(to: CGPoint(x: box.minX, y: y)); context.addLine(to: CGPoint(x: box.maxX, y: y))
        }
        context.strokePath()
        let frame = box.insetBy(dx: box.width * 0.14, dy: box.height * 0.16)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.85).cgColor)
        context.setLineWidth(2)
        context.addPath(UIBezierPath(roundedRect: frame, cornerRadius: 12).cgPath)
        context.strokePath()
    }
}
