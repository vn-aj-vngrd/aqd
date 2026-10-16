import AQDCore
import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct PieceCaptureView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: "Save",
                              isPending: model.isSaving) { model.save() }
                    .disabled(!model.canSave)
                    .accessibilityIdentifier("capture.save")
    }

    @Environment(\.openURL) private var openURL
    @Bindable var model: CaptureModel
    @State private var sourceSheet = false
    @State private var pickerPresented = false
    @State private var cameraPresented = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var pendingSource: PhotoSource?
    @State private var cameraData: Data?
    @State private var showDetails = false
    @State private var manageCategories = false
    @State private var showPhotoEditor = false
    @State private var showBackgroundRemoval = false
    @State private var backgroundCropRequested = false
    @State private var discardDecision = false
    @State private var cameraDenied = false
    @State private var cameraRestricted = false
    @State private var cameraUnavailable = false
    @AccessibilityFocusState private var photoFocused: Bool
    @FocusState private var nameEditing: Bool

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
            .navigationDestination(isPresented: $manageCategories) { WardrobeCategorySettingsView() }
            .navigationTitle(model.saved == nil ? (model.draft.baseRevision == nil ? "Add piece" : "Edit piece") : "Piece saved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if model.saved == nil { confirmation }
            } }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { leave() } label: { Label("Cancel", systemImage: "xmark") }
                        .accessibilityIdentifier("capture.back")
                        .tint(AppTheme.ink)
                        .disabled(model.isSaving)
                }

            }
            .draftDiscardConfirmation(isPresented: $discardDecision, title: "Discard this draft?", message: model.draftSaveFailed
                                  ? "The latest changes couldn’t be kept. Discard removes only this piece draft, not saved pieces or original Photos."
                                  : "Discard removes only this recoverable edit and its unused AQD photo edits. Saved pieces and original Photos stay unchanged.") {
                    discardDecision = false
                    model.discard()
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
        .tint(AppTheme.ink)
        .interactiveDismissDisabled(model.isSaving || model.hasUnsavedChanges || model.saved != nil)
        .photosPicker(isPresented: $pickerPresented, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            model.importPhoto { try await item.loadTransferable(type: Data.self) }
            selectedPhoto = nil
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
        .sheet(isPresented: $showBackgroundRemoval, onDismiss: {
            if backgroundCropRequested { backgroundCropRequested = false; showPhotoEditor = true }
        }) { BackgroundRemovalView(capture: model) { backgroundCropRequested = true; showBackgroundRemoval = false } }
        .sheet(isPresented: $showPhotoEditor) { PhotoEditorView(model: model) }
        .onDisappear { model.cancelImport() }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                mediaContent
                LabeledField(title: "Name", text: Binding(get: { model.draft.displayName },
                                                         set: { model.update(\.name, value: $0) }),
                             prompt: "e.g. Cotton shirt", validation: nameValidation, accessibilityID: "capture.field.name",
                             editingFocus: $nameEditing)
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text("Category").font(AppTypography.body)
                        Menu {
                            ForEach(model.categories) { category in
                                Button { model.selectCategory(category) } label: {
                                    if model.categorySelectionID == category.id {
                                        Label(category.name, systemImage: "checkmark")
                                    } else { Text(category.name) }
                                }
                            }
                            Divider()
                            Button("Manage categories", systemImage: "slider.horizontal.3") {
                                nameEditing = false
                                manageCategories = true
                            }
                        } label: {
                            MenuSelectionLabel(title: model.categoryName)
                        }
                        .menuIndicator(.hidden).buttonStyle(.plain).foregroundStyle(AppTheme.ink)
                        .accessibilityLabel("Category")
                        .accessibilityValue(model.categoryName)
                        .accessibilityIdentifier("capture.category")
                    }.padding(.horizontal, 14).frame(minHeight: 54)
                    Divider().padding(.leading, 14)
                    DisclosureRow(title: "More details", value: "Optional") {
                        nameEditing = false
                        showDetails = true
                    }
                }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
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

    }

    private var mediaContent: some View {
        let image = model.photoData().flatMap { UIImage(data: $0) }
        return VStack(alignment: .leading, spacing: 12) {
            Button { nameEditing = false; sourceSheet = true } label: {
            Group {
                if let image {
                    Image(uiImage: image).resizable().scaledToFit()
                        .frame(maxWidth: .infinity).frame(height: 280)
                        .accessibilityLabel(model.draft.photoRecipe.crop == nil ? "Selected piece photo, entire image fitted" : "Selected piece photo, portrait crop")
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled").font(.system(size: 40, weight: .light))
                            .foregroundStyle(AppTheme.actionText).accessibilityHidden(true)
                        Text(model.draft.photoID == nil ? "Start with a piece photo" : "Photo unavailable")
                            .font(AppTypography.detailTitle)
                        Text(model.draft.photoID == nil ? "Choose a photo or take one now." : "Choose another photo. Your details are kept.")
                            .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }.frame(maxWidth: .infinity, minHeight: 180).padding(16)
                }
            }.frame(maxWidth: .infinity).background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: 12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }.buttonStyle(.plain).disabled(model.isImporting || model.isSaving)
                .accessibilityLabel(model.draft.photoID == nil ? "Add piece photo" : "Change piece photo")
            DisclosureRow(title: model.draft.photoID == nil ? "Add photo" : image == nil ? "Replace unavailable photo" : "Change photo", value: "Photos or camera") {
                nameEditing = false
                sourceSheet = true
            }.disabled(model.isImporting || model.isSaving)
                .popover(isPresented: $sourceSheet, arrowEdge: .top) {
                    PhotoSourcePopover(photos: { pendingSource = .photos; sourceSheet = false },
                                       camera: { pendingSource = .camera; sourceSheet = false })
                        .onDisappear(perform: presentPendingSource)
                }
                .accessibilityIdentifier("capture.addPhoto").accessibilityFocused($photoFocused)
            if model.isImporting {
                HStack(spacing: 12) {
                    OperationProgress(title: "Preparing photo…")
                    Spacer()
                    Button("Cancel") { model.cancelImport() }.frame(minHeight: 44)
                }
            }
            if model.draft.photoID != nil {
                HStack {
                    Text("Photo options").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    Spacer()
                    Menu {
                        if image != nil {
                            Button("Edit photo", systemImage: "crop") { showPhotoEditor = true }
                                .accessibilityIdentifier("capture.editPhoto")
                        }
                        Button("Remove background", systemImage: "person.crop.rectangle") { showBackgroundRemoval = true }
                        Button("Remove photo", systemImage: "trash", role: .destructive) { model.removePhoto() }
                    } label: { Label("Photo options", systemImage: "ellipsis").labelStyle(.iconOnly).frame(width: 44, height: 44) }
                        .disabled(model.isImporting || model.isSaving)
                }
            }
        }.padding(12).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
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
                Text(piece.displayName).font(.title2.weight(.medium))
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
                ActionStack {
                    PrimaryAction(title: model.isFirstOutfit ? "Build my first outfit" : "Build outfit") { model.buildFirstOutfit() }
                    SecondaryAction(title: "Open my closet") { model.openCloset() }
                        .accessibilityIdentifier("capture.openCloset")
                }
            }
        }
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
        if model.saved == nil && model.hasUnsavedChanges {
            model.cancelImport()
            discardDecision = true
        } else {
            model.leave()
            if model.draftSaveFailed { discardDecision = true }
        }
    }
}
