import SwiftUI

struct PrimaryAction: View {
    let title: String
    var isPending = false
    var systemImage: String? = nil
    var role: ButtonRole? = nil
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    private var usesAccent: Bool { isEnabled || isPending }

    var body: some View {
        Button(role: role) {
            guard isEnabled && !isPending else { return }
            action()
        } label: {
            HStack(spacing: AppSpacing.small) {
                if isPending {
                    ProgressView().tint(usesAccent ? AppTheme.onAccent : AppTheme.secondary).accessibilityHidden(true)
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
            .foregroundStyle(usesAccent ? AppTheme.onAccent : AppTheme.secondary)
            .background(usesAccent ? (role == .destructive ? AppTheme.dangerFill : AppTheme.accent) : AppTheme.divider, in: Capsule())
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

/// The splash wordmark is the shared MVP logo; no separate brand symbol.
struct AQDWordmark: View {
    var body: some View {
        Text("AQD").font(.system(size: 44)).tracking(-1.1)
            .foregroundStyle(AppTheme.ink).accessibilityLabel("AQD")
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
        .tint(AppTheme.accent)
        .disabled(isPending || !isEnabled)
        .accessibilityValue(isPending ? "In progress" : "")
    }
}
