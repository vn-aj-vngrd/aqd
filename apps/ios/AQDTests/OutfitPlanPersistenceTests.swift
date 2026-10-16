import AQDCore
import Foundation
import SwiftData
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor
struct OutfitPlanPersistenceTests {
    private func seedOutfit(_ store: PieceStore) async throws -> Outfit {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in
            UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32))
        }
        let photo = try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 0.9)))
        _ = try store.acceptPhoto(photo)
        let piece = try store.savePiece(PieceDraft(name: "Shirt", category: .tops, photoID: photo.id), operationID: UUID())
        var draft = OutfitDraft(ownerID: try store.todayConfiguration().ownerID)
        draft.name = "Weekend"; draft.select(piece.id)
        try store.saveOutfitDraft(draft)
        let outfit = try store.saveOutfit(draft)
        try store.acknowledgeOutfitReceipt(draft)
        return outfit
    }

    @Test func planReopensWithExactDateAndRetryCreatesOneEntry() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        let outfit = try await seedOutfit(#require(store))
        var draft = OutfitPlanDraft(ownerID: outfit.ownerID, outfit: outfit,
            day: LocalPlanDay(year: 2026, month: 11, day: 1, timeZoneID: "America/New_York"))
        draft.occasion = "Afternoon"
        try #require(store).savePlanDraft(draft)
        let saved = try #require(store).savePlan(draft)
        #expect(saved.day.key == "2026-11-01")
        #expect(saved.state == .planned)
        #expect(saved.outfitID == outfit.id)
        #expect(try #require(store).savePlan(draft) == saved)
        store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).planEntries() == [saved])
        #expect(try #require(store).planDraft() == draft)
        #expect(try #require(store).savedPlan(for: draft) == saved)
        #expect(try #require(store).outfit(id: outfit.id) == outfit)
        try #require(store).finishPlanDraft(draft)
        var overlap = OutfitPlanDraft(ownerID: outfit.ownerID, outfit: outfit, day: draft.day)
        overlap.occasion = " Afternoon "
        try #require(store).savePlanDraft(overlap)
        #expect(throws: PlanValidationError.overlap) { try #require(store).savePlan(overlap) }
        overlap.allowsOverlap = true
        try #require(store).savePlanDraft(overlap)
        _ = try #require(store).savePlan(overlap)
        #expect(try #require(store).planEntries().count == 2)
        store = nil
    }

    @Test func unassignedIsExplicitAndFailedOrUnknownSaveRetainsExactOperation() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var deny = false, loseAck = false
        var store: PieceStore? = try PieceStore(directory: directory,
            beforeOutfitSave: { if deny { throw CocoaError(.fileWriteNoPermission) } },
            afterOutfitSave: { if loseAck { throw CocoaError(.fileReadUnknown) } })
        var draft = OutfitPlanDraft(ownerID: try #require(store).todayConfiguration().ownerID)
        try #require(store).savePlanDraft(draft)
        #expect(throws: PlanValidationError.invalidOutfit) { try #require(store).savePlan(draft) }
        draft.unassignedByChoice = true
        try #require(store).savePlanDraft(draft)
        deny = true
        #expect(throws: (any Error).self) { try #require(store).savePlan(draft) }
        #expect(try #require(store).planEntries().isEmpty)
        #expect(try #require(store).planDraft() == draft)
        deny = false; loseAck = true
        #expect(throws: (any Error).self) { try #require(store).savePlan(draft) }
        let saved = try #require(store).savePlan(draft)
        #expect(saved.state == .unassigned)
        #expect(saved.outfitID == nil)
        #expect(try #require(store).planEntries() == [saved])
        store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).savedPlan(for: draft) == saved)
        try #require(store).finishPlanDraft(draft)
        #expect(try #require(store).planDraft() == nil)
        store = nil
    }

    @Test func v5MigrationPreservesOutfitAndThemeMembershipBeforePlanning() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let today = TodayConfiguration(ownerID: UUID())
        let piece = WardrobePiece(id: UUID(), name: "Legacy piece", category: .tops, photoID: UUID())
        let outfit = Outfit(id: UUID(), ownerID: today.ownerID, name: "Legacy look", pieceIDs: [piece.id])
        let theme = OutfitTheme(ownerID: today.ownerID, name: "Weekend", outfitIDs: [outfit.id])
        do {
            let schema = Schema(versionedSchema: LocalSchemaV5.self)
            let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            context.insert(StoredTodayConfiguration(today))
            context.insert(try StoredLocalExperience(LocalExperience(enteredPrivateSpace: true)))
            context.insert(StoredPiece(piece)); context.insert(StoredPhoto(id: piece.photoID, pixelWidth: 24, pixelHeight: 32))
            context.insert(try StoredOutfit(outfit)); context.insert(try StoredOutfitTheme(theme))
            try context.save()
        }
        try Data("AQD-piece-store:5".utf8).write(to: directory.appendingPathComponent("schema-version"))
        let store = try PieceStore(directory: directory)
        #expect(try store.outfits() == [outfit])
        #expect(try store.themes() == [theme])
        let draft = OutfitPlanDraft(ownerID: today.ownerID, outfit: outfit)
        try store.savePlanDraft(draft)
        _ = try store.savePlan(draft)
        #expect(try store.themes() == [theme])
        #expect(try store.outfit(id: outfit.id) == outfit)
    }
    @Test func movingEntryRetainsIdentityOtherAssignmentsAndExactRetry() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let outfit = try await seedOutfit(store)
        var saved: [OutfitPlanEntry] = []
        for day in [1, 2] {
            let draft = OutfitPlanDraft(ownerID: outfit.ownerID, outfit: outfit,
                day: LocalPlanDay(year: 2026, month: 11, day: day, timeZoneID: "America/New_York"))
            try store.savePlanDraft(draft); saved.append(try store.savePlan(draft)); try store.finishPlanDraft(draft)
        }
        var edit = OutfitPlanDraft(editing: saved[0], outfit: outfit)
        edit.day.day = 3; edit.occasion = "Moved afternoon"
        try store.savePlanDraft(edit)
        let updated = try store.savePlan(edit)
        #expect(try store.savePlan(edit) == updated)
        try store.finishPlanDraft(edit)
        let reopened = try PieceStore(directory: directory)
        #expect(updated.id == saved[0].id)
        #expect(updated.planID == saved[0].planID)
        #expect(updated.day.key == "2026-11-03")
        #expect(updated.day.timeZoneID == "America/New_York")
        #expect(updated.revision == 2)
        #expect(try reopened.planEntries().contains(saved[1]))
        #expect(try reopened.planEntries().count == 2)
        let stale = OutfitPlanDraft(editing: saved[0], outfit: outfit)
        try reopened.savePlanDraft(stale)
        #expect(throws: PieceStore.StoreError.staleRevision) { try reopened.savePlan(stale) }
        #expect(try reopened.planEntries().contains(updated))
    }

    @Test func removalAndSaveUndoTouchOnlyReviewedEntryAndReconcileUnknownWrite() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var deny = false, loseAck = false
        let store = try PieceStore(directory: directory,
            beforeOutfitSave: { if deny { throw CocoaError(.fileWriteNoPermission) } },
            afterOutfitSave: { if loseAck { throw CocoaError(.fileReadUnknown) } })
        let outfit = try await seedOutfit(store)
        let state = AppState(store: store)
        let day = LocalPlanDay(year: 2026, month: 11, day: 1, timeZoneID: "Asia/Manila")
        state.plannerDay = day; state.plannerMode = .month
        state.openPlan(outfitID: outfit.id, day: day)
        let editor = try #require(state.planEditor)
        await editor.save(); let saved = try #require(editor.saved)
        editor.finish(openPlanner: true)
        #expect(state.plannerDay == day)
        #expect(state.plannerMode == .month)
        #expect(state.recentPlan == saved)
        let request = try #require(state.planUndoRequest)
        deny = true
        #expect(throws: (any Error).self) { try store.deletePlanEntry(request) }
        #expect(try store.planEntries() == [saved])
        deny = false; loseAck = true
        state.undoRecentPlan()
        #expect(state.planUndoPending)
        #expect(state.recentPlan == saved)
        state.planUndoDeadline = .distantPast
        state.undoRecentPlan()
        #expect(!state.planUndoPending)
        #expect(state.planError == nil)
        #expect(state.recentPlan == nil)
        #expect(try store.planEntries().isEmpty)
        #expect(try store.outfit(id: outfit.id) == outfit)
        #expect(try store.wearRecords().isEmpty)
        state.store = nil
    }

    @Test func v10MigrationRetainsCalendarIntentBeforeEntryMutation() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let today = TodayConfiguration(ownerID: UUID())
        let entry = OutfitPlanEntry(id: UUID(), planID: UUID(), ownerID: today.ownerID,
            day: LocalPlanDay(year: 2026, month: 11, day: 1, timeZoneID: "America/New_York"), occasion: "Retain gap",
            outfitID: nil, outfitRevision: nil, state: .unassigned)
        do {
            let schema = Schema(versionedSchema: LocalSchemaV10.self)
            let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            context.insert(StoredTodayConfiguration(today)); context.insert(try StoredLocalExperience(LocalExperience(enteredPrivateSpace: true)))
            context.insert(try StoredOutfitPlanEntry(entry)); try context.save()
        }
        try Data("AQD-piece-store:10".utf8).write(to: directory.appendingPathComponent("schema-version"))
        let store = try PieceStore(directory: directory)
        #expect(try store.planEntries() == [entry])
        let request = PlanEntryDeletionRequest(entry: entry)
        try store.deletePlanEntry(request); try store.deletePlanEntry(request)
        #expect(try store.planEntries().isEmpty)
        #expect(try store.wearRecords().isEmpty)
    }
    @Test func outfitEditFlagsFutureAssignmentsWithoutRewritingPastIntent() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let outfit = try await seedOutfit(store)
        for year in [2000, 2099] {
            let draft = OutfitPlanDraft(ownerID: outfit.ownerID, outfit: outfit,
                day: LocalPlanDay(year: year, month: 1, day: 1, timeZoneID: "Asia/Manila"))
            try store.savePlanDraft(draft); _ = try store.savePlan(draft); try store.finishPlanDraft(draft)
        }
        let before = try store.planEntries()
        var edit = OutfitDraft(editing: outfit); edit.name = "Updated composition"
        try store.saveOutfitDraft(edit); _ = try store.saveOutfit(edit); try store.acknowledgeOutfitReceipt(edit)
        let entries = try store.planEntries()
        #expect(entries.first == before.first)
        #expect(entries.last?.requiresReview == true)
        #expect(entries.last?.outfitID == outfit.id)
        #expect(entries.last?.day.key == "2099-01-01")
        #expect(try store.wearRecords().isEmpty)
    }
    @Test func bulkPlanSavesFourteenReviewedDatesAtomicallyWithKeepBothAndExactRetry() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var deny = false, loseAck = false
        let store = try PieceStore(directory: directory,
            beforeOutfitSave: { if deny { throw CocoaError(.fileWriteNoPermission) } },
            afterOutfitSave: { if loseAck { throw CocoaError(.fileReadUnknown) } })
        let outfit = try await seedOutfit(store)
        let start = LocalPlanDay(year: 2026, month: 11, day: 1, timeZoneID: "America/New_York")
        let single = OutfitPlanDraft(ownerID: outfit.ownerID, outfit: outfit, day: start)
        try store.savePlanDraft(single); let previous = try store.savePlan(single); try store.finishPlanDraft(single)
        var draft = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: outfit.ownerID, name: "Two weeks", start: start,
            end: LocalPlanDay(year: 2026, month: 11, day: 14, timeZoneID: start.timeZoneID)))
        draft.slots[0].outfit = outfit
        for i in draft.slots.indices where i > 0 { draft.slots[i].unassignedByChoice = true }
        try store.savePlanAuthoringDraft(draft)
        #expect(throws: PlanAuthoringError.unresolvedConflict) { try store.savePlanAuthoring(draft) }
        #expect(try store.planEntries() == [previous])
        draft.resolutions = [PlanConflictResolution(existing: previous, choice: .keepBoth)]
        try store.savePlanAuthoringDraft(draft)
        deny = true
        #expect(throws: (any Error).self) { try store.savePlanAuthoring(draft) }
        #expect(try store.planDefinitions().isEmpty)
        #expect(try store.planEntries() == [previous])
        #expect(try store.planAuthoringDraft() == draft)
        deny = false; loseAck = true
        #expect(throws: (any Error).self) { try store.savePlanAuthoring(draft) }
        let saved = try store.savePlanAuthoring(draft)
        #expect(saved.entries.count == 14)
        #expect(saved.entries.filter { $0.state == .unassigned }.count == 13)
        #expect(saved.entries.last?.day.key == "2026-11-14")
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.planEntries().count == 15)
        #expect(try reopened.planEntries().contains(previous))
        #expect(try reopened.planDefinitions() == [saved.plan])
        #expect(try reopened.planAuthoringDraft() == draft)
        #expect(try reopened.savedPlanAuthoring(draft) == saved)
        try reopened.finishPlanAuthoring(draft)
        #expect(try reopened.planAuthoringDraft() == nil)
        #expect(try reopened.wearRecords().isEmpty)
    }

    @Test func bulkConflictChoiceIsRevisionBoundAndCancelLeavesExistingCalendar() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let outfit = try await seedOutfit(store)
        let day = LocalPlanDay(year: 2026, month: 11, day: 1, timeZoneID: "Asia/Manila")
        let single = OutfitPlanDraft(ownerID: outfit.ownerID, outfit: outfit, day: day)
        try store.savePlanDraft(single); let previous = try store.savePlan(single); try store.finishPlanDraft(single)
        var draft = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: outfit.ownerID, name: "Replace reviewed", start: day, end: day))
        draft.slots[0].outfit = outfit
        draft.resolutions = [PlanConflictResolution(existing: previous, choice: .replace)]
        try store.savePlanAuthoringDraft(draft)
        let edit = OutfitPlanDraft(editing: previous, outfit: outfit)
        try store.savePlanDraft(edit); let newer = try store.savePlan(edit); try store.finishPlanDraft(edit)
        #expect(throws: PlanAuthoringError.unresolvedConflict) { try store.savePlanAuthoring(draft) }
        #expect(try store.planEntries() == [newer])
        try store.finishPlanAuthoring(draft, discarding: true)
        #expect(try store.planEntries() == [newer])
        #expect(try store.planDefinitions().isEmpty)
        var fresh = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: outfit.ownerID, name: "Replace confirmed", start: day, end: day))
        fresh.slots[0].outfit = outfit; fresh.resolutions = [PlanConflictResolution(existing: newer, choice: .replace)]
        try store.savePlanAuthoringDraft(fresh)
        let saved = try store.savePlanAuthoring(fresh)
        #expect(try store.planEntries() == saved.entries)
        #expect(saved.entries.first?.id != previous.id)
        #expect(try store.wearRecords().isEmpty)
    }

    @Test func v11MigrationPreservesSingleEntryBeforeBulkAuthoring() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let today = TodayConfiguration(ownerID: UUID())
        let day = LocalPlanDay(year: 2026, month: 11, day: 1, timeZoneID: "Asia/Manila")
        let entry = OutfitPlanEntry(id: UUID(), planID: UUID(), ownerID: today.ownerID, day: day, occasion: "Keep gap",
            outfitID: nil, outfitRevision: nil, state: .unassigned)
        do {
            let schema = Schema(versionedSchema: LocalSchemaV11.self)
            let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config]); let context = ModelContext(container)
            context.insert(StoredTodayConfiguration(today)); context.insert(try StoredLocalExperience(LocalExperience(enteredPrivateSpace: true)))
            context.insert(try StoredOutfitPlanEntry(entry)); try context.save()
        }
        try Data("AQD-piece-store:11".utf8).write(to: directory.appendingPathComponent("schema-version"))
        let store = try PieceStore(directory: directory)
        #expect(try store.planEntries() == [entry])
        #expect(try store.planDefinitions().isEmpty)
        #expect(try store.planAuthoringDraft() == nil)
    }
    @Test func threeCalendarMonthRoutineUsesReviewedRulesWithoutAutomaticWear() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let outfit = try await seedOutfit(store)
        let state = AppState(store: store)
        let start = LocalPlanDay(year: 2026, month: 10, day: 1, timeZoneID: "Asia/Manila")
        state.openPlanAuthoring(day: start, routine: true)
        let model = try #require(state.planAuthoringEditor)
        model.dates { $0.name = "Office weekdays"; $0.end = LocalPlanDay(year: 2026, month: 12, day: 31, timeZoneID: start.timeZoneID) }
        model.update { $0.plan.routine?.preferredOutfitIDs = [outfit.id] }
        model.fillRoutine()
        #expect(model.draft.slots.count == 66)
        #expect(model.draft.usesRules == true)
        #expect(try store.planEntries().isEmpty)
        await model.save()
        let saved = try #require(model.saved)
        #expect(saved.entries.count == 66)
        #expect(saved.entries.allSatisfy { $0.outfitID == outfit.id && $0.state == .planned })
        #expect(try store.wearRecords().isEmpty)
        model.finish(openPlan: true)
        #expect(state.plannerPath == [.plan(saved.plan.id)])
        #expect(try store.planAuthoringDraft() == nil)
        state.store = nil
    }

    @Test func editingFutureRoutineEntriesPreservesEarlierIntentAndReconcilesLostAcknowledgment() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var loseAck = false
        let store = try PieceStore(directory: directory, afterOutfitSave: { if loseAck { throw CocoaError(.fileReadUnknown) } })
        let outfit = try await seedOutfit(store)
        let start = LocalPlanDay(year: 2026, month: 10, day: 1, timeZoneID: "Asia/Manila")
        let definition = PlanDefinition(ownerID: outfit.ownerID, name: "Office", start: start,
            end: LocalPlanDay(year: 2026, month: 10, day: 5, timeZoneID: start.timeZoneID), routine: RoutineConfiguration(occasion: "Office"))
        var draft = try PlanAuthoringDraft(plan: definition)
        for i in draft.slots.indices { draft.slots[i].outfit = outfit }
        try store.savePlanAuthoringDraft(draft); let initial = try store.savePlanAuthoring(draft); try store.finishPlanAuthoring(draft)
        #expect(initial.entries.count == 3)
        #expect(initial.entries.allSatisfy { $0.occasion == "Office" })
        let anchor = initial.entries[1]
        var edit = try PlanAuthoringDraft(editing: initial.plan, entries: store.planEntries(), outfits: [outfit], scope: .future, anchorEntryID: anchor.id)
        edit.plan.name = "Updated office"; edit.plan.end.day = 6; try edit.rebuildDates()
        for i in edit.slots.indices where edit.slots[i].outfit == nil { edit.slots[i].unassignedByChoice = true }
        try store.savePlanAuthoringDraft(edit)
        loseAck = true
        #expect(throws: (any Error).self) { try store.savePlanAuthoring(edit) }
        let saved = try store.savePlanAuthoring(edit)
        #expect(saved.plan.id == initial.plan.id)
        #expect(saved.plan.revision == 2)
        let reopened = try PieceStore(directory: directory)
        let current = try reopened.planEntries()
        #expect(current.count == 4)
        #expect(current.first == initial.entries.first)
        #expect(current.first { $0.id == anchor.id }?.revision == 2)
        #expect(current.last?.day.key == "2026-10-06")
        #expect(try reopened.savedPlanAuthoring(edit) == saved)
        #expect(try reopened.wearRecords().isEmpty)
    }
    @Test func refreshingStaleRoutineRetainsProposedNewDateIdentityAndOutfit() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let outfit = try await seedOutfit(store)
        let start = LocalPlanDay(year: 2026, month: 10, day: 1, timeZoneID: "Asia/Manila")
        var draft = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: outfit.ownerID, name: "Office", start: start,
            end: LocalPlanDay(year: 2026, month: 10, day: 5, timeZoneID: start.timeZoneID), routine: RoutineConfiguration(occasion: "Office")))
        for i in draft.slots.indices { draft.slots[i].outfit = outfit }
        try store.savePlanAuthoringDraft(draft); let saved = try store.savePlanAuthoring(draft); try store.finishPlanAuthoring(draft)
        let state = AppState(store: store)
        state.editPlanDefinition(saved.plan, scope: .whole, anchorEntryID: nil)
        let model = try #require(state.planAuthoringEditor)
        model.dates { $0.end.day = 6 }
        let proposed = try #require(model.draft.slots.first { $0.day.day == 6 })
        model.update { value in if let i = value.slots.firstIndex(where: { $0.id == proposed.id }) { value.slots[i].outfit = outfit } }
        var changed = OutfitPlanDraft(editing: saved.entries[0], outfit: outfit); changed.occasion = "Changed elsewhere"
        try store.savePlanDraft(changed); _ = try store.savePlan(changed); try store.finishPlanDraft(changed)
        await model.save()
        #expect(model.saved == nil)
        #expect(model.error != nil)
        model.refreshReviewedBase()
        #expect(model.error == nil)
        #expect(model.draft.slots.first { $0.day.day == 6 }?.id == proposed.id)
        #expect(model.draft.slots.first { $0.day.day == 6 }?.outfit == outfit)
        await model.save()
        #expect(model.saved?.entries.count == 4)
        state.planAuthoringEditor = nil; state.store = nil
    }
}
