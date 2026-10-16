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
    var generating = false
    var generationTask: Task<Void, Never>?
    var suggestionAvailability = OutfitSuggestions.availability()
    var proposalSource: String? {
        switch draft.proposalSource {
        case .rules: "Rule-based combination · Review before saving"
        case .appleIntelligence: "Apple Intelligence · On-device draft · Review before saving"
        case nil: nil
        }
    }
    var hasUnsavedChanges: Bool {
        guard saved == nil else { return false }
        if pending || unknown || generating { return true }
        if !(draft.pinnedPieceIDs ?? []).isEmpty || draft.weather != nil || draft.proposalSource != nil { return true }
        if draft.baseRevision > 0 {
            guard let store = state.store,
                  let outfit = try? store.outfit(id: draft.outfitID), outfit.revision == draft.baseRevision,
                  let themes = try? store.themes() else { return true }
            let existingThemes = Set(themes.filter { $0.outfitIDs.contains(outfit.id) }.map(\.id))
            return draft.name != outfit.name || draft.pieceIDs != outfit.pieceIDs
                || draft.mood != outfit.mood || draft.occasion != outfit.occasion
                || (draft.themeIDs.map(Set.init) ?? existingThemes) != existingThemes
        }
        return !draft.name.isEmpty || !draft.pieceIDs.isEmpty || !(draft.themeIDs ?? []).isEmpty
            || !(draft.mood ?? "").isEmpty || !(draft.occasion ?? "").isEmpty
    }

    var needsPieceReview: Bool {
        guard let revisions = draft.reviewedPieceRevisions else { return false }
        return draft.pieceIDs.contains { id in state.pieces.first(where: { $0.id == id })?.revision != revisions[id] }
    }

    init(state: AppState, draft: OutfitDraft) { self.state = state; self.draft = draft; id = draft.id }

    var canSave: Bool {
        !pending && !unknown && !generating && saved == nil && (draft.baseRevision == 0 || hasUnsavedChanges || needsPieceReview) && (try? draft.validatedForSave(pieces: state.pieces)) != nil
    }

    func update(_ change: (inout OutfitDraft) -> Void) {
        guard !pending, !unknown, !generating, saved == nil else { return }
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
        guard !pending, !generating, saved == nil else { return }
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
        guard !pending, !unknown, !generating, saved == nil else { return }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.discardOutfitDraft(id: draft.id)
            state.outfitEditor = nil
        } catch { self.error = "Your draft couldn’t be discarded. Keep it here and retry." }
    }

    func finish(openOutfit: Bool = false) {
        guard saved != nil else { return }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.acknowledgeOutfitReceipt(draft)
            state.outfitEditor = nil; state.reloadOutfits()
            state.reloadThemes()
            if openOutfit { state.openClosetDestination(scope: "Outfits", route: .outfit(draft.outfitID)) }
        } catch { self.error = "The outfit is saved. Retry opening your collection; no additional outfit will be created." }
    }
}

extension AppState {
    func reloadOutfits() {
        do { outfits = try store?.outfits() ?? []; outfitError = nil }
        catch { outfitError = "Your outfits couldn’t be read. Existing data is retained. Retry." }
    }

    func resumeOutfitDraft() {
        guard todayEditor == nil, fitEditor == nil, identityEditor == nil, planAuthoringEditor == nil, outfitEditor == nil, styleEditor == nil, capture == nil, entry.page == .main else { return }
        do {
            guard let store, let draft = try store.outfitDraft() else { return }
            let model = OutfitEditorModel(state: self, draft: draft)
            model.saved = try store.savedOutfit(for: draft)
            outfitEditor = model
        } catch { outfitError = "Your outfit draft couldn’t be read. Keep your app data and retry." }
    }

    func buildOutfit(editing outfit: Outfit? = nil, pieceID: UUID? = nil, firstOutfit: Bool = false, suggest: Bool = false, themeID: UUID? = nil) {
        guard todayEditor == nil, fitEditor == nil, identityEditor == nil, planAuthoringEditor == nil, outfitEditor == nil, styleEditor == nil, capture == nil else { return }
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
            if suggest { draft.stage = .suggest }
            if let themeID { draft.themeIDs = [themeID] }
            if let pieceID {
                draft.select(pieceID); draft.pin(pieceID); draft.starterPieceID = pieceID
                draft.stage = firstOutfit && outfits.isEmpty ? .readiness : suggest ? .suggest : .builder
            }
            try store.saveOutfitDraft(draft)
            outfitEditor = OutfitEditorModel(state: self, draft: draft)
        } catch { outfitError = "An outfit draft couldn’t be opened. Your saved collection hasn’t changed." }
    }
}

