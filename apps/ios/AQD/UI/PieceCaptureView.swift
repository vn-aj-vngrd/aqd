import AQDCore
import AVFoundation
import PhotosUI
import SwiftUI

struct PieceCaptureView: View {
    @Environment(\.openURL) private var openURL
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
    @State private var cameraRestricted = false
    @State private var cameraUnavailable = false
    @AccessibilityFocusState private var photoFocused: Bool

    private enum PhotoSource: Hashable { case photos, camera }

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
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                Button("Choose from Photos") { pickerPresented = true }
                Button("Keep draft", role: .cancel) {}
            } message: {
                Text("Allow Camera in iPhone Settings to take a photo, or choose an existing photo. Your entered fields are unchanged.")
            }
            .alert("Camera access is restricted", isPresented: $cameraRestricted) {
                Button("Choose from Photos") { pickerPresented = true }
                Button("Keep draft", role: .cancel) {}
            } message: {
                Text("A device restriction prevents camera access. Choose an existing photo or keep this draft. Your entered fields are unchanged.")
            }
            .alert("Camera isn’t available", isPresented: $cameraUnavailable) {
                Button("Choose from Photos") { pickerPresented = true }
                Button("Keep draft", role: .cancel) {}
            }
        }
        .tint(AppTheme.actionText)
        .interactiveDismissDisabled(model.isSaving || model.draftSaveFailed || model.saved != nil)
        .photosPicker(isPresented: $pickerPresented, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            model.importPhoto { try await item.loadTransferable(type: Data.self) }
            selectedPhoto = nil
        }
        .sheet(isPresented: $sourceSheet, onDismiss: presentPendingSource) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.screen) {
                        // Paper SQ4/SQE: 16pt inset + 24pt icon + 14pt gap;
                        // the separator starts at the label, not beneath the icon.
                        SurfaceGroup([PhotoSource.photos, .camera], id: \.self,
                                     separatorInsets: EdgeInsets(top: 0, leading: 54, bottom: 0, trailing: 0)) { source in
                            sourceRow(source == .photos ? "Choose from Photos" : "Take photo",
                                      symbol: source == .photos ? "photo.on.rectangle" : "camera", source: source)
                        }
                        Text("Selected photos are copied into AQD on this device. iCloud Photos may download your selection. Originals stay in Photos.")
                            .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    }
                    .padding(AppSpacing.screen)
                }
                .background(AppTheme.canvas)
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
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    HStack {
                        Text("Photo").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
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
                        SecondaryAction(title: "Edit photo") { showPhotoEditor = true }
                            .disabled(model.isImporting || model.isSaving)
                            .accessibilityIdentifier("capture.editPhoto")
                    } else {
                        Button { sourceSheet = true } label: {
                            HStack(spacing: AppSpacing.large) {
                                Image(systemName: "photo")
                                    .font(.system(size: AppControlMetrics.disclosureLane))
                                    .foregroundStyle(AppTheme.actionText)
                                    .accessibilityHidden(true)
                                Text(model.draft.photoID == nil ? "Add photo" : "Replace unavailable photo")
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppTheme.actionText)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.forward")
                                    .font(.system(size: AppControlMetrics.disclosureLane))
                                    .frame(width: AppControlMetrics.disclosureLane)
                                    .foregroundStyle(AppTheme.secondary)
                                    .accessibilityHidden(true)
                            }
                            .padding(AppSpacing.screen).frame(minHeight: 88)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.group))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("capture.addPhoto")
                        .accessibilityFocused($photoFocused)
                    }
                    if model.isImporting {
                        HStack(spacing: 12) {
                            OperationProgress(title: "Preparing photo…")
                            Spacer()
                            Button("Cancel") { model.cancelImport() }.frame(minHeight: 44)
                        }
                    }
                }
                LabeledField(title: "Name", text: Binding(get: { model.draft.name },
                                                         set: { model.update(\.name, value: $0) }),
                             prompt: "e.g. Cotton shirt", validation: nameValidation, accessibilityID: "capture.field.name")
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    LabeledControl(title: "Category") {
                        Picker("Category", selection: Binding(get: { model.draft.category },
                                                              set: { model.update(\.category, value: $0) })) {
                            Text("Choose category").foregroundStyle(AppTheme.secondary).tag(Optional<PieceCategory>.none)
                            ForEach(PieceCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(Optional(category))
                            }
                        }
                        .pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("capture.category")
                    }
                    // Paper JR5/JR6 is a plain supporting link, not a surfaced row.
                    Button { showDetails = true } label: {
                        Text("More details").font(AppTypography.supporting)
                            .foregroundStyle(AppTheme.actionText)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, AppSpacing.medium)
                            .frame(maxWidth: .infinity, minHeight: AppControlMetrics.minimumTarget, alignment: .topLeading)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
                if let error = model.errorText {
                    // This legacy channel mixes failures/conflicts/unknown writes.
                    // Keep its exact recovery copy; do not infer a severity from prose.
                    Text(error).font(AppTypography.supporting).foregroundStyle(AppTheme.error)
                    if model.draftSaveFailed {
                        Button("Retry keeping draft") { model.persistDraft() }.frame(minHeight: 44)
                    }
                }
                if model.draft.photoID == nil && (!model.draft.name.isEmpty || model.draft.category != nil) {
                    SemanticFeedback(role: .danger, message: "Add a photo to save this piece.")
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.medium)
            .padding(.bottom, AppSpacing.screen)
            .disabled(model.isSaving)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            ActionFooter {
                PrimaryAction(title: model.draft.baseRevision == nil ? "Save piece" : "Save changes",
                              isPending: model.isSaving) { model.save() }
                    .disabled(!model.canSave)
                    .accessibilityIdentifier("capture.save")
            }
        }
    }

    private var nameValidation: String? {
        if model.draft.name.count > 80 { return "Use 80 characters or fewer for the piece name." }
        if !model.draft.name.isEmpty && model.draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter a name, not only spaces."
        }
        return nil
    }

    private func receipt(_ piece: WardrobePiece) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(piece.name).font(.title2.weight(.medium))
                SemanticFeedback(role: .success, message: "Saved privately on this device.")
                if model.receiptIsHistorical {
                    Text("This receipt shows an earlier saved revision. Your closet opens the current piece.")
                        .font(.subheadline).foregroundStyle(AppTheme.secondary)
                }
                if let error = model.errorText {
                    Text(error).font(.subheadline).foregroundStyle(AppTheme.error)
                }
                if let data = model.photoData(), let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 280)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            ActionFooter {
                PrimaryAction(title: "Open my closet") { model.openCloset() }
                    .accessibilityIdentifier("capture.openCloset")
            }
        }
    }

    private func sourceRow(_ title: String, symbol: String, source: PhotoSource) -> some View {
        Button {
            pendingSource = source
            sourceSheet = false
        } label: {
            // These are system-source commands, not app disclosure destinations.
            // Paper SQ4/SQE has a leading symbol and no trailing chevron.
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: AppControlMetrics.disclosureLane))
                    .frame(width: 24)
                    .accessibilityHidden(true)
                Text(title).font(AppTypography.body)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .foregroundStyle(AppTheme.actionText)
            .padding(.horizontal, AppSpacing.large)
            .padding(.vertical, AppSpacing.small)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .contentShape(Rectangle())
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
            switch status {
            case .authorized: cameraPresented = true
            case .denied: cameraDenied = true
            case .restricted: cameraRestricted = true
            case .notDetermined:
                if await AVCaptureDevice.requestAccess(for: .video) {
                    cameraPresented = true
                } else if AVCaptureDevice.authorizationStatus(for: .video) == .restricted {
                    cameraRestricted = true
                } else {
                    cameraDenied = true
                }
            @unknown default: cameraUnavailable = true
            }
        }
    }

    private func leave() {
        model.leave()
        if model.draftSaveFailed { discardDecision = true }
    }
}
