import SwiftUI

struct LocalEraseView: View {
    @Bindable var model: LocalRestoreModel
    let onCancel: () -> Void
    let onInstall: (PieceStore, LocalDataCoordinator, Int) -> Void
    @State private var phrase = ""
    @State private var confirm = false
    var body: some View {
        NavigationStack {
            ScrollView { VStack(alignment: .leading, spacing: 20) {
                switch model.phase {
                case .choose, .validating:
                    ProgressView("Preparing reset review…")
                case .review:
                    Label("Start from scratch", systemImage: "trash").font(AppTypography.section)
                    Text("Reset AQD’s local data and return to Welcome to go through onboarding again.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    if let summary = model.review?.originalSummary { LocalDataSummaryView(summary: summary) }
                    else { Text("Current data could not be fully validated. Reset replaces all AQD local data on this iPhone.") }
                    Text("Removes your closet, outfits, plans, wear history, fit journal, chats, feedback, profile, preferences, Today content and AQD-owned photo copies.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    Text("Original Photos, exported archives and iPhone permission settings stay. There is no automatic cloud copy to restore.").font(.subheadline).foregroundStyle(AppTheme.secondary)
                    NavigationLink { LocalExportView().navigationTitle("Export before reset").secondaryPage() } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up").accessibilityHidden(true)
                            Text("Export a copy first")
                            Spacer(minLength: 12)
                            Image(systemName: "chevron.forward").font(AppTypography.disclosure).accessibilityHidden(true)
                        }.font(AppTypography.supporting).foregroundStyle(AppTheme.ink).frame(minHeight: 44)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type RESET to continue").font(AppTypography.fieldLabel)
                        TextField("RESET", text: $phrase).textInputAutocapitalization(.characters).autocorrectionDisabled()
                            .font(AppTypography.body).padding(14).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityLabel("Type RESET to confirm")
                        Text("This action can’t be undone.").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    }
                case .committing:
                    ProgressView("Resetting local data…")
                    Text("Keep AQD open while your local data resets.")
                case .complete:
                    Text("AQD is ready for a fresh start.").font(.title2)
                    Text("Return to Welcome to begin onboarding. AQD will finish removing its old files after you continue; any cleanup that needs attention will stay visible.")
                case .failed, .newer:
                    Text("Reset wasn’t completed").font(.title2)
                    Text(model.error ?? "Your previous local records are retained.").foregroundStyle(AppTheme.error)
                case .unknown:
                    Text("Check the reset outcome").font(.title2)
                    Text(model.error ?? "Check the same operation before resetting again. A completed switch cannot be undone by cancelling.")
                }
            }.padding(20) }.background(AppTheme.canvas).navigationTitle("Reset data").navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if model.phase != .choose && model.phase != .validating && model.phase != .committing {
                        ActionFooter {
                            switch model.phase {
                            case .review:
                                PrimaryAction(title: "Reset data", systemImage: "trash", role: .destructive) { confirm = true }
                                    .disabled(phrase != "RESET")
                            case .complete:
                                PrimaryAction(title: "Return to Welcome") { if let store = model.installed { onInstall(store, model.coordinator, 0) } }
                            case .failed, .newer:
                                if model.review != nil { PrimaryAction(title: "Review current impact again") { model.refresh(); phrase = "" } }
                                else { PrimaryAction(title: "Prepare review again", action: model.prepareErase) }
                            case .unknown: PrimaryAction(title: "Check same operation", action: model.checkOutcome)
                            case .choose, .validating, .committing: EmptyView()
                            }
                        }
                    }
                }
                .toolbar { ToolbarItem(placement: .cancellationAction) { if model.phase != .complete {
                    Button { if model.cancel() { onCancel() } } label: { Image(systemName: "xmark") }.buttonBorderShape(.circle).accessibilityLabel("Cancel").disabled(model.phase == .committing)
                } } }
                .alert("Reset all AQD data?", isPresented: $confirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset data", role: .destructive) { model.resetData(confirmation: phrase) }
                } message: { Text("Permanently replaces all local AQD records and schedules AQD-only file cleanup. Original Photos and exported archives stay. No automatic recovery.") }
        }.tint(AppTheme.ink).onAppear { if model.phase == .review { model.refresh() } else { model.prepareErase() } }
            .onChange(of: model.review?.version) { _, _ in phrase = "" }
            .interactiveDismissDisabled(model.review != nil || model.phase == .committing || model.phase == .validating)
    }
}
