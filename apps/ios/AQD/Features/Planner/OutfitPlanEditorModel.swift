import AQDCore
import Foundation
import Observation

@MainActor @Observable
final class OutfitPlanEditorModel: Identifiable {
    nonisolated let id: UUID
    let state: AppState
    var draft: OutfitPlanDraft
    var saved: OutfitPlanEntry?
    var error: String?
    var pending = false
    var unknown = false

    init(state: AppState, draft: OutfitPlanDraft) throws {
        self.state = state; self.draft = draft; id = draft.id
        saved = try state.store?.savedPlan(for: draft)
    }
    var availabilityConflict: String? { PlanningAvailability.message(outfit: draft.outfit, day: draft.day, pieces: state.ownedPieces) }
    var hasUnsavedChanges: Bool {
        saved == nil && (pending || unknown || error != nil || draft.hasChanges)
    }
    var canSave: Bool { !pending && !unknown && saved == nil && (draft.baseEntry == nil || draft.hasChanges || draft.baseEntry?.requiresReview == true || draft.baseEntry?.outfitRevision != draft.outfit?.revision) && availabilityConflict == nil && (try? draft.validatedForSave(outfits: state.outfits)) != nil }
    var hasOverlap: Bool {
        state.planEntries.contains { $0.id != draft.entryID && $0.day == draft.day && $0.occasion.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == draft.occasion.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    }
    func update(_ change: (inout OutfitPlanDraft) -> Void) {
        guard !pending, !unknown, saved == nil else { return }
        var changed = draft; change(&changed); draft = changed
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.savePlanDraft(draft); error = nil
        } catch { self.error = "These plan edits couldn’t be retained. Keep the screen open and retry." }
    }
    func save() async { await runSave() }
    func finish(discarding: Bool = false, openPlanner: Bool = false) {
        guard !pending, !unknown else { return }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.finishPlanDraft(draft, discarding: discarding)
            state.planEditor = nil; state.reloadPlanEntries()
            if !discarding, let saved {
                state.plannerDay = saved.day
                if draft.baseEntry == nil {
                    state.recentPlan = saved; state.planUndoDeadline = Date().addingTimeInterval(20)
                    state.planUndoRequest = PlanEntryDeletionRequest(entry: saved); state.planUndoPending = false
                }
            }
            if openPlanner { state.selection = 2 }
        } catch { self.error = "This task couldn’t close. Your plan and draft are retained; retry." }
    }
}

extension AppState {
    func reloadPlanEntries() {
        do {
            let entries = try store?.planEntries() ?? []
            let definitions = try store?.planDefinitions() ?? []
            planEntries = entries; planDefinitions = definitions; planError = nil
        }
        catch { planError = "Your plans couldn’t be read. Existing data is retained; retry." }
    }
    func resumePlanDraft() {
        guard todayEditor == nil, fitEditor == nil, identityEditor == nil, planAuthoringEditor == nil, planEditor == nil, outfitEditor == nil, styleEditor == nil, capture == nil, entry.page == .main else { return }
        do {
            guard let draft = try store?.planDraft() else { return }
            planEditor = try OutfitPlanEditorModel(state: self, draft: draft)
        } catch { planError = "Your plan draft couldn’t be read. Keep the app data and retry." }
    }
    func openPlan(outfitID: UUID? = nil, day: LocalPlanDay = LocalPlanDay(), editing entry: OutfitPlanEntry? = nil, parentPlanID: UUID? = nil) {
        guard todayEditor == nil, fitEditor == nil, identityEditor == nil, planAuthoringEditor == nil, planEditor == nil, outfitEditor == nil, styleEditor == nil, capture == nil else { return }
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            reloadOutfits(); reloadPlanEntries()
            if let retained = try store.planDraft() { planEditor = try OutfitPlanEditorModel(state: self, draft: retained); return }
            let selectedOutfitID = entry?.outfitID ?? outfitID
            let outfit = try selectedOutfitID.flatMap { try store.outfit(id: $0) }
            if selectedOutfitID != nil && outfit == nil { throw PieceStore.StoreError.staleRevision }
            let draft: OutfitPlanDraft
            if let entry { draft = OutfitPlanDraft(editing: entry, outfit: outfit) }
            else { draft = OutfitPlanDraft(ownerID: try store.todayConfiguration().ownerID, outfit: outfit, day: day, planID: parentPlanID) }
            try store.savePlanDraft(draft)
            planEditor = try OutfitPlanEditorModel(state: self, draft: draft)
        } catch { collectionError = "A plan draft couldn’t open. Your existing outfit and plans haven’t changed." }
    }
}

extension AppState {
    func undoRecentPlan() {
        guard let request = planUndoRequest, let deadline = planUndoDeadline, planUndoPending || deadline >= Date() else {
            recentPlan = nil; planUndoRequest = nil; return
        }
        planUndoPending = true
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            try store.deletePlanEntry(request)
            recentPlan = nil; planUndoRequest = nil; planUndoDeadline = nil; planUndoPending = false; reloadPlanEntries()
        } catch { planError = "Undo isn’t acknowledged. Retry the same Undo before changing this entry." }
    }
}

extension OutfitPlanEditorModel: DraftSaving {
    func persistDraft() throws { try state.requireStore().savePlanDraft(draft) }
    func commit() throws -> OutfitPlanEntry { try state.requireStore().savePlan(draft) }
    func receipt() throws -> OutfitPlanEntry? { try state.requireStore().savedPlan(for: draft) }
    func didFinishSave(recovered: Bool) {
        if recovered { state.reloadPieces() }
        state.reloadPlanEntries()
    }
    func notSavedMessage() -> String {
        availabilityConflict ?? "The plan wasn’t saved. Check its current outfit and date, and explicitly keep both if that occasion already has a plan. Your draft is retained."
    }
    var unknownMessage: String { "The save result is unknown. Check the same operation before editing or starting another plan." }
}
