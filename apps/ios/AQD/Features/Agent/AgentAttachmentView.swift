import AQDCore
import AVFoundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

enum AgentAttachmentSource: String, CaseIterable, Identifiable {
    case camera = "Camera", photos = "Photos", files = "Files"
    var id: Self { self }
    var icon: String { switch self { case .camera: "camera"; case .photos: "photo"; case .files: "folder" } }
}

/// Native pickers return directly to the composer rather than an intermediate form.
struct AgentAttachmentPicker: ViewModifier {
    @Bindable var model: AgentModel
    @Bindable var importer: AgentAttachmentImporter
    @Binding var source: AgentAttachmentSource?
    @Binding var presented: Bool
    @State private var photos = false
    @State private var files = false
    @State private var camera = false
    @State private var items: [PhotosPickerItem] = []
    @State private var importedItems: [PhotosPickerItem] = []
    @State private var cameraData: Data?
    @State private var permission: Task<Void, Never>?
    func body(content: Content) -> some View {
        content
            .onChange(of: source) { _, value in
                guard let value else { return }; source = nil; presented = true
                switch value {
                case .photos: importedItems = []; items = []; photos = true
                case .files: files = true
                case .camera: openCamera()
                }
            }
            .photosPicker(isPresented: $photos, selection: $items, maxSelectionCount: max(1, AgentAttachment.maximumCount - importer.count), selectionBehavior: .ordered, matching: .images)
            .onChange(of: items) { _, _ in if !photos { importPhotos() } }
            .onChange(of: photos) { _, shown in if !shown { presented = files || camera; importPhotos() } }
            .onChange(of: files) { _, shown in if !shown { presented = photos || camera } }
            .fileImporter(isPresented: $files, allowedContentTypes: [.image, .pdf, .plainText, UTType(filenameExtension: "md") ?? .plainText], allowsMultipleSelection: true) { selection in
                switch selection {
                case .success(let urls):
                    for url in urls {
                        importer.add(name: url.lastPathComponent) {
                            let accessed = url.startAccessingSecurityScopedResource(); defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                            let values = try url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
                            guard (values.fileSize ?? 0) <= 20 * 1024 * 1024 else { throw AgentAttachmentReader.Failure.tooLarge }
                            let type = values.contentType
                            guard type?.conforms(to: .image) == true || type?.conforms(to: .pdf) == true || type?.conforms(to: .text) == true || url.pathExtension.lowercased() == "md" else { throw AgentAttachmentReader.Failure.unsupported }
                            return try await AgentAttachmentReader.prepare(data: Data(contentsOf: url, options: .mappedIfSafe), name: url.lastPathComponent, image: type?.conforms(to: .image) == true, pdf: type?.conforms(to: .pdf) == true)
                        }
                    }
                case .failure(let error): if (error as NSError).code != NSUserCancelledError { model.error = "The file couldn’t open. Your message and attachments are retained. Choose again." }
                }
            }
            .fullScreenCover(isPresented: $camera, onDismiss: {
                presented = false
                guard let data = cameraData else { return }; cameraData = nil
                importer.add(name: "Camera photo") { try await AgentAttachmentReader.prepare(data: data, name: "Camera photo", image: true) }
            }) { NativeCamera(onPhoto: { cameraData = $0; camera = false }, onCancel: { camera = false }).ignoresSafeArea() }
            .onDisappear { permission?.cancel() }
    }
    private func importPhotos() {
        for value in items where !importedItems.contains(value) {
            importedItems.append(value)
            importer.add(name: "Photo") {
                guard let data = try await value.loadTransferable(type: Data.self) else { throw AgentAttachmentReader.Failure.unreadable }
                return try await AgentAttachmentReader.prepare(data: data, name: "Photo", image: true)
            }
        }
    }
    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { presented = false; model.error = "Camera is unavailable. Choose Photos or Files instead."; return }
        permission?.cancel()
        permission = Task { @MainActor in
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard !Task.isCancelled else { return }
            if granted { camera = true } else { presented = false; model.error = "Allow Camera for AQD in iPhone Settings, or choose Photos or Files." }
        }
    }
}

