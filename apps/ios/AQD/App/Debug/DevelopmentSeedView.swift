#if DEBUG
import AQDCore
import SwiftUI

/// Internal testing only: replaces the closet with Angelika Domingo's realistic sample life. Opening this page never changes records;
/// the app itself always starts empty.
struct DevelopmentSeedView: View {
    @Environment(AppState.self) private var state
    @State private var busy = false
    @State private var receipt: RealisticClosetSeed.Receipt?
    @State private var error: String?
    private var blocked: Bool { busy || state.agentModel?.active == true || state.agentModel?.hasPendingOperation == true || state.agentControlsModel?.hasPending == true }

    var body: some View {
        List {
            Section {
                Text(receipt == nil ? "Fill the app with \(RealisticClosetSeed.ownerName)’s closet, plans, wear, fit journal, profile and style preferences."
                                    : "\(RealisticClosetSeed.ownerName)’s data is ready. Go back to explore it.")
                Text("A backup archive is saved to Files first. Seeding replaces the current pieces, outfits, themes, plans, wear, fits, profile and style answers. Settings and chats stay.")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }.listRowBackground(AppTheme.surface)
            if let receipt {
                Section("Seeded records") {
                    LabeledContent("Pieces", value: String(receipt.pieces.count))
                    LabeledContent("Outfits", value: String(receipt.outfits.count))
                    LabeledContent("Themes", value: String(receipt.themes.count))
                    LabeledContent("Plans", value: String(receipt.plans.count))
                    LabeledContent("Worn days", value: String(receipt.wear.count))
                    LabeledContent("Fits", value: String(receipt.fits.count))
                    LabeledContent("Backup", value: receipt.backup).lineLimit(1).truncationMode(.middle)
                }.listRowBackground(AppTheme.surface)
            }
            if busy || error != nil || (blocked && !busy) {
                Section {
                    if busy { OperationProgress(title: "Seeding \(RealisticClosetSeed.ownerName)’s data") }
                    if let error { SemanticFeedback(role: .danger, message: error) }
                    if blocked && !busy { Text("Finish the Agent’s current response or pending save first.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                }.listRowBackground(AppTheme.surface)
            }
        }.listStyle(.insetGrouped).contentMargins(.top, AppSpacing.small, for: .scrollContent)
            .scrollContentBackground(.hidden).background(AppTheme.canvas)
            .navigationTitle("Seed sample data").navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(busy)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    ToolbarSaveAction(title: receipt == nil ? (error == nil ? "Seed" : "Try again") : "Seed again", isPending: busy) { Task { await seed() } }
                        .disabled(blocked)
                }
            }
    }
    private func seed() async {
        guard !blocked else { return }
        busy = true; error = nil
        defer {
            busy = false
            state.reloadPieces(); state.reloadOutfits(); state.reloadThemes(); state.reloadPlanEntries(); state.reloadFits()
            state.reloadWear(); state.reloadToday(); state.reloadIdentity(); state.reloadSettings()
        }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("AQD Development Samples", isDirectory: true)
            receipt = try await RealisticClosetSeed.run(store: store, outputDirectory: directory)
        } catch {
            self.error = "Seeding couldn’t finish. A backup archive is in Files under AQD Development Samples if setup reached that step. Try again after other saves finish."
        }
    }
}
#endif
