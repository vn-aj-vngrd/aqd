import AQDCore
import Foundation
import SwiftData
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor
struct OutfitPersistenceTests {
    private func seedPiece(_ store: PieceStore) async throws -> WardrobePiece {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in
            UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32))
        }
        let data = try #require(image.jpegData(compressionQuality: 0.9))
        let photo = try await PhotoPreparer().prepare(data: data)
        _ = try store.acceptPhoto(photo)
        return try store.savePiece(PieceDraft(name: "Blue shirt", category: .tops, photoID: photo.id), operationID: UUID())
    }

    @Test func manualOutfitSaveRetryReopenEditAndDiscardKeepStableIdentity() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        let piece = try await seedPiece(#require(store))
        var draft = OutfitDraft(ownerID: try #require(store).todayConfiguration().ownerID)
        draft.name = " Weekend "; draft.select(piece.id)
        try #require(store).saveOutfitDraft(draft)
        let saved = try #require(store).saveOutfit(draft)
        #expect(saved.name == "Weekend")
        #expect(try #require(store).saveOutfit(draft) == saved)
        store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).outfitDraft() == draft)
        #expect(try #require(store).savedOutfit(for: draft) == saved)
        #expect(try #require(store).outfits() == [saved])
        try #require(store).acknowledgeOutfitReceipt(draft)
        var edit = OutfitDraft(editing: saved)
        edit.name = "Evening"
        try #require(store).saveOutfitDraft(edit)
        let updated = try #require(store).saveOutfit(edit)
        #expect(updated.id == saved.id)
        #expect(updated.revision == 2)
        #expect(updated.pieceIDs == [piece.id])
        try #require(store).acknowledgeOutfitReceipt(edit)
        var cancelled = OutfitDraft(editing: updated)
        cancelled.name = "Discard me"
        try #require(store).saveOutfitDraft(cancelled)
        try #require(store).discardOutfitDraft(id: cancelled.id)
        #expect(try #require(store).outfit(id: saved.id) == updated)
        #expect(try #require(store).piece(id: piece.id) == piece)
        store = nil
    }

    @Test func failedSaveKeepsDraftAndLostAcknowledgmentReturnsOneReceipt() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var deny = false
        var store: PieceStore? = try PieceStore(directory: directory, beforeOutfitSave: {
            if deny { throw CocoaError(.fileWriteNoPermission) }
        })
        let piece = try await seedPiece(#require(store))
        var draft = OutfitDraft(ownerID: try #require(store).todayConfiguration().ownerID)
        draft.name = "Weekend"; draft.select(piece.id)
        try #require(store).saveOutfitDraft(draft)
        deny = true
        #expect(throws: (any Error).self) { try #require(store).saveOutfit(draft) }
        #expect(try #require(store).outfits().isEmpty)
        #expect(try #require(store).outfitDraft() == draft)
        store = nil
        store = try PieceStore(directory: directory, afterOutfitSave: { throw CocoaError(.fileReadUnknown) })
        #expect(throws: (any Error).self) { try #require(store).saveOutfit(draft) }
        let saved = try #require(store).saveOutfit(draft)
        #expect(try #require(store).outfits() == [saved])
        #expect(try #require(store).savedOutfit(for: draft) == saved)
        var different = draft
        different.name = "Conflicting retry"
        #expect(throws: PieceStore.StoreError.operationConflict) { try #require(store).saveOutfit(different) }
        #expect(throws: PieceStore.StoreError.operationConflict) { try #require(store).discardOutfitDraft(id: draft.id) }
        store = nil
    }

    @Test func unmarkedOutfitStoreCannotBeReseededAsAnEmptyCloset() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do { _ = try PieceStore(directory: directory) }
        do {
            let schema = Schema(versionedSchema: LocalSchemaV5.self)
            let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            context.insert(try StoredOutfit(Outfit(id: UUID(), ownerID: UUID(), name: "Retain me", pieceIDs: [UUID()])))
            try context.save()
        }
        try FileManager.default.removeItem(at: directory.appendingPathComponent("schema-version"))
        #expect(throws: (any Error).self) { _ = try PieceStore(directory: directory) }
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("schema-version").path))
    }

    @Test func v3MigrationPreservesPreferencesPiecesAndTheirMedia() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let experience = LocalExperience(enteredPrivateSpace: true)
        let today = TodayConfiguration(ownerID: UUID())
        let legacyPiece = WardrobePiece(id: UUID(), name: "Legacy shirt", category: .tops, photoID: UUID())
        let media = directory.appendingPathComponent("media", isDirectory: true)
        try FileManager.default.createDirectory(at: media, withIntermediateDirectories: true)
        let legacyMedia = Data([1, 2, 3, 4])
        try legacyMedia.write(to: media.appendingPathComponent("\(legacyPiece.photoID.uuidString).jpg"))
        do {
            let schema = Schema(versionedSchema: LocalSchemaV3.self)
            let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            context.insert(StoredTodayConfiguration(today))
            context.insert(StoredPiece(legacyPiece))
            context.insert(StoredPhoto(id: legacyPiece.photoID, pixelWidth: 24, pixelHeight: 32))
            context.insert(try StoredLocalExperience(experience))
            try context.save()
        }
        try Data("AQD-piece-store:3".utf8).write(to: directory.appendingPathComponent("schema-version"))
        var store: PieceStore? = try PieceStore(directory: directory)
        #expect(try #require(store).localExperience() == experience)
        #expect(try #require(store).todayConfiguration() == today)
        #expect(try #require(store).piece(id: legacyPiece.id) == legacyPiece)
        #expect(try #require(store).originalPhoto(id: legacyPiece.photoID) == legacyMedia)
        let piece = try await seedPiece(#require(store))
        var draft = OutfitDraft(ownerID: today.ownerID)
        draft.name = "Migrated closet"; draft.select(piece.id)
        try #require(store).saveOutfitDraft(draft)
        let saved = try #require(store).saveOutfit(draft)
        store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).outfit(id: saved.id) == saved)
        #expect(try #require(store).piece(id: piece.id) == piece)
        #expect(try #require(store).localExperience() == experience)
        store = nil
    }
}
