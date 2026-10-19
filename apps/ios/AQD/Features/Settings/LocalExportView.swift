import AQDCore
import SwiftUI
import UniformTypeIdentifiers

extension UTType { static let aqdArchive = UTType(exportedAs: "app.aqd.local-archive", conformingTo: .data) }
struct LocalArchiveDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.aqdArchive] }
    let data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents, data.count <= LocalArchivePackage.maximumBytes else { throw LocalArchiveError.invalid }; self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
struct LocalExportView: View {
    @Environment(AppState.self) private var state
    @State private var model: LocalExportModel?
    var body: some View {
        Group { if let model { LocalExportContent(model: model) } else { LoadingStatePage(title: "Opening export") } }
            .navigationTitle("Export closet").navigationBarTitleDisplayMode(.inline)
            .onAppear { if model == nil, let store = state.store { model = LocalExportModel(store: store) } }
            .onDisappear { model?.cancel() }
    }
}
private struct LocalExportContent: View {
    @Bindable var model: LocalExportModel
    @State private var files = false
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 20) {
            Text("Keep a private copy").font(AppTypography.section)
            Text("Includes pieces and photos, outfits/themes, plans/routines/trips, recorded wear, identity/preferences, fit memories, Today layouts and retained content, conversations, recoverable drafts and operation receipts.")
            Text("Archives up to \(LocalArchivePackage.maximumSizeDescription). Larger closets cannot be exported in this version; your current data stays in place.").font(.subheadline).foregroundStyle(AppTheme.secondary)
            Text("Choose where to save in Files. A destination may use cloud storage. This archive contains sensitive private data and is not encrypted by AQD at its chosen destination.").font(.subheadline).foregroundStyle(AppTheme.secondary)
            switch model.phase {
            case .idle: EmptyView()
            case .preparing:
                ProgressView("Preparing your archive…")
                Text("Your existing closet stays in place.")
            case .failed:
                Text(model.error ?? "The archive couldn’t be prepared.").foregroundStyle(AppTheme.error)
            case .ready:
                Text("Your archive is ready.").font(AppTypography.section)
                if let summary = model.summary { LocalDataSummaryView(summary: summary) }
                if let data = model.data { Text(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)).font(.footnote) }
                if let result = model.fileResult { Text(result).font(.subheadline) }
            }
        }.padding(20) }.background(AppTheme.canvas)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ActionFooter {
                    ActionStack {
                        switch model.phase {
                        case .idle: PrimaryAction(title: "Create archive", action: model.start)
                        case .preparing: SecondaryAction(title: "Cancel export", action: model.cancel)
                        case .failed: PrimaryAction(title: "Try again", action: model.start)
                        case .ready:
                            PrimaryAction(title: "Save to Files") { files = true }
                            SecondaryAction(title: "Prepare a new archive", action: model.start)
                        }
                    }
                }
            }
            .fileExporter(isPresented: $files, document: model.data.map(LocalArchiveDocument.init), contentType: .aqdArchive,
                defaultFilename: "AQD-closet-\(Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash)))") { result in
                    switch result {
                    case .success: model.fileResult = "Files confirmed the archive was saved. Protect your exported copy."
                    case .failure(let error): model.fileResult = (error as? CocoaError)?.code == .userCancelled ? "Files was cancelled. The prepared archive is still here." : "Files couldn’t confirm saving. Your prepared archive and closet are retained; try Save to Files again."
                    }
                }
    }
}
