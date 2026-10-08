import AQDCore
import AVFoundation
import PhotosUI
import SwiftUI

struct PieceCaptureView: View {
    @Bindable var model: CaptureModel
    @State private var sourceSheet = false
    @State private var pickerPresented = false
    @State private var cameraPresented = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var pendingSource: PhotoSource?
    @State private var cameraData: Data?
    @State private var showDetails = false
    @State private var showPhotoEditor = false
    @State private var discardDecision = false
    @State private var cameraDenied = false
    @State private var cameraUnavailable = false
    @AccessibilityFocusState private var photoFocused: Bool

    private enum PhotoSource { case photos, camera }

    var body: some View {
        NavigationStack {
            Group {
                if let saved = model.saved {
                    receipt(saved)
                } else {
                    form
                }
            }
            .background(AppTheme.canvas)
            .navigationTitle(model.saved == nil ? (model.draft.baseRevision == nil ? "Add piece" : "Edit piece") : "Piece saved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { leave() } label: { Label("Back", systemImage: "chevron.left") }
                        .accessibilityIdentifier("capture.back")
                        .disabled(model.isSaving)
                }
                if model.saved == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { discardDecision = true } label: {
                            Label("Discard draft", systemImage: "trash")
                        }
                        .disabled(model.isSaving || model.isImporting)
                        .accessibilityIdentifier("capture.discard")
                    }
                }
            }
            .confirmationDialog("Discard this draft?", isPresented: $discardDecision, titleVisibility: .visible) {
                Button("Discard draft", role: .destructive) { model.discard() }
                Button("Keep editing", role: .cancel) {}
            } message: {
                Text(model.draftSaveFailed
                     ? "The latest changes couldn’t be kept. Discard removes only this piece draft, not saved pieces or original Photos."
                     : "Discard removes only this recoverable edit and its unused AQD photo edits. Saved pieces and original Photos stay unchanged.")
            }
            .alert("Camera access is off", isPresented: $cameraDenied) {
                Button("Choose from Photos") { pickerPresented = true }
                Button("Keep draft", role: .cancel) {}
            } message: {
                Text("Allow Camera in iPhone Settings to take a photo, or choose an existing photo. Your entered fields are unchanged.")
            }
            .alert("Camera isn’t available", isPresented: $cameraUnavailable) {
                Button("Choose from Photos") { pickerPresented = true }
                Button("Keep draft", role: .cancel) {}
            }
        }
        .tint(AppTheme.actionText)
        .interactiveDismissDisabled(model.isSaving || model.draftSaveFailed)
        .photosPicker(isPresented: $pickerPresented, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            model.importPhoto { try await item.loadTransferable(type: Data.self) }
            selectedPhoto = nil
        }
        .sheet(isPresented: $sourceSheet, onDismiss: presentPendingSource) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 0) {
                        sourceRow("Choose from Photos", symbol: "photo.on.rectangle", source: .photos)
                        Divider().padding(.leading, 20)
                        sourceRow("Take photo", symbol: "camera", source: .camera)
                    }
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    Text("Selected photos are copied into AQD on this device. iCloud Photos may download your selection. Originals stay in Photos.")
                        .font(.footnote).foregroundStyle(AppTheme.secondary)
                    Spacer(minLength: 0)
                }
                .padding(20).background(AppTheme.canvas)
                .navigationTitle("Add photo").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { sourceSheet = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $cameraPresented, onDismiss: {
            if let cameraData {
                model.importPhoto { cameraData }
                self.cameraData = nil
            }
            photoFocused = true
        }) {
            NativeCamera(onPhoto: { data in cameraData = data; cameraPresented = false },
                         onCancel: { cameraPresented = false })
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showDetails) { PieceDetailsView(model: model) }
        .sheet(isPresented: $showPhotoEditor) { PhotoEditorView(model: model) }
        .onDisappear { model.cancelImport() }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Photo").font(.subheadline)
                        Spacer()
                        if model.draft.photoID != nil {
                            Menu("Change") {
                                Button("Choose from Photos", systemImage: "photo.on.rectangle") { pickerPresented = true }
                                Button("Take photo", systemImage: "camera") { requestCamera() }
                                Button("Remove photo", systemImage: "trash", role: .destructive) { model.removePhoto() }
                            }
                            .frame(minWidth: 44, minHeight: 44)
                            .disabled(model.isImporting || model.isSaving)
                        }
                    }
                    if let data = model.photoData(), let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFit()
                            .frame(width: 168, height: 224)
                            .background(AppTheme.imageGround)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(model.draft.photoRecipe.crop == nil ? "Selected piece photo, entire image fitted" : "Selected piece photo, portrait crop")
                        Button("Edit photo") { showPhotoEditor = true }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .disabled(model.isImporting || model.isSaving)
                            .accessibilityIdentifier("capture.editPhoto")
                    } else {
                        Button { sourceSheet = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "photo").accessibilityHidden(true)
                                Text(model.draft.photoID == nil ? "Add photo" : "Replace unavailable photo")
                                Spacer()
                                Image(systemName: "chevron.right").accessibilityHidden(true)
                            }
                            .padding(20).frame(minHeight: 88)
                            .foregroundStyle(AppTheme.ink)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("capture.addPhoto")
                        .accessibilityFocused($photoFocused)
                    }
                    if model.isImporting {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Preparing photo…").font(.subheadline)
                            Spacer()
                            Button("Cancel") { model.cancelImport() }.frame(minHeight: 44)
                        }
                    }
                }
                CaptureField(title: "Name", text: Binding(get: { model.draft.name },
                                                         set: { model.update(\.name, value: $0) }))
                if model.draft.name.count > 80 {
                    Text("Use 80 characters or fewer for the piece name.").font(.subheadline).foregroundStyle(AppTheme.error)
                } else if !model.draft.name.isEmpty && model.draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Enter a name, not only spaces.").font(.subheadline).foregroundStyle(AppTheme.error)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category").font(.subheadline)
                    Picker("Category", selection: Binding(get: { model.draft.category },
                                                          set: { model.update(\.category, value: $0) })) {
                        Text("Choose category").tag(Optional<PieceCategory>.none)
                        ForEach(PieceCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(Optional(category))
                        }
                    }
                    .pickerStyle(.menu).frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .padding(.horizontal, 14)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityIdentifier("capture.category")
                }
                Button { showDetails = true } label: {
                    HStack {
                        Text("More details")
                        Spacer()
                        Image(systemName: "chevron.right").accessibilityHidden(true)
                    }
                    .foregroundStyle(AppTheme.ink).padding(14).frame(minHeight: 52)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain)
                if let error = model.errorText {
                    Text(error).font(.subheadline).foregroundStyle(AppTheme.error)
                    if model.draftSaveFailed {
                        Button("Retry keeping draft") { model.persistDraft() }.frame(minHeight: 44)
                    }
                }
                if model.draft.photoID == nil && (!model.draft.name.isEmpty || model.draft.category != nil) {
                    Text("Add a photo to save this piece.").font(.subheadline).foregroundStyle(AppTheme.error)
                }
            }
            .padding(20)
            .disabled(model.isSaving)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            PrimaryAction(title: model.draft.baseRevision == nil ? "Save piece" : "Save changes",
                          isPending: model.isSaving) { model.save() }
                .disabled(!model.canSave)
                .opacity(model.canSave ? 1 : 0.5)
                .accessibilityIdentifier("capture.save")
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(AppTheme.canvas)
        }
    }

    private func receipt(_ piece: WardrobePiece) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(piece.name).font(.title2.weight(.medium))
            Text("Saved privately on this device.").foregroundStyle(AppTheme.secondary)
            if let data = model.photoData(), let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 280)
            }
            Spacer()
            PrimaryAction(title: "Open my closet") { model.openCloset() }
                .accessibilityIdentifier("capture.openCloset")
        }.padding(20)
    }

    private func sourceRow(_ title: String, symbol: String, source: PhotoSource) -> some View {
        Button {
            pendingSource = source
            sourceSheet = false
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol).accessibilityHidden(true)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right").accessibilityHidden(true)
            }.padding(.horizontal, 20).frame(minHeight: 56).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private func presentPendingSource() {
        defer { pendingSource = nil }
        switch pendingSource {
        case .photos: pickerPresented = true
        case .camera: requestCamera()
        case nil: photoFocused = true
        }
    }

    private func requestCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { cameraUnavailable = true; return }
        Task {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            let allowed: Bool
            switch status {
            case .authorized: allowed = true
            case .notDetermined: allowed = await AVCaptureDevice.requestAccess(for: .video)
            default: allowed = false
            }
            if allowed { cameraPresented = true } else { cameraDenied = true }
        }
    }

    private func leave() {
        model.leave()
        if model.draftSaveFailed { discardDecision = true }
    }
}
