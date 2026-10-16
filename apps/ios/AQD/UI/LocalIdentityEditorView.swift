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
    @Bindable var model: LocalIdentityEditorModel
    @State private var discard = false
    @State private var editingPhoto = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Name and photo are optional and private on this iPhone.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    LocalIdentityAvatar(photoID: model.draft.photoID, recipe: model.draft.photoRecipe ?? .fitOriginal).frame(width: 96, height: 96).frame(maxWidth: .infinity)
                    if model.saved == nil {
                        SharedPhotoSourceButton(title: "Choose photo", selectionToken: model.importID, locked: model.locked, onData: model.importPhoto)
                        if model.importing { ProgressView("Preparing photo"); Button("Cancel import") { model.cancelImport() }.frame(minHeight: 44) }
                        if model.draft.photoID != nil { SecondaryAction(title: "Edit photo") { editingPhoto = true }.disabled(model.locked || model.importing); Button("Remove photo", role: .destructive) { model.removePhoto() }.frame(minHeight: 44).disabled(model.locked) }
                        LabeledField(title: "Name", text: Binding(get: { model.draft.name }, set: { name in model.update { $0.name = name } })).disabled(model.locked)
                        if !model.draft.name.isEmpty { Button("Clear name") { model.update { $0.name = "" } }.frame(minHeight: 44).disabled(model.locked) }
                        PrimaryAction(title: model.unknown ? "Check save result" : "Save profile", isPending: model.pending) { Task { await model.save() } }.disabled(model.pending || model.importing)
                    } else {
                        Text("Profile saved").font(AppTypography.section)
                        PrimaryAction(title: "Done") { model.finish() }
                    }
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                }.padding(20)
            }.background(AppTheme.canvas).navigationTitle("Edit profile").navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink)
                .navigationDestination(isPresented: $editingPhoto) { PhotoEditorView(model: model) }
                .toolbar { ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if model.saved != nil { model.finish() }
                        else if !model.draft.hasChanges { model.finish(discarding: true) }
                        else { discard = true }
                    } label: { Image(systemName: model.saved == nil ? "xmark" : "checkmark") }
                        .accessibilityLabel(model.saved == nil ? "Cancel profile edits" : "Done").disabled(model.pending || model.unknown)
                } }
        }.interactiveDismissDisabled().draftDiscardConfirmation(isPresented: $discard, title: "Discard profile changes?", message: "Your saved name and photo stay unchanged. Other local data is unaffected.") {
                model.finish(discarding: true); if model.state.identityEditor == nil { discard = false }
            }
    }
}
