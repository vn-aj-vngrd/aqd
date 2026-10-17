import SwiftUI

/// Shimmer applies only to the operation label, never to generated response text.
struct AgentWorkingIndicator: View {
    let title: String
    var animates = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Text(title)
            .font(AppTypography.supporting)
            .foregroundStyle(contrast == .increased ? AppTheme.ink : AppTheme.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .overlay {
                if animates && !reduceMotion && contrast != .increased && scenePhase == .active {
                    TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                        GeometryReader { geometry in
                            let width = geometry.size.width
                            let phase = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.8) / 1.8
                            LinearGradient(colors: [.clear, AppTheme.ink, .clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: width * 0.65)
                                .offset(x: width * (phase * 1.65 - 0.65))
                        }
                    }
                    .mask(Text(title).font(AppTypography.supporting).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading))
                    .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
    }
}
