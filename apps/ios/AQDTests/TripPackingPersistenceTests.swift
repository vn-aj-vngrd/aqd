import AQDCore
import Foundation
import SwiftData
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor
struct TripPackingPersistenceTests {
    private func seed(_ store: PieceStore) async throws -> (PlanAuthoringReceipt, Outfit, Outfit, WardrobePiece, WardrobePiece) {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in
            UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32))
        }
        let photo = try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 0.9)))
        _ = try store.acceptPhoto(photo)
        let old = try store.savePiece(PieceDraft(name: "Shirt", category: .tops, photoID: photo.id), operationID: UUID())
        let new = try store.savePiece(PieceDraft(name: "Shoes", category: .shoes, photoID: photo.id), operationID: UUID())
        let owner = try store.todayConfiguration().ownerID
        var outfits: [Outfit] = []
        for piece in [old, new] {
            var draft = OutfitDraft(ownerID: owner); draft.name = piece.name + " look"; draft.select(piece.id)
            try store.saveOutfitDraft(draft); outfits.append(try store.saveOutfit(draft)); try store.acknowledgeOutfitReceipt(draft)
        }
        let start = LocalPlanDay(year: 2026, month: 10, day: 18, timeZoneID: "Asia/Seoul")
        var end = start; end.day = 19
        let definition = PlanDefinition(ownerID: owner, name: "Seoul, slowly", start: start, end: end,
            trip: TripConfiguration(destination: "Seoul, South Korea", activities: ["Walking", "Museums"]))
        var draft = try PlanAuthoringDraft(plan: definition)
        draft.slots[0].outfit = outfits[0]; draft.slots[1].outfit = outfits[1]
        try store.savePlanAuthoringDraft(draft); let saved = try store.savePlanAuthoring(draft); try store.finishPlanAuthoring(draft)
        return (saved, outfits[0], outfits[1], old, new)
    }

    @Test func assignmentReplacementPrunesRemovedChecksAndKeepsRetainedChecksAfterRestart() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let (saved, oldOutfit, newOutfit, oldPiece, newPiece) = try await seed(store)
        let oldRequest = PackingCheckRequest(planID: saved.plan.id, pieceID: oldPiece.id, checked: true, expectedRevision: 0)
        let first = try store.setPackingCheck(oldRequest)
        _ = try store.setPackingCheck(PackingCheckRequest(planID: saved.plan.id, pieceID: newPiece.id, checked: true, expectedRevision: first.revision))
        let replacing = OutfitPlanDraft(editing: saved.entries[0], outfit: newOutfit)
        try store.savePlanDraft(replacing); let updated = try store.savePlan(replacing); try store.finishPlanDraft(replacing)
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.packingState(planID: saved.plan.id).checkedIDs == [newPiece.id])
        let packed = try reopened.packingSummary(planID: saved.plan.id)
        #expect(packed.items.count == 1)
        #expect(packed.items.first?.id == newPiece.id)
        #expect(packed.items.first?.uses == 2)
        #expect(packed.items.first?.checked == true)
        // A historical acknowledgment never rewinds the current checked set.
        #expect(try reopened.setPackingCheck(oldRequest) == first)
        var back = OutfitPlanDraft(editing: updated, outfit: oldOutfit); back.allowsOverlap = nil
        try reopened.savePlanDraft(back); _ = try reopened.savePlan(back); try reopened.finishPlanDraft(back)
        let restored = try reopened.packingSummary(planID: saved.plan.id)
        #expect(restored.items.first { $0.id == oldPiece.id }?.checked == false)
        #expect(restored.items.first { $0.id == newPiece.id }?.checked == true)
        #expect(try reopened.wearRecords().isEmpty)
    }

    @Test func deniedAndUnknownPackingWritesRetainExactRequestWithoutOverwritingOtherChoices() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var deny = false, loseAck = false
        let store = try PieceStore(directory: directory,
            beforeOutfitSave: { if deny { throw CocoaError(.fileWriteNoPermission) } },
            afterOutfitSave: { if loseAck { throw CocoaError(.fileReadUnknown) } })
        let (saved, _, _, piece, _) = try await seed(store)
        let request = PackingCheckRequest(planID: saved.plan.id, pieceID: piece.id, checked: true, expectedRevision: 0)
        deny = true
        #expect(throws: (any Error).self) { try store.setPackingCheck(request) }
        #expect(try store.packingState(planID: saved.plan.id).revision == 0)
        deny = false; loseAck = true
        #expect(throws: (any Error).self) { try store.setPackingCheck(request) }
        let reopened = try PieceStore(directory: directory)
        let ack = try reopened.setPackingCheck(request)
        #expect(ack.revision == 1)
        #expect(ack.checkedIDs == [piece.id])
        let conflict = PackingCheckRequest(planID: saved.plan.id, pieceID: piece.id, checked: false, expectedRevision: 0, operationID: request.operationID)
        #expect(throws: PieceStore.StoreError.operationConflict) { try reopened.setPackingCheck(conflict) }
        #expect(try reopened.packingSummary(planID: saved.plan.id).items.first { $0.id == piece.id }?.checked == true)
    }

    @Test func missingTripDateCreatesAnEntryInTheSamePlanWithoutRecordingWear() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let (saved, outfit, _, _, _) = try await seed(store)
        let missing = saved.entries[1]
        try store.deletePlanEntry(PlanEntryDeletionRequest(entry: missing))
        let gap = try #require(try store.packingSummary(planID: saved.plan.id).gaps.first)
        #expect(gap.entryID == nil)
        let state = AppState(store: store)
        state.openPlan(day: gap.day, parentPlanID: saved.plan.id)
        let editor = try #require(state.planEditor)
        editor.update { $0.outfit = outfit }
        await editor.save()
        #expect(editor.saved?.planID == saved.plan.id)
        editor.finish()
        #expect(try store.packingSummary(planID: saved.plan.id).gaps.isEmpty)
        #expect(try store.planEntries().filter { $0.planID == saved.plan.id }.count == 2)
        #expect(try store.wearRecords().isEmpty)
        state.store = nil
    }

    @Test func v12MigrationRetainsTripDatesAndStartsWithNoInventedPackingChecks() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let today = TodayConfiguration(ownerID: UUID())
        let day = LocalPlanDay(year: 2026, month: 10, day: 18, timeZoneID: "Asia/Seoul")
        let plan = PlanDefinition(ownerID: today.ownerID, name: "Keep trip", start: day, end: day, trip: TripConfiguration(destination: "Seoul"))
        let entry = OutfitPlanEntry(id: UUID(), planID: plan.id, ownerID: today.ownerID, day: day, occasion: "Walking",
            outfitID: nil, outfitRevision: nil, state: .unassigned)
        do {
            let schema = Schema(versionedSchema: LocalSchemaV12.self)
            let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config]); let context = ModelContext(container)
            context.insert(StoredTodayConfiguration(today)); context.insert(try StoredLocalExperience(LocalExperience(enteredPrivateSpace: true)))
            context.insert(try StoredPlanDefinition(plan)); context.insert(try StoredOutfitPlanEntry(entry)); try context.save()
        }
        try Data("AQD-piece-store:12".utf8).write(to: directory.appendingPathComponent("schema-version"))
        let store = try PieceStore(directory: directory)
        #expect(try store.planDefinitions() == [plan])
        #expect(try store.planEntries() == [entry])
        #expect(try store.packingState(planID: plan.id) == PackingState(planID: plan.id))
        #expect(try store.packingSummary(planID: plan.id).gaps.count == 1)
    }
    @Test func namedPlanRejectsNewAndMovedEntriesOutsideItsReviewedRange() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let (saved, outfit, _, _, _) = try await seed(store)
        var outside = saved.plan.end; outside.day = 20
        let newEntry = OutfitPlanDraft(ownerID: saved.plan.ownerID, outfit: outfit, day: outside, planID: saved.plan.id)
        try store.savePlanDraft(newEntry)
        #expect(throws: PlanValidationError.invalidDay) { try store.savePlan(newEntry) }
        try store.finishPlanDraft(newEntry, discarding: true)
        var moved = OutfitPlanDraft(editing: saved.entries[0], outfit: outfit); moved.day = outside
        try store.savePlanDraft(moved)
        #expect(throws: PlanValidationError.invalidDay) { try store.savePlan(moved) }
        #expect(try store.planEntries() == saved.entries)
        #expect(try store.planDefinitions() == [saved.plan])
        try store.finishPlanDraft(moved, discarding: true)
        var travel = OutfitPlanDraft(editing: saved.entries[0], outfit: outfit)
        travel.day.timeZoneID = "America/New_York"
        try store.savePlanDraft(travel)
        #expect(throws: PlanValidationError.invalidDay) { try store.savePlan(travel) }
        #expect(try store.planEntries() == saved.entries)
    }
}
