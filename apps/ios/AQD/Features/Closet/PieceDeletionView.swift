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
                VStack(alignment: .leading, spacing: 20) {
                    Text("Review what this changes before deleting.").font(AppTypography.body)
                    if let impact {
                        Text("\(impact.outfitRevisions.count) saved outfits affected").font(AppTypography.section)
                        ForEach(state.outfits.filter { impact.outfitRevisions[$0.id] != nil }) { outfit in
                            Text(outfitImpactLabel(outfit))
                        }
                        Text("\(impact.themeRevisions.count) themes contain affected outfits")
                        Text("\(impact.futurePlanRevisions.count) future plans become unassigned")
                        ForEach(state.planEntries.filter { impact.futurePlanRevisions[$0.id] != nil }) { plan in
                            Text("\(plan.day.key) · \(plan.occasion)")
                        }
                        Text("Empty outfits and their theme memberships are removed. Future plans keep their dates and occasions for re-selection. Original Photos and historical wear snapshots stay. Unreferenced AQD photos are removed.")
                            .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        Button(role: .destructive) { confirming = true } label: {
                            Text("Delete \(piece.displayName)").frame(maxWidth: .infinity, minHeight: 48)
                        }.buttonStyle(.borderedProminent).tint(AppTheme.dangerFill)
                    }
                    if let error {
                        SemanticFeedback(role: .danger, message: error)
                        Button(submitted ? "Retry reviewed deletion" : "Refresh impact") {
                            if submitted { remove() } else { review() }
                        }.frame(minHeight: 44)
                    }
                }.padding(20)
            }.background(AppTheme.canvas).navigationTitle("Delete piece").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }.tint(AppTheme.ink)
                        .accessibilityLabel("Cancel deletion").disabled(submitted)
                } }
                .appConfirmation("Delete \(piece.displayName)?", isPresented: $confirming) {
                    Button("Delete piece", role: .destructive, action: remove)
                    Button("Cancel", role: .cancel) {}
                } message: { Text("This deletes the reviewed piece and changes the references shown here. This cannot be undone.") }
        }.interactiveDismissDisabled(submitted).onAppear(perform: review)
    }

    private func outfitImpactLabel(_ outfit: Outfit) -> String {
        let effect = outfit.pieceIDs.count == 1 ? "removed when empty" : "remaining pieces retained"
        return outfit.displayName + " · " + effect
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
