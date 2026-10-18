import AQDCore
import SwiftUI

struct PieceDeletionView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let piece: WardrobePiece
    let deleted: () -> Void
    @State private var impact: PieceDeletionImpact?
    @State private var operationID = UUID()
    @State private var error: String?
    @State private var submitted = false
    @State private var confirming = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    header
                    if let impact {
                        impactSummary(impact)
                        Text("Original Photos and historical wear snapshots stay. Photos that only AQD kept are removed. This cannot be undone.")
                            .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        PrimaryAction(title: "Delete piece", role: .destructive) { confirming = true }
                    }
                    if let error {
                        SemanticFeedback(role: .danger, message: error)
                        Button(submitted ? "Retry reviewed deletion" : "Refresh impact") {
                            if submitted { remove() } else { review() }
                        }.frame(minHeight: 44)
                    }
                }.padding(AppSpacing.screen)
            }.background(AppTheme.canvas).navigationTitle("Delete piece").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }.tint(AppTheme.ink)
                        .accessibilityLabel("Cancel deletion").disabled(submitted)
                } }
                .deleteConfirmation("piece", isPresented: $confirming, message: "This deletes \(piece.displayName) and changes the references shown here. This cannot be undone.", delete: remove)
        }.interactiveDismissDisabled(submitted).onAppear(perform: review)
    }

    private var header: some View {
        HStack(spacing: AppSpacing.medium) {
            PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe).frame(width: 72, height: 84)
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(piece.displayName).font(AppTypography.section).foregroundStyle(AppTheme.ink)
                Text("Review what changes before you delete it.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder private func impactSummary(_ impact: PieceDeletionImpact) -> some View {
        let outfits = state.outfits.filter { impact.outfitRevisions[$0.id] != nil }
        let plans = state.planEntries.filter { impact.futurePlanRevisions[$0.id] != nil }
        if outfits.isEmpty && impact.themeRevisions.isEmpty && plans.isEmpty {
            impactRow("checkmark.circle", "Nothing else changes", "No outfit, theme or future plan uses this piece.", [])
        } else {
            VStack(spacing: AppSpacing.medium) {
                if !outfits.isEmpty {
                    impactRow("square.stack", count(outfits.count, "outfit") + " affected", "An outfit is removed only when this was its last piece.", outfits.map(outfitImpactLabel))
                }
                if !impact.themeRevisions.isEmpty {
                    impactRow("folder", count(impact.themeRevisions.count, "theme") + " updated", "Themes lose any outfit that is removed.", [])
                }
                if !plans.isEmpty {
                    impactRow("calendar", count(plans.count, "future plan") + " unassigned", "Dates and occasions stay so you can choose again.", plans.map { "\($0.day.displayDate), \($0.occasion)" })
                }
            }
        }
    }

    private func count(_ value: Int, _ noun: String) -> String { "\(value) \(noun)" + (value == 1 ? "" : "s") }

    private func impactRow(_ symbol: String, _ title: String, _ detail: String, _ items: [String]) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: symbol).font(.system(size: 18)).foregroundStyle(AppTheme.controlIcon).frame(width: 26).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(title).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                Text(detail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                ForEach(items, id: \.self) { Text($0).font(AppTypography.supporting).foregroundStyle(AppTheme.ink) }
            }
            Spacer(minLength: 0)
        }.padding(AppSpacing.medium).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card)).accessibilityElement(children: .combine)
    }

    private func outfitImpactLabel(_ outfit: Outfit) -> String {
        let effect = outfit.pieceIDs.count == 1 ? "removed when empty" : "remaining pieces retained"
        return outfit.displayName + ", " + effect
    }

    private func review() {
        guard !submitted else { return }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            let latest = try store.pieceDeletionImpact(id: piece.id)
            guard latest.pieceRevision == piece.revision else { throw PieceStore.StoreError.staleRevision }
            state.reloadOutfits(); state.reloadThemes(); state.reloadPlanEntries()
            impact = latest; error = nil; operationID = UUID()
        } catch { impact = nil; self.error = "This review is no longer current. Close it and reopen the saved piece, or retry." }
    }
    private func remove() {
        guard let impact else { return }
        submitted = true
        do {
            try state.deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: operationID, impact: impact)
            deleted()
        } catch PieceStore.StoreError.staleRevision {
            submitted = false; self.impact = nil
            error = "The piece or its references changed. Refresh the impact before deciding again."
        } catch { self.error = "Deletion isn’t acknowledged. Retry this same reviewed operation to reconcile it." }
    }
}
