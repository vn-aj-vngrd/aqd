import AQDCore
import AVFoundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

enum AgentAttachmentSource: String, CaseIterable, Identifiable {
    case camera = "Camera", photos = "Photos", files = "Files"
    var id: Self { self }
    var icon: String { switch self { case .camera: "camera"; case .photos: "photo"; case .files: "paperclip" } }
}

struct AgentAttachmentView: View {
    @Bindable var model: AgentModel
    let source: AgentAttachmentSource
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var didChoose = false
    @State private var photos = false
    @State private var files = false
    @State private var camera = false
    @State private var photo: PhotosPickerItem?
    @State private var cameraData: Data?
    @State private var text = ""
    @State private var result: AgentAttachmentReader.Result?
    @State private var error: String?
    @State private var loading = false
    @State private var task: Task<Void, Never>?
    @State private var timeout: Task<Void, Never>?
    @State private var token = UUID()
    @State private var appended = false
    @State private var retrySave = false
    var body: some View {
        Form {
            if loading {
                Section { HStack { ProgressView(); Text("Preparing attachment…") }; Button("Cancel processing") { cancel() } }
            } else if let result {
                Section {
                    Label(result.name, systemImage: source.icon).lineLimit(2)
                    Text(result.method).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    if result.partial { Text("Partial attachment. Only the first readable section is included.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                    TextEditor(text: $text).frame(minHeight: 180).disabled(appended).accessibilityLabel("Attachment text to include")
                    Text("\(text.count) / \(AgentAttachmentPolicy.maximumCharacters)").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                } header: { Text("Review before adding") } footer: { Text("Only this text is added to your message. The original file or photo is not saved in chat. Nothing is sent automatically.") }
            } else if error == nil {
                Section { Text("Choose an attachment to prepare a local text reference.").foregroundStyle(AppTheme.secondary) }
            }
            if let error { Section { SemanticFeedback(role: .danger, message: error) } }
            if !loading && !appended { Section { Button("Choose \(source.rawValue.lowercased())", action: choose) } }
            if retrySave { Section { Button("Retry draft save") { if model.persist() { retrySave = false; dismiss() } else { error = model.error } } } }
        }.scrollContentBackground(.hidden).background(AppTheme.canvas).navigationTitle("Add attachment").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button { cancel(); dismiss() } label: { Image(systemName: "xmark") }.accessibilityLabel("Close attachment").disabled(retrySave) }
                ToolbarItem(placement: .confirmationAction) { ToolbarSaveAction(title: "Add") { add() }.disabled(loading || result == nil || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text.count > AgentAttachmentPolicy.maximumCharacters || appended || !model.canGenerate) }
            }.interactiveDismissDisabled(retrySave)
            .photosPicker(isPresented: $photos, selection: $photo, matching: .images)
            .onChange(of: photo) { _, item in
                guard let item else { return }
                start {
                    guard let data = try await item.loadTransferable(type: Data.self) else { throw AgentAttachmentReader.Failure.unreadable }
                    return try await AgentAttachmentReader.perform { try await AgentAttachmentReader.read(data: data, name: "Selected photo", image: true) }
                }
            }
            .fileImporter(isPresented: $files, allowedContentTypes: [.image, .pdf, .plainText, UTType(filenameExtension: "md") ?? .plainText]) { selection in
                switch selection {
                case .success(let url):
                    start {
                        try await AgentAttachmentReader.perform {
                            let accessed = url.startAccessingSecurityScopedResource(); defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                            let values = try url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
                            guard (values.fileSize ?? 0) <= 20 * 1024 * 1024 else { throw AgentAttachmentReader.Failure.tooLarge }
                            let type = values.contentType
                            guard type?.conforms(to: .image) == true || type?.conforms(to: .pdf) == true || type?.conforms(to: .text) == true || url.pathExtension.lowercased() == "md" else { throw AgentAttachmentReader.Failure.unsupported }
                            return try await AgentAttachmentReader.read(data: Data(contentsOf: url, options: .mappedIfSafe), name: url.lastPathComponent, image: type?.conforms(to: .image) == true, pdf: type?.conforms(to: .pdf) == true)
                        }
                    }
                case .failure(let failure): if (failure as NSError).code != NSUserCancelledError { error = "The file couldn’t open. Try choosing it again." }
                }
            }
            .fullScreenCover(isPresented: $camera, onDismiss: {
                guard let data = cameraData else { return }; cameraData = nil
                start { try await AgentAttachmentReader.perform { try await AgentAttachmentReader.read(data: data, name: "Camera photo", image: true) } }
            }) { NativeCamera(onPhoto: { cameraData = $0; camera = false }, onCancel: { camera = false }).ignoresSafeArea() }
            .task { if !didChoose { didChoose = true; choose() } }.onDisappear { cancel() }
            .onChange(of: scenePhase) { _, phase in if phase == .background { cancel(); error = "Attachment preparation paused. Your draft is unchanged. Choose the attachment again." } }
    }
    private func choose() {
        error = nil
        switch source {
        case .photos: photo = nil; photos = true
        case .files: files = true
        case .camera:
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else { error = "Camera is unavailable on this device. Use Photos or Files instead."; return }
            task = Task { @MainActor in
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                guard !Task.isCancelled else { return }
                if granted { camera = true } else { error = "Allow Camera for AQD in iPhone Settings, or choose Photos or Files." }
            }
        }
    }
    private func start(_ operation: @escaping @Sendable () async throws -> AgentAttachmentReader.Result) {
        cancel(); loading = true; error = nil; result = nil; let current = token
        task = Task { @MainActor in
            do {
                let value = try await operation()
                guard !Task.isCancelled, token == current else { return }
                result = value; text = value.text; loading = false; timeout?.cancel()
            } catch { guard !Task.isCancelled, token == current else { return }; loading = false; self.error = (error as? LocalizedError)?.errorDescription ?? "Attachment processing failed. Your draft is unchanged. Try again."; timeout?.cancel() }
        }
        timeout = Task { @MainActor in
            try? await Task.sleep(for: .seconds(60)); guard !Task.isCancelled, token == current, loading else { return }
            cancel(); error = AgentAttachmentReader.Failure.timeout.errorDescription
        }
    }
    private func cancel() { token = UUID(); task?.cancel(); task = nil; timeout?.cancel(); timeout = nil; loading = false }
    private func add() {
        guard let result, !appended, model.canGenerate else { return }
        do {
            let addition = try AgentAttachmentPolicy.draftText(name: result.name, method: result.method, text: text)
            let original = model.conversation.draft
            model.updateDraft(original + (original.isEmpty ? "" : "\n\n") + addition); appended = true
            if model.persist() { dismiss() } else { retrySave = true; error = model.error }
        } catch { self.error = "Review the attachment text before adding it." }
    }
}
