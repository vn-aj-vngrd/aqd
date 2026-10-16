import AQDCore
import Foundation
import SwiftData
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor
struct OutfitWearPersistenceTests {
    private func seed(_ store: PieceStore) async throws -> (Outfit, WardrobePiece) {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in
            UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32))
        }
        let photo = try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 0.9)))
        _ = try store.acceptPhoto(photo)
        let piece = try store.savePiece(PieceDraft(name: "Shirt as worn", category: .tops, photoID: photo.id), operationID: UUID())
        var draft = OutfitDraft(ownerID: try store.todayConfiguration().ownerID)
        draft.name = "Look"; draft.select(piece.id)
        try store.saveOutfitDraft(draft)
        let outfit = try store.saveOutfit(draft)
        try store.acknowledgeOutfitReceipt(draft)
        return (outfit, piece)
    }

    @Test func plansNeverRecordWearAndDuplicateDecisionKeepsOneHistoricalSnapshot() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        let (outfit, piece) = try await seed(#require(store))
        let plan = OutfitPlanDraft(ownerID: outfit.ownerID, outfit: outfit)
        try #require(store).savePlanDraft(plan)
        _ = try #require(store).savePlan(plan)
        try #require(store).finishPlanDraft(plan)
        #expect(try #require(store).wearRecords().isEmpty)
        let day = LocalPlanDay(year: 2026, month: 1, day: 1, timeZoneID: "Asia/Manila")
        let draft = OutfitWearDraft(ownerID: outfit.ownerID, outfitID: outfit.id, pieces: [piece], day: day)
        try #require(store).saveWearDraft(draft)
        let saved = try #require(store).saveWear(draft)
        #expect(try #require(store).saveWear(draft) == saved)
        try #require(store).finishWearDraft(draft)
        var duplicate = OutfitWearDraft(ownerID: outfit.ownerID, outfitID: outfit.id, pieces: [piece], day: day)
        try #require(store).saveWearDraft(duplicate)
        #expect(throws: WearValidationError.alreadyRecorded) { try #require(store).saveWear(duplicate) }
        duplicate.acceptedDuplicateID = saved.id
        try #require(store).saveWearDraft(duplicate)
        #expect(try #require(store).saveWear(duplicate) == saved)
        try #require(store).finishWearDraft(duplicate)
        #expect(try #require(store).wearRecords() == [saved])
        let impact = try #require(store).pieceDeletionImpact(id: piece.id)
        try #require(store).deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: UUID(), impact: impact)
        #expect(try #require(store).wearRecords() == [saved])
        #expect(saved.pieces.first?.name == "Shirt as worn")
        store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).wearRecords() == [saved])
        #expect(try #require(store).savedWear(for: duplicate) == saved)
        store = nil
    }

    @Test func deniedAndUnknownWearWritesRetainTheSameDraftAndDoNotDoubleCount() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var deny = false, loseAck = false
        let store = try PieceStore(directory: directory,
            beforeOutfitSave: { if deny { throw CocoaError(.fileWriteNoPermission) } },
            afterOutfitSave: { if loseAck { throw CocoaError(.fileReadUnknown) } })
        let (outfit, piece) = try await seed(store)
        let draft = OutfitWearDraft(ownerID: outfit.ownerID, outfitID: outfit.id, pieces: [piece])
        try store.saveWearDraft(draft)
        deny = true
        #expect(throws: (any Error).self) { try store.saveWear(draft) }
        #expect(try store.wearRecords().isEmpty)
        #expect(try store.wearDraft() == draft)
        deny = false; loseAck = true
        #expect(throws: (any Error).self) { try store.saveWear(draft) }
        let saved = try store.saveWear(draft)
        #expect(try store.wearRecords() == [saved])
        #expect(try store.savedWear(for: draft) == saved)
    }

    @Test func explicitWearLinksPlansAndSkipAndPlanDeletionPreserveActualFacts() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let (outfit, piece) = try await seed(store)
        let day = LocalPlanDay(year: 2026, month: 1, day: 1, timeZoneID: "Asia/Manila")
        var authoring = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: outfit.ownerID, name: "Real plan", start: day, end: day))
        authoring.plan.name = "Real plan"
        authoring.slots[0].outfit = outfit
        try store.savePlanAuthoringDraft(authoring)
        let receipt = try store.savePlanAuthoring(authoring)
        try store.finishPlanAuthoring(authoring)
        let entry = try #require(receipt.entries.first)
        #expect(try store.wearRecords().isEmpty)
        var wear = OutfitWearDraft(ownerID: outfit.ownerID, outfitID: outfit.id, pieces: [piece], day: day)
        wear.planEntry = entry
        try store.saveWearDraft(wear)
        let actual = try store.saveWear(wear)
        try store.finishWearDraft(wear)
        let linked = try #require(try store.planEntries().first)
        #expect(linked.state == .worn && linked.wearRecordID == actual.id)
        #expect(actual.planEntryID == entry.id)
        let deletion = HistoryMutation(action: .deletePlan(receipt.plan, [linked]))
        try store.applyHistoryMutation(deletion)
        try store.applyHistoryMutation(deletion)
        #expect(try store.planEntries().isEmpty)
        #expect(try store.wearRecords() == [actual])
        var other = OutfitPlanDraft(ownerID: outfit.ownerID, outfit: outfit, day: day)
        other.occasion = "Evening"
        try store.savePlanDraft(other)
        let skippable = try store.savePlan(other)
        try store.finishPlanDraft(other)
        let skip = HistoryMutation(action: .skip(skippable))
        try store.applyHistoryMutation(skip)
        try store.applyHistoryMutation(skip)
        #expect(try store.planEntries().first?.state == .skipped)
        #expect(try store.wearRecords() == [actual])
    }

    @Test func v6MigrationKeepsTheExistingPlanWithoutInventingWear() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let today = TodayConfiguration(ownerID: UUID())
        let piece = WardrobePiece(id: UUID(), name: "Historical shirt", category: .tops, photoID: UUID())
        let outfit = Outfit(id: UUID(), ownerID: today.ownerID, name: "Look", pieceIDs: [piece.id])
        let day = LocalPlanDay(year: 2026, month: 1, day: 1, timeZoneID: "Asia/Manila")
        let entry = OutfitPlanEntry(id: UUID(), planID: UUID(), ownerID: today.ownerID, day: day, occasion: "Afternoon",
                                    outfitID: outfit.id, outfitRevision: outfit.revision, state: .planned)
        do {
            let schema = Schema(versionedSchema: LocalSchemaV6.self)
            let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            context.insert(StoredTodayConfiguration(today))
            context.insert(try StoredLocalExperience(LocalExperience(enteredPrivateSpace: true)))
            context.insert(StoredPiece(piece)); context.insert(StoredPhoto(id: piece.photoID, pixelWidth: 24, pixelHeight: 32))
            context.insert(try StoredOutfit(outfit)); context.insert(try StoredOutfitPlanEntry(entry))
            try context.save()
        }
        try Data("AQD-piece-store:6".utf8).write(to: directory.appendingPathComponent("schema-version"))
        let store = try PieceStore(directory: directory)
        #expect(try store.planEntries() == [entry])
        #expect(try store.wearRecords().isEmpty)
        let draft = OutfitWearDraft(ownerID: today.ownerID, outfitID: outfit.id, pieces: [piece], day: day)
        try store.saveWearDraft(draft)
        _ = try store.saveWear(draft)
        #expect(try store.planEntries() == [entry])
        #expect(try store.wearRecords().count == 1)
    }
}
