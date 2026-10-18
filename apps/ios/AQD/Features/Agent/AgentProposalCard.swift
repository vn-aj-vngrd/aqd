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
    var setTripOptions: ((_ includeTheme: Bool?, _ includePlan: Bool?) -> Void)?
    @State private var previewing: LookPreview?

    private var detail: String {
        switch proposal.action {
        case .outfit(let draft): draft.displayName
        case .theme(let draft): draft.displayName
        case .plan(let draft): draft.plan.name
        case .wear(let draft): draft.day.displayDate
        case .availability(let change): change.pieceName
        case .piece(let change): change.draft.name
        case .profile: "Name and bio"
        case .trip(let draft): "\(draft.name), \(draft.days.count) \(draft.days.count == 1 ? "day" : "days")"
        }
    }

    struct LookPreview: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let pieceIDs: [UUID]
    }

    var body: some View {
        content.sheet(item: $previewing) { look in
            AgentLookSheet(title: look.title, subtitle: look.subtitle, pieceIDs: look.pieceIDs).presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder private var content: some View {
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
            if case .trip(let draft) = proposal.action { tripDays(draft) }
            Text(proposal.status == .executing ? "Check save result" : proposal.action.savesSummary + " Not saved yet.")
                .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
            AdaptiveActions { iconsOnly in
                Button(action: review) {
                    Label(proposal.status == .executing ? "Check result" : "Review and save", systemImage: "checkmark.circle")
                        .font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.onPrimary).padding(.horizontal, AppSpacing.medium)
                        .frame(minHeight: 32).background(AppTheme.primaryFill, in: Capsule()).frame(minHeight: AppControlMetrics.minimumTarget).contentShape(Rectangle())
                }.buttonStyle(.plain)
                if proposal.status == .proposed {
                    if let tryAnother {
                        Button(action: tryAnother) { AdaptiveLabel(title: "Try another", symbol: "arrow.triangle.2.circlepath", iconsOnly: iconsOnly) }.buttonStyle(.plain).disabled(locked)
                    }
                    Button(action: dismiss) { AdaptiveLabel(title: "Dismiss", symbol: "xmark", iconsOnly: iconsOnly) }.buttonStyle(.plain).disabled(locked)
                }
            }
        }.padding(AppSpacing.medium).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
            .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var thumbnails: some View {
        if case .outfit(let draft) = proposal.action {
            let shown = draft.pieceIDs.compactMap { id in pieces.first { $0.id == id } }
            if !shown.isEmpty {
                Button { previewing = LookPreview(title: draft.displayName, subtitle: draft.occasion ?? "", pieceIDs: draft.pieceIDs) } label: {
                HStack(spacing: AppSpacing.small) {
                    ForEach(shown) { piece in
                        PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe).frame(width: 56, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.field)).accessibilityLabel(piece.displayName)
                    }
                }
                }.buttonStyle(.plain).accessibilityHint("Opens a larger preview")
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

    /// One row per day: its label over the pieces of that day's look, then what saving will do.
    private func tripDays(_ draft: AgentTripDraft) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            ForEach(Array(draft.days.enumerated()), id: \.element.id) { index, day in
                Button { previewing = LookPreview(title: day.label, subtitle: day.day?.displayDate ?? "Day \(index + 1)", pieceIDs: day.outfit.pieceIDs) } label: {
                HStack(spacing: AppSpacing.small) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.label).font(AppTypography.supporting.weight(.medium)).foregroundStyle(AppTheme.ink).truncated()
                        Text(day.day?.displayDate ?? "Day \(index + 1)").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).truncated()
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 4) {
                        ForEach(day.outfit.pieceIDs.prefix(4), id: \.self) { id in
                            if let piece = pieces.first(where: { $0.id == id }) {
                                PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe).frame(width: 36, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo)).accessibilityLabel(piece.displayName)
                            }
                        }
                    }
                }
                .padding(AppSpacing.small)
                .background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: AppRadius.group, style: .continuous))
                .contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityElement(children: .combine).accessibilityHint("Opens a preview of this look")
            }
            if proposal.status == .proposed, let setTripOptions {
                HStack(spacing: AppSpacing.small) {
                    optionChip("Outfits", symbol: "checkmark", on: true, locked: true) {}
                    optionChip("Theme", symbol: draft.includeTheme ? "checkmark" : "plus", on: draft.includeTheme) { setTripOptions(!draft.includeTheme, nil) }
                    if draft.canPlan { optionChip("Planner", symbol: draft.includePlan ? "checkmark" : "plus", on: draft.includePlan) { setTripOptions(nil, !draft.includePlan) } }
                }
            }
        }
    }

    private func optionChip(_ title: String, symbol: String, on: Bool, locked: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol).compactControl(tint: on ? AppTheme.ink : AppTheme.secondary)
        }.buttonStyle(.plain).disabled(locked || self.locked).accessibilityValue(on ? "Included" : "Not included")
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
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
        }.buttonStyle(.plain).accessibilityHint("Opens the saved receipt")
    }

    private func quietRow(symbol: String, text: String) -> some View {
        Label(text, systemImage: symbol).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            .frame(minHeight: AppControlMetrics.minimumTarget)
    }
}
