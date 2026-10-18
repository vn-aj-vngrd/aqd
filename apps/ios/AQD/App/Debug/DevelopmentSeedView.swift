#if DEBUG
import AQDCore
import SwiftUI

/// Explicit development-only seeding. Opening this sheet never changes records.
struct DevelopmentSeedView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var busy = false
    @State private var receipt: PreviewSampleContent.Receipt?
    @State private var error: String?
    private var blocked: Bool { busy || state.agentModel?.active == true || state.agentModel?.hasPendingOperation == true || state.agentControlsModel?.hasPending == true }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(receipt == nil ? "Add a demo wardrobe to explore Closet, Planner and your fit journal." : "Sample data is ready. Close this screen to explore it.")
                    Text("Personal records and onboarding progress stay unchanged. Sample plans and fits do not count as recorded wear.")
                        .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }.listRowBackground(AppTheme.surface)
                if let receipt {
                    Section("Sample records") {
                        LabeledContent("Pieces", value: String(receipt.added["pieces", default: 0]))
                        LabeledContent("Outfits", value: String(receipt.added["outfits", default: 0]))
                        LabeledContent("Themes", value: String(receipt.added["themes", default: 0]))
                        LabeledContent("Plan entries", value: String(receipt.added["plans", default: 0]))
                        LabeledContent("Fits", value: String(receipt.added["fits", default: 0]))
                    }.listRowBackground(AppTheme.surface)
                } else {
                    Section {
                        if busy { ProgressView("Preparing sample data…") }
                        else { Text("A local archive is saved before changes. Seeding again reuses the same sample records.") }
                        if let error { SemanticFeedback(role: .danger, message: error) }
                        if blocked && !busy { Text("Finish the Agent’s current response or pending save first.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                    }.listRowBackground(AppTheme.surface)
                }
            }.listStyle(.insetGrouped).contentMargins(.top, AppSpacing.small, for: .scrollContent)
                .scrollContentBackground(.hidden).background(AppTheme.canvas)
                .navigationTitle("Seed sample data").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { dismiss() } label: { Image(systemName: "xmark") }.accessibilityLabel("Close sample data").disabled(busy)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if receipt != nil { ToolbarSaveAction(title: "Done") { dismiss() } }
                        else {
                            ToolbarSaveAction(title: error == nil ? "Seed data" : "Try again", isPending: busy) { Task { await seed() } }
                                .disabled(blocked)
                        }
                    }
                }
        }.tint(AppTheme.ink).interactiveDismissDisabled(busy)
    }
    private func seed() async {
        guard !blocked, receipt == nil else { return }
        busy = true; error = nil
        defer {
            busy = false
            state.reloadPieces(); state.reloadOutfits(); state.reloadThemes(); state.reloadPlanEntries(); state.reloadFits(); state.reloadToday()
        }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("AQD Development Samples", isDirectory: true)
                .appendingPathComponent(try store.todayConfiguration().ownerID.uuidString, isDirectory: true)
            receipt = try await PreviewSampleContent.populate(store: store, outputDirectory: directory)
        } catch PreviewSampleContent.Failure.partialSamples {
            error = "Some sample records are missing. Existing data is kept. Export anything you need, then use Reset data before seeding a fresh set."
        } catch {
            self.error = "Sample setup couldn’t finish. Personal records have not been replaced. A local archive is retained if setup reached that step. Try again after other saves finish."
        }
    }
}
#endif
