import SwiftUI
import UIKit

enum AppTheme {
    static let canvas = color(light: 0xF7F7F5, dark: 0x1C1C1B)
    static let surface = color(light: 0xFFFFFF, dark: 0x2B2B29)
    static let ink = color(light: 0x242321, dark: 0xF3F1EB)
    static let secondary = color(light: 0x6A6863, dark: 0xBCB9B1)
    static let imageGround = color(light: 0xF5F4F1, dark: 0x242422)
    static let accent = color(light: 0x8C6A36, dark: 0xD3B47C)
    static let actionText = color(light: 0x765829, dark: 0xD9BD8A)
    static let onAccent = color(light: 0xFFFFFF, dark: 0x1C1C1B)
    static let primaryFill = color(light: 0x292826, dark: 0xF2F0EB)
    static let onPrimary = color(light: 0xFFFFFF, dark: 0x242321)
    static let segmentSelection = color(light: 0xEBE7DF, dark: 0x454036)
    static let divider = color(light: 0xE4E2DC, dark: 0x4A4842)
    static let accentSoft = color(light: 0xF5F2EC, dark: 0x383125)
    static let controlBoundary = color(light: 0x807B72, dark: 0x969187)
    static let error = color(light: 0xD4142A, dark: 0xFF6472)
    static let errorSurface = color(light: 0xFFF0F2, dark: 0x422027)
    static let dangerFill = color(light: 0xE02335, dark: 0xFF6472)
    static let success = color(light: 0x416451, dark: 0xB8D0BF)
    static let successSurface = color(light: 0xE8EFEA, dark: 0x293B30)
    static let warning = color(light: 0x795B2E, dark: 0xDCC7A2)
    static let warningSurface = color(light: 0xF3EEE4, dark: 0x403728)
    static let information = actionText
    static let informationSurface = accentSoft
    static let regularGlass = color(light: 0xFFFFFF, dark: 0x2B2B29, lightAlpha: 0.88, darkAlpha: 0.94)
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
