import AQDCore
import SwiftUI

struct AgentActionReviewView: View {
    @Environment(AppState.self) private var state
    @Bindable var model: AgentModel
    let id: UUID
    private var proposal: AgentActionProposal? { model.conversation.proposals?.first { $0.id == id } }
    private func isNewPiece(_ proposal: AgentActionProposal) -> Bool {
        if case .piece(let change) = proposal.action { change.isNewPiece } else { false }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let proposal {
                    Text(proposal.action.title).font(AppTypography.section)
                    Text(proposal.status == .succeeded ? "Saved locally" : "Draft, not confirmed saved").foregroundStyle(AppTheme.secondary)
                    preview(proposal.action)
                    if let error = model.error { Text(error).foregroundStyle(AppTheme.error); Button("Check conversation save") { model.retryPending() }.frame(minHeight: 44) }
                    if let receipt = proposal.receipt, proposal.status == .succeeded {
                        Text("Saved receipt, \(receipt.acknowledgedAt.displayTimestamp())").font(.footnote)
                        if receipt.kind == "outfit" { NavigationLink("Open outfit", value: ClosetRoute.outfit(receipt.recordID)) }
                        else if receipt.kind == "theme" { NavigationLink("Open theme", value: ClosetRoute.theme(receipt.recordID)) }
                        else if receipt.kind == "piece" { NavigationLink("Open piece", value: ClosetRoute.piece(receipt.recordID)) }
                        else if receipt.kind == "profile" { Text("Your Profile now shows these saved details.") }
                        else if receipt.kind == "trip", case .trip(let draft) = proposal.action { tripReceipt(draft, receipt) }
                        else if receipt.kind == "plan", case .plan(let draft) = proposal.action {
                            PrimaryAction(title: "Open in Planner") { state.plannerDay = draft.plan.start; state.plannerMode = .week; state.selection = 2 }
                        } else { Text("Open Planner or wear history to review the acknowledged records.") }
                    } else if proposal.status == .proposed || proposal.status == .executing {
                        if proposal.status == .proposed { SecondaryAction(title: "Keep current records") { model.cancelProposal(id) } }
                        Text("Approval applies only to this exact version. Changed records require a new review. Check an unconfirmed operation before making another draft.").font(.footnote).foregroundStyle(AppTheme.secondary)
                    }
                } else { Text("This proposal is unavailable. Your saved records are retained.") }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Review changes").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if let proposal, proposal.status == .proposed || proposal.status == .executing, !isNewPiece(proposal) {
                    ToolbarSaveAction(title: proposal.status == .executing ? "Check result" : "Apply") {
                        model.approveProposal(id, version: proposal.version)
                        state.reloadPieces(); state.reloadOutfits(); state.reloadThemes(); state.reloadPlanEntries(); state.reloadWear(); state.reloadIdentity()
                    }.disabled(model.hasPendingOperation)
                        .accessibilityLabel(proposal.status == .executing ? "Check reviewed operation" : "Apply reviewed change")
                }
            } }
            .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
    }
    @ViewBuilder private func preview(_ action: AgentReviewedAction) -> some View {
        switch action {
        case .piece(let change):
            Text(change.draft.name.isEmpty ? "New piece" : change.draft.name).font(.headline)
            LabeledContent("Color", value: change.draft.details.color)
            LabeledContent("Brand", value: change.draft.details.brand)
            Text(change.isNewPiece ? "Saved from the Closet editor with your full-quality photo." : "Photo, category and other details stay unchanged.").font(.footnote).foregroundStyle(AppTheme.secondary)
        case .profile(let draft):
            Text("Name").font(.headline); Text((draft.base?.name ?? "Not set") + " → " + (draft.name.isEmpty ? "Not set" : draft.name))
            Text("Bio").font(.headline); Text((draft.base?.caption ?? LocalProfileIdentity.defaultCaption) + " → " + (draft.caption ?? LocalProfileIdentity.defaultCaption))
            Text("Your profile photo stays unchanged.").font(.footnote).foregroundStyle(AppTheme.secondary)
        case .theme(let draft): Text(draft.displayName).font(.headline); ForEach(draft.outfitIDs, id: \.self) { id in Text(state.outfits.first { $0.id == id }?.displayName ?? "Unavailable outfit") }
        case .outfit(let draft): Text(draft.displayName).font(.headline); ForEach(draft.pieceIDs, id: \.self) { id in Text(state.ownedPieces.first { $0.id == id }?.displayName ?? "Unavailable piece") }
        case .plan(let draft):
            Text(draft.plan.name).font(.headline)
            Text("\(draft.plan.start.displayDate) – \(draft.plan.end.displayDate), \(draft.slots.filter { $0.outfit != nil }.count) of \(draft.slots.count) days planned. All days save together or not at all.")
                .font(.footnote).foregroundStyle(AppTheme.secondary)
            ForEach(draft.slots) { slot in VStack(alignment: .leading) { Text(slot.day.displayDate); Text(slot.day.timeZoneID).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary); Text(slot.outfit?.displayName ?? "Intentionally unassigned") } }
        case .trip(let draft): tripPreview(draft)
        case .wear(let draft): Text(draft.day.displayDate); Text(draft.day.timeZoneID).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary); ForEach(draft.pieceIDs, id: \.self) { id in Text(state.ownedPieces.first { $0.id == id }?.displayName ?? "Unavailable piece") }; Text("Records actual wear. This is separate from a plan or fit memory.")
        case .availability(let change): Text(change.pieceName).font(.headline); Text("Availability → " + change.value.rawValue.capitalized); Text("Affected future plans will require review; actual wear stays.")
        }
    }

    @ViewBuilder private func tripPreview(_ draft: AgentTripDraft) -> some View {
        Text(draft.name).font(.headline)
        if !draft.destination.isEmpty { Text(draft.destination).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
        ForEach(Array(draft.days.enumerated()), id: \.element.id) { index, day in
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(day.label).font(AppTypography.body.weight(.semibold)).truncated()
                Text(day.day?.displayDate ?? "Day \(index + 1)").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                ScrollView(.horizontal) {
                    HStack(spacing: AppSpacing.small) {
                        ForEach(day.outfit.pieceIDs, id: \.self) { id in
                            if let piece = state.ownedPieces.first(where: { $0.id == id }) {
                                VStack(spacing: 4) {
                                    PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe).frame(width: 64, height: 76)
                                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo))
                                    Text(piece.displayName).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).truncated().frame(width: 64)
                                }
                            }
                        }
                    }
                }.scrollIndicators(.hidden)
            }.padding(AppSpacing.medium).frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Saving adds").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
            Label("\(draft.days.count) \(draft.days.count == 1 ? "outfit" : "outfits") to your closet", systemImage: "checkmark")
            if proposal?.status == .proposed {
                Toggle("Group them in a theme called \(draft.theme.name)", isOn: Binding(get: { draft.includeTheme }, set: { model.setTripOptions(id, includeTheme: $0) }))
                if draft.canPlan { Toggle("Add the trip to your Planner", isOn: Binding(get: { draft.includePlan }, set: { model.setTripOptions(id, includePlan: $0) })) }
                else { Text("Add dates to place these days on your Planner.").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary) }
            } else {
                if draft.includeTheme { Label("Theme \(draft.theme.name)", systemImage: "checkmark") }
                if draft.includePlan { Label("Planner trip", systemImage: "checkmark") }
            }
        }.font(AppTypography.supporting)
    }

    @ViewBuilder private func tripReceipt(_ draft: AgentTripDraft, _ receipt: AgentActionReceipt) -> some View {
        if draft.includePlan, let start = draft.plan?.plan.start {
            PrimaryAction(title: "Open in Planner") { state.plannerDay = start; state.plannerMode = .week; state.selection = 2 }
        }
        if draft.includeTheme { NavigationLink("Open theme", value: ClosetRoute.theme(draft.theme.themeID)) }
        else if let first = draft.days.first { NavigationLink("Open first outfit", value: ClosetRoute.outfit(first.outfit.outfitID)) }
    }
}