struct AgentAttachmentStrip: View {
    let attachments: [AgentAttachment]
    var pending: [AgentAttachmentImporter.Pending] = []
    var order: [UUID] = []
    var remove: ((UUID) -> Void)?
    var cancelImport: ((UUID) -> Void)?
    var locked = false
    @Environment(AppState.self) private var state
    @Environment(\.dynamicTypeSize) private var textSize
    private var tileSize: CGFloat { textSize.isAccessibilitySize ? 140 : 104 }
    @State private var selected: AgentAttachment?
    @State private var importError: String?
    private var visibleIDs: [UUID] {
        let ids = attachments.map(\.id) + pending.map(\.id)
        return order.filter { ids.contains($0) } + ids.filter { !order.contains($0) }
    }
    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: AppSpacing.small) {
                ForEach(visibleIDs, id: \.self) { id in
                    if let attachment = attachments.first(where: { $0.id == id }) {
                        tile(name: attachment.name, id: attachment.id, action: { selected = attachment }, remove: remove) {
                            if let data = attachment.preview, let image = UIImage(data: data) {
                                Image(uiImage: image).resizable().scaledToFill().frame(width: tileSize, height: tileSize).clipped()
                            } else {
                                VStack(spacing: AppSpacing.small) {
                                    if !textSize.isAccessibilitySize { Image(systemName: "doc.text").font(.title2).foregroundStyle(AppTheme.controlIcon) }
                                    Text(attachment.name).font(AppTypography.metadata).foregroundStyle(AppTheme.ink).lineLimit(2).multilineTextAlignment(.center)
                                }.padding(AppSpacing.small).frame(width: tileSize, height: tileSize)
                            }
                        }
                    } else if let item = pending.first(where: { $0.id == id }) {
                        tile(name: item.name, id: item.id, action: { importError = item.error }, remove: cancelImport, removalLocked: false) {
                            VStack(spacing: AppSpacing.small) {
                                if item.error != nil { Image(systemName: "exclamationmark.circle").foregroundStyle(AppTheme.error); Text("Couldn’t load").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary) }
                                else { AgentWorkingIndicator(title: "Loading…") }
                            }.frame(width: tileSize, height: tileSize)
                        }.accessibilityLabel(item.error ?? "Loading \(item.name)")
                    }
                }
            }.padding(.vertical, AppSpacing.xSmall)
        }.frame(height: tileSize + 2 * AppSpacing.xSmall)
            .appConfirmation("Attachment couldn’t load", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK", role: .cancel) { importError = nil }
        } message: { Text(importError ?? "Remove this attachment and choose again.") }
            .scrollIndicators(.hidden).defaultScrollAnchor(remove == nil ? .trailing : .leading)
            .sheet(item: $selected) { attachment in
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.large) {
                            if let data = attachment.preview, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 420) }
                            Text(attachment.method).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                            if attachment.partial { Text("Partial text excerpt. The full document is not included.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                            if !attachment.text.isEmpty { Text(attachment.text).textSelection(.enabled) }
                            Text(attachment.kind == .image ? "A resized image is stored privately with this chat. Original full-resolution files aren’t retained." : "This chat stores the prepared text excerpt, not the original file.")
                                .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                        }.padding(AppSpacing.screen)
                    }.background(AppTheme.canvas).navigationTitle(attachment.name).navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { ToolbarSaveAction(title: "Done") { selected = nil } } }
                }.appAppearance(state.appearance)
            }
    }
    private func tile<Content: View>(name: String, id: UUID, action: @escaping () -> Void, remove: ((UUID) -> Void)?, removalLocked: Bool? = nil, @ViewBuilder content: () -> Content) -> some View {
        Button(action: action) { content().background(AppTheme.imageGround).clipShape(RoundedRectangle(cornerRadius: AppRadius.field)) }
            .buttonStyle(.plain).accessibilityLabel("Open \(name)")
            .overlay(alignment: .topTrailing) {
                if let remove {
                    Button { remove(id) } label: {
                        Image(systemName: "xmark").font(.system(size: 11, weight: .semibold)).foregroundStyle(AppTheme.onMedia)
                            .frame(width: 22, height: 22).background(AppTheme.mediaChip, in: Circle())
                            .frame(width: 44, height: 44)
                    }.buttonStyle(.plain).accessibilityLabel("Remove \(name)").disabled(removalLocked ?? locked)
                }
            }
    }
}
