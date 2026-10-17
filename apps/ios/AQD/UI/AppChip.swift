import SwiftUI

extension View {
    /// Single recipe for tappable compact controls (chips, secondary buttons, round icon buttons).
    /// iOS 26+ uses native interactive regular glass; Reduce Transparency, Increase Contrast and
    /// older systems fall back to a flat white surface with a hairline. No hand-drawn shadows.
    func glassControlSurface<S: InsettableShape>(_ shape: S) -> some View {
        modifier(GlassControlSurface(shape: shape))
    }
}

private struct GlassControlSurface<S: InsettableShape>: ViewModifier {
    let shape: S
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26, *), !reduceTransparency, contrast != .increased {
            content.glassEffect(.regular.interactive(!reduceMotion), in: shape)
        } else {
            content.background {
                shape.fill(AppTheme.surface)
                    .overlay(shape.strokeBorder(contrast == .increased ? AppTheme.controlBoundary : AppTheme.divider, lineWidth: 1))
            }
        }
    }
}

/// Shared selectable capsule for category and filter rows. Selected uses the neutral
/// primary pair; unselected uses the shared glass control surface.
struct AppChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(.subheadline)
                .padding(.horizontal, AppSpacing.medium).frame(minHeight: 32)
                .foregroundStyle(isSelected ? AppTheme.onPrimary : AppTheme.ink)
                .background { if isSelected { Capsule().fill(AppTheme.primaryFill) } }
                .modifier(RaisedWhenUnselected(isSelected: isSelected))
                .frame(minHeight: AppControlMetrics.minimumTarget).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct RaisedWhenUnselected: ViewModifier {
    let isSelected: Bool
    func body(content: Content) -> some View {
        if isSelected { content } else { content.glassControlSurface(Capsule()) }
    }
}
