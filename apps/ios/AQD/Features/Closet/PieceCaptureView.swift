import AQDCore
import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct PieceCaptureView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: "Save",
                              isPending: model.isSaving) {
            model.save()
            if model.saved != nil {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                model.leave()
            }
        }
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
            .appConfirmation("Cut out the background?", isPresented: $model.offersCutout) {
                Button("Cut out") { model.autoCutout() }
                Button("Keep original", role: .cancel) {}
            } message: {
                Text("A clean cutout makes a better listing photo. You can refine it or go back to the original at any time.")
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
            NativeCamera(guide: .piece, onPhoto: { data in cameraData = data; cameraPresented = false },
                         onCancel: { cameraPresented = false })
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showDetails) { PieceDetailsView(model: model) }
        .sheet(isPresented: $showBackgroundRemoval) { PieceCutoutView(capture: model) }
        .editImportedPhoto(model, importing: model.isImporting, locked: model.isSaving, presented: $showPhotoEditor)
        .sheet(isPresented: $showPhotoEditor) { PhotoEditorView(model: model, isPresentedModally: true) }
        .onAppear {
            if model.opensCutout { model.opensCutout = false; showBackgroundRemoval = true }
        }
        .onChange(of: model.opensCutout) { _, requested in
            if requested { model.opensCutout = false; showBackgroundRemoval = true }
        }
        .onDisappear { model.cancelImport() }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                mediaContent
                if model.cutoutState == .failed {
                    Label("Automatic cutout isn’t available for this photo. Tap Cut out to erase the background by hand, or Crop to trim the sides.",
                          systemImage: "info.circle").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }
                if !model.photoHints.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        ForEach(model.photoHints, id: \.self) { hint in
                            Label(hint.message, systemImage: "info.circle").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }
                    }.accessibilityIdentifier("capture.photoHints")
                }
                LabeledField(title: "Name", text: Binding(get: { model.draft.displayName },
                                                         set: { model.update(\.name, value: $0) }),
                             prompt: "e.g. Cotton shirt", validation: nameValidation, accessibilityID: "capture.field.name",
                             editingFocus: $nameEditing).submitLabel(.done).onSubmit { nameEditing = false }
                categoryChips
                DisclosureRow(title: "More details", value: "Optional") {
                    nameEditing = false
                    showDetails = true
                }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
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

    /// No photo yet: two direct choices, no menu.
    private var emptyPhoto: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "camera").font(.system(size: 34, weight: .light)).foregroundStyle(AppTheme.ink).accessibilityHidden(true)
            Text(model.draft.photoID == nil ? "Add a photo" : "Photo unavailable").font(AppTypography.detailTitle)
            Text(model.draft.photoID == nil ? "A flat piece on a plain, well-lit surface works best." : "Choose another photo. Your details are kept.")
                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).multilineTextAlignment(.center)
            HStack(spacing: AppSpacing.small) {
                Button { nameEditing = false; requestCamera() } label: {
                    Label("Take photo", systemImage: "camera").font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.onPrimary)
                        .padding(.horizontal, AppSpacing.large).frame(minHeight: AppControlMetrics.minimumTarget)
                        .background(AppTheme.primaryFill, in: Capsule())
                }.buttonStyle(.plain).accessibilityIdentifier("capture.takePhoto")
                Button { nameEditing = false; pickerPresented = true } label: {
                    Label("Photos", systemImage: "photo.on.rectangle").compactControl(fullWidth: true)
                }.buttonStyle(.plain).accessibilityIdentifier("capture.addPhoto")
            }.disabled(model.isImporting || model.isSaving).accessibilityFocused($photoFocused)
        }.padding(AppSpacing.large)
    }

    private func photoAction(_ title: String, systemImage: String, id: String, label: String, action: @escaping () -> Void) -> some View {
        Button { nameEditing = false; action() } label: {
            Label(title, systemImage: systemImage).compactControl()
        }.buttonStyle(.plain).disabled(model.isImporting || model.isSaving || model.cutoutState == .working)
            .accessibilityLabel(label).accessibilityIdentifier(id)
    }

    private var mediaContent: some View {
        let image = model.photoData().flatMap { UIImage(data: $0) }
        return VStack(alignment: .leading, spacing: AppSpacing.small) {
            ZStack {
                if let image {
                    Image(uiImage: image).resizable().scaledToFit()
                        .padding(AppSpacing.medium)
                        .accessibilityLabel(model.draft.photoRecipe.crop == nil ? "Selected piece photo, entire image fitted" : "Selected piece photo, portrait crop")
                } else {
                    emptyPhoto
                }
            }
            .frame(maxWidth: .infinity).frame(height: image == nil ? 280 : 320)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
            .overlay(alignment: .bottomLeading) {
                if image != nil {
                    HStack(spacing: AppSpacing.small) {
                        photoAction("Crop", systemImage: "crop", id: "capture.crop", label: "Crop photo") { showPhotoEditor = true }
                        photoAction(model.hasProcessedPhoto ? "Refine" : "Cut out", systemImage: "scissors", id: "capture.cutout",
                                    label: model.hasProcessedPhoto ? "Refine cutout" : "Cut out piece") { showBackgroundRemoval = true }
                    }.padding(AppSpacing.medium)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // A small, separate menu: the system glass menu morphs cleanly from a compact control.
                if image != nil {
                    Menu {
                        Button("Choose from Photos", systemImage: "photo.on.rectangle") { nameEditing = false; pickerPresented = true }
                        Button("Take photo", systemImage: "camera") { nameEditing = false; requestCamera() }
                        Section { DestructiveMenuButton("Remove photo") { model.removePhoto(); photoFocused = true } }
                    } label: {
                        Image(systemName: "ellipsis").font(.body.weight(.medium)).foregroundStyle(AppTheme.ink)
                            .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
                            .glassControlSurface(Circle())
                    }.menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
                        .disabled(model.isImporting || model.isSaving || model.cutoutState == .working)
                        .padding(AppSpacing.medium)
                        .accessibilityLabel("Change piece photo").accessibilityIdentifier("capture.addPhoto").accessibilityFocused($photoFocused)
                }
            }
            .overlay {
                if model.isImporting || model.cutoutState == .working {
                    VStack(spacing: AppSpacing.small) {
                        ProgressView().controlSize(.large)
                        if model.cutoutState == .working { Text("Cutting out the piece…").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                    }.padding(AppSpacing.large).background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.group))
                }
            }
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
                    PrimaryAction(title: "Done") { model.openCloset() }
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
