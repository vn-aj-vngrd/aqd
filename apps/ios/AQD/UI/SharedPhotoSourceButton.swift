import AVFoundation
import PhotosUI
import SwiftUI

/// Selected sources dismiss before presenting the system picker or camera.
struct SharedPhotoSourceButton: View {
    let title: String
    let selectionToken: UUID
    var locked = false
    let onData: (Data) -> Void
    @State private var sources = false
    @State private var pendingSource: Bool?
    @State private var photos = false
    @State private var camera = false
    @State private var item: PhotosPickerItem?
    @State private var error: String?
    @State private var loading = false
    @State private var loadTask: Task<Void, Never>?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureRow(title: title, value: "Photos or camera") { sources = true }.disabled(locked || loading)
            if loading { ProgressView("Loading selected photo"); Button("Cancel photo loading") { cancel() }.frame(minHeight: 44) }
            if let error { SemanticFeedback(role: .danger, message: error) }
        }
        .sheet(isPresented: $sources, onDismiss: presentSource) {
            NativeChoiceSheet(title: "Add photo", footer: "Selected photos are copied into AQD on this device. iCloud Photos may download your selection. Originals stay in Photos.") {
                NativeChoiceRow(title: "Choose from Photos", symbol: "photo.on.rectangle", disclosure: false) {
                    pendingSource = false; sources = false
                }
                NativeChoiceRow(title: "Take photo", symbol: "camera", disclosure: false) {
                    pendingSource = true; sources = false
                }
            }
        }
        .photosPicker(isPresented: $photos, selection: $item, matching: .images)
        .fullScreenCover(isPresented: $camera) {
            NativeCamera(onPhoto: { data in camera = false; guard !locked else { return }; onData(data) }, onCancel: { camera = false }).ignoresSafeArea()
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
