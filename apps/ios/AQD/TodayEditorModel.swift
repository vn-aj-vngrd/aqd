import AQDCore
import Foundation
import Observation

@Observable @MainActor final class TodayEditorModel: Identifiable, PhotoEditingOwner {
    let state: AppState
    var draft: TodayLayoutDraft
    var pending = false
    var unknown = false
    var error: String?
    var saved: TodayConfiguration?
    var draftFailed = false
    var importing = false
    var importID = UUID()
    @ObservationIgnored private var importTask: Task<Void, Never>?
    nonisolated let id: UUID
    var locked: Bool { pending || unknown || saved != nil }
    var errorText: String? { error }
    var editingPhotoID: UUID? { draft.nested?.options?.personal?.photoID }
    var editingPhotoRecipe: PhotoEditRecipe { draft.nested?.options?.personal?.photoRecipe ?? .fitOriginal }
    init(state: AppState, draft: TodayLayoutDraft, saved: TodayConfiguration? = nil) { self.state = state; self.draft = draft; self.saved = saved; id = draft.id }
    func update(_ change: (inout TodayLayoutDraft) throws -> Void) {
        guard !locked else { return }
        var changed = draft
        do {
            try change(&changed)
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.saveTodayDraft(changed); draft = changed; error = nil; draftFailed = false
        } catch TodayLayoutError.minimumOne {
            self.error = "Keep at least one widget. Add another before removing this one."
        } catch { draft = changed; self.error = "These edits could not be retained. Keep this screen open and retry. Your saved layout is unchanged."; draftFailed = true }
    }
    func begin(_ instance: TodayWidgetInstance) {
        cancelImport()
        update { draft in
            draft.nested = instance; draft.nestedBase = instance
            if draft.nested?.options == nil { draft.nested?.options = TodayWidgetOptions() }
            if instance.kind == .personalNote || instance.kind == .personalPhoto, instance.options?.personal == nil {
                let card = TodayPersonalCard(ownerID: draft.base.ownerID, kind: instance.kind)
                draft.nested?.options?.personal = card
            }
            draft.nestedBase = draft.nested
        }
    }
    func nested(_ change: (inout TodayWidgetInstance) -> Void) {
        update { draft in guard var value = draft.nested else { return }; change(&value); draft.nested = value }
    }
    var canApply: Bool {
        guard !locked, !importing, let nested = draft.nested else { return false }
        return (try? nested.validatedContent(ownerID: draft.base.ownerID)) != nil
    }
    func applyNested() {
        guard canApply else { return }
        cancelImport()
        update { draft in
            guard var nested = draft.nested else { return }
            if var card = nested.options?.personal,
               let old = draft.base.instances.compactMap({ $0.options?.personal }).first(where: { $0.id == card.id }), card != old {
                card.revision = old.revision + 1; nested.options?.personal = card
            }
            if let index = draft.value.instances.firstIndex(where: { $0.id == nested.id }) { draft.value.instances[index] = nested }
            else { draft.value.instances.append(nested) }
            draft.nested = nil; draft.nestedBase = nil
        }
    }
    func cancelNested() { cancelImport(); update { $0.nested = nil; $0.nestedBase = nil } }
    func move(_ id: UUID, by offset: Int) {
        update { draft in
            guard let index = draft.value.instances.firstIndex(where: { $0.id == id }), draft.value.instances.indices.contains(index + offset) else { return }
            draft.value.instances.swapAt(index, index + offset)
        }
    }
    func save() async {
        guard !pending, !importing, saved == nil else { return }
        if !draft.hasChanges && !unknown { finish(discarding: true); return }
        pending = true; defer { pending = false }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            if !unknown && draftFailed { try store.saveTodayDraft(draft); draftFailed = false }
            if let receipt = try store.savedTodayLayout(draft) { saved = receipt }
            else { saved = try store.saveTodayLayout(draft) }
            unknown = false; error = nil; state.reloadToday()
            finish()
        } catch {
            do {
                if let receipt = try state.store?.savedTodayLayout(draft) { saved = receipt; unknown = false; state.reloadToday(); self.error = nil; finish() }
                else { unknown = false; self.error = "Today was not saved. Your previous layout and draft are retained. Retry or keep editing." }
            } catch { unknown = true; self.error = "The save result could not be read. Check the result before editing or leaving." }
        }
    }
    func finish(discarding: Bool = false) {
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            let retained = try store.todayDraft()
            if let retained {
                guard retained.id == draft.id, retained.operationID == draft.operationID else { throw PieceStore.StoreError.staleDraft }
                try store.finishTodayDraft(discarding ? retained : draft, discarding: discarding)
            } else {
                guard discarding, !draft.hasChanges else { throw PieceStore.StoreError.staleDraft }
            }
            cancelImport(); state.todayEditor = nil; state.reloadToday(); state.retryPhotoCleanup()
        } catch { self.error = "Your Today task could not close. Its draft and acknowledged result are retained. Retry." }
    }
    func cancelImport() { importID = UUID(); importTask?.cancel(); importTask = nil; importing = false }
    func importPhoto(_ data: Data) {
        guard !locked, draft.nested?.kind == .personalPhoto else { return }
        cancelImport(); let token = importID, instanceID = draft.nested?.id; importing = true
        importTask = Task {
            do {
                let prepared = try await PhotoPreparer().prepare(data: data)
                guard !Task.isCancelled, token == importID, draft.nested?.id == instanceID, !locked else { return }
                guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
                _ = try store.acceptPhoto(prepared); importing = false
                nested { $0.options?.personal?.photoID = prepared.id; $0.options?.personal?.photoRecipe = .fitOriginal }
            } catch { if token == importID { importing = false; self.error = "The photo could not be prepared. Your previous photo and caption are retained." } }
        }
    }
    func originalPhotoData() -> Data? { editingPhotoID.flatMap { try? state.store?.originalPhoto(id: $0) } }
    func originalThumbnailData() -> Data? { editingPhotoID.flatMap { try? state.store?.thumbnailPhoto(id: $0) } }
    func applyPhotoEdit(_ recipe: PhotoEditRecipe, sourceID: UUID, previousRecipe: PhotoEditRecipe) async -> Bool {
        guard !locked, editingPhotoID == sourceID, editingPhotoRecipe == previousRecipe else { return false }
        cancelImport(); let token = importID, instanceID = draft.nested?.id; importing = true
        do {
            guard let data = originalPhotoData() else { throw PieceStore.StoreError.missingPhoto }
            let prepared = try await PhotoPreparer().render(data: data, sourcePhotoID: sourceID, recipe: recipe)
            guard !Task.isCancelled, token == importID, draft.nested?.id == instanceID, editingPhotoID == sourceID, editingPhotoRecipe == previousRecipe, !locked else { return false }
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.acceptPhotoEdit(prepared); importing = false; nested { $0.options?.personal?.photoRecipe = recipe }; return error == nil
        } catch { if token == importID { importing = false; self.error = "The photo edit could not be applied. Retry or cancel." }; return false }
    }
}

