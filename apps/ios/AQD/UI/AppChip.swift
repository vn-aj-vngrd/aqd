import SwiftUI

extension View {
    /// Single recipe for tappable white surfaces (chips, secondary buttons): a hairline edge and a
    /// soft shadow keep them visible on the canvas and on sheets. Cards and rows stay flat.
    func raisedSurface<S: InsettableShape>(_ shape: S) -> some View {
        background {
            shape.fill(AppTheme.surface)
                .overlay(shape.strokeBorder(AppTheme.divider, lineWidth: 1))
                .shadow(color: AppTheme.controlShadow, radius: 4, y: 1)
        }
    }
}

/// Shared selectable capsule for category and filter rows. Selected uses the neutral
/// primary pair; unselected uses the raised white surface.
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
        if isSelected { content } else { content.raisedSurface(Capsule()) }
    }
}
