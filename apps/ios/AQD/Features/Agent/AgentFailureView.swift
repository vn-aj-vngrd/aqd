import AQDCore
import SwiftUI

/// A failed reply, explained: what happened in one line and the ways forward as glass pills. Partial text, when there is some, stays above it.
struct AgentFailureView: View {
    let failure: AgentFailure
    let perform: (AgentFailure.Action) -> Void
    var locked = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
                Image(systemName: "exclamationmark.circle").foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(failure.title).font(AppTypography.section).foregroundStyle(AppTheme.ink)
                    Text(failure.cause + (failure.keptPartialReply ? " The partial reply above is kept." : ""))
                        .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }.accessibilityElement(children: .combine)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.small) { actions }.fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: 0) { actions }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actions: some View {
        ForEach(failure.actions, id: \.self) { action in
            Button { perform(action) } label: { Label(action.title, systemImage: action.symbol).compactControl() }
                .buttonStyle(.plain).disabled(locked)
        }
    }
}

/// Tool refusals as quiet single lines, so a change that could not be prepared never vanishes.
struct AgentRejectionNotes: View {
    let steps: [AgentToolStep]

    var body: some View {
        ForEach(steps.filter { $0.rejection != nil }) { step in
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
                Image(systemName: "exclamationmark.circle").font(.caption).foregroundStyle(AppTheme.controlIcon).frame(width: 18).accessibilityHidden(true)
                Text(step.summary).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).fixedSize(horizontal: false, vertical: true)
            }.accessibilityElement(children: .combine)
        }
    }
}
