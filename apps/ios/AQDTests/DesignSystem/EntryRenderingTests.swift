import UIKit
import XCTest
@testable import AQD

@MainActor
final class EntryRenderingTests: XCTestCase {
    func testNativeLaunchUsesIconArtworkOnWhiteInLightAndDark() throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let originalKeyWindow = scene.windows.first(where: \.isKeyWindow)
        for style in [UIUserInterfaceStyle.light, .dark] {
            let controller = try XCTUnwrap(UIStoryboard(name: "LaunchScreen", bundle: .main).instantiateInitialViewController())
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 440, height: 956)
            window.overrideUserInterfaceStyle = style
            window.rootViewController = controller
            window.makeKeyAndVisible()
            defer { window.isHidden = true; window.rootViewController = nil; originalKeyWindow?.makeKey() }
            controller.view.frame = window.bounds
            controller.view.setNeedsLayout(); controller.view.layoutIfNeeded()
            let wordmark = try XCTUnwrap(images(in: controller.view).first { $0.image != nil })
            XCTAssertEqual(wordmark.image?.cgImage?.width, 1024)
            XCTAssertEqual(wordmark.image?.cgImage?.height, 1024)
            XCTAssertEqual(wordmark.contentMode, .scaleAspectFit)
            XCTAssertEqual(wordmark.bounds.width, 144, accuracy: 1)
            XCTAssertEqual(wordmark.bounds.height, 144, accuracy: 1)
            let background = try XCTUnwrap(controller.view.backgroundColor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)))
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            XCTAssertTrue(background.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
            for component in [red, green, blue, alpha] { XCTAssertEqual(component, 1, accuracy: 0.001) }
            XCTAssertEqual(wordmark.center.x, controller.view.bounds.midX, accuracy: 1)
            XCTAssertEqual(wordmark.center.y, controller.view.bounds.midY, accuracy: 1)
            let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = "L172 native launch wordmark \(style == .light ? "light" : "dark")"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    private func images(in view: UIView) -> [UIImageView] {
        (view as? UIImageView).map { [$0] } ?? view.subviews.flatMap(images)
    }
}
