import AQDCore
import SwiftUI

struct FitMemoryArtwork: View {
    let memory: FitMemory
    var thumbnail = false
    @Environment(AppState.self) private var state
    var body: some View {
        Group {
            if let id = memory.photoID {
                if let data = photoData(id), let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Private fit photo")
                } else { Label("Photo unavailable", systemImage: "photo.badge.exclamationmark").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
            } else if let snapshot = memory.outfit {
                OutfitComposition(pieceIDs: snapshot.pieces.map(\.id), pieceHeight: thumbnail ? 68 : 160)
            } else { Text("No fit content").foregroundStyle(AppTheme.secondary) }
        }.frame(maxWidth: .infinity).background(AppTheme.imageGround)
    }
    private func photoData(_ id: UUID) -> Data? {
        guard let store = state.store else { return nil }
        return try? thumbnail ? store.photoThumbnail(id: id, recipe: memory.photoRecipe) : store.photoRendition(id: id, recipe: memory.photoRecipe)
    }
}

struct FitJournalGrid: View {
    @Environment(AppState.self) private var state
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your fits").font(AppTypography.fieldLabel)
                if let error = state.fitError {
                    SemanticFeedback(role: .danger, message: error)
                    Button("Retry journal") { state.reloadFits() }.frame(minHeight: 44)
                } else if state.fitMemories.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A little space for your style").font(.headline)
                        Text("Use Add fit (+) above to keep a photo or outfit here. Memories stay private.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12)).accessibilityIdentifier("profile.fits.empty")
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: typeSize.isAccessibilitySize ? 1 : 3), spacing: 8) {
                        ForEach(state.fitMemories) { memory in
                            NavigationLink { FitMemoryDetailView(id: memory.id) } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    FitMemoryArtwork(memory: memory, thumbnail: true).aspectRatio(3 / 4, contentMode: .fit).clipShape(RoundedRectangle(cornerRadius: 4))
                                    Text(journalDate(memory.day) + (memory.photoID == nil ? " · Outfit" : "")).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                                }
                            }.buttonStyle(.plain).id(memory.id)
                                .accessibilityLabel("\(memory.day.key), \(memory.photoID == nil ? "outfit composition" : "photo"), \(memory.outfit?.name ?? "unlinked"), \(memory.note)")
                        }
                    }
                }
            }
        }
    }
    private func journalDate(_ day: LocalPlanDay) -> String {
        guard let date = try? day.date(), let zone = TimeZone(identifier: day.timeZoneID) else { return day.key }
        return date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: zone))
    }

}

struct FitEditorView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: model.unknown ? "Check result" : "Save", isPending: model.pending) { Task { await model.save() } }.disabled(!model.unknown && !model.canSave)
    }

    @Bindable var model: FitEditorModel
    @State private var discard = false
    @State private var removePhoto = false
    @State private var choosingOutfit = false
    @State private var timezone = false
    @State private var editingPhoto = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if model.saved != nil {
                        Text("Fit saved").font(AppTypography.section)

                    } else {
                        LabeledControl(title: "Date") {
                            DatePicker("Fit date", selection: Binding(get: { (try? model.draft.value.day.date()) ?? Date() }, set: { date in
                                let zone = TimeZone(identifier: model.draft.value.day.timeZoneID) ?? .current
                                model.update { $0.day = LocalPlanDay(date: date, timeZone: zone) }
                            }), displayedComponents: .date).environment(\.timeZone, TimeZone(identifier: model.draft.value.day.timeZoneID) ?? .current)
                        }.disabled(model.locked)
                        DisclosureRow(title: "Timezone", value: model.draft.value.day.timeZoneID) { timezone = true }.disabled(model.locked)
                        if model.draft.value.photoID != nil || model.draft.value.outfit != nil {
                            FitMemoryArtwork(memory: model.draft.value).frame(minHeight: 144, maxHeight: 240)
                        }
                        SharedPhotoSourceButton(title: model.draft.value.photoID == nil ? "Add photo" : "Change photo", selectionToken: model.importID, locked: model.locked, onData: model.importPhoto)
                        if model.importing { ProgressView("Preparing photo"); Button("Cancel import") { model.cancelImport() }.frame(minHeight: 44) }
                        if model.draft.value.photoID != nil { SecondaryAction(title: "Edit photo") { editingPhoto = true }.disabled(model.locked || model.importing); Button("Remove photo", role: .destructive) { removePhoto = true }.frame(minHeight: 44).disabled(model.locked) }
                        DisclosureRow(title: "Link outfit", value: model.draft.value.outfit?.name ?? "Not linked") { choosingOutfit = true }.disabled(model.locked)
                        if model.draft.value.outfit != nil { SecondaryAction(title: "Unlink outfit") { _ = model.link(nil) }.disabled(model.locked) }
                        LabeledControl(title: "Private note") {
                            TextField("What would you like to remember?", text: Binding(get: { model.draft.value.note }, set: { value in model.update { $0.note = value } }), axis: .vertical)
                                .lineLimit(4...12).font(AppTypography.body).disabled(model.locked)
                        }
                        Text("\(model.draft.value.note.count) / 500").font(AppTypography.metadata).foregroundStyle(model.draft.value.note.count > 500 ? AppTheme.error : AppTheme.secondary).frame(maxWidth: .infinity, alignment: .trailing)
                        if model.draft.value.note.count > 500 { SemanticFeedback(role: .danger, message: "Keep the note within 500 characters. Your full text is retained.") }
                        Text("Add a photo or link an outfit to save. Saving a fit never records wear.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)

                    }
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                }.padding(20)
            }.background(AppTheme.canvas).navigationTitle(model.draft.base == nil ? "Add fit" : "Edit fit").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if model.saved == nil { confirmation }
            } }.tint(AppTheme.ink)
                .toolbar { ToolbarItem(placement: model.saved == nil ? .topBarLeading : .topBarTrailing) {
                    Button {
                        if model.saved != nil { model.finish() }
                        else if !model.draft.hasChanges { model.finish(discarding: true) }
                        else { discard = true }
                    } label: { if model.saved == nil { Image(systemName: "xmark") } else { Text("Done") } }.accessibilityLabel(model.saved == nil ? "Cancel fit" : "Done").disabled(model.pending || model.unknown)
                } }
                .navigationDestination(isPresented: $editingPhoto) { PhotoEditorView(model: model) }
                .navigationDestination(isPresented: $choosingOutfit) { FitOutfitChooser(model: model) }
                .navigationDestination(isPresented: $timezone) {
                    TimezoneChooser(current: model.draft.value.day.timeZoneID) { zone in model.update { $0.day.timeZoneID = zone }; return model.error == nil }
                }
                .alert("Remove this fit photo?", isPresented: $removePhoto) {
                    Button("Cancel", role: .cancel) {}
                    Button("Remove photo", role: .destructive) { model.removePhoto() }
                } message: { Text("Changes this draft only until Save. Keep an outfit link or add another photo to save the fit. Original Photos are unchanged.") }
        }.interactiveDismissDisabled().draftDiscardConfirmation(isPresented: $discard, title: "Discard fit changes?", message: "Your saved memory and original Photos stay unchanged. No wear is recorded.") {
                model.finish(discarding: true); if model.state.fitEditor == nil { discard = false }
            }
    }
}

