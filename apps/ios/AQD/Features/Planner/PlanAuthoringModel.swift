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
    func availabilityMessage(for slot: PlanSlotDraft) -> String? {
        PlanningAvailability.message(outfit: slot.outfit, day: slot.day, pieces: state.ownedPieces)
    }
    var availabilityConflicts: [String] { draft.slots.compactMap { availabilityMessage(for: $0) } }
    var canReview: Bool { !pending && !unknown && (try? draft.plan.validated()) != nil }
    var hasUnsavedChanges: Bool {
        saved == nil && (pending || unknown || error != nil || draft.hasChanges)
    }
    var needsCompositionReview: Bool {
        draft.slots.contains { slot in
            guard let base = draft.baseEntries?.first(where: { $0.id == slot.id }),
                  let outfit = slot.outfit, base.outfitID == outfit.id else { return false }
            return base.requiresReview || base.outfitRevision != outfit.revision
        }
    }
    var canSave: Bool {
        !pending && !unknown && saved == nil && (draft.basePlan == nil || draft.hasChanges || needsCompositionReview) && availabilityConflicts.isEmpty && (try? draft.validatedForSave(outfits: state.outfits, existing: state.planEntries)) != nil
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
    func fillRoutine() {
        guard let routine = draft.plan.routine else { return }
        state.reloadOutfits(); state.reloadPieces()
        let eligible = Set(state.pieces.filter { $0.availability == .available }.map(\.id))
        let chosen = routine.preferredOutfitIDs.compactMap { id in state.outfits.first { $0.id == id } }
        guard !chosen.isEmpty, chosen.count == routine.preferredOutfitIDs.count,
              chosen.allSatisfy({ Set($0.pieceIDs).isSubset(of: eligible) }) else {
            error = "Choose current outfits with available pieces before filling dates. Manual choices and gaps remain available."; return
        }
        update { draft in
            for i in draft.slots.indices {
                draft.slots[i].outfit = chosen[routine.repetition == .repeatFirst ? 0 : i % chosen.count]
                draft.slots[i].unassignedByChoice = false
            }
            draft.usesRules = true
        }
    }

    func refreshReviewedBase() {
        guard !pending, !unknown, saved == nil, let store = state.store, draft.basePlan != nil else { return }
        do {
            guard let current = try store.planDefinitions().first(where: { $0.id == draft.plan.id }) else { throw PieceStore.StoreError.staleRevision }
            let entries = try store.planEntries().filter { $0.planID == current.id }
            let editable = try PlanAuthoringDraft(editing: current, entries: entries, outfits: store.outfits(),
                scope: draft.editScope ?? .whole, anchorEntryID: draft.anchorEntryID)
            var refreshed = draft
            refreshed.basePlan = current; refreshed.baseEntries = entries; refreshed.plan.revision = current.revision
            guard Set(refreshed.slots.map(\.id)).count == refreshed.slots.count else { throw PlanAuthoringError.invalidSlots }
            let oldBaseIDs = Set((draft.baseEntries ?? []).map(\.id))
            let currentOutfits = try store.outfits()
            var proposed = refreshed.slots.filter { !oldBaseIDs.contains($0.id) }
            for i in proposed.indices {
                if let old = proposed[i].outfit {
                    proposed[i].outfit = currentOutfits.first { $0.id == old.id }
                    if proposed[i].outfit == nil { proposed[i].unassignedByChoice = false }
                }
            }
            refreshed.slots = editable.slots + proposed
            if refreshed.editScope == .entry { refreshed.plan = current }
            try refreshed.rebuildDates()
            draft = refreshed
            try store.savePlanAuthoringDraft(draft)
            state.reloadPlanEntries(); state.reloadOutfits(); error = nil
        } catch { self.error = "The reviewed source couldn’t refresh. Keep this draft or cancel and reopen the current routine." }
    }

    func save() async { await runSave() }
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
        guard todayEditor == nil, fitEditor == nil, identityEditor == nil, planAuthoringEditor == nil, planEditor == nil, outfitEditor == nil, wearEditor == nil,
              styleEditor == nil, capture == nil, entry.page == .main else { return }
        do {
            guard let draft = try store?.planAuthoringDraft() else { return }
            planAuthoringEditor = try PlanAuthoringModel(state: self, draft: draft)
        } catch { planError = "Your multi-day plan draft couldn’t open. Keep the app data and retry." }
    }
    func openPlanAuthoring(day: LocalPlanDay, routine: Bool = false, trip: Bool = false) {
        guard todayEditor == nil, fitEditor == nil, identityEditor == nil, planAuthoringEditor == nil, planEditor == nil, outfitEditor == nil, wearEditor == nil,
              styleEditor == nil, capture == nil else { return }
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            let draft: PlanAuthoringDraft
            if let retained = try store.planAuthoringDraft() { draft = retained }
            else {
                var end = day
                if routine || trip {
                    var calendar = Calendar(identifier: .gregorian)
                    let zone = TimeZone(identifier: day.timeZoneID) ?? .current; calendar.timeZone = zone
                    guard let date = calendar.date(byAdding: .day, value: 13, to: try day.date()) else { throw PlanValidationError.invalidDay }
                    end = LocalPlanDay(date: date, timeZone: zone)
                }
                draft = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: store.todayConfiguration().ownerID, start: day, end: end,
                    routine: routine ? RoutineConfiguration() : nil, trip: trip ? TripConfiguration() : nil))
                try store.savePlanAuthoringDraft(draft)
            }
            reloadPlanEntries(); reloadOutfits()
            planAuthoringEditor = try PlanAuthoringModel(state: self, draft: draft)
        } catch { collectionError = "A multi-day plan draft couldn’t open. Your existing calendar is unchanged." }
    }
}

