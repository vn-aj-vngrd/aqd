import AQDCore
import Foundation
import Observation

@MainActor @Observable
final class LocalIdentityEditorModel: Identifiable {
    let id: UUID
    let state: AppState
    var draft: LocalIdentityDraft
    var saved: LocalProfileIdentity?
    var error: String?
    var pending = false
    var unknown = false
    var importID = UUID()
    var importing = false
    var completedPhotoImportID: UUID?
    private var importTask: Task<Void, Never>?
    init(state: AppState, draft: LocalIdentityDraft) throws {
        self.state = state; self.draft = draft; id = draft.id
        saved = try state.store?.savedIdentity(for: draft)
    }
    var hasUnsavedChanges: Bool {
        saved == nil && (pending || unknown || importing || error != nil || draft.hasChanges)
    }
    var canSave: Bool { !locked && !importing && draft.hasChanges && (try? draft.result()) != nil }
    var locked: Bool { pending || unknown || saved != nil }
    func update(_ change: (inout LocalIdentityDraft) -> Void) {
        guard !locked else { return }
        var value = draft; change(&value); draft = value
        do { guard let store = state.store else { throw PieceStore.StoreError.corruptStore }; try store.saveIdentityDraft(draft); error = nil }
        catch { self.error = "These profile edits could not be retained. Keep the editor open and retry." }
    }
    func cancelImport() { importID = UUID(); importTask?.cancel(); importTask = nil; importing = false }
    func removePhoto() { guard !locked else { return }; cancelImport(); update { $0.photoID = nil; $0.photoRecipe = nil } }
    func importPhoto(_ data: Data) {
        guard !locked else { return }
        cancelImport(); let token = importID; importing = true
        importTask = Task { [weak self] in
            do {
                let photo = try await PhotoPreparer().prepare(data: data)
                guard let self, self.importID == token, !Task.isCancelled, !self.locked else { return }
                guard let store = self.state.store else { throw PieceStore.StoreError.corruptStore }
                _ = try store.acceptPhoto(photo)
                self.update { $0.photoID = photo.id; $0.photoRecipe = nil }; self.importing = false
                if self.error == nil { self.completedPhotoImportID = photo.id }
            } catch {
                guard let self, self.importID == token else { return }
                self.importing = false; self.error = "The photo could not be prepared. Your previous photo and name are retained; choose another or retry."
            }
        }
    }
    func save() async {
        guard !importing else { return }
        await runSave()
        if saved != nil { finish() }
    }
    func finish(discarding: Bool = false) {
        guard !pending, !unknown else { return }
        cancelImport()
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            let retained = try store.identityDraft()
            guard let retained, retained.id == draft.id, retained.operationID == draft.operationID,
                  retained.base == draft.base else { throw PieceStore.StoreError.staleDraft }
            try store.finishIdentityDraft(discarding ? retained : draft, discarding: discarding)
            state.identityEditor = nil; state.reloadIdentity(); state.retryPhotoCleanup()
        } catch { self.error = "This profile task could not close. Keep the draft and retry." }
    }
}

extension AppState {
    func reloadIdentity() {
        do { localIdentity = try store?.localIdentity(); identityError = nil }
        catch { identityError = "Your saved profile could not be read. Keep your local data and retry." }
    }
    func openIdentity() {
        guard !hasActiveEditor else { return }
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            let draft = try store.identityDraft() ?? LocalIdentityDraft(ownerID: store.todayConfiguration().ownerID, base: store.localIdentity())
            if try store.identityDraft() == nil { try store.saveIdentityDraft(draft) }
            identityEditor = try LocalIdentityEditorModel(state: self, draft: draft)
        } catch { identityError = "Profile editing could not open. Your saved identity is retained." }
    }
    func resumeIdentity() {
        guard entry.page == .main else { return }
        do { if try store?.identityDraft() != nil { openIdentity() } }
        catch { identityError = "Your profile draft could not be recovered. Keep the app data." }
    }
}

extension LocalIdentityEditorModel: DraftSaving {
    func persistDraft() throws { try state.requireStore().saveIdentityDraft(draft) }
    func commit() throws -> LocalProfileIdentity { try state.requireStore().saveIdentity(draft) }
    func receipt() throws -> LocalProfileIdentity? { try state.requireStore().savedIdentity(for: draft) }
    func didFinishSave(recovered: Bool) { state.reloadIdentity() }
    func notSavedMessage() -> String { "Profile was not saved. Your edits and previous identity are retained. Retry the same save." }
    var unknownMessage: String { "The result is unknown. Check the same save before editing." }
}