private struct FitOutfitChooser: View {
    @Bindable var model: FitEditorModel
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if model.state.outfits.isEmpty { AppEmptyState("No saved outfits", systemImage: "square.stack", description: Text("You can save this memory with a photo instead, or build an outfit in Closet.")) }
                ForEach(model.state.outfits.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }) { outfit in
                    Button { if model.link(outfit) { dismiss() } } label: {
                        VStack(alignment: .leading, spacing: 8) { OutfitComposition(pieceIDs: outfit.pieceIDs); Text(outfit.name).foregroundStyle(AppTheme.ink) }
                    }.buttonStyle(.plain).disabled(model.locked)
                }
                if let error = model.error { SemanticFeedback(role: .danger, message: error) }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Link outfit").navigationBarTitleDisplayMode(.inline).searchable(text: $query, prompt: "Search outfits")
            .onAppear { model.state.reloadOutfits(); model.state.reloadPieces() }
    }
}

struct FitMemoryDetailView: View {
    let id: UUID
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var confirming = false
    @State private var request: FitDeletionRequest?
    @State private var error: String?
    private var memory: FitMemory? { state.fitMemories.first { $0.id == id } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let memory {
                    FitMemoryArtwork(memory: memory).frame(minHeight: 240, maxHeight: 360)
                    Text(memory.day.key).font(AppTypography.section)
                    Text(memory.day.timeZoneID).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    Label("Private on this iPhone", systemImage: "lock").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    if !memory.note.isEmpty { Text(memory.note).font(AppTypography.body) }
                    if let snapshot = memory.outfit {
                        Text(snapshot.name).font(AppTypography.fieldLabel)
                        ForEach(snapshot.pieces, id: \.id) { Text("\($0.name) · \($0.category.rawValue.capitalized)").font(AppTypography.supporting) }
                        if state.outfits.contains(where: { $0.id == snapshot.id }) {
                            NavigationLink(value: ClosetRoute.outfit(snapshot.id)) { Text("Open linked outfit") }.frame(minHeight: 44)
                        } else { Text("Linked outfit unavailable. This memory keeps its recorded snapshot.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                    }
                    PrimaryAction(title: "Edit fit") { state.openFit(memory) }.disabled(request != nil)
                    SecondaryAction(title: "Record wear") {
                        state.recordWear(from: memory)
                    }.disabled(request != nil)
                    Text("A memory, not a wear record. Record wear only through the separate reviewed action.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                } else { AppEmptyState("Memory unavailable", systemImage: "photo") }
                if let error { SemanticFeedback(role: .danger, message: error); if request != nil { Button("Check deletion result", action: delete).frame(minHeight: 44) } }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Fit memory").navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink)
            .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
            .onAppear { state.reloadFits(); state.reloadOutfits() }
            .toolbar { if let memory { ToolbarItem(placement: .topBarTrailing) {
                Menu { Button("Delete memory", role: .destructive) { request = FitDeletionRequest(memory: memory); confirming = true } } label: { Label("More", systemImage: "ellipsis") }.disabled(request != nil)
            } } }
            .alert("Delete this memory?", isPresented: $confirming) {
                Button("Cancel", role: .cancel) { request = nil }
                Button("Delete memory", role: .destructive, action: delete)
            } message: { Text("Removes only this local memory and unshared AQD photo copies. Your outfit, wear history, other memories and original Photos stay.") }
    }
    private func delete() {
        guard let request else { return }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.deleteFit(request); state.reloadFits(); state.retryPhotoCleanup(); dismiss()
        } catch PieceStore.StoreError.staleRevision { self.request = nil; error = "This memory changed. Review the latest version before deleting."; state.reloadFits() }
        catch { self.error = "Deletion is not acknowledged. Check the same operation before changing this memory." }
    }
}
