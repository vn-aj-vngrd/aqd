import SwiftUI

/// Shimmer applies only to the operation label, never to generated response text.
struct AgentWorkingIndicator: View {
    let title: String
    var animates = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    private var label: some View {
        Text(title).font(AppTypography.supporting).fixedSize(horizontal: false, vertical: true)
    }

    var body: some View {
        Group {
            if animates && !reduceMotion && contrast != .increased {
                TimelineView(.animation) { timeline in
                    let phase = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.6) / 1.6
                    let start = phase * 2.2 - 0.6
                    label.foregroundStyle(AppTheme.secondary.opacity(0.55))
                        .overlay {
                            label.foregroundStyle(AppTheme.ink)
                                .mask(LinearGradient(colors: [.clear, .white, .clear], startPoint: UnitPoint(x: start, y: 0.5), endPoint: UnitPoint(x: start + 0.6, y: 0.5)))
                        }
                }
            } else {
                label.foregroundStyle(contrast == .increased ? AppTheme.ink : AppTheme.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }
}
