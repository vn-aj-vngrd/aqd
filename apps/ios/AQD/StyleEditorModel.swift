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
        guard !pending, saved == nil, draft.isComplete else { return }
        pending = true
        defer { pending = false }
        await Task.yield()
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            if !unknown { try store.saveStyleDraft(draft) }
            saved = try store.saveStylePreferences(draft)
            unknown = false; error = nil
        } catch {
            // A lost acknowledgment must be reconciled against the same exact
            // operation before editing or retry can produce another write.
            do {
                guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
                let value = try store.localExperience()
                if let receipt = value.style, receipt.operationID == draft.operationID, receipt.answers == draft.answers {
                    saved = receipt; unknown = false; self.error = nil
                } else {
                    unknown = false
                    self.error = "Preferences weren’t saved. Your previous preferences and this draft are still here. Retry save, or keep editing."
                }
            } catch {
                unknown = true
                self.error = "The save result is unknown. Keep this draft while AQD checks the same save. No second update will be started."
            }
        }
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
            state.reloadEntryAfterStyle = true
            state.styleEditor = nil
            return
        }
        if draft.source == .onboarding {
            if saved != nil { state.reloadEntryAfterStyle = true }
            else { state.reloadEntry() }
        } else {
            state.selection = 4
            if state.profileSettings != (draft.source == .settings) { state.profileSettings = draft.source == .settings }
        }
        state.styleEditor = nil
    }
}
