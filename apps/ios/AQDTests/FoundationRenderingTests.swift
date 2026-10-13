import SwiftUI
import UIKit
import XCTest
@testable import AQD

@MainActor
final class FoundationRenderingTests: XCTestCase {
    func testDisabledActionChangesToNeutralWithoutCallerOpacity() async throws {
        let host = UIHostingController(rootView: PrimaryAction(title: "Save piece") {}.disabled(false).ignoresSafeArea())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        try await Task.sleep(for: .milliseconds(100))
        let enabled = render(host.view)
        attach(enabled, "Primary enabled")
        host.rootView = PrimaryAction(title: "Save piece") {}.disabled(true).ignoresSafeArea()
        try await Task.sleep(for: .milliseconds(100))
        let disabled = render(host.view)
        attach(disabled, "Primary disabled")
        // Sample the solid capsule away from the label, spinner and rounded edge.
        // Independent DESIGN requirement: disabled controls stay neutral, not blue.
        XCTAssertGreaterThan(try bluePixels(enabled), 100, "Enabled action must render accent")
        XCTAssertLessThan(try bluePixels(disabled), 10, "Disabled primary must be neutral without caller-specific opacity")
    }

    func testLongActionsGrowAtLargestTextAndKeepFullWidthWhilePending() async throws {
        let title = "Save these changes to my private wardrobe on this device"
        let normal = UIHostingController(rootView: PrimaryAction(title: title) {})
        let large = UIHostingController(rootView: PrimaryAction(title: title) {}
            .environment(\.dynamicTypeSize, .accessibility5))
        let pending = UIHostingController(rootView: PrimaryAction(title: title, isPending: true) {}
            .environment(\.dynamicTypeSize, .accessibility5))
        let proposal = CGSize(width: 320, height: 2000)
        let ordinarySize = normal.sizeThatFits(in: proposal)
        let largeSize = large.sizeThatFits(in: proposal)
        let pendingSize = pending.sizeThatFits(in: proposal)
        XCTAssertEqual(largeSize.width, 320, accuracy: 0.5)
        XCTAssertEqual(pendingSize.width, 320, accuracy: 0.5)
        XCTAssertGreaterThan(largeSize.height, ordinarySize.height)
        XCTAssertGreaterThan(largeSize.height, 50)
        XCTAssertGreaterThanOrEqual(pendingSize.height, largeSize.height)
        try await capture(PrimaryAction(title: title, isPending: true) {}
            .environment(\.dynamicTypeSize, .accessibility5), name: "Long pending action largest text", width: 320)
    }

    func testContentActionKeepsPaperVerticalInsetsWhenTextGrows() {
        // Paper 165-0 / 167-0: 12-point vertical padding, independent of
        // section spacing. Large text must grow the control, not eat its insets.
        let proposal = CGSize(width: 320, height: 2000)
        let label = UIHostingController(rootView: Text("Save").font(.body.weight(.medium))
            .environment(\.dynamicTypeSize, .accessibility5))
        let textHeight = label.sizeThatFits(in: proposal).height
        let primary = UIHostingController(rootView: PrimaryAction(title: "Save") {}
            .environment(\.dynamicTypeSize, .accessibility5))
        let secondary = UIHostingController(rootView: SecondaryAction(title: "Save") {}
            .environment(\.dynamicTypeSize, .accessibility5))
        XCTAssertGreaterThanOrEqual(primary.sizeThatFits(in: proposal).height, textHeight + 24 - 0.5)
        XCTAssertGreaterThanOrEqual(secondary.sizeThatFits(in: proposal).height, textHeight + 24 - 0.5)
    }

    func testExpandedGroupedDisclosureKeepsEightPointVerticalInsets() {
        // components.md: standalone14pt, grouped8pt vertical; both14pt horizontal.
        // Force both real rows beyond their minimum so the insets are observable.
        let title = "Select the pieces for this private wardrobe outfit"
        let value = "A long selected value that must remain fully readable"
        let standalone = UIHostingController(rootView: DisclosureRow(title: title, value: value) {}
            .environment(\.dynamicTypeSize, .accessibility5))
        let grouped = UIHostingController(rootView: DisclosureRow(title: title, value: value, placement: .grouped) {}
            .environment(\.dynamicTypeSize, .accessibility5))
        let proposal = CGSize(width: 320, height: 4000)
        let standaloneSize = standalone.sizeThatFits(in: proposal)
        let groupedSize = grouped.sizeThatFits(in: proposal)
        XCTAssertGreaterThan(groupedSize.height, 54)
        XCTAssertEqual(groupedSize.width, 320, accuracy: 0.5)
        XCTAssertEqual(standaloneSize.width, groupedSize.width, accuracy: 0.5)
        XCTAssertEqual(standaloneSize.height - groupedSize.height, 12, accuracy: 0.5,
                       "Expanded grouped rows keep8pt at each vertical edge, not standalone14pt")
    }