extension AppState {
    func editPlanDefinition(_ plan: PlanDefinition, scope: RoutineEditScope, anchorEntryID: UUID?) {
        guard todayEditor == nil, fitEditor == nil, identityEditor == nil, planAuthoringEditor == nil, planEditor == nil, outfitEditor == nil, wearEditor == nil, styleEditor == nil, capture == nil else { return }
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            if let retained = try store.planAuthoringDraft() {
                planAuthoringEditor = try PlanAuthoringModel(state: self, draft: retained); return
            }
            guard let current = try store.planDefinitions().first(where: { $0.id == plan.id }) else { throw PieceStore.StoreError.staleRevision }
            let entries = try store.planEntries().filter { $0.planID == plan.id }
            let draft = try PlanAuthoringDraft(editing: current, entries: entries, outfits: store.outfits(), scope: scope, anchorEntryID: anchorEntryID)
            try store.savePlanAuthoringDraft(draft)
            reloadPlanEntries(); reloadOutfits()
            planAuthoringEditor = try PlanAuthoringModel(state: self, draft: draft)
        } catch { collectionError = "The routine couldn’t open for this edit scope. Your saved entries and history are retained." }
    }
}

extension PlanAuthoringModel: DraftSaving {
    func persistDraft() throws { try state.requireStore().savePlanAuthoringDraft(draft) }
    func commit() throws -> PlanAuthoringReceipt { try state.requireStore().savePlanAuthoring(draft) }
    func receipt() throws -> PlanAuthoringReceipt? { try state.requireStore().savedPlanAuthoring(draft) }
    func didFinishSave(recovered: Bool) {
        if recovered { state.reloadPieces(); state.reloadOutfits() }
        state.reloadPlanEntries()
    }
    func notSavedMessage() -> String {
        availabilityConflicts.isEmpty
            ? "The plan wasn’t saved. Review its dates, current outfits, intentional gaps and conflict choices, then retry."
            : availabilityConflicts.joined(separator: "\n")
    }
    var unknownMessage: String { "The result is unknown. Check this same save before editing or starting another plan." }
}
