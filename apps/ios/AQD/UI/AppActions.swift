import SwiftUI
import UIKit

struct PrimaryAction: View {
    let title: String
    var isPending = false
    var systemImage: String? = nil
    var role: ButtonRole? = nil
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    private var usesAccent: Bool { isEnabled || isPending }
    private var activeForeground: Color { role == .destructive ? AppTheme.onAccent : AppTheme.onPrimary }

    var body: some View {
        Button(role: role) {
            guard isEnabled && !isPending else { return }
            action()
        } label: {
            HStack(spacing: AppSpacing.small) {
                if isPending {
                    ProgressView().tint(usesAccent ? activeForeground : AppTheme.secondary).accessibilityHidden(true)
                }
                if let systemImage {
                    Image(systemName: systemImage).accessibilityHidden(true)
                }
                Text(title).font(usesAccent ? AppTypography.action : AppTypography.body)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.vertical, AppSpacing.medium)
            .frame(maxWidth: .infinity, minHeight: AppControlMetrics.actionHeight)
            .foregroundStyle(usesAccent ? activeForeground : AppTheme.secondary)
            .background(usesAccent ? (role == .destructive ? AppTheme.dangerFill : AppTheme.primaryFill) : AppTheme.divider, in: Capsule())
            .contentShape(Rectangle())
        }
        .buttonStyle(ContentActionStyle())
        .disabled(isPending)
        .accessibilityLabel(title)
        .accessibilityValue(isPending ? "In progress" : "")
    }
}

struct SecondaryAction: View {
    let title: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Text(title).font(AppTypography.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, AppSpacing.screen)
                .padding(.vertical, AppSpacing.medium)
                .frame(maxWidth: .infinity, minHeight: AppControlMetrics.actionHeight)
                .foregroundStyle(isEnabled ? AppTheme.ink : AppTheme.secondary)
                .contentShape(Rectangle())
        }.buttonStyle(ContentActionStyle())
    }
}

/// Keep authored disabled/pending contrast rather than plain-style automatic
/// dimming. Native Button still owns activation, keyboard and disabled traits.
private struct ContentActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Always vertical, including largest accessibility text; one primary dominates.
struct ActionStack<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(spacing: AppSpacing.actionGap, content: content)
    }
}

/// Content only: caller uses safeAreaInset. No fixed viewport/keyboard offsets.
struct ActionFooter<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
            .padding(.horizontal, AppSpacing.screen)
            .padding(.vertical, AppSpacing.medium)
            .background(AppTheme.canvas)
    }
}

/// Shared wordmark; the gold Q matches the packaged Home Screen icon.
struct AQDWordmark: View {
    var body: some View {
        Text(mark).font(.system(size: 44)).tracking(0.5)
            .accessibilityLabel("AQD")
    }
    private var mark: AttributedString {
        var text = AttributedString("AQD")
        text.foregroundColor = AppTheme.ink
        if let range = text.range(of: "Q") { text[range].foregroundColor = AppTheme.accent }
        return text
    }
}

/// Native text confirmation for sheet editors. Feature owners retain their
/// validation, cancellation and immutable save/reconciliation operations.
struct ToolbarSaveAction: View {
    let title: String
    var isPending = false
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    var body: some View {
        Button {
            guard isEnabled && !isPending else { return }
            action()
        } label: {
            Text(title).font(AppTypography.action).frame(minWidth: 44, minHeight: 44)
        }
        .tint(AppTheme.actionText)
        .disabled(isPending || !isEnabled)
        .accessibilityValue(isPending ? "In progress" : "")
    }
}

/// Neutral navigation between review steps; persistence stays with ToolbarSaveAction.
struct ToolbarForwardAction: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.forward")
        }.tint(AppTheme.ink).accessibilityLabel(title)
    }
}

/// Native menu symbols resolve semantic gray or danger color for the selected appearance.
struct AccessoryLabel: View {
    let title: String
    let systemImage: String
    var destructive = false
    @Environment(\.colorScheme) private var colorScheme
    init(_ title: String, systemImage: String, destructive: Bool = false) {
        self.title = title; self.systemImage = systemImage; self.destructive = destructive
    }
    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(uiImage: symbol).renderingMode(.original).accessibilityHidden(true)
        }
    }
    private var symbol: UIImage {
        let traits = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        let color = UIColor(destructive ? AppTheme.error : AppTheme.controlIcon).resolvedColor(with: traits)
        return UIImage(systemName: systemImage)?.withTintColor(color, renderingMode: .alwaysOriginal) ?? UIImage()
    }
}

struct AccessoryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title; self.systemImage = systemImage; self.action = action
    }
    var body: some View { Button(action: action) { AccessoryLabel(title, systemImage: systemImage) } }
}

extension View {
    @ViewBuilder func neutralToolbarGlass() -> some View {
        if #available(iOS 26, *) { buttonStyle(.glass) }
        else { self }
    }
}
