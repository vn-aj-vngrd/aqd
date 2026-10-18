import AQDCore
import SwiftUI

/// Inline card under the message that produced a proposal. Review opens the modal sheet; nothing is saved until Apply there.
struct AgentProposalCard: View {
    let proposal: AgentActionProposal
    let locked: Bool
    var pieces: [WardrobePiece] = []
    let review: () -> Void
    let dismiss: () -> Void
    var tryAnother: (() -> Void)?

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
        case .cancelled: quietRow(symbol: "xmark.circle", text: "Dismissed. \(detail)")
        case .proposed, .executing: reviewCard
        }
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(proposal.action.title).font(AppTypography.section).foregroundStyle(AppTheme.ink)
            Text(detail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            thumbnails
            if case .plan(let draft) = proposal.action { planGrid(draft) }
            Text(proposal.status == .executing ? "Check save result" : "Not saved yet. Review before it changes anything.")
                .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
            ScrollView(.horizontal) {
                HStack(spacing: AppSpacing.small) {
                    Button(action: review) {
                        Label(proposal.status == .executing ? "Check result" : "Review and save", systemImage: "checkmark.circle")
                            .font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.onPrimary).padding(.horizontal, AppSpacing.medium)
                            .frame(minHeight: 32).background(AppTheme.primaryFill, in: Capsule()).frame(minHeight: AppControlMetrics.minimumTarget).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    if proposal.status == .proposed {
                        if let tryAnother {
                            Button(action: tryAnother) { Label("Try another", systemImage: "arrow.triangle.2.circlepath").compactControl() }.buttonStyle(.plain).disabled(locked)
                        }
                        Button(action: dismiss) { Label("Dismiss", systemImage: "xmark").compactControl() }.buttonStyle(.plain).disabled(locked)
                    }
                }
            }.scrollIndicators(.hidden)
        }.padding(AppSpacing.medium).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
            .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var thumbnails: some View {
        if case .outfit(let draft) = proposal.action {
            let shown = draft.pieceIDs.compactMap { id in pieces.first { $0.id == id } }
            if !shown.isEmpty {
                HStack(spacing: AppSpacing.small) {
                    ForEach(shown) { piece in
                        PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe).frame(width: 56, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.field)).accessibilityLabel(piece.displayName)
                    }
                }
            }
        }
    }

    /// First seven days of a plan: weekday initial over a mark for an assigned outfit or a gap. The full list lives in Review.
    private func planGrid(_ draft: PlanAuthoringDraft) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            HStack(spacing: AppSpacing.small) {
                ForEach(draft.slots.prefix(7)) { slot in
                    VStack(spacing: AppSpacing.xSmall) {
                        Text(Self.weekdayInitial(slot.day)).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                        Image(systemName: slot.outfit == nil ? "minus" : "tshirt").foregroundStyle(slot.outfit == nil ? AppTheme.secondary : AppTheme.ink)
                    }.frame(maxWidth: .infinity).accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(slot.day.displayDate): \(slot.outfit?.displayName ?? "no outfit")")
                }
            }
            if draft.slots.count > 7 {
                Text("+\(draft.slots.count - 7) more days").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
            }
        }
    }

    private static func weekdayInitial(_ day: LocalPlanDay) -> String {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: day.timeZoneID) ?? .current
        guard let date = try? day.date() else { return "–" }
        return calendar.veryShortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
    }

    private var receiptRow: some View {
        Button(action: review) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "checkmark.circle").foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text("Saved locally").foregroundStyle(AppTheme.ink)
                    Text(detail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
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
