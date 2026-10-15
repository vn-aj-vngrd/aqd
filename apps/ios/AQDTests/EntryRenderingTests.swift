import UIKit
import XCTest
@testable import AQD

@MainActor
final class EntryRenderingTests: XCTestCase {
    func testNativeLaunchWordmarkMatchesPaperInLightAndDark() throws {
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
            let wordmark = try XCTUnwrap(labels(in: controller.view).first { $0.text == "AQD" })
            XCTAssertEqual(wordmark.font.pointSize, 44)
            XCTAssertEqual(wordmark.center.x, controller.view.bounds.midX, accuracy: 1)
            XCTAssertEqual(wordmark.center.y, controller.view.bounds.midY, accuracy: 1)
            XCTAssertGreaterThanOrEqual(wordmark.bounds.height, wordmark.font.lineHeight)
            let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = "L172 native launch wordmark \(style == .light ? "light" : "dark")"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    private func labels(in view: UIView) -> [UILabel] {
        (view as? UILabel).map { [$0] } ?? view.subviews.flatMap(labels)
    }
}
