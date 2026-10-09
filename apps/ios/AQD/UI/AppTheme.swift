import SwiftUI
import UIKit

enum AppTheme {
    static let canvas = color(light: 0xF5F5F7, dark: 0x1C1C1E)
    static let surface = color(light: 0xFFFFFF, dark: 0x2C2C2E)
    static let ink = color(light: 0x292C30, dark: 0xF2F2F7)
    static let secondary = color(light: 0x686C72, dark: 0xB8B8BD)
    static let imageGround = color(light: 0xF0F0EE, dark: 0x242426)
    static let accent = color(light: 0x006FEE, dark: 0x338EF7)
    static let actionText = color(light: 0x005BC4, dark: 0x66AAF9)
    static let onAccent = color(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let divider = color(light: 0xE2E5E9, dark: 0x48484A)
    static let accentSoft = color(light: 0xE6F1FE, dark: 0x142B47)
    static let controlBoundary = color(light: 0x7B8088, dark: 0x8E8E93)
    static let error = color(light: 0xD4142A, dark: 0xFF6472)
    static let errorSurface = color(light: 0xFFF0F2, dark: 0x422027)
    static let dangerFill = color(light: 0xE02335, dark: 0xFF6472)
    static let success = color(light: 0x416451, dark: 0xB8D0BF)
    static let successSurface = color(light: 0xE8EFEA, dark: 0x293B30)
    static let warning = color(light: 0x795B2E, dark: 0xDCC7A2)
    static let warningSurface = color(light: 0xF3EEE4, dark: 0x403728)
    static let information = actionText
    static let informationSurface = accentSoft
    static let regularGlass = color(light: 0xFFFFFF, dark: 0x2C2C2E, lightAlpha: 0.88, darkAlpha: 0.94)
    static let prominentGlass = accent
    static let glassEdge = color(light: 0xFFFFFF, dark: 0xFFFFFF, lightAlpha: 0.70, darkAlpha: 0.12)
    static let segmentTrack = color(light: 0x767680, dark: 0x767680, lightAlpha: 0.10, darkAlpha: 0.24)
    static let controlShadow = color(light: 0x141416, dark: 0x000000, lightAlpha: 0.08, darkAlpha: 0.22)

    private static func color(light: UInt32, dark: UInt32, lightAlpha: Double = 1, darkAlpha: Double = 1) -> Color {
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((value >> 16) & 255) / 255,
                           green: CGFloat((value >> 8) & 255) / 255,
                           blue: CGFloat(value & 255) / 255,
                           alpha: traits.userInterfaceStyle == .dark ? darkAlpha : lightAlpha)
        })
    }
}

struct PrimaryAction: View {
    let title: String
    var isPending = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isPending { ProgressView().tint(AppTheme.onAccent) }
                Text(title).font(.body.weight(.medium))
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(AppTheme.onAccent)
            .background(AppTheme.accent, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct CaptureField: View {
    let title: String
    @Binding var text: String
    var multiline = false
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline).foregroundStyle(AppTheme.ink)
            TextField(title, text: $text, axis: multiline ? .vertical : .horizontal)
                .lineLimit(multiline ? 3...8 : 1...1)
                .textFieldStyle(.plain)
                .padding(14)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    if contrast == .increased {
                        RoundedRectangle(cornerRadius: 16).stroke(AppTheme.controlBoundary, lineWidth: 1)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityLabel(title)
                .accessibilityIdentifier("capture.field.\(title.lowercased())")
        }
    }
}
