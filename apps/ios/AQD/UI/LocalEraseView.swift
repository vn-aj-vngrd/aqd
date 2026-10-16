import SwiftUI

struct LocalEraseView: View {
    @Bindable var model: LocalRestoreModel
    let onCancel: () -> Void
    let onInstall: (PieceStore, LocalDataCoordinator, Int) -> Void
    @State private var phrase = ""
    @State private var confirm = false
    @State private var export = false
    var body: some View {
        NavigationStack {
            ScrollView { VStack(alignment: .leading, spacing: 20) {
                switch model.phase {
                case .choose, .validating:
                    ProgressView("Preparing local erase review…")
                case .review:
                    Text("Remove this closet?").font(.title2)
                    if let summary = model.review?.originalSummary { Text(summary.description) }
                    else { Text("Current data could not be fully validated. Erase replaces all AQD local data on this iPhone.") }
                    Text("Erases wardrobe, themes, plans, wear history, identity, preferences, private memories, Today content, conversations, drafts, Undo and AQD photos/derived files.")
                    Text("Original images in Photos and archives you exported are not deleted. There is no account or cloud copy to restore automatically.").font(.subheadline).foregroundStyle(AppTheme.secondary)
                    SecondaryAction(title: "Export first") { export = true }
                    TextField("Type ERASE to confirm", text: $phrase).textInputAutocapitalization(.characters).autocorrectionDisabled().padding(14).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                    Button("Erase this closet", role: .destructive) { confirm = true }.frame(maxWidth: .infinity, minHeight: 50).buttonStyle(.borderedProminent).tint(AppTheme.dangerFill).disabled(phrase != "ERASE")
                case .committing:
                    ProgressView("Erasing local records…")
                    Text("Keep AQD open. Record acknowledgment and AQD file cleanup are tracked separately.")
                case .complete:
                    Text("Your local records are erased.").font(.title2)
                    Text("The previous AQD files are queued for safe removal after the old store closes. Any pending cleanup stays visible. Original Photos and exported copies remain outside AQD.")
                    PrimaryAction(title: "Start again") { if let store = model.installed { onInstall(store, model.coordinator, 0) } }
                case .failed, .newer:
                    Text("Erase wasn’t completed").font(.title2)
                    Text(model.error ?? "Your previous local records are retained.").foregroundStyle(AppTheme.error)
                    if model.review != nil { PrimaryAction(title: "Review current impact again") { model.refresh(); phrase = "" } }
                    else { PrimaryAction(title: "Prepare review again", action: model.prepareErase) }
                case .unknown:
                    Text("Check the erase outcome").font(.title2)
                    Text(model.error ?? "Check the same operation before erasing again. A completed switch cannot be undone by cancelling.")
                    PrimaryAction(title: "Check same operation", action: model.checkOutcome)
                }
            }.padding(20) }.background(AppTheme.canvas).navigationTitle("Erase local closet").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { if model.phase != .complete {
                    Button { if model.cancel() { onCancel() } } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel("Cancel").disabled(model.phase == .committing)
                } } }
                .alert("Erase this local closet?", isPresented: $confirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Erase closet", role: .destructive) { model.commit(confirmation: phrase) }
                } message: { Text("Permanently replaces all local AQD records and schedules AQD-only file cleanup. Original Photos and exported archives stay. No automatic recovery.") }
                .sheet(isPresented: $export) { NavigationStack { LocalExportView().navigationTitle("Export before erase").toolbar { ToolbarItem(placement: .confirmationAction) { Button { export = false } label: { Image(systemName: "checkmark") }.accessibilityLabel("Done") } } } }
        }.tint(AppTheme.ink).onAppear { model.prepareErase() }
            .onChange(of: model.review?.version) { _, _ in phrase = "" }
            .interactiveDismissDisabled(model.review != nil || model.phase == .committing || model.phase == .validating)
    }
}