extension OutfitEditorModel {
    @discardableResult func applyManualPieces(_ ids: [UUID]) -> Bool {
        guard !pending, !unknown, !generating, saved == nil else { return false }
        do {
            var updated = draft
            updated.pinnedPieceIDs = []
            updated.starterPieceID = nil
            updated.proposalSource = nil
            updated.stage = .builder
            try updated.applyManualSelection(ids, pieces: state.pieces)
            update { $0 = updated }
            return error == nil
        } catch {
            self.error = "These pieces are no longer available. Refresh your closet and choose again. Your previous selection is kept."
            return false
        }
    }

    var readiness: OutfitReadiness { OutfitReadiness(pieces: state.pieces, pinnedIDs: draft.pinnedPieceIDs ?? []) }

    func useRules() {
        guard !pending, !unknown, !generating, readiness.isReady else { return }
        do {
            var updated = draft
            try updated.applyProposal(readiness.candidateIDs, pieces: state.pieces)
            if updated.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { updated.name = "A look from your closet" }
            updated.stage = .review
            updated.proposalSource = .rules
            update { $0 = updated }
        } catch { self.error = "These pieces can’t make that combination. Keep your pin, add a missing category, unpin it or build manually." }
    }

    func suggestOnDevice() {
        guard !pending, !unknown, !generating else { return }
        suggestionAvailability = OutfitSuggestions.availability()
        guard suggestionAvailability == .available else { return }
        generating = true
        let requestedDraft = draft
        let requestedPieces = state.pieces
        generationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.generating = false; self.generationTask = nil }
            do {
                let ids = try await OutfitSuggestions.generate(draft: requestedDraft, pieces: requestedPieces)
                try Task.checkCancellation()
                guard self.draft == requestedDraft else { return }
                self.state.reloadPieces()
                guard ids.allSatisfy({ id in
                    self.state.pieces.first(where: { $0.id == id })?.revision == requestedPieces.first(where: { $0.id == id })?.revision
                }) else { throw OutfitValidationError.stalePieces }
                var updated = requestedDraft
                try updated.applyProposal(ids, pieces: self.state.pieces)
                if updated.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { updated.name = "A look from your closet" }
                updated.stage = .review
                updated.proposalSource = .appleIntelligence
                self.generating = false
                self.update { $0 = updated }
            } catch is CancellationError { }
            catch { self.error = "Suggestions didn’t finish. Your draft and pins are retained. Use a rule-based combination or build manually." }
        }
    }

    func planSavedOutfit() {
        guard let saved, !pending, !unknown else { return }
        let outfitID = saved.id
        finish()
        if state.outfitEditor == nil { state.pendingPlanOutfitID = outfitID }
    }

    func stopGeneration() { generationTask?.cancel() }

    func addMissingPiece(_ category: PieceCategory) {
        guard !pending, !unknown, !generating else { return }
        update { $0.stage = .readiness }
        guard error == nil else { return }
        state.pendingOutfitCaptureCategory = category
        state.outfitEditor = nil
    }
}

extension AppState {
    func openPendingOutfitCapture() {
        if pendingOutfitEditID != nil { resumePendingOutfitEdit(); return }
        if let id = pendingPlanOutfitID {
            pendingPlanOutfitID = nil
            openPlan(outfitID: id)
            return
        }
        guard let category = pendingOutfitCaptureCategory else { return }
        pendingOutfitCaptureCategory = nil
        addPiece()
        if let capture, capture.draft.name.isEmpty, capture.draft.category == nil, capture.draft.photoID == nil {
            capture.update(\.category, value: category)
        }
    }

    func finishOutfitCaptureReturn() {
        if let pieceID = pendingFirstOutfitPieceID {
            pendingFirstOutfitPieceID = nil
            buildOutfit(pieceID: pieceID, firstOutfit: true)
        } else { reloadPieces(); resumeOutfitDraft() }
    }
}


extension OutfitEditorModel {
    func editSavedOutfit() {
        guard !pending, !unknown, let saved else { return }
        do {
            guard let store = state.store, try store.outfit(id: saved.id) != nil else { throw PieceStore.StoreError.staleRevision }
            try store.acknowledgeOutfitReceipt(draft)
            state.pendingOutfitEditID = saved.id
            state.outfitEditor = nil
        } catch { self.error = "This saved outfit couldn’t open for editing. Its receipt is retained; retry." }
    }
}

extension AppState {
    func resumePendingOutfitEdit() {
        guard let id = pendingOutfitEditID else { return }
        pendingOutfitEditID = nil
        do {
            guard let store, let outfit = try store.outfit(id: id) else { throw PieceStore.StoreError.staleRevision }
            buildOutfit(editing: outfit)
        } catch { outfitError = "The saved outfit couldn’t reopen. Your collection is retained; retry from its detail." }
    }
}
