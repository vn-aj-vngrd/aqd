import AQDCore
import Foundation
import Observation

@MainActor @Observable
final class PlanAuthoringModel: Identifiable {
    nonisolated let id: UUID
    let state: AppState
    var draft: PlanAuthoringDraft
    var saved: PlanAuthoringReceipt?
    var error: String?
    var pending = false
    var unknown = false
    init(state: AppState, draft: PlanAuthoringDraft) throws {
        self.state = state; self.draft = draft; id = draft.id
        saved = try state.store?.savedPlanAuthoring(draft)
    }
    var conflicts: [OutfitPlanEntry] { draft.conflicts(in: state.planEntries) }
    var canReview: Bool { !pending && !unknown && (try? draft.plan.validated()) != nil }
    var canSave: Bool {
        !pending && !unknown && saved == nil && (try? draft.validatedForSave(outfits: state.outfits, existing: state.planEntries)) != nil
    }
    func update(invalidateConflicts: Bool = true, _ change: (inout PlanAuthoringDraft) -> Void) {
        guard !pending, !unknown, saved == nil else { return }
        var value = draft; change(&value)
        if invalidateConflicts { value.resolutions = [] }
        draft = value
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.savePlanAuthoringDraft(draft); error = nil
        } catch { self.error = "These plan edits couldn’t be retained. Keep this task open and retry; the calendar is unchanged." }
    }
    func dates(_ change: (inout PlanDefinition) -> Void) {
        update { draft in
            change(&draft.plan)
            do { try draft.rebuildDates() } catch { /* Retain invalid input for correction; Save stays disabled. */ }
        }
    }
    func chooseConflict(_ entry: OutfitPlanEntry, choice: PlanConflictChoice) {
        update(invalidateConflicts: false) { draft in
            draft.resolutions.removeAll { $0.existing.id == entry.id }
            draft.resolutions.append(PlanConflictResolution(existing: entry, choice: choice))
        }
    }
    func save() async {
        guard !pending, saved == nil else { return }
        pending = true; defer { pending = false }
        await Task.yield()
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            if !unknown { try store.savePlanAuthoringDraft(draft) }
            saved = try store.savePlanAuthoring(draft); unknown = false; error = nil; state.reloadPlanEntries()
        } catch {
            do {
                guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
                saved = try store.savedPlanAuthoring(draft); unknown = false
                self.error = saved == nil ? "The plan wasn’t saved. Review its dates, current outfits, intentional gaps and conflict choices, then retry." : nil
                state.reloadPlanEntries(); state.reloadOutfits()
            } catch { unknown = true; self.error = "The result is unknown. Check this same save before editing or starting another plan." }
        }
    }
    func finish(discarding: Bool = false, openPlan: Bool = false) {
        guard !pending, !unknown else { return }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.finishPlanAuthoring(draft, discarding: discarding)
            state.planAuthoringEditor = nil; state.reloadPlanEntries()
            if let saved, openPlan {
                state.selection = 2; state.plannerDay = saved.plan.start; state.plannerPath = [.plan(saved.plan.id)]
            }
        } catch { self.error = "This task couldn’t close. Its draft and saved records are retained; retry." }
    }
}

extension AppState {
    func resumePlanAuthoring() {
        guard planAuthoringEditor == nil, planEditor == nil, outfitEditor == nil, wearEditor == nil,
              styleEditor == nil, capture == nil, entry.page == .main else { return }
        do {
            guard let draft = try store?.planAuthoringDraft() else { return }
            planAuthoringEditor = try PlanAuthoringModel(state: self, draft: draft)
        } catch { planError = "Your multi-day plan draft couldn’t open. Keep the app data and retry." }
    }
    func openPlanAuthoring(day: LocalPlanDay) {
        guard planAuthoringEditor == nil, planEditor == nil, outfitEditor == nil, wearEditor == nil,
              styleEditor == nil, capture == nil else { return }
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            let draft: PlanAuthoringDraft
            if let retained = try store.planAuthoringDraft() { draft = retained }
            else {
                draft = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: store.todayConfiguration().ownerID, start: day, end: day))
                try store.savePlanAuthoringDraft(draft)
            }
            reloadPlanEntries(); reloadOutfits()
            planAuthoringEditor = try PlanAuthoringModel(state: self, draft: draft)
        } catch { collectionError = "A multi-day plan draft couldn’t open. Your existing calendar is unchanged." }
    }
}
