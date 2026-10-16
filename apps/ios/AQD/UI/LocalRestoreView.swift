import SwiftUI
import UniformTypeIdentifiers

struct LocalRestoreView: View {
    @Bindable var model: LocalRestoreModel
    let onCancel: () -> Void
    let onInstall: (PieceStore, LocalDataCoordinator, Int) -> Void
    @State private var files = false
    @State private var confirmation = false
    var body: some View {
        NavigationStack {
            ScrollView { VStack(alignment: .leading, spacing: 20) {
                switch model.phase {
                case .choose:
                    Text("Choose a closet archive").font(AppTypography.section)
                    Text("Restore replaces this iPhone’s local closet after validation and review. Export your current data first if you want to keep a copy.")
                    Text("Archives up to \(LocalArchivePackage.maximumSizeDescription) are supported.").foregroundStyle(AppTheme.secondary)
                case .validating:
                    ProgressView("Validating archive…")
                    Text("Checking records, media, sizes and schema in a separate copy. Your current closet stays in place.")
                case .review:
                    review
                case .committing:
                    ProgressView("Restoring your closet…")
                    Text("Keep AQD open. Your previous closet is retained while the validated copy becomes active.")
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
            }.padding(20) }.background(AppTheme.canvas).navigationTitle("Restore closet").navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if model.phase != .validating && model.phase != .committing {
                        ActionFooter { ActionStack { actions } }
                    }
                }
                .toolbar { ToolbarItem(placement: .cancellationAction) { if model.phase != .complete {
                    Button { if model.cancel() { onCancel() } } label: { Image(systemName: "xmark") }.buttonBorderShape(.circle).accessibilityLabel("Cancel").disabled(model.phase == .committing)
                } } }
                .alert("Replace this iPhone’s closet?", isPresented: $confirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Replace closet", role: .destructive, action: { model.commit() })
                } message: { Text("Installs only this validated archive and replaces current AQD records, photos, history, Profile, conversations and drafts. Original Photos and exported copies stay.") }
                .fileImporter(isPresented: $files, allowedContentTypes: [.aqdArchive, .data]) { result in
                    switch result { case .success(let url): model.choose(url)
                    case .failure(let error): if (error as? CocoaError)?.code != .userCancelled { model.error = "The file couldn’t be opened. Your closet has not changed."; model.phase = .failed } }
                }
        }.tint(AppTheme.ink).onAppear { if model.phase == .review { model.refresh() } }.interactiveDismissDisabled(model.phase != .choose && model.phase != .newer && model.review != nil || model.phase == .validating || model.phase == .committing)
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

struct LocalDataCleanupView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        if let error = state.localDataCleanupError {
            VStack(alignment: .leading, spacing: 8) {
                Text(error).font(.subheadline).foregroundStyle(AppTheme.warning)
                Button("Retry local data cleanup") { state.retryLocalDataCleanup() }.frame(minHeight: 44)
            }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(AppTheme.canvas)
        }
    }
}
