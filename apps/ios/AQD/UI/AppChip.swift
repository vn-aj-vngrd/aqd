import SwiftUI

/// Shared selectable capsule for category and filter rows. Selected uses the neutral
/// primary pair; unselected is a white surface lifted by a hairline and soft shadow so it
/// stays visible on the canvas and on sheets.
struct AppChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(.subheadline)
                .padding(.horizontal, AppSpacing.medium).padding(.vertical, 6)
                .frame(minHeight: AppControlMetrics.minimumTarget)
                .foregroundStyle(isSelected ? AppTheme.onPrimary : AppTheme.ink)
                .background {
                    Capsule().fill(isSelected ? AppTheme.primaryFill : AppTheme.surface)
                        .overlay(Capsule().strokeBorder(isSelected ? .clear : AppTheme.divider, lineWidth: 1))
                        .shadow(color: isSelected ? .clear : AppTheme.controlShadow, radius: 4, y: 1)
                        .padding(.vertical, 6)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
