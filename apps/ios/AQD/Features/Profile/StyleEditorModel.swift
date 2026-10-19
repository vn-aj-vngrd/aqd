import AQDCore
import Foundation
import Observation

@MainActor @Observable
final class StyleEditorModel: Identifiable {
    let state: AppState
    var draft: StylePreferenceDraft
    var error: String?
    var pending = false
    var unknown = false
    var saved: SavedStylePreferences?
    nonisolated let id: UUID

    init(state: AppState, draft: StylePreferenceDraft) { self.state = state; self.draft = draft; id = draft.id }

    var hasUnsavedChanges: Bool {
        if saved != nil { return false }
        if pending || unknown || error != nil { return true }
        guard let experience = try? state.store?.localExperience() else { return true }
        guard (experience.style?.revision ?? 0) == draft.baseRevision else { return true }
        return draft.answers != (experience.style?.answers ?? StylePreferences()) || draft.heightInput.map { $0 != HeightInput(body: draft.answers.body) } == true || draft.bodyShapePicker.map { $0 != BodyShapeDraft(current: draft.answers.body.shape) } == true
    }

    func update(_ change: (inout StylePreferenceDraft) -> Void) {
        guard !pending, !unknown, saved == nil else { return }
        var changed = draft
        change(&changed)
        draft = changed
        persist()
    }

    func persist() {
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.saveStyleDraft(draft)
            error = nil
        } catch {
            self.error = "Your latest draft couldn’t be saved. Keep this screen open and retry. Your saved preferences haven’t changed."
        }
    }

    func next() {
        guard draft.isAnswered(draft.page) else { return }
        update { $0.page = $0.editingFromReview ? 6 : min(6, $0.page + 1); $0.editingFromReview = false }
    }

    func save() async {
        guard draft.isComplete else { return }
        await runSave()
    }

    func discard() {
        guard !pending, !unknown else { return }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.discardStyleDraft(id: draft.id)
            finish()
        } catch { self.error = "The draft couldn’t be discarded. It is still retained; retry without changing your saved preferences." }
    }

    func finish(openCloset: Bool = false) {
        if saved != nil {
            do {
                guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
                try store.acknowledgeStyleReceipt(operationID: draft.operationID, openCloset: openCloset)
            } catch { self.error = "Your preferences are saved. The receipt couldn’t close yet; try the same action again."; return }
        }
        if saved != nil && openCloset {
            state.openClosetDestination()
            state.profileSettings = false
            // Swap what sits under the closing sheet now, so it slides away onto the closet instead of flashing Welcome.
            state.reloadEntry()
            state.styleEditor = nil
            return
        }
        if draft.source == .onboarding {
            // Under the closing sheet the tour is already in place, so Show me around goes straight into it.
            if saved != nil { state.reloadEntry() }
            else { state.reloadEntry() }
        } else {
            state.selection = 4
            if state.profileSettings != (draft.source == .settings) { state.profileSettings = draft.source == .settings }
        }
        state.styleEditor = nil
    }
}

extension StyleEditorModel: DraftSaving {
    func persistDraft() throws { try state.requireStore().saveStyleDraft(draft) }
    func commit() throws -> SavedStylePreferences { try state.requireStore().saveStylePreferences(draft) }
    /// A lost acknowledgment is reconciled against the same exact operation before any retry can write again.
    func receipt() throws -> SavedStylePreferences? {
        guard let receipt = try state.requireStore().localExperience().style,
              receipt.operationID == draft.operationID, receipt.answers == draft.answers else { return nil }
        return receipt
    }
    func notSavedMessage() -> String { "Preferences weren’t saved. Your previous preferences and this draft are still here. Retry save, or keep editing." }
    var unknownMessage: String { "The save result is unknown. Keep this draft while AQD checks the same save. No second update will be started." }
}
