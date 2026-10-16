import SwiftUI

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
                .foregroundStyle(isEnabled ? AppTheme.actionText : AppTheme.secondary)
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

/// Matches the static system launch artwork; motion never blocks store opening.
struct BrandSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arrived = false
    var body: some View {
        AQDWordmark().environment(\.colorScheme, .light)
            .scaleEffect(reduceMotion || arrived ? 1 : 0.96)
            .opacity(reduceMotion || arrived ? 1 : 0.85)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("LaunchCanvas")).ignoresSafeArea()
            .accessibilityIdentifier("entry.splash")
            .onAppear {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.32)) { arrived = true }
            }
    }
}
