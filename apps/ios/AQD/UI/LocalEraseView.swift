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
                    ProgressView("Preparing local erase review…")
                case .review:
                    Label("Erase this closet", systemImage: "trash").font(AppTypography.section)
                    Text("Remove AQD’s local data from this iPhone.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    if let summary = model.review?.originalSummary { LocalDataSummaryView(summary: summary) }
                    else { Text("Current data could not be fully validated. Erase replaces all AQD local data on this iPhone.") }
                    Text("Also removes your local profile, preferences, Today layout and content, Undo history, and AQD-owned photo copies.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    Text("Original images in Photos and archives you exported are not deleted. There is no account or cloud copy to restore automatically.").font(.subheadline).foregroundStyle(AppTheme.secondary)
                    NavigationLink { LocalExportView().navigationTitle("Export before erase").secondaryPage() } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up").accessibilityHidden(true)
                            Text("Export a copy first")
                            Spacer(minLength: 12)
                            Image(systemName: "chevron.forward").font(AppTypography.disclosure).accessibilityHidden(true)
                        }.font(AppTypography.supporting).foregroundStyle(AppTheme.ink).frame(minHeight: 44)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type ERASE to continue").font(AppTypography.fieldLabel)
                        TextField("ERASE", text: $phrase).textInputAutocapitalization(.characters).autocorrectionDisabled()
                            .font(AppTypography.body).padding(14).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityLabel("Type ERASE to confirm")
                        Text("This action can’t be undone.").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    }
                case .committing:
                    ProgressView("Erasing local records…")
                    Text("Keep AQD open. Record acknowledgment and AQD file cleanup are tracked separately.")
                case .complete:
                    Text("Your local records are erased.").font(.title2)
                    Text("The previous AQD files are queued for safe removal after the old store closes. Any pending cleanup stays visible. Original Photos and exported copies remain outside AQD.")
                case .failed, .newer:
                    Text("Erase wasn’t completed").font(.title2)
                    Text(model.error ?? "Your previous local records are retained.").foregroundStyle(AppTheme.error)
                case .unknown:
                    Text("Check the erase outcome").font(.title2)
                    Text(model.error ?? "Check the same operation before erasing again. A completed switch cannot be undone by cancelling.")
                }
            }.padding(20) }.background(AppTheme.canvas).navigationTitle("Erase local closet").navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if model.phase != .choose && model.phase != .validating && model.phase != .committing {
                        ActionFooter {
                            switch model.phase {
                            case .review:
                                PrimaryAction(title: "Erase closet", systemImage: "trash", role: .destructive) { confirm = true }
                                    .disabled(phrase != "ERASE")
                            case .complete:
                                PrimaryAction(title: "Start again") { if let store = model.installed { onInstall(store, model.coordinator, 0) } }
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
                .alert("Erase this local closet?", isPresented: $confirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Erase closet", role: .destructive) { model.commit(confirmation: phrase) }
                } message: { Text("Permanently replaces all local AQD records and schedules AQD-only file cleanup. Original Photos and exported archives stay. No automatic recovery.") }
        }.tint(AppTheme.ink).onAppear { if model.phase == .review { model.refresh() } else { model.prepareErase() } }
            .onChange(of: model.review?.version) { _, _ in phrase = "" }
            .interactiveDismissDisabled(model.review != nil || model.phase == .committing || model.phase == .validating)
    }
}