    func testFieldsRowsAndFeedbackReflowWithoutShrinkingTargets() async throws {
        let normalField = UIHostingController(rootView: LabeledField(title: "Name", text: .constant("Private draft")))
        let largeField = UIHostingController(rootView: LabeledField(title: "Name of this private wardrobe piece",
            text: .constant("Private draft"), validation: "Use 80 characters or fewer for the piece name.", accessibilityID: "test.name")
            .environment(\.dynamicTypeSize, .accessibility5))
        let proposal = CGSize(width: 320, height: 2000)
        XCTAssertGreaterThanOrEqual(normalField.sizeThatFits(in: proposal).height, 52)
        XCTAssertGreaterThan(largeField.sizeThatFits(in: proposal).height, normalField.sizeThatFits(in: proposal).height)
        let row = UIHostingController(rootView: DisclosureRow(title: "Select the pieces for this outfit",
            value: "A very long selected value that must remain readable", placement: .grouped) {}
            .environment(\.dynamicTypeSize, .accessibility5))
        XCTAssertEqual(row.sizeThatFits(in: proposal).width, 320, accuracy: 0.5)
        XCTAssertGreaterThan(row.sizeThatFits(in: proposal).height, 54)
        try await capture(VStack(alignment: .leading, spacing: 24) {
            LabeledField(title: "Name", text: .constant("Retained input"), validation: "Enter a name, not only spaces.")
            DisclosureRow(title: "More details", value: "Selected private details") {}
            ActionStack {
                PrimaryAction(title: "Save changes") {}
                SecondaryAction(title: "Keep editing") {}
            }
            OperationProgress(title: "Preparing photo…")
            SemanticFeedback(role: .neutral, message: "Draft — Not saved", contained: true)
            SemanticFeedback(role: .information, message: "Saved offline guidance", contained: true)
            SemanticFeedback(role: .success, message: "Changes saved", contained: true)
            SemanticFeedback(role: .warning, message: "Save result unknown — check status before retry", contained: true)
            SemanticFeedback(role: .danger, message: "Couldn’t save — changes still here", contained: true)
        }.padding(20).background(AppTheme.canvas), name: "Shared states light")
        try await capture(VStack(alignment: .leading, spacing: 24) {
            LabeledField(title: "Name of this private wardrobe piece", text: .constant("Retained input"),
                         validation: "Use 80 characters or fewer for the piece name.")
            SurfaceGroup(["Color", "Material"], id: \.self) { title in
                DisclosureRow(title: title, value: "Retained selected value", placement: .grouped) {}
            }
            ActionStack {
                PrimaryAction(title: "Save these private changes on this device", isPending: true) {}
                SecondaryAction(title: "Keep editing this draft") {}
            }
            SemanticFeedback(role: .warning, message: "Save result unknown — check status before retry", contained: true)
        }.padding(20).background(AppTheme.canvas)
            .environment(\.dynamicTypeSize, .accessibility5), name: "Shared states dark largest text contrast", dark: true, width: 320, increasedContrast: true)
    }

