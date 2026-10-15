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
}
