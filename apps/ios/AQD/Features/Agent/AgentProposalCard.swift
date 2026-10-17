import AQDCore
import SwiftUI

/// Inline card under the message that produced a proposal. Review opens the modal sheet; nothing is saved until Apply there.
struct AgentProposalCard: View {
    let proposal: AgentActionProposal
    let locked: Bool
    let review: () -> Void
    let dismiss: () -> Void

    private var detail: String {
        switch proposal.action {
        case .outfit(let draft): draft.displayName
        case .theme(let draft): draft.displayName
        case .plan(let draft): draft.plan.name
        case .wear(let draft): draft.day.displayDate
        case .availability(let change): change.pieceName
        case .piece(let change): change.draft.name
        case .profile: "Name and bio"
        }
    }

    var body: some View {
        switch proposal.status {
        case .succeeded: receiptRow
        case .cancelled: quietRow(symbol: "xmark.circle", text: "Dismissed · \(detail)")
        case .proposed, .executing: reviewCard
        }
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(proposal.action.title).font(AppTypography.section).foregroundStyle(AppTheme.ink)
            Text(detail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            Text(proposal.status == .executing ? "Check save result" : "Not saved · Review before it changes anything")
                .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
            HStack(spacing: AppSpacing.small) {
                Button(action: review) {
                    Text(proposal.status == .executing ? "Check result" : "Review").frame(minHeight: AppControlMetrics.minimumTarget).padding(.horizontal, AppSpacing.large)
                        .foregroundStyle(AppTheme.onPrimary).background(AppTheme.primaryFill, in: Capsule())
                }.buttonStyle(.plain)
                if proposal.status == .proposed {
                    Button(action: dismiss) {
                        Text("Dismiss").frame(minHeight: AppControlMetrics.minimumTarget).padding(.horizontal, AppSpacing.large).contentShape(Rectangle())
                    }.buttonStyle(.plain).foregroundStyle(AppTheme.ink).disabled(locked)
                }
            }
        }.padding(AppSpacing.medium).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
            .accessibilityElement(children: .contain)
    }

    private var receiptRow: some View {
        Button(action: review) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "checkmark.circle").foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text("Saved locally · \(detail)").foregroundStyle(AppTheme.ink)
                    if let receipt = proposal.receipt {
                        Text(receipt.acknowledgedAt.displayTimestamp()).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    }
                }
                Spacer(minLength: AppSpacing.small)
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
            }.frame(minHeight: AppControlMetrics.minimumTarget).padding(AppSpacing.medium).contentShape(Rectangle())
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
        }.buttonStyle(.plain).accessibilityHint("Opens the saved receipt")
    }

    private func quietRow(symbol: String, text: String) -> some View {
        Label(text, systemImage: symbol).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            .frame(minHeight: AppControlMetrics.minimumTarget)
    }
}