    func testAllPaletteRolesMatchIndependentLightAndDarkDesignValues() {
        let roles: [(Color, UInt32, UInt32, CGFloat, CGFloat)] = [
            (AppTheme.canvas, 0xF5F5F7, 0x1C1C1E, 1, 1),
            (AppTheme.surface, 0xFFFFFF, 0x2C2C2E, 1, 1),
            (AppTheme.ink, 0x292C30, 0xF2F2F7, 1, 1),
            (AppTheme.secondary, 0x686C72, 0xB8B8BD, 1, 1),
            (AppTheme.divider, 0xE2E5E9, 0x48484A, 1, 1),
            (AppTheme.imageGround, 0xF0F0EE, 0x242426, 1, 1),
            (AppTheme.accent, 0x006FEE, 0x338EF7, 1, 1),
            (AppTheme.actionText, 0x005BC4, 0x66AAF9, 1, 1),
            (AppTheme.onAccent, 0xFFFFFF, 0x1C1C1E, 1, 1),
            (AppTheme.accentSoft, 0xE6F1FE, 0x142B47, 1, 1),
            (AppTheme.controlBoundary, 0x7B8088, 0x8E8E93, 1, 1),
            (AppTheme.regularGlass, 0xFFFFFF, 0x2C2C2E, 0.88, 0.94),
            (AppTheme.prominentGlass, 0x006FEE, 0x338EF7, 1, 1),
            (AppTheme.glassEdge, 0xFFFFFF, 0xFFFFFF, 0.70, 0.12),
            (AppTheme.segmentTrack, 0x767680, 0x767680, 0.10, 0.24),
            (AppTheme.controlShadow, 0x141416, 0x000000, 0.08, 0.22),
            (AppTheme.error, 0xD4142A, 0xFF6472, 1, 1),
            (AppTheme.dangerFill, 0xE02335, 0xFF6472, 1, 1),
            (AppTheme.errorSurface, 0xFFF0F2, 0x422027, 1, 1),
            (AppTheme.success, 0x416451, 0xB8D0BF, 1, 1),
            (AppTheme.successSurface, 0xE8EFEA, 0x293B30, 1, 1),
            (AppTheme.warning, 0x795B2E, 0xDCC7A2, 1, 1),
            (AppTheme.warningSurface, 0xF3EEE4, 0x403728, 1, 1),
            (AppTheme.information, 0x005BC4, 0x66AAF9, 1, 1),
            (AppTheme.informationSurface, 0xE6F1FE, 0x142B47, 1, 1)
        ]
        for (index, role) in roles.enumerated() {
            for dark in [false, true] {
                let expected = dark ? role.2 : role.1
                var environment = EnvironmentValues()
                environment.colorScheme = dark ? .dark : .light
                let resolved = role.0.resolve(in: environment)
                XCTAssertEqual(Double(resolved.red), Double((expected >> 16) & 255) / 255, accuracy: 0.002, "role \(index)")
                XCTAssertEqual(Double(resolved.green), Double((expected >> 8) & 255) / 255, accuracy: 0.002, "role \(index)")
                XCTAssertEqual(Double(resolved.blue), Double(expected & 255) / 255, accuracy: 0.002, "role \(index)")
                XCTAssertEqual(Double(resolved.opacity), Double(dark ? role.4 : role.3), accuracy: 0.002, "role \(index)")
            }
        }
    }

    func testAppearanceChoiceUsesNativeInheritanceAndSinglePalette() async throws {
        XCTAssertNil(AppAppearance.system.colorScheme)
        for appearance in AppAppearance.allCases {
            let host = UIHostingController(rootView: AppTheme.canvas.appAppearance(appearance))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.overrideUserInterfaceStyle = .dark
            window.rootViewController = host
            window.makeKeyAndVisible()
            try await Task.sleep(for: .milliseconds(100))
            XCTAssertEqual(host.traitCollection.userInterfaceStyle, appearance == .light ? .light : .dark)
            attach(render(host.view), "Appearance \(appearance.rawValue)")
            window.isHidden = true
        }
    }

    private func capture(_ content: some View, name: String, dark: Bool = false, width: CGFloat = 390, increasedContrast: Bool = false) async throws {
        let host = UIHostingController(rootView: content.ignoresSafeArea())
        host.overrideUserInterfaceStyle = dark ? .dark : .light
        host.traitOverrides.accessibilityContrast = increasedContrast ? .high : .normal
        let size = host.sizeThatFits(in: CGSize(width: width, height: 4000))
        let container = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: max(size.height, 844)))
        window.rootViewController = container
        window.makeKeyAndVisible()
        container.addChild(host)
        container.view.addSubview(host.view)
        host.view.frame = CGRect(origin: .zero, size: size)
        host.didMove(toParent: container)
        defer { window.isHidden = true }
        try await Task.sleep(for: .milliseconds(100))
        attach(render(host.view), name)
    }

    private func attach(_ image: UIImage, _ name: String) {
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func render(_ view: UIView) -> UIImage {
        view.layoutIfNeeded()
        return UIGraphicsImageRenderer(bounds: view.bounds).image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }

    private func bluePixels(_ image: UIImage) throws -> Int {
        let cg = try XCTUnwrap(image.cgImage)
        var pixels = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        let context = try XCTUnwrap(CGContext(data: &pixels, width: cg.width, height: cg.height, bitsPerComponent: 8,
            bytesPerRow: cg.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        return stride(from: 0, to: pixels.count, by: 4).filter { Int(pixels[$0 + 2]) - Int(pixels[$0]) > 80 }.count
    }
}
