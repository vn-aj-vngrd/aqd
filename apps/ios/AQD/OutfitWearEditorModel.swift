import AQDCore
import Foundation
import Observation

@MainActor @Observable
final class OutfitWearEditorModel: Identifiable {
    nonisolated let id: UUID
    let state: AppState
    var draft: OutfitWearDraft
    var pieces: [WardrobePiece] = []
    var saved: OutfitWearRecord?
    var duplicate: OutfitWearRecord?
    var error: String?
    var pending = false
    var unknown = false

    init(state: AppState, draft: OutfitWearDraft) throws {
        self.state = state; self.draft = draft; id = draft.id
        guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
        saved = try store.savedWear(for: draft)
        pieces = try store.ownedPiecesForWear()
        duplicate = try store.matchingWear(for: draft)
    }
    var canSave: Bool { !pending && !unknown && saved == nil && (try? draft.validatedForSave(pieces: pieces)) != nil }
    func update(_ change: (inout OutfitWearDraft) -> Void) {
        guard !pending, !unknown, saved == nil else { return }
        var changed = draft; change(&changed); changed.acceptedDuplicateID = nil; draft = changed
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.saveWearDraft(draft)
            duplicate = try store.matchingWear(for: draft); error = nil
        } catch { self.error = "These wear edits couldn’t be retained. Keep the screen open and retry." }
    }
    func save(useExisting: Bool = false) async {
        guard !pending, saved == nil else { return }
        if useExisting && !unknown {
            do {
                guard let store = state.store, let existing = try store.matchingWear(for: draft) else { throw PieceStore.StoreError.staleRevision }
                draft.acceptedDuplicateID = existing.id
                try store.saveWearDraft(draft)
            } catch { self.error = "The matching record changed. Review the current history before retrying."; return }
        }
        pending = true
        defer { pending = false }
        await Task.yield()
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            if !unknown { try store.saveWearDraft(draft) }
            saved = try store.saveWear(draft); unknown = false; error = nil; state.reloadWear()
        } catch {
            do {
                guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
                saved = try store.savedWear(for: draft)
                duplicate = try store.matchingWear(for: draft)
                unknown = false
                self.error = saved == nil ? "Wear wasn’t recorded. Check the day and current pieces, or use the matching existing record. Your draft is retained." : nil
                state.reloadWear()
            } catch { unknown = true; self.error = "The result is unknown. Check the same operation before editing or recording again." }
        }
    }
    func finish(discarding: Bool = false) {
        guard !pending, !unknown else { return }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.finishWearDraft(draft, discarding: discarding)
            state.wearEditor = nil; state.reloadWear()
        } catch { self.error = "This task couldn’t close. The draft and history are retained; retry." }
    }
}

extension AppState {
    func reloadWear() {
        do { wearRecords = try store?.wearRecords() ?? []; wearError = nil }
        catch { wearError = "Your wear history couldn’t be read. Keep your existing data and retry." }
    }
    func resumeWearDraft() {
        guard planAuthoringEditor == nil, wearEditor == nil, planEditor == nil, outfitEditor == nil, styleEditor == nil, capture == nil, entry.page == .main else { return }
        do {
            guard let draft = try store?.wearDraft() else { return }
            wearEditor = try OutfitWearEditorModel(state: self, draft: draft)
        } catch { wearError = "Your wear draft couldn’t be read. Keep the app data for recovery." }
    }
    func openWear(outfitID: UUID) {
        guard planAuthoringEditor == nil, wearEditor == nil, planEditor == nil, outfitEditor == nil, styleEditor == nil, capture == nil else { return }
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            if let retained = try store.wearDraft() { wearEditor = try OutfitWearEditorModel(state: self, draft: retained); return }
            guard let outfit = try store.outfit(id: outfitID) else { throw PieceStore.StoreError.staleRevision }
            let pieces = try outfit.pieceIDs.map { id -> WardrobePiece in
                guard let value = try store.piece(id: id) else { throw PieceStore.StoreError.staleRevision }
                return value
            }
            let draft = OutfitWearDraft(ownerID: outfit.ownerID, outfitID: outfit.id, pieces: pieces)
            try store.saveWearDraft(draft)
            wearEditor = try OutfitWearEditorModel(state: self, draft: draft)
        } catch { collectionError = "A wear draft couldn’t open. Your saved outfit and history haven’t changed." }
    }
}