extension AppState {
    func resumeTodayDraft() {
        guard entry.page == .main else { return }
        do { if try store?.todayDraft() != nil { openTodayEditor() } }
        catch { todayError = "Your Today task could not be recovered. Keep the app data." }
    }
    func openTodayEditor() {
        guard todayEditor == nil, fitEditor == nil, identityEditor == nil, capture == nil, outfitEditor == nil, planEditor == nil, wearEditor == nil, planAuthoringEditor == nil, styleEditor == nil, themeEditor == nil else { return }
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            let draft: TodayLayoutDraft
            if let retained = try store.todayDraft() { draft = retained }
            else { draft = TodayLayoutDraft(base: try store.todayConfiguration()) }
            todayEditor = TodayEditorModel(state: self, draft: draft, saved: try store.savedTodayLayout(draft))
        } catch { todayError = "Your Today draft could not open. Saved data has not been reset." }
    }
    func undoTodayLayout() {
        do {
            guard let store, try store.todayDraft() == nil, let undo = try store.todayUndo() else { return }
            var draft = TodayLayoutDraft(base: undo.current)
            draft.value.instances = undo.previous.instances
            let retained = try store.todayPersonalCards()
            for index in draft.value.instances.indices {
                if var card = draft.value.instances[index].options?.personal, let current = retained.first(where: { $0.id == card.id }), current != card {
                    card.revision = current.revision + 1; draft.value.instances[index].options?.personal = card
                }
            }
            try store.saveTodayDraft(draft)
            todayEditor = TodayEditorModel(state: self, draft: draft)
            Task { await todayEditor?.save() }
        } catch { todayError = "Layout Undo could not complete. Your saved layout is retained." }
    }
}
