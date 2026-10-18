import AQDCore
import SwiftUI
import UIKit

/// Bounded local layout motion.
enum AQDMotion {
    static let reflow = Animation.smooth(duration: 0.22, extraBounce: 0)
}

/// DESIGN.md space scale; semantic aliases keep intent readable at call sites.
enum AppSpacing {
    static let headerGap: CGFloat = 20
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let screen: CGFloat = 20
    static let section: CGFloat = 24
    static let transition: CGFloat = 32
    static let spacious: CGFloat = 40
    static let extraLarge: CGFloat = 48
    static let actionGap = medium
}

enum AppRadius {
    static let photo: CGFloat = 4
    static let group: CGFloat = 12
    static let field: CGFloat = 16
    /// Large rounded cards that read like home-screen widgets.
    static let card: CGFloat = 24
    static let composer: CGFloat = 28
}

enum AppControlMetrics {
    static let minimumTarget: CGFloat = 44
    static let actionHeight: CGFloat = 50
    static let fieldHeight: CGFloat = 52
    static let rowHeight: CGFloat = 54
    static let fieldPadding: CGFloat = 14
    static let disclosureLane: CGFloat = 22
    static let feedbackSymbol: CGFloat = 18
}

/// Semantic Apple styles scale with Dynamic Type; native navigation/tab titles
/// remain OS-owned. No fixed line heights or alternate font dependency.
enum AppTypography {
    static let rootTitle: Font = .largeTitle.weight(.medium)
    static let detailTitle: Font = .title3.weight(.medium)
    static let section: Font = .title2.weight(.medium)
    static let body: Font = .body
    static let action: Font = .body.weight(.medium)
    static let supporting: Font = .subheadline
    static let fieldLabel: Font = .subheadline.weight(.medium)
    static let metadata: Font = .footnote
    static let disclosure = Font.footnote.weight(.medium)
}

/// Presentation preference only. Section09 owns persistence and Settings UI.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: Self { self }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
    /// Menus, context-menu previews, popovers and alerts follow the window, not the SwiftUI preference, so the window carries the choice too.
    @MainActor func applyToWindows() {
        let style: UIUserInterfaceStyle = switch self { case .system: .unspecified; case .light: .light; case .dark: .dark }
        for scene in UIApplication.shared.connectedScenes {
            for window in (scene as? UIWindowScene)?.windows ?? [] where window.overrideUserInterfaceStyle != style { window.overrideUserInterfaceStyle = style }
        }
    }
}

extension View {
    /// Apply to a SwiftUI presentation root; system inherits native appearance.
    func appAppearance(_ appearance: AppAppearance) -> some View {
        preferredColorScheme(appearance.colorScheme)
            .onChange(of: appearance, initial: true) { _, value in value.applyToWindows() }
    }
}

/// Calendar-day UI text comes from `LocalPlanDay.display(_:)` in Core so every screen reads the same way.
extension LocalPlanDay {
    /// "Fri, Oct 16": the default for rows and metadata.
    var displayDate: String { display(.standard) }
}
