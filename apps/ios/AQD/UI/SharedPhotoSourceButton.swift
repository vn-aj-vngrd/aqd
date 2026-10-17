import AVFoundation
import PhotosUI
import SwiftUI

/// Selected sources dismiss before presenting the system picker or camera.
struct SharedPhotoSourceButton: View {
    let title: String
    let selectionToken: UUID
    var locked = false
    var presentation: Binding<Bool>? = nil
    var iconOnly = false
    var onEdit: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil
    let onData: (Data) -> Void
    @State private var sources = false
    @State private var pendingSource: Bool?
    @State private var pendingAction: (() -> Void)?
    @State private var cameraResult: (data: Data, token: UUID)?
    @State private var photos = false
    @State private var camera = false
    @State private var item: PhotosPickerItem?
    @State private var error: String?
    @State private var loading = false
    @State private var loadTask: Task<Void, Never>?
    private var sourcePresentation: Binding<Bool> { presentation ?? $sources }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { sourcePresentation.wrappedValue = true } label: {
                if iconOnly {
                    Image(systemName: "camera.fill").foregroundStyle(AppTheme.ink).frame(width: 44, height: 44)
                        .raisedSurface(Circle())
                } else {
                    HStack {
                        AccessoryLabel(title, systemImage: "photo")
                        Spacer()
                        Image(systemName: "chevron.down").font(AppTypography.disclosure).foregroundStyle(AppTheme.controlIcon).accessibilityHidden(true)
                    }.foregroundStyle(AppTheme.ink).padding(.horizontal, 14).frame(minHeight: 54)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
                }
            }.buttonStyle(.plain).accessibilityLabel(title).disabled(locked || loading)
                .popover(isPresented: sourcePresentation, arrowEdge: .top) {
                    PhotoSourcePopover(photos: { pendingSource = false; sourcePresentation.wrappedValue = false },
                                       camera: { pendingSource = true; sourcePresentation.wrappedValue = false },
                                       edit: onEdit.map { action in { pendingAction = action; sourcePresentation.wrappedValue = false } },
                                       remove: onRemove.map { action in { pendingAction = action; sourcePresentation.wrappedValue = false } })
                        .onDisappear(perform: presentSource)
                }
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
    private func presentSource() {
        if let action = pendingAction { pendingAction = nil; guard !locked else { return }; action(); return }
        guard let source = pendingSource else { return }; pendingSource = nil
        guard !locked else { return }
        if !source { photos = true; return }
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { error = "Camera is unavailable. Choose from Photos instead."; return }
        Task { @MainActor in
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard !locked else { return }
            if granted { camera = true } else { error = "Camera access is unavailable. Choose from Photos, or enable Camera for AQD in iPhone Settings." }
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
