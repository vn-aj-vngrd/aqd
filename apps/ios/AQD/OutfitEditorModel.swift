import AQDCore
import Foundation
import Observation

@MainActor @Observable
final class OutfitEditorModel: Identifiable {
    nonisolated let id: UUID
    let state: AppState
    var draft: OutfitDraft
    var saved: Outfit?
    var error: String?
    var pending = false
    var unknown = false

    init(state: AppState, draft: OutfitDraft) { self.state = state; self.draft = draft; id = draft.id }

    var canSave: Bool {
        !pending && !unknown && saved == nil && (try? draft.validatedForSave(pieces: state.pieces)) != nil
    }

    func update(_ change: (inout OutfitDraft) -> Void) {
        guard !pending, !unknown, saved == nil else { return }
        var changed = draft
        change(&changed)
        draft = changed
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.saveOutfitDraft(draft)
            error = nil
        } catch { self.error = "Your latest edits couldn’t be retained. Keep this screen open and retry. Your saved outfit hasn’t changed." }
    }

    func save() async {
        guard !pending, saved == nil else { return }
        pending = true
        defer { pending = false }
        await Task.yield()
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            if !unknown { try store.saveOutfitDraft(draft) }
            saved = try store.saveOutfit(draft)
            error = nil; unknown = false
            state.reloadOutfits()
        } catch {
            do {
                guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
                if let receipt = try store.savedOutfit(for: draft) {
                    saved = receipt; self.error = nil; unknown = false
                    state.reloadOutfits()
                } else {
                    unknown = false
                    self.error = "The outfit wasn’t saved. Your draft is retained. Check its name and selected pieces, then retry."
                }
            } catch {
                unknown = true
                self.error = "The save result is unknown. Check the same operation again before editing or starting another save."
            }
        }
    }

    func discard() {
        guard !pending, !unknown, saved == nil else { return }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.discardOutfitDraft(id: draft.id)
            state.outfitEditor = nil
        } catch { self.error = "Your draft couldn’t be discarded. Keep it here and retry." }
    }

    func finish(openOutfits: Bool = false) {
        guard saved != nil else { return }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.acknowledgeOutfitReceipt(draft)
            state.outfitEditor = nil; state.reloadOutfits()
            if openOutfits { state.selection = 1; state.closetScope = "Outfits"; state.closetPath.removeAll() }
        } catch { self.error = "The outfit is saved. Retry opening your collection; no additional outfit will be created." }
    }
}

extension AppState {
    func reloadOutfits() {
        do { outfits = try store?.outfits() ?? []; outfitError = nil }
        catch { outfitError = "Your outfits couldn’t be read. Existing data is retained. Retry." }
    }

    func resumeOutfitDraft() {
        guard outfitEditor == nil, styleEditor == nil, capture == nil, entry.page == .main else { return }
        do {
            guard let store, let draft = try store.outfitDraft() else { return }
            let model = OutfitEditorModel(state: self, draft: draft)
            model.saved = try store.savedOutfit(for: draft)
            outfitEditor = model
        } catch { outfitError = "Your outfit draft couldn’t be read. Keep your app data and retry." }
    }

    func buildOutfit(editing outfit: Outfit? = nil, pieceID: UUID? = nil) {
        guard outfitEditor == nil, styleEditor == nil, capture == nil else { return }
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            if let existing = try store.outfitDraft() {
                let model = OutfitEditorModel(state: self, draft: existing)
                model.saved = try store.savedOutfit(for: existing)
                outfitEditor = model
                return
            }
            var draft: OutfitDraft
            if let outfit {
                draft = OutfitDraft(editing: outfit)
                draft.themeIDs = try store.themes().filter { $0.outfitIDs.contains(outfit.id) }.map(\.id)
            }
            else { draft = OutfitDraft(ownerID: try store.todayConfiguration().ownerID) }
            if let pieceID { draft.select(pieceID) }
            try store.saveOutfitDraft(draft)
            outfitEditor = OutfitEditorModel(state: self, draft: draft)
        } catch { outfitError = "An outfit draft couldn’t be opened. Your saved collection hasn’t changed." }
    }
}
