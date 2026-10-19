import SwiftUI
import UIKit
import XCTest
@testable import AQD

@MainActor
final class FoundationRenderingTests: XCTestCase {
    func testDisabledActionChangesToNeutralWithoutCallerOpacity() async throws {
        let host = UIHostingController(rootView: PrimaryAction(title: "Save piece") {}.disabled(false).ignoresSafeArea()
            .environment(\.colorScheme, .light))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        try await Task.sleep(for: .milliseconds(100))
        let enabled = render(host.view)
        attach(enabled, "Primary enabled")
        host.rootView = PrimaryAction(title: "Save piece") {}.disabled(true).ignoresSafeArea()
            .environment(\.colorScheme, .light)
        try await Task.sleep(for: .milliseconds(100))
        let disabled = render(host.view)
        attach(disabled, "Primary disabled")
        // Sample the solid capsule away from the label, spinner and rounded edge.
        // Independent DESIGN requirement: disabled controls retain an opaque neutral fill.
        XCTAssertGreaterThan(try matchingPixels(enabled, rgb: 0x292826), 100, "Enabled primary uses the approved charcoal fill")
        XCTAssertLessThan(try matchingPixels(disabled, rgb: 0x292826), 10, "Disabled primary must use its neutral fill without caller opacity")
        XCTAssertGreaterThan(try matchingPixels(disabled, rgb: 0xE4E2DC), 100,
                             "Disabled controls use the approved opaque divider role")
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

    func testContainedFeedbackKeepsPaperFourteenPointVerticalInsets() {
        let proposal = CGSize(width: 320, height: 2000)
        let inline = UIHostingController(rootView: SemanticFeedback(role: .success, message: "Saved"))
        let contained = UIHostingController(rootView: SemanticFeedback(role: .success, message: "Saved", contained: true))
        XCTAssertEqual(contained.sizeThatFits(in: proposal).height - inline.sizeThatFits(in: proposal).height,
                       28, accuracy: 0.5, "Paper10SS-0 requires14pt at each vertical edge")
    }

    func testStandaloneAndGroupedDisclosuresKeepTheSamePaperRowGeometry() {
        // Paper582/588: disclosure rows54pt min,8pt vertical/14pt horizontal,
        // with12pt corners. The52pt/16-corner selection field is a different role.
        // Force both rows beyond their minimum so the insets are observable.
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
        XCTAssertEqual(standaloneSize.height, groupedSize.height, accuracy: 0.5,
                       "Standalone and grouped disclosures share8pt vertical insets; only the container changes")
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

    func testNativeMetadataPreservesRoleExposureLargestTextAndRTL() async throws {
        let text = "Selected photos are copied into AQD on this device. Originals stay in Photos."
        let normal = UIHostingController(rootView: MetadataText(text).background(AppTheme.canvas))
        let normalSize = normal.sizeThatFits(in: CGSize(width: 320, height: 4000))
        func content(scheme: ColorScheme) -> some View {
            MetadataText(text).background(AppTheme.canvas)
                .environment(\.dynamicTypeSize, .accessibility5)
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.colorScheme, scheme)
                .ignoresSafeArea()
        }
        let host = UIHostingController(rootView: content(scheme: .dark))
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive })
        let container = UIViewController()
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 320, height: 844)
        window.overrideUserInterfaceStyle = .dark
        window.rootViewController = container
        window.makeKeyAndVisible()
        container.addChild(host)
        container.view.addSubview(host.view)
        host.view.frame = window.bounds
        host.didMove(toParent: container)
        defer { window.isHidden = true; window.rootViewController = nil }
        host.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(100))
        // Fit only after mounting establishes scene traits and safe-area geometry.
        // The standalone rendering canvas has no navigation/status-bar inset.
        let largeSize = host.sizeThatFits(in: CGSize(width: 320, height: 4000))
        XCTAssertGreaterThan(largeSize.height, normalSize.height)
        XCTAssertLessThanOrEqual(largeSize.width, 320)
        host.view.frame = CGRect(x: 0, y: 0, width: 320, height: largeSize.height)
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(100))
        let image = render(host.view)
        attach(image, "Native metadata dark largest text RTL")
        XCTAssertGreaterThan(try matchingPixels(image, rgb: 0xBCB9B1), 100,
                             "The rendered caption must contain the independent dark secondary ink")
        let label = try XCTUnwrap(nativeLabel(in: host.view, text: text))
        let requiredSize = label.sizeThatFits(CGSize(width: label.bounds.width, height: .greatestFiniteMagnitude))
        let labelInHost = label.convert(label.bounds, to: host.view)
        let diagnostics = XCTAttachment(string: """
            font=\(String(describing: label.font))
            labelTraits=\(label.traitCollection)
            hostTraits=\(host.traitCollection)
            windowTraits=\(window.traitCollection)
            labelBounds=\(label.bounds) requiredAtActualWidth=\(requiredSize)
            labelInHost=\(labelInHost) hostBounds=\(host.view.bounds) hostFrame=\(host.view.frame)
            """)
        diagnostics.name = "Native metadata settled fit"
        diagnostics.lifetime = .keepAlways
        add(diagnostics)
        XCTAssertLessThanOrEqual(requiredSize.height, label.bounds.height + 1,
                                 "The settled label must fit the complete caption at its actual width")
        XCTAssertGreaterThanOrEqual(labelInHost.minX, host.view.bounds.minX - 1)
        XCTAssertGreaterThanOrEqual(labelInHost.minY, host.view.bounds.minY - 1)
        XCTAssertLessThanOrEqual(labelInHost.maxX, host.view.bounds.maxX + 1)
        XCTAssertLessThanOrEqual(labelInHost.maxY, host.view.bounds.maxY + 1)
        XCTAssertTrue(label.isAccessibilityElement, "Native metadata must remain exposed, not silence the audit")
        XCTAssertTrue(label.accessibilityTraits.contains(.staticText))
        XCTAssertEqual(label.text, text)
        XCTAssertEqual(label.textAlignment, .right)
        XCTAssertEqual(label.semanticContentAttribute, .forceRightToLeft)
        XCTAssertEqual(label.numberOfLines, 0)
        let expectedFont = UIFont.preferredFont(forTextStyle: .footnote,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge))
        XCTAssertEqual(label.font.pointSize, expectedFont.pointSize, accuracy: 0.1)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        XCTAssertTrue(label.textColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            .getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        XCTAssertEqual(red, 188.0 / 255, accuracy: 0.002)
        XCTAssertEqual(green, 185.0 / 255, accuracy: 0.002)
        XCTAssertEqual(blue, 177.0 / 255, accuracy: 0.002)
        XCTAssertEqual(alpha, 1, accuracy: 0.002)

        // Reconfigure the same hosted view through the public SwiftUI environment.
        // Reacquire the native label because an update may remount representables.
        for (index, scheme) in [ColorScheme.light, .dark, .light].enumerated() {
            host.rootView = content(scheme: scheme)
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(100))
            let updatedImage = render(host.view)
            let updatedLabel = try XCTUnwrap(nativeLabel(in: host.view, text: text))
            let style: UIUserInterfaceStyle = scheme == .dark ? .dark : .light
            let expected: UInt32 = scheme == .dark ? 0xBCB9B1 : 0x6A6863
            let inkPixels = try matchingPixels(updatedImage, rgb: expected)
            var updatedRed: CGFloat = 0, updatedGreen: CGFloat = 0
            var updatedBlue: CGFloat = 0, updatedAlpha: CGFloat = 0
            XCTAssertTrue(updatedLabel.textColor.getRed(&updatedRed, green: &updatedGreen,
                                                       blue: &updatedBlue, alpha: &updatedAlpha))
            XCTAssertEqual(updatedLabel.overrideUserInterfaceStyle, style)
            XCTAssertEqual(updatedLabel.traitCollection.userInterfaceStyle, style)
            XCTAssertEqual(updatedRed, CGFloat((expected >> 16) & 255) / 255, accuracy: 0.002)
            XCTAssertEqual(updatedGreen, CGFloat((expected >> 8) & 255) / 255, accuracy: 0.002)
            XCTAssertEqual(updatedBlue, CGFloat(expected & 255) / 255, accuracy: 0.002)
            XCTAssertEqual(updatedAlpha, 1, accuracy: 0.002)
            XCTAssertGreaterThan(inkPixels, 100, "Updated appearance must render its independent secondary ink")
            XCTAssertEqual(updatedLabel.font.pointSize, expectedFont.pointSize, accuracy: 0.1)
            XCTAssertEqual(updatedLabel.text, text)
            XCTAssertTrue(updatedLabel.isAccessibilityElement)
            XCTAssertTrue(updatedLabel.accessibilityTraits.contains(.staticText))
            XCTAssertEqual(updatedLabel.textAlignment, .right)
            XCTAssertEqual(updatedLabel.semanticContentAttribute, .forceRightToLeft)
            XCTAssertEqual(updatedLabel.numberOfLines, 0)
            let updatedRequiredSize = updatedLabel.sizeThatFits(
                CGSize(width: updatedLabel.bounds.width, height: .greatestFiniteMagnitude))
            let updatedInHost = updatedLabel.convert(updatedLabel.bounds, to: host.view)
            XCTAssertLessThanOrEqual(updatedRequiredSize.height, updatedLabel.bounds.height + 1)
            XCTAssertGreaterThanOrEqual(updatedInHost.minX, host.view.bounds.minX - 1)
            XCTAssertGreaterThanOrEqual(updatedInHost.minY, host.view.bounds.minY - 1)
            XCTAssertLessThanOrEqual(updatedInHost.maxX, host.view.bounds.maxX + 1)
            XCTAssertLessThanOrEqual(updatedInHost.maxY, host.view.bounds.maxY + 1)
            attach(updatedImage, "Native metadata update \(index) \(scheme) largest text RTL")
            let updateDiagnostics = XCTAttachment(string: """
                scheme=\(scheme) rgb=\(updatedRed),\(updatedGreen),\(updatedBlue) alpha=\(updatedAlpha)
                matchingInkPixels=\(inkPixels) expectedRGB=\(String(expected, radix: 16))
                font=\(String(describing: updatedLabel.font)) traits=\(updatedLabel.traitCollection)
                labelBounds=\(updatedLabel.bounds) requiredAtActualWidth=\(updatedRequiredSize)
                labelInHost=\(updatedInHost) hostBounds=\(host.view.bounds) hostFrame=\(host.view.frame)
                """)
            updateDiagnostics.name = "Native metadata appearance update \(index) \(scheme)"
            updateDiagnostics.lifetime = .keepAlways
            add(updateDiagnostics)
        }
    }

    func testAllPaletteRolesMatchIndependentLightAndDarkDesignValues() {
        let roles: [(Color, UInt32, UInt32, CGFloat, CGFloat)] = [
            (AppTheme.canvas, 0xF7F7F5, 0x1C1C1B, 1, 1),
            (AppTheme.surface, 0xFFFFFF, 0x2B2B29, 1, 1),
            (AppTheme.ink, 0x242321, 0xF3F1EB, 1, 1),
            (AppTheme.secondary, 0x6A6863, 0xBCB9B1, 1, 1),
            (AppTheme.divider, 0xE4E2DC, 0x4A4842, 1, 1),
            (AppTheme.imageGround, 0xF5F4F1, 0x242422, 1, 1),
            (AppTheme.accent, 0x8C6A36, 0xD3B47C, 1, 1),
            (AppTheme.onAccent, 0xFFFFFF, 0x1C1C1B, 1, 1),
            (AppTheme.primaryFill, 0x292826, 0xF2F0EB, 1, 1),
            (AppTheme.onPrimary, 0xFFFFFF, 0x242321, 1, 1),
            (AppTheme.segmentSelection, 0xECEBE7, 0x454545, 1, 1),
            (AppTheme.messageBubble, 0xF0EEEA, 0x3A3A37, 1, 1),
            (AppTheme.unreadIndicator, 0x2F6BFF, 0x6E9BFF, 1, 1),
            (AppTheme.controlBoundary, 0x807B72, 0x969187, 1, 1),
            (AppTheme.regularGlass, 0xFFFFFF, 0x2B2B29, 0.88, 0.94),
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
            (AppTheme.information, 0x6A6863, 0xBCB9B1, 1, 1),
            (AppTheme.informationSurface, 0xF5F4F1, 0x242422, 1, 1)
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

    private func nativeLabel(in view: UIView, text: String) -> UILabel? {
        if let label = view as? UILabel, label.text == text { return label }
        for child in view.subviews {
            if let label = nativeLabel(in: child, text: text) { return label }
        }
        return nil
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
        let format = UIGraphicsImageRendererFormat()
        // Compare SDR design literals without device-dependent HDR tone mapping.
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(bounds: view.bounds, format: format).image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }

    private func bluePixels(_ image: UIImage) throws -> Int {
        let pixels = try pixelBytes(image)
        return stride(from: 0, to: pixels.count, by: 4).filter { Int(pixels[$0 + 2]) - Int(pixels[$0]) > 80 }.count
    }

    private func matchingPixels(_ image: UIImage, rgb: UInt32) throws -> Int {
        let pixels = try pixelBytes(image)
        let expected = [Int((rgb >> 16) & 255), Int((rgb >> 8) & 255), Int(rgb & 255)]
        let matches = stride(from: 0, to: pixels.count, by: 4).filter { index in
            (0..<3).allSatisfy { abs(Int(pixels[index + $0]) - expected[$0]) <= 3 }
        }.count
        return matches
    }

    private func pixelBytes(_ image: UIImage) throws -> [UInt8] {
        let cg = try XCTUnwrap(image.cgImage)
        var pixels = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        // DESIGN literals are sRGB. Device RGB can use the physical display's
        // gamut, so normalize before comparing the same literal on every device.
        let colorSpace = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        try pixels.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: cg.width, height: cg.height,
                bitsPerComponent: 8, bytesPerRow: cg.width * 4, space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
            context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        }
        return pixels
    }
}
