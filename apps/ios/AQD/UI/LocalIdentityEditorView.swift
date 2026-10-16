import AQDCore
import SwiftUI

struct LocalIdentityAvatar: View {
    let photoID: UUID?
    var recipe = PhotoEditRecipe.fitOriginal
    @Environment(AppState.self) private var state
    var body: some View {
        Group {
            if let photoID, let data = try? state.store?.photoThumbnail(id: photoID, recipe: recipe), let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill().clipShape(Circle()).accessibilityLabel("Private profile photo")
            } else {
                Image(systemName: photoID == nil ? "person.crop.circle.fill" : "photo.badge.exclamationmark")
                    .resizable().scaledToFit().foregroundStyle(AppTheme.secondary)
                    .accessibilityLabel(photoID == nil ? "No profile photo" : "Profile photo unavailable")
            }
        }.clipped()
    }
}

struct LocalIdentityEditorView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: model.unknown ? "Check result" : "Save", isPending: model.pending) { Task { await model.save() } }.disabled(model.pending || model.importing || (!model.unknown && !model.canSave))
    }

    @Bindable var model: LocalIdentityEditorModel
    @State private var discard = false
    @State private var editingPhoto = false
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    LocalIdentityAvatar(photoID: model.draft.photoID, recipe: model.draft.photoRecipe ?? .fitOriginal).frame(width: 96, height: 96)
                        .overlay(alignment: .bottomTrailing) {
                            if model.saved == nil {
                                SharedPhotoSourceButton(title: "Profile photo", selectionToken: model.importID, locked: model.locked || model.importing,
                                    iconOnly: true, onEdit: model.draft.photoID == nil ? nil : { editingPhoto = true },
                                    onRemove: model.draft.photoID == nil ? nil : { model.removePhoto() }, onData: model.importPhoto)
                                    .offset(x: 12, y: 8)
                            }
                        }.frame(maxWidth: .infinity).padding(.bottom, 8)
                    Group {
                        if model.importing { ProgressView("Preparing photo"); Button("Cancel import") { model.cancelImport() }.frame(minHeight: 44) }
                        LabeledField(title: "Name", text: Binding(get: { model.draft.name }, set: { name in model.update { $0.name = name } })).disabled(model.locked)
                        LabeledField(title: "Caption", text: Binding(get: { model.draft.caption ?? LocalProfileIdentity.defaultCaption },
                                     set: { value in model.update { $0.caption = value } }), multiline: true, characterLimit: TextAreaLimits.caption,
                                     validation: (model.draft.caption?.count ?? 0) > 160 ? "Use 160 characters or fewer." : nil)
                            .disabled(model.locked)
                            .accessibilityIdentifier("profile.caption")

                    }
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                }.padding(20)
            }.background(AppTheme.canvas).navigationTitle("Edit profile").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if model.saved == nil { confirmation }
            } }.tint(AppTheme.ink)
                .editImportedPhoto(model, importing: model.importing, locked: model.locked, presented: $editingPhoto)
                .navigationDestination(isPresented: $editingPhoto) { PhotoEditorView(model: model).secondaryPage() }
                .toolbar { ToolbarItem(placement: model.saved == nil ? .topBarLeading : .topBarTrailing) {
                    Button {
                        if model.saved != nil { model.finish() }
                        else if !model.hasUnsavedChanges { model.finish(discarding: true) }
                        else { discard = true }
                    } label: { if model.saved == nil { Image(systemName: "xmark") } else { Text("Done") } }
                        .accessibilityLabel(model.saved == nil ? "Cancel profile edits" : "Done").disabled(model.pending || model.unknown)
                } }
        }.interactiveDismissDisabled().draftDiscardConfirmation(isPresented: $discard, title: "Discard profile changes?", message: "Your saved profile stays unchanged. Other local data is unaffected.") {
                model.finish(discarding: true); if model.state.identityEditor == nil { discard = false }
            }
    }
}
