import AQDCore
import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct PieceCaptureView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: "Save",
                              isPending: model.isSaving) { model.save(); if model.saved != nil { model.leave() } }
                    .disabled(!model.canSave)
                    .accessibilityIdentifier("capture.save")
    }

    @Environment(\.openURL) private var openURL
    @Bindable var model: CaptureModel
    @State private var pickerPresented = false
    @State private var cameraPresented = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var cameraData: Data?
    @State private var showDetails = false
    @State private var manageCategories = false
    @State private var showPhotoEditor = false
    @State private var showBackgroundRemoval = false
    @State private var discardDecision = false
    @State private var cameraDenied = false
    @State private var cameraRestricted = false
    @State private var cameraUnavailable = false
    @AccessibilityFocusState private var photoFocused: Bool
    @FocusState private var nameEditing: Bool

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
            .navigationDestination(isPresented: $manageCategories) { WardrobeCategorySettingsView().secondaryPage() }
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
            .appConfirmation("Camera access is off", isPresented: $cameraDenied) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                Button("Choose from Photos") { pickerPresented = true }
                Button("Keep draft", role: .cancel) {}
            } message: {
                Text("Allow Camera in iPhone Settings to take a photo, or choose an existing photo. Your entered fields are unchanged.")
            }
            .appConfirmation("Camera access is restricted", isPresented: $cameraRestricted) {
                Button("Choose from Photos") { pickerPresented = true }
                Button("Keep draft", role: .cancel) {}
            } message: {
                Text("A device restriction prevents camera access. Choose an existing photo or keep this draft. Your entered fields are unchanged.")
            }
            .appConfirmation("Camera isn’t available", isPresented: $cameraUnavailable) {
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
        .sheet(isPresented: $showBackgroundRemoval) { PieceCutoutView(capture: model) }
        .editImportedPhoto(model, importing: model.isImporting, locked: model.isSaving, presented: $showPhotoEditor)
        .sheet(isPresented: $showPhotoEditor) { PhotoEditorView(model: model, isPresentedModally: true) }
        .onDisappear { model.cancelImport() }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                mediaContent
                LabeledField(title: "Name", text: Binding(get: { model.draft.displayName },
                                                         set: { model.update(\.name, value: $0) }),
                             prompt: "e.g. Cotton shirt", validation: nameValidation, accessibilityID: "capture.field.name",
                             editingFocus: $nameEditing).submitLabel(.done).onSubmit { nameEditing = false }
                categoryChips
                DisclosureRow(title: "More details", value: "Optional") {
                    nameEditing = false
                    showDetails = true
                }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
                if let error = model.errorText {
                    // This legacy channel mixes failures/conflicts/unknown writes.
                    // Keep its exact recovery copy; do not infer a severity from prose.
                    Text(error).font(AppTypography.supporting).foregroundStyle(AppTheme.error)
                    if model.draftSaveFailed {
                        Button("Retry keeping draft") { model.persistDraft() }.frame(minHeight: 44)
                    }
                }
                if let hint = saveHint {
                    Text(hint).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        .accessibilityIdentifier("capture.saveHint")
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.medium)
            .padding(.bottom, AppSpacing.screen)
            .disabled(model.isSaving)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    /// What still blocks Save, in plain words. Empty once the piece can be saved.
    private var saveHint: String? {
        guard model.saved == nil, !model.isSaving, !model.isImporting else { return nil }
        var missing: [String] = []
        if model.draft.photoID == nil { missing.append("a photo") }
        if model.draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("a name") }
        if model.draft.category == nil { missing.append("a category") }
        guard !missing.isEmpty else { return nil }
        let list = missing.count == 1 ? missing[0] : missing.dropLast().joined(separator: ", ") + " and " + missing[missing.count - 1]
        return "To save, add " + list + "."
    }

    private var categoryChips: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Category").font(AppTypography.fieldLabel).foregroundStyle(AppTheme.secondary)
            ScrollView(.horizontal) {
                HStack(spacing: AppSpacing.small) {
                    ForEach(model.categories) { category in
                        AppChip(title: category.name, isSelected: model.categorySelectionID == category.id) {
                            nameEditing = false
                            model.selectCategory(category)
                        }.accessibilityIdentifier("capture.category.\(category.id)")
                    }
                    Button { nameEditing = false; manageCategories = true } label: {
                        Image(systemName: "slider.horizontal.3").foregroundStyle(AppTheme.ink)
                            .frame(width: 32, height: 32).glassControlSurface(Circle())
                            .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
                    }.buttonStyle(.plain).accessibilityLabel("Manage categories")
                }
            }.scrollIndicators(.hidden)
        }
    }

    private var mediaContent: some View {
        let image = model.photoData().flatMap { UIImage(data: $0) }
        return VStack(alignment: .leading, spacing: AppSpacing.small) {
            Menu {
                Button("Choose from Photos", systemImage: "photo.on.rectangle") { nameEditing = false; pickerPresented = true }
                Button("Take photo", systemImage: "camera") { nameEditing = false; requestCamera() }
                if image != nil {
                    Divider()
                    Button("Edit photo", systemImage: "crop") { showPhotoEditor = true }
                }
                if model.draft.photoID != nil {
                    Button("Cut out piece", systemImage: "scissors") { showBackgroundRemoval = true }
                    Divider()
                    Button("Remove photo", systemImage: "trash", role: .destructive) { model.removePhoto(); photoFocused = true }
                }
            } label: {
                ZStack {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFit()
                            .padding(AppSpacing.medium)
                            .accessibilityLabel(model.draft.photoRecipe.crop == nil ? "Selected piece photo, entire image fitted" : "Selected piece photo, portrait crop")
                    } else {
                        VStack(spacing: AppSpacing.medium) {
                            Image(systemName: "camera").font(.system(size: 34, weight: .light))
                                .foregroundStyle(AppTheme.ink).accessibilityHidden(true)
                            Text(model.draft.photoID == nil ? "Add a photo" : "Photo unavailable").font(AppTypography.detailTitle)
                            Text(model.draft.photoID == nil ? "Take one now or choose from Photos." : "Choose another photo. Your details are kept.")
                                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).multilineTextAlignment(.center)
                        }.padding(AppSpacing.large)
                    }
                }
                .frame(maxWidth: .infinity).frame(height: image == nil ? 240 : 320)
                .background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: AppRadius.field))
                .overlay(alignment: .bottomLeading) {
                    if image != nil {
                        Button { nameEditing = false; showBackgroundRemoval = true } label: {
                            Label("Cut out", systemImage: "scissors").font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.ink)
                                .padding(.horizontal, AppSpacing.medium).frame(minHeight: AppControlMetrics.minimumTarget)
                                .glassControlSurface(Capsule())
                        }.buttonStyle(.plain).padding(AppSpacing.medium).disabled(model.isImporting || model.isSaving)
                            .accessibilityLabel("Cut out piece").accessibilityHint("Removes the background and trims the sides")
                            .accessibilityIdentifier("capture.cutout")
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if image != nil {
                        Image(systemName: "pencil").font(.body.weight(.medium)).foregroundStyle(AppTheme.ink)
                            .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
                            .glassControlSurface(Circle()).padding(AppSpacing.medium).accessibilityHidden(true)
                    }
                }
                .overlay { if model.isImporting { ProgressView().controlSize(.large) } }
                .contentShape(RoundedRectangle(cornerRadius: AppRadius.field))
            }
            .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
            .disabled(model.isImporting || model.isSaving)
            .accessibilityLabel(model.draft.photoID == nil ? "Add piece photo" : "Change piece photo")
            .accessibilityIdentifier("capture.addPhoto").accessibilityFocused($photoFocused)
            if model.isImporting {
                HStack(spacing: 12) {
                    OperationProgress(title: "Preparing photo…")
                    Spacer()
                    Button("Cancel") { model.cancelImport() }.frame(minHeight: 44)
                }
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
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                Group {
                    if let data = model.photoData(), let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFit().padding(AppSpacing.medium)
                    } else {
                        Image(systemName: "tshirt").font(.system(size: 36, weight: .light)).foregroundStyle(AppTheme.secondary)
                    }
                }.frame(maxWidth: .infinity).frame(height: 320)
                    .background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: AppRadius.field))
                    .accessibilityLabel("Photo of \(piece.displayName)")
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(piece.displayName).font(.title2.weight(.medium))
                    Text(model.categoryName(for: piece)).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }
                SemanticFeedback(role: .success, message: "Saved privately on this device.")
                if model.receiptIsHistorical {
                    Text("This receipt shows an earlier saved revision. Your closet opens the current piece.")
                        .font(.subheadline).foregroundStyle(AppTheme.secondary)
                }
                if let error = model.errorText {
                    Text(error).font(.subheadline).foregroundStyle(AppTheme.error)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(AppSpacing.screen)
        }
        .safeAreaInset(edge: .bottom) {
            ActionFooter {
                ActionStack {
                    PrimaryAction(title: model.isFirstOutfit ? "Build my first outfit" : "Build outfit") { model.buildFirstOutfit() }
                    SecondaryAction(title: "Add another piece") { model.addAnother() }
                        .accessibilityIdentifier("capture.addAnother")
                    SecondaryAction(title: "Open my closet") { model.openCloset() }
                        .accessibilityIdentifier("capture.openCloset")
                }
            }
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
