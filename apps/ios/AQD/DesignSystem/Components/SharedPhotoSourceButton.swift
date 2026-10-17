import AVFoundation
import PhotosUI
import SwiftUI

/// One native photo-source Menu shared by every editor. The default label is a compact row
/// (or round icon); pass `label` to make a hero image the menu trigger instead.
struct SharedPhotoSourceButton<Label: View>: View {
    let title: String
    let selectionToken: UUID
    var locked = false
    var iconOnly = false
    var onEdit: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil
    let onData: (Data) -> Void
    @ViewBuilder let label: () -> Label
    @State private var cameraResult: (data: Data, token: UUID)?
    @State private var photos = false
    @State private var camera = false
    @State private var item: PhotosPickerItem?
    @State private var error: String?
    @State private var loading = false
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Menu {
                Button("Choose from Photos", systemImage: "photo.on.rectangle") { guard !locked else { return }; photos = true }
                Button("Take photo", systemImage: "camera") { openCamera() }
                if let onEdit { Divider(); Button("Edit photo", systemImage: "crop") { guard !locked else { return }; onEdit() } }
                if let onRemove { Button("Remove photo", systemImage: "trash", role: .destructive) { guard !locked else { return }; onRemove() } }
            } label: { label() }
                .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
                .accessibilityLabel(title).disabled(locked || loading)
            if loading { ProgressView("Loading selected photo"); Button("Cancel photo loading") { cancel() }.frame(minHeight: 44) }
            if let error { SemanticFeedback(role: .danger, message: error) }
        }
        .photosPicker(isPresented: $photos, selection: $item, matching: .images)
        .fullScreenCover(isPresented: $camera, onDismiss: {
            guard let result = cameraResult else { return }; cameraResult = nil
            guard result.token == selectionToken, !locked else { return }; onData(result.data)
        }) {
            NativeCamera(onPhoto: { data in cameraResult = (data, selectionToken); camera = false }, onCancel: { cameraResult = nil; camera = false }).ignoresSafeArea()
        }
        .onChange(of: item) { _, value in
            cancel(); guard let value, !locked else { return }
            let token = selectionToken; loading = true
            loadTask = Task { @MainActor in
                do {
                    guard let data = try await value.loadTransferable(type: Data.self), !Task.isCancelled, token == selectionToken, !locked else { loading = false; return }
                    loading = false; error = nil; onData(data)
                } catch { if !Task.isCancelled { loading = false; self.error = "This photo could not load. Your previous photo and fields are retained. Choose another or retry." } }
            }
        }
        .onChange(of: selectionToken) { _, _ in cancel(); item = nil }
        .onDisappear { cancel() }
    }
    private func cancel() { loadTask?.cancel(); loadTask = nil; loading = false }
    private func openCamera() {
        guard !locked else { return }
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { error = "Camera is unavailable. Choose from Photos instead."; return }
        Task { @MainActor in
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard !locked else { return }
            if granted { camera = true } else { error = "Camera access is unavailable. Choose from Photos, or enable Camera for AQD in iPhone Settings." }
        }
    }
}

extension SharedPhotoSourceButton where Label == SharedPhotoSourceRowLabel {
    init(title: String, selectionToken: UUID, locked: Bool = false, iconOnly: Bool = false,
         onEdit: (() -> Void)? = nil, onRemove: (() -> Void)? = nil, onData: @escaping (Data) -> Void) {
        self.init(title: title, selectionToken: selectionToken, locked: locked, iconOnly: iconOnly,
                  onEdit: onEdit, onRemove: onRemove, onData: onData,
                  label: { SharedPhotoSourceRowLabel(title: title, iconOnly: iconOnly) })
    }
}

struct SharedPhotoSourceRowLabel: View {
    let title: String
    let iconOnly: Bool
    var body: some View {
        if iconOnly {
            Image(systemName: "camera.fill").foregroundStyle(AppTheme.ink).frame(width: 44, height: 44)
                .glassControlSurface(Circle())
        } else {
            HStack {
                AccessoryLabel(title, systemImage: "photo")
                Spacer()
                Image(systemName: "chevron.down").font(AppTypography.disclosure).foregroundStyle(AppTheme.controlIcon).accessibilityHidden(true)
            }.foregroundStyle(AppTheme.ink).padding(.horizontal, 14).frame(minHeight: 54)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
        }
    }
}

private struct ImportedPhotoEditor<Model: PhotoEditingOwner>: ViewModifier {
    let model: Model
    let importing: Bool
    let locked: Bool
    @Binding var presented: Bool
    func body(content: Content) -> some View {
        content.onChange(of: model.completedPhotoImportID) { old, new in
            guard let new, new != old, new == model.editingPhotoID, !importing, !locked else { return }
            presented = true
        }
    }
}
extension View {
    func editImportedPhoto<Model: PhotoEditingOwner>(_ model: Model, importing: Bool, locked: Bool, presented: Binding<Bool>) -> some View {
        modifier(ImportedPhotoEditor(model: model, importing: importing, locked: locked, presented: presented))
    }
}
