import SwiftUI
import UniformTypeIdentifiers

struct LocalRestoreView: View {
    @Bindable var model: LocalRestoreModel
    let onCancel: () -> Void
    let onInstall: (PieceStore, LocalDataCoordinator, Int) -> Void
    var embedded = false
    @State private var files = false
    @State private var confirmation = false
    var body: some View {
        container {
            ScrollView { VStack(alignment: .leading, spacing: 20) {
                switch model.phase {
                case .choose:
                    Text("Choose a closet archive").font(AppTypography.section)
                    Text("Restore replaces this iPhone’s local closet after validation and review. Export your current data first if you want to keep a copy.")
                    Text("Archives up to \(LocalArchivePackage.maximumSizeDescription) are supported.").foregroundStyle(AppTheme.secondary)
                case .validating, .committing:
                    EmptyView()
                case .review:
                    review
                case .complete:
                    Text("Your closet is restored.").font(AppTypography.section)
                    if let value = model.review { LocalDataSummaryView(summary: value.incomingSummary) }
                    Text("The archive replaced your previous local data. Previous AQD files are queued for safe cleanup after the old store closes.").foregroundStyle(AppTheme.secondary)
                case .failed:
                    Text("Restore couldn’t finish").font(AppTypography.section)
                    if let error = model.error { Text(error).foregroundStyle(AppTheme.error) }
                case .newer:
                    Text("A newer AQD is needed.").font(AppTypography.section)
                    Text(model.error ?? "This archive uses a newer format. Your current data is retained.")
                case .unknown:
                    Text("Check the restore outcome").font(AppTypography.section)
                    Text(model.error ?? "Your operation needs reconciliation before another replacement.")
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(20) }.background(AppTheme.canvas.ignoresSafeArea())
                .overlay { loadingState }
                .navigationTitle("Restore closet").navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if model.phase != .validating && model.phase != .committing {
                        ActionFooter { ActionStack { actions } }
                    }
                }
                .toolbar { ToolbarItem(placement: .cancellationAction) { if !embedded && model.phase != .complete {
                    Button { if model.cancel() { onCancel() } } label: { Image(systemName: "xmark") }.buttonBorderShape(.circle).accessibilityLabel("Cancel").disabled(model.phase == .committing)
                } } }
                .appConfirmation("Replace this iPhone’s closet?", isPresented: $confirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Replace closet", role: .destructive, action: { model.commit() })
                } message: { Text("Installs only this validated archive and replaces current AQD records, photos, history, Profile, conversations and drafts. Original Photos and exported copies stay.") }
                .fileImporter(isPresented: $files, allowedContentTypes: [.aqdArchive, .data]) { result in
                    switch result { case .success(let url): model.choose(url)
                    case .failure(let error): if (error as? CocoaError)?.code != .userCancelled { model.error = "The file couldn’t be opened. Your closet has not changed."; model.phase = .failed } }
                }
        }.tint(AppTheme.ink).onAppear { if model.phase == .review { model.refresh() } }.interactiveDismissDisabled(model.phase != .choose && model.phase != .newer && model.review != nil || model.phase == .validating || model.phase == .committing)
    }

    /// Pushed from Settings it is a page with the system back button; elsewhere it brings its own stack.
    @ViewBuilder private func container(@ViewBuilder _ content: () -> some View) -> some View {
        if embedded {
            content().navigationBarBackButtonHidden(model.phase == .validating || model.phase == .committing)
        } else { NavigationStack { content() } }
    }
    /// Centered like every other waiting page, instead of a spinner stranded at the top of a scroll view.
    @ViewBuilder private var loadingState: some View {
        switch model.phase {
        case .validating:
            LoadingStatePage(title: "Validating archive",
                             description: Text("Checking records, media, sizes and schema in a separate copy. Your current closet stays in place."))
                .background(AppTheme.canvas.ignoresSafeArea())
        case .committing:
            LoadingStatePage(title: "Restoring your closet",
                             description: Text("Keep AQD open. Your previous closet is retained while the validated copy becomes active."))
                .background(AppTheme.canvas.ignoresSafeArea())
        default: EmptyView()
        }
    }
    @ViewBuilder private var actions: some View {
        switch model.phase {
        case .choose: PrimaryAction(title: "Choose archive") { files = true }
        case .review:
            PrimaryAction(title: "Restore this archive") { confirmation = true }
            SecondaryAction(title: "Choose another file") { files = true }
        case .complete:
            PrimaryAction(title: "Open Closet") { install(destination: 1) }
            SecondaryAction(title: "Open Today") { install(destination: 0) }
        case .failed:
            if model.review != nil {
                PrimaryAction(title: "Try the reviewed operation again", action: { model.commit() })
                SecondaryAction(title: "Review current replacement again", action: model.refresh)
            }
            SecondaryAction(title: "Choose another archive") { files = true }
        case .newer: PrimaryAction(title: "Choose another file") { files = true }
        case .unknown:
            PrimaryAction(title: "Check same operation", action: model.checkOutcome)
            if model.source == nil { SecondaryAction(title: "Choose another archive for recovery") { files = true } }
        case .validating, .committing: EmptyView()
        }
    }
    @ViewBuilder private var review: some View {
        if let value = model.review {
            Text(model.sourceName ?? "Validated closet archive").font(AppTypography.section)
            LocalDataSummaryView(summary: value.incomingSummary)
            if let version = value.migratedFrom { Text("This archive was migrated from local schema \(version). IDs and records are preserved.").font(.footnote).foregroundStyle(AppTheme.secondary) }
            Text("Replaces current local data").font(.headline)
            if let original = value.originalSummary { LocalDataSummaryView(summary: original) }
            else { Text("Current data could not be fully validated. Existing files are retained until replacement is confirmed.") }
            Text("The replacement includes identity, preferences, Today content, conversations and drafts. It is not a merge. Export your current closet first if you want to retain it.").foregroundStyle(AppTheme.secondary)
        }
    }
    private func install(destination: Int) { if let store = model.installed { onInstall(store, model.coordinator, destination) } }
}
