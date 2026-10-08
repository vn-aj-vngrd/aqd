import AQDCore
import Foundation
import SwiftData
import Testing
import UIKit
@testable import AQD

@MainActor
struct PiecePersistenceTests {
    @Test func versionOneMigrationPreservesPieceDraftPhotoAndTodayIdentities() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let media = directory.appendingPathComponent("media", isDirectory: true)
        try FileManager.default.createDirectory(at: media, withIntermediateDirectories: true)
        let photo = try await preparedPhoto()
        try photo.originalData.write(to: media.appendingPathComponent("\(photo.id.uuidString).jpg"))
        try photo.thumbnailData.write(to: media.appendingPathComponent("\(photo.id.uuidString)-thumbnail.jpg"))
        let saved = WardrobePiece(id: UUID(), name: "Legacy piece", category: .tops, photoID: photo.id)
        let draft = PieceDraft(itemID: saved.id, name: "Retained legacy edit", category: .tops,
                               photoID: photo.id, baseRevision: saved.revision)
        let operation = UUID()
        let today = TodayConfiguration(ownerID: UUID())
        // Arrange the supported previous native schema, then verify through the
        // public store boundary rather than inspecting migrated database rows.
        do {
            let schema = Schema(versionedSchema: LocalSchemaV1.self)
            let configuration = ModelConfiguration(schema: schema,
                url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            context.insert(StoredPiece(saved))
            context.insert(StoredPhoto(id: photo.id, pixelWidth: photo.pixelWidth, pixelHeight: photo.pixelHeight))
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            context.insert(StoredPieceDraft(draft: draft, operationID: operation,
                                           payload: try encoder.encode(draft)))
            context.insert(StoredTodayConfiguration(today))
            try context.save()
        }
        try Data("AQD-piece-store:1".utf8).write(to: directory.appendingPathComponent("schema-version"))
        var migrated: PieceStore? = try PieceStore(directory: directory)
        #expect(try #require(migrated).piece(id: saved.id) == saved)
        #expect(try #require(migrated).recoverableDraft(itemID: saved.id) == RecoverablePieceDraft(draft: draft, operationID: operation))
        #expect(try #require(migrated).originalPhoto(id: photo.id) == photo.originalData)
        #expect(try #require(migrated).todayConfiguration() == today)
        migrated = nil
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.piece(id: saved.id) == saved)
        #expect(try reopened.thumbnailPhoto(id: photo.id) == photo.thumbnailData)
        #expect(try reopened.todayConfiguration() == today)
        _ = try reopened.savePiece(draft, operationID: operation)
        #expect(try reopened.piece(id: saved.id)?.name == draft.name)
    }

    @Test func replacedAndDiscardedDraftPhotosAreQueuedDurablyIncludingDerivatives() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let old = try await preparedPhoto()
        let replacement = try await preparedPhoto()
        let recipe = PhotoEditRecipe(quarterTurns: 1)
        let edit = try await PhotoPreparer().render(data: old.originalData, sourcePhotoID: old.id, recipe: recipe)
        var store: PieceStore? = try PieceStore(directory: directory, removeMediaFile: { _ in
            throw CocoaError(.fileWriteNoPermission)
        })
        _ = try #require(store).acceptPhoto(old)
        try #require(store).acceptPhotoEdit(edit)
        var draft = PieceDraft(name: "Keep fields", photoID: old.id, photoRecipe: recipe)
        let operation = UUID()
        try #require(store).saveDraft(draft, operationID: operation)
        _ = try #require(store).acceptPhoto(replacement)
        draft.photoID = replacement.id
        draft.photoRecipe = .fitOriginal
        try #require(store).saveDraft(draft, operationID: operation)
        #expect(try #require(store).latestDraft()?.draft == draft)
        #expect(try #require(store).hasPendingPhotoCleanup())
        store = nil
        let reopened = try PieceStore(directory: directory)
        try reopened.reconcilePendingPhotoCleanup()
        #expect(throws: (any Error).self) { try reopened.originalPhoto(id: old.id) }
        #expect(throws: (any Error).self) { try reopened.thumbnailPhoto(id: old.id) }
        #expect(throws: (any Error).self) { try reopened.photoRendition(id: old.id, recipe: recipe) }
        #expect(throws: (any Error).self) { try reopened.photoThumbnail(id: old.id, recipe: recipe) }
        #expect(try reopened.originalPhoto(id: replacement.id) == replacement.originalData)
        try reopened.discardDraft(id: draft.id)
        try reopened.reconcilePendingPhotoCleanup()
        #expect(try reopened.latestDraft() == nil)
        #expect(throws: (any Error).self) { try reopened.originalPhoto(id: replacement.id) }
        #expect(throws: (any Error).self) { try reopened.thumbnailPhoto(id: replacement.id) }
        #expect(try !reopened.hasPendingPhotoCleanup())
    }

    @Test func failedPhotoStagingSurvivesReopenAndRefusesUnsafeOrUnknownFiles() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        var store: PieceStore? = try PieceStore(directory: directory, writeMediaFile: { data, url in
            if url.lastPathComponent == "\(source.id.uuidString)-thumbnail.jpg" {
                throw CocoaError(.fileWriteNoPermission)
            }
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        })
        #expect(throws: (any Error).self) { try #require(store).acceptPhoto(source) }
        let thumbnail = directory.appendingPathComponent("media/\(source.id.uuidString)-thumbnail.jpg")
        try FileManager.default.createDirectory(at: thumbnail, withIntermediateDirectories: false)
        let sentinel = thumbnail.appendingPathComponent("unknown")
        try Data("Keep foreign content".utf8).write(to: sentinel)
        let unknown = directory.appendingPathComponent("media/unknown.jpg")
        try Data("Keep unknown file".utf8).write(to: unknown)
        #expect(try #require(store).originalPhoto(id: source.id) == source.originalData)
        #expect(try #require(store).hasPendingPhotoCleanup())
        store = nil
        let reopened = try PieceStore(directory: directory)
        #expect(throws: PieceStore.StoreError.unsafeMediaPath) { try reopened.reconcilePendingPhotoCleanup() }
        #expect(try reopened.hasPendingPhotoCleanup())
        #expect(try Data(contentsOf: sentinel) == Data("Keep foreign content".utf8))
        try FileManager.default.removeItem(at: thumbnail)
        try reopened.reconcilePendingPhotoCleanup()
        #expect(try !reopened.hasPendingPhotoCleanup())
        #expect(throws: (any Error).self) { try reopened.originalPhoto(id: source.id) }
        #expect(try Data(contentsOf: unknown) == Data("Keep unknown file".utf8))
    }

    @Test func relinquishedDraftRecipeIsCleanedWithoutDeletingSharedSavedOriginal() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let source = try await preparedPhoto()
        _ = try store.acceptPhoto(source)
        let saved = try store.savePiece(PieceDraft(name: "Saved Fit", category: .tops, photoID: source.id), operationID: UUID())
        let recipe = PhotoEditRecipe(quarterTurns: 1)
        let edit = try await PhotoPreparer().render(data: source.originalData, sourcePhotoID: source.id, recipe: recipe)
        try store.acceptPhotoEdit(edit)
        var draft = PieceDraft(itemID: saved.id, name: "Uncommitted framing", category: .tops,
            photoID: source.id, baseRevision: saved.revision, photoRecipe: recipe)
        let operation = UUID()
        try store.saveDraft(draft, operationID: operation)
        try store.reconcilePendingPhotoCleanup()
        #expect(try store.photoRendition(id: source.id, recipe: recipe) == edit.renditionData)
        draft.photoRecipe = .fitOriginal
        try store.saveDraft(draft, operationID: operation)
        try store.reconcilePendingPhotoCleanup()
        #expect(throws: (any Error).self) { try store.photoRendition(id: source.id, recipe: recipe) }
        #expect(throws: (any Error).self) { try store.photoThumbnail(id: source.id, recipe: recipe) }
        #expect(try store.originalPhoto(id: source.id) == source.originalData)
        #expect(try store.piece(id: saved.id) == saved)
        try store.acceptPhotoEdit(edit)
        draft.photoRecipe = recipe
        try store.saveDraft(draft, operationID: operation)
        try store.reconcilePendingPhotoCleanup()
        try store.discardDraft(id: draft.id)
        try store.reconcilePendingPhotoCleanup()
        #expect(throws: (any Error).self) { try store.photoRendition(id: source.id, recipe: recipe) }
        #expect(try store.thumbnailPhoto(id: source.id) == source.thumbnailData)
    }

    @Test func failedEditStagingCleansOnlyUnusedRecipeWhileKeepingSavedOriginal() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        let recipe = PhotoEditRecipe(quarterTurns: 1)
        let edit = try await PhotoPreparer().render(data: source.originalData, sourcePhotoID: source.id, recipe: recipe)
        var store: PieceStore? = try PieceStore(directory: directory, writeMediaFile: { data, url in
            if url.lastPathComponent.contains("-edit-") && url.lastPathComponent.hasSuffix("-thumbnail.jpg") {
                throw CocoaError(.fileWriteNoPermission)
            }
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        })
        _ = try #require(store).acceptPhoto(source)
        let saved = try #require(store).savePiece(PieceDraft(name: "Keep original", category: .tops, photoID: source.id), operationID: UUID())
        #expect(throws: (any Error).self) { try #require(store).acceptPhotoEdit(edit) }
        #expect(try #require(store).photoRendition(id: source.id, recipe: recipe) == edit.renditionData)
        store = nil
        let reopened = try PieceStore(directory: directory)
        try reopened.reconcilePendingPhotoCleanup()
        #expect(throws: (any Error).self) { try reopened.photoRendition(id: source.id, recipe: recipe) }
        #expect(try reopened.originalPhoto(id: source.id) == source.originalData)
        #expect(try reopened.thumbnailPhoto(id: source.id) == source.thumbnailData)
        #expect(try reopened.piece(id: saved.id) == saved)
        #expect(try !reopened.hasPendingPhotoCleanup())
    }

    @Test func stagingCleanupPreservesSharedDraftsAndSaveAndArchiveReceiptMedia() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let source = try await preparedPhoto()
        let replacement = try await preparedPhoto()
        _ = try store.acceptPhoto(source)
        _ = try store.acceptPhoto(replacement)
        let recipe = PhotoEditRecipe(quarterTurns: 1)
        let edit = try await PhotoPreparer().render(data: source.originalData, sourcePhotoID: source.id, recipe: recipe)
        try store.acceptPhotoEdit(edit)
        let initial = PieceDraft(name: "Receipt owner", category: .tops, photoID: source.id, photoRecipe: recipe)
        let saveOperation = UUID()
        let saved = try store.savePiece(initial, operationID: saveOperation)
        let archiveOperation = UUID()
        let archived = try store.setArchived(id: saved.id, archived: true, expectedRevision: 1, operationID: archiveOperation)
        _ = try store.savePiece(PieceDraft(itemID: saved.id, name: "Replaced", category: .tops,
            photoID: replacement.id, baseRevision: 2), operationID: UUID())
        let shared = PieceDraft(name: "Shared unfinished", photoID: replacement.id)
        try store.saveDraft(shared, operationID: UUID())
        let discarded = PieceDraft(name: "Discard", photoID: source.id)
        try store.saveDraft(discarded, operationID: UUID())
        try store.discardDraft(id: discarded.id)
        try store.reconcilePendingPhotoCleanup()
        #expect(try store.originalPhoto(id: source.id) == source.originalData)
        #expect(try store.photoRendition(id: source.id, recipe: recipe) == edit.renditionData)
        #expect(try store.savePiece(initial, operationID: saveOperation) == saved)
        #expect(try store.setArchived(id: saved.id, archived: true, expectedRevision: 1, operationID: archiveOperation) == archived)
        #expect(try store.latestDraft()?.draft == shared)
        #expect(try store.originalPhoto(id: replacement.id) == replacement.originalData)
        #expect(try !store.hasPendingPhotoCleanup())
    }

    @Test func itemRecoveryReturnsItsExactDraftAndOperationRatherThanTheLatestOtherItem() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        let target = PieceDraft(name: "Resume this", baseRevision: 3)
        let operation = UUID()
        try #require(store).saveDraft(target, operationID: operation)
        let other = PieceDraft(name: "More recent")
        try #require(store).saveDraft(other, operationID: UUID())
        store = nil
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.recoverableDraft(itemID: target.itemID) == RecoverablePieceDraft(draft: target, operationID: operation))
        #expect(try reopened.recoverableDraft(itemID: UUID()) == nil)
        let competing = PieceDraft(itemID: target.itemID, name: "Ambiguous", baseRevision: 3)
        try reopened.saveDraft(competing, operationID: UUID())
        #expect(throws: PieceStore.StoreError.invalidRecord) { try reopened.recoverableDraft(itemID: target.itemID) }
        try reopened.discardDraft(id: competing.id)
        #expect(try reopened.recoverableDraft(itemID: target.itemID)?.draft == target)
    }

    @Test func restartFindsPendingCleanupWithoutRememberingTheDeletedOperationInUI() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        var failing: PieceStore? = try PieceStore(directory: directory, removeMediaFile: { _ in
            throw NSError(domain: "AQDFileSystemFixture", code: 1)
        })
        let id = try #require(failing).acceptPhoto(source)
        let piece = try #require(failing).savePiece(PieceDraft(name: "Cleanup restart", category: .tops, photoID: id), operationID: UUID())
        #expect(throws: (any Error).self) { try #require(failing).deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: UUID()) }
        #expect(try #require(failing).hasPendingPhotoCleanup())
        failing = nil
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.piece(id: piece.id) == nil)
        #expect(try reopened.hasPendingPhotoCleanup())
        try reopened.reconcilePendingPhotoCleanup()
        #expect(try !reopened.hasPendingPhotoCleanup())
        #expect(throws: (any Error).self) { try reopened.originalPhoto(id: id) }
        try reopened.reconcilePendingPhotoCleanup()
        #expect(try reopened.piece(id: piece.id) == nil)
    }

    @Test func editRecipeStagesBeforeSaveAndSurvivesDraftReceiptAndReopen() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        var first: PieceStore? = try PieceStore(directory: directory)
        let id = try #require(first).acceptPhoto(source)
        let recipe = try PhotoEditRecipe.portrait(originalWidth: source.pixelWidth, originalHeight: source.pixelHeight, quarterTurns: 1)
        let draft = PieceDraft(name: "Framed", category: .tops, photoID: id, photoRecipe: recipe)
        let operation = UUID()
        #expect(throws: (any Error).self) { try #require(first).savePiece(draft, operationID: operation) }
        let edit = try await PhotoPreparer().render(data: source.originalData, sourcePhotoID: id, recipe: recipe)
        try #require(first).acceptPhotoEdit(edit)
        try #require(first).saveDraft(draft, operationID: operation)
        #expect(try #require(first).originalPhoto(id: id) == source.originalData)
        #expect(try #require(first).photoRendition(id: id, recipe: recipe) == edit.renditionData)
        #expect(try #require(first).photoThumbnail(id: id, recipe: recipe) == edit.thumbnailData)
        first = nil
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.latestDraft()?.draft == draft)
        let saved = try reopened.savePiece(draft, operationID: operation)
        #expect(saved.photoRecipe == recipe && saved.photoID == id)
        #expect(try reopened.savePiece(draft, operationID: operation) == saved)
        #expect(try PieceStore(directory: directory).piece(id: saved.id) == saved)
        try FileManager.default.removeItem(at: directory.appendingPathComponent("media/\(id.uuidString).jpg"))
        let metadata = PieceDraft(itemID: saved.id, name: "Updated", category: .tops, photoID: id,
                                  baseRevision: saved.revision, photoRecipe: recipe)
        #expect(try reopened.savePiece(metadata, operationID: UUID()).photoRecipe == recipe)
        var changed = metadata
        changed.baseRevision = 2
        changed.photoRecipe = .init(quarterTurns: 2)
        #expect(throws: (any Error).self) { try reopened.savePiece(changed, operationID: UUID()) }
    }

    @Test func editAcceptanceRejectsWrongDigestAndUnknownSource() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let source = try await preparedPhoto()
        _ = try store.acceptPhoto(source)
        let edit = try await PhotoPreparer().render(data: source.originalData, sourcePhotoID: source.id,
                                                   recipe: .init(quarterTurns: 1))
        let wrongDigest = PreparedPhotoEdit(renditionData: edit.renditionData, thumbnailData: edit.thumbnailData,
            pixelWidth: edit.pixelWidth, pixelHeight: edit.pixelHeight, sourcePhotoID: source.id,
            recipe: edit.recipe, recipeDigest: String(repeating: "0", count: 64))
        #expect(throws: PieceStore.StoreError.invalidRecord) { try store.acceptPhotoEdit(wrongDigest) }
        let unknown = PreparedPhotoEdit(renditionData: edit.renditionData, thumbnailData: edit.thumbnailData,
            pixelWidth: edit.pixelWidth, pixelHeight: edit.pixelHeight, sourcePhotoID: UUID(),
            recipe: edit.recipe, recipeDigest: edit.recipeDigest)
        #expect(throws: PieceStore.StoreError.invalidRecord) { try store.acceptPhotoEdit(unknown) }
        #expect(try store.photoRendition(id: source.id, recipe: .fit) == source.originalData)
        #expect(try store.photoThumbnail(id: source.id, recipe: .fit) == source.thumbnailData)
    }

    @Test func derivedCleanupRetainsSharedSourcesAndRefusesForeignPaths() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let source = try await preparedPhoto()
        let id = try store.acceptPhoto(source)
        let recipe = PhotoEditRecipe(quarterTurns: 1)
        let edit = try await PhotoPreparer().render(data: source.originalData, sourcePhotoID: id, recipe: recipe)
        try store.acceptPhotoEdit(edit)
        let a = try store.savePiece(PieceDraft(name: "A", category: .tops, photoID: id, photoRecipe: recipe), operationID: UUID())
        let b = try store.savePiece(PieceDraft(name: "B", category: .tops, photoID: id), operationID: UUID())
        let media = directory.appendingPathComponent("media")
        let unknown = media.appendingPathComponent("\(id.uuidString)-edit-unknown-rendition.jpg")
        try Data("unowned".utf8).write(to: unknown)
        try store.deletePiece(id: a.id, expectedRevision: 1, operationID: UUID())
        #expect(try store.photoRendition(id: id, recipe: recipe) == edit.renditionData)
        let foreign = directory.appendingPathComponent("foreign.jpg")
        try Data("foreign".utf8).write(to: foreign)
        let symlink = media.appendingPathComponent("\(id.uuidString)-edit-\(String(repeating: "a", count: 64))-rendition.jpg")
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: foreign)
        let deleteOperation = UUID()
        #expect(throws: PieceStore.StoreError.unsafeMediaPath) {
            try store.deletePiece(id: b.id, expectedRevision: 1, operationID: deleteOperation)
        }
        #expect(try Data(contentsOf: foreign) == Data("foreign".utf8))
        try FileManager.default.removeItem(at: symlink)
        try store.deletePiece(id: b.id, expectedRevision: 1, operationID: deleteOperation)
        #expect(throws: (any Error).self) { try store.photoRendition(id: id, recipe: recipe) }
        #expect(try Data(contentsOf: unknown) == Data("unowned".utf8))
    }

    @Test func draftSurvivesReopenAndOnlyExactAcknowledgedPayloadClearsIt() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let prepared = try await preparedPhoto()
        var first: PieceStore? = try PieceStore(directory: directory)
        let photo = try #require(first).acceptPhoto(prepared)
        var draft = PieceDraft(name: "Blue shirt", category: .tops, photoID: photo)
        let operation = UUID()
        try #require(first).saveDraft(draft, operationID: operation)
        first = nil
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.latestDraft() == RecoverablePieceDraft(draft: draft, operationID: operation))
        let stale = draft
        draft.name = "Updated shirt"
        try reopened.saveDraft(draft, operationID: operation)
        #expect(throws: PieceStore.StoreError.staleDraft) { try reopened.savePiece(stale, operationID: operation) }
        #expect(try reopened.piece(id: draft.itemID) == nil)
        #expect(try reopened.latestDraft()?.draft == draft)
        #expect(throws: PieceStore.StoreError.staleDraft) { try reopened.savePiece(draft, operationID: UUID()) }
        let saved = try reopened.savePiece(draft, operationID: operation)
        #expect(saved.name == "Updated shirt")
        #expect(try reopened.latestDraft() == nil)
        draft.name = "Conflict"
        #expect(throws: PieceStore.StoreError.operationConflict) { try reopened.savePiece(draft, operationID: operation) }
    }

    @Test func editKeepsIdentityAndDetailsAndRejectsStaleOrFailedWrites() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        let photo = try #require(store).acceptPhoto(try await preparedPhoto())
        let original = try #require(store).savePiece(PieceDraft(name: "Shirt", category: .tops, photoID: photo), operationID: UUID())
        var edit = PieceDraft(itemID: original.id, name: "Silk shirt", category: .tops, photoID: photo,
                              baseRevision: original.revision,
                              details: PieceDetails(color: "Blue", brand: "Local", size: "M", fit: "Loose", material: "Silk",
                                                    season: "Summer", condition: "Good", ownershipAge: "Two years",
                                                    tags: ["casual"], notes: "Private", priorWearCount: 4), availability: .laundry)
        let operation = UUID()
        try #require(store).saveDraft(edit, operationID: operation)
        let updated = try #require(store).savePiece(edit, operationID: operation)
        #expect(updated.id == original.id)
        #expect(updated.revision == 2)
        #expect(updated.createdAt == original.createdAt)
        #expect(updated.details == edit.details)
        #expect(updated.availability == .laundry)
        #expect(try #require(store).savePiece(edit, operationID: operation) == updated)
        #expect(throws: PieceStore.StoreError.staleRevision) { try #require(store).savePiece(edit, operationID: UUID()) }
        store = nil
        var readOnly: PieceStore? = try PieceStore(directory: directory, allowsSave: false)
        edit.baseRevision = updated.revision
        edit.name = "Rejected"
        let failedOperation = UUID()
        #expect(throws: (any Error).self) { try #require(readOnly).savePiece(edit, operationID: failedOperation) }
        #expect(try #require(readOnly).piece(id: original.id) == updated)
        readOnly = nil
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.piece(id: original.id) == updated)
        let recoveredEdit = try reopened.savePiece(edit, operationID: failedOperation)
        #expect(recoveredEdit.revision == 3)
        #expect(recoveredEdit.name == "Rejected")
    }

    @Test func metadataSearchCombinesCategoryAndSeparateArchiveLifecycle() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let photo = try store.acceptPhoto(try await preparedPhoto())
        let shirt = try store.savePiece(PieceDraft(name: "Alpha", category: .tops, photoID: photo,
                                                 details: PieceDetails(color: "Blúe", tags: ["travel"]), availability: .laundry), operationID: UUID())
        let shoes = try store.savePiece(PieceDraft(name: "Beta", category: .shoes, photoID: photo,
                                                 details: PieceDetails(color: "Blue")), operationID: UUID())
        #expect(try store.pieces(query: "BLUE").map(\.id) == [shirt.id, shoes.id])
        #expect(try store.pieces(query: "travel", category: .tops).map(\.id) == [shirt.id])
        let operation = UUID()
        try store.setArchived(id: shirt.id, archived: true, expectedRevision: shirt.revision, operationID: operation)
        try store.setArchived(id: shirt.id, archived: true, expectedRevision: shirt.revision, operationID: operation)
        #expect(try store.pieces().map(\.id) == [shoes.id])
        let archived = try #require(store.pieces(query: "blue", category: .tops, archived: true).first)
        #expect(archived.availability == .laundry)
        #expect(archived.revision == 2)
        #expect(throws: PieceStore.StoreError.staleRevision) {
            try store.setArchived(id: shirt.id, archived: false, expectedRevision: 1, operationID: UUID())
        }
        try store.setArchived(id: shirt.id, archived: false, expectedRevision: 2, operationID: UUID())
        #expect(try store.pieces().map(\.id) == [shirt.id, shoes.id])
        #expect(try store.pieces(archived: true).isEmpty)
    }

    @Test func availabilityCombinesWithSearchCategoryAndIndependentArchiveFilter() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        let photo = try #require(store).acceptPhoto(try await preparedPhoto())
        let available = try #require(store).savePiece(PieceDraft(name: "Alpha", category: .tops, photoID: photo,
            details: PieceDetails(color: "Blúe")), operationID: UUID())
        let laundry = try #require(store).savePiece(PieceDraft(name: "Beta", category: .tops, photoID: photo,
            details: PieceDetails(color: "Blue"), availability: .laundry), operationID: UUID())
        let unavailable = try #require(store).savePiece(PieceDraft(name: "Gamma", category: .tops, photoID: photo,
            details: PieceDetails(color: "Blue"), availability: .unavailable), operationID: UUID())
        let shoes = try #require(store).savePiece(PieceDraft(name: "Delta", category: .shoes, photoID: photo,
            details: PieceDetails(color: "Blue"), availability: .laundry), operationID: UUID())
        let red = try #require(store).savePiece(PieceDraft(name: "Epsilon", category: .tops, photoID: photo,
            details: PieceDetails(color: "Red"), availability: .laundry), operationID: UUID())
        let archived = try #require(store).savePiece(PieceDraft(name: "Zeta", category: .tops, photoID: photo,
            details: PieceDetails(color: "Blue"), availability: .laundry), operationID: UUID())
        try #require(store).setArchived(id: archived.id, archived: true, expectedRevision: 1, operationID: UUID())
        store = nil
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.piece(id: archived.id)?.availability == .laundry)
        #expect(try reopened.pieces().map(\.id) == [available.id, laundry.id, shoes.id, red.id, unavailable.id])
        #expect(try reopened.pieces(availability: .available).map(\.id) == [available.id])
        #expect(try reopened.pieces(availability: .unavailable).map(\.id) == [unavailable.id])
        #expect(try reopened.pieces(availability: .laundry).map(\.id) == [laundry.id, shoes.id, red.id])
        #expect(try reopened.pieces(query: " BLUE ", category: .tops, availability: .laundry).map(\.id) == [laundry.id])
        #expect(try reopened.pieces(query: "blue", category: .shoes, availability: .laundry).map(\.id) == [shoes.id])
        #expect(try reopened.pieces(query: "blue", category: .tops, archived: true, availability: .laundry).map(\.id) == [archived.id])
        #expect(try reopened.pieces(query: "blue", category: .tops, archived: true, availability: .available).isEmpty)
        #expect(try reopened.pieces(query: "red", category: .tops, archived: true, availability: .laundry).isEmpty)
        #expect(try reopened.pieces(query: "missing", availability: .laundry).isEmpty)
    }

    @Test func recentlyAddedSortUsesCreationRatherThanEditTimeAndCombinesFiltersAfterReopen() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        let photo = try #require(store).acceptPhoto(try await preparedPhoto())
        let oldest = try #require(store).savePiece(PieceDraft(name: "Alpha", category: .tops, photoID: photo,
            details: PieceDetails(color: "Blue"), availability: .laundry), operationID: UUID())
        let middle = try #require(store).savePiece(PieceDraft(name: "Beta", category: .shoes, photoID: photo,
            details: PieceDetails(color: "Blue"), availability: .laundry), operationID: UUID())
        let newest = try #require(store).savePiece(PieceDraft(name: "Zulu", category: .tops, photoID: photo,
            details: PieceDetails(color: "Blue"), availability: .laundry), operationID: UUID())
        try #require(oldest.createdAt < middle.createdAt && middle.createdAt < newest.createdAt)
        let edited = try #require(store).savePiece(PieceDraft(itemID: oldest.id, name: "Alpha", category: .tops,
            photoID: photo, baseRevision: oldest.revision, details: oldest.details, availability: .laundry), operationID: UUID())
        #expect(edited.createdAt == oldest.createdAt)
        store = nil
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.piece(id: oldest.id) == edited)
        #expect(try reopened.pieces().map(\.id) == [oldest.id, middle.id, newest.id])
        #expect(try reopened.pieces(sort: .name).map(\.id) == [oldest.id, middle.id, newest.id])
        #expect(try reopened.pieces(sort: .recentlyAdded).map(\.id) == [newest.id, middle.id, oldest.id])
        #expect(try reopened.pieces(query: "blue", category: .tops, availability: .laundry,
            sort: .recentlyAdded).map(\.id) == [newest.id, oldest.id])
        try reopened.setArchived(id: newest.id, archived: true, expectedRevision: newest.revision, operationID: UUID())
        #expect(try reopened.pieces(query: "blue", category: .tops, availability: .laundry,
            sort: .recentlyAdded).map(\.id) == [oldest.id])
        #expect(try reopened.pieces(query: "blue", category: .tops, archived: true, availability: .laundry,
            sort: .recentlyAdded).map(\.id) == [newest.id])
    }

    @Test func nameSortFoldsCaseAndDiacriticsAndBreaksTiesByIdentity() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let photo = try store.acceptPhoto(try await preparedPhoto())
        let lowerID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        let higherID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        _ = try store.savePiece(PieceDraft(itemID: higherID, name: "álpha", category: .tops, photoID: photo), operationID: UUID())
        _ = try store.savePiece(PieceDraft(itemID: lowerID, name: "ALPHA", category: .tops, photoID: photo), operationID: UUID())
        #expect(try store.pieces().map(\.id) == [lowerID, higherID])
        #expect(try store.pieces(sort: .name).map(\.id) == [lowerID, higherID])
    }

    @Test func deletionIsExactRetryableAndRetainsSharedMediaAndOtherDrafts() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let photo = try store.acceptPhoto(try await preparedPhoto())
        let draft = PieceDraft(name: "Delete me", category: .tops, photoID: photo)
        let saveOperation = UUID()
        let removed = try store.savePiece(draft, operationID: saveOperation)
        let survivor = try store.savePiece(PieceDraft(name: "Keep me", category: .shoes, photoID: photo), operationID: UUID())
        let otherDraft = PieceDraft(name: "Unfinished", category: .layers, photoID: photo)
        try store.saveDraft(otherDraft, operationID: UUID())
        try store.saveDraft(PieceDraft(itemID: removed.id, name: "Edit", category: .tops, photoID: photo, baseRevision: 1), operationID: UUID())
        let operation = UUID()
        #expect(throws: PieceStore.StoreError.staleRevision) {
            try store.deletePiece(id: removed.id, expectedRevision: 9, operationID: operation)
        }
        try store.deletePiece(id: removed.id, expectedRevision: 1, operationID: operation)
        try store.deletePiece(id: removed.id, expectedRevision: 1, operationID: operation)
        #expect(try store.piece(id: removed.id) == nil)
        #expect(try store.piece(id: survivor.id) == survivor)
        #expect(try store.latestDraft()?.draft == otherDraft)
        #expect(try store.originalPhoto(id: photo).count > 0)
        #expect(throws: PieceStore.StoreError.deletedPiece) { try store.savePiece(draft, operationID: saveOperation) }
        #expect(throws: PieceStore.StoreError.operationConflict) {
            try store.deletePiece(id: survivor.id, expectedRevision: 1, operationID: operation)
        }
        #expect(throws: PieceStore.StoreError.operationConflict) {
            try store.savePiece(otherDraft, operationID: operation)
        }
    }

    @Test func deletionCleansOnlyItsUnreferencedOriginalsAndThumbnails() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let prepared = try await preparedPhoto()
        let oldPhoto = try store.acceptPhoto(prepared)
        let draft = PieceDraft(name: "Remove", category: .tops, photoID: oldPhoto)
        let saved = try store.savePiece(draft, operationID: UUID())
        let replacement = try store.acceptPhoto(try await preparedPhoto())
        let updated = try store.savePiece(PieceDraft(itemID: saved.id, name: "Remove", category: .tops,
                                                     photoID: replacement, baseRevision: 1), operationID: UUID())
        let draftPhoto = try store.acceptPhoto(try await preparedPhoto())
        try store.saveDraft(PieceDraft(itemID: saved.id, name: "Unfinished edit", photoID: draftPhoto,
                                      baseRevision: 2), operationID: UUID())
        let unrelated = try await preparedPhoto()
        _ = try store.acceptPhoto(unrelated)
        let unknown = directory.appendingPathComponent("media/unknown.jpg")
        try Data("not owned by any record".utf8).write(to: unknown)
        try store.deletePiece(id: updated.id, expectedRevision: 2, operationID: UUID())
        #expect(try store.piece(id: saved.id) == nil)
        #expect(try store.latestDraft() == nil)
        for photo in [oldPhoto, replacement, draftPhoto] {
            #expect(throws: (any Error).self) { try store.originalPhoto(id: photo) }
            #expect(throws: (any Error).self) { try store.thumbnailPhoto(id: photo) }
        }
        #expect(try store.originalPhoto(id: unrelated.id) == unrelated.originalData)
        #expect(try store.thumbnailPhoto(id: unrelated.id) == unrelated.thumbnailData)
        #expect(try Data(contentsOf: unknown) == Data("not owned by any record".utf8))
    }

    @Test func failedCleanupIsNotCompletedAndSameOperationReconcilesAfterReopen() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let prepared = try await preparedPhoto()
        // Permission changes also block protection reapplication before database commit
        // on the simulator. Inject only the OS unlink failure, using real files otherwise.
        let failedUnlink: (URL) throws -> Void = { url in
            if url.lastPathComponent == "\(prepared.id.uuidString)-thumbnail.jpg" {
                throw CocoaError(.fileWriteNoPermission)
            }
            try FileManager.default.removeItem(at: url)
        }
        var store: PieceStore? = try PieceStore(directory: directory, removeMediaFile: failedUnlink)
        let photo = try #require(store).acceptPhoto(prepared)
        let removed = try #require(store).savePiece(PieceDraft(name: "Remove", category: .tops, photoID: photo), operationID: UUID())
        let keptPhoto = try await preparedPhoto()
        _ = try #require(store).acceptPhoto(keptPhoto)
        let survivor = try #require(store).savePiece(PieceDraft(name: "Stay", category: .shoes, photoID: keptPhoto.id), operationID: UUID())
        let operation = UUID()
        #expect(throws: (any Error).self) {
            try #require(store).deletePiece(id: removed.id, expectedRevision: 1, operationID: operation)
        }
        #expect(try #require(store).piece(id: removed.id) == nil)
        #expect(throws: (any Error).self) { try #require(store).originalPhoto(id: photo) }
        #expect(try #require(store).thumbnailPhoto(id: photo) == prepared.thumbnailData)
        store = nil
        var reopened: PieceStore? = try PieceStore(directory: directory, removeMediaFile: failedUnlink)
        #expect(throws: (any Error).self) {
            try #require(reopened).deletePiece(id: removed.id, expectedRevision: 1, operationID: operation)
        }
        #expect(try #require(reopened).piece(id: survivor.id) == survivor)
        reopened = nil
        var readOnly: PieceStore? = try PieceStore(directory: directory, allowsSave: false)
        #expect(throws: PieceStore.StoreError.cleanupPending) {
            try #require(readOnly).deletePiece(id: removed.id, expectedRevision: 1, operationID: operation)
        }
        readOnly = nil
        let recovered = try PieceStore(directory: directory)
        #expect(throws: PieceStore.StoreError.operationConflict) {
            try recovered.deletePiece(id: survivor.id, expectedRevision: 1, operationID: operation)
        }
        try recovered.deletePiece(id: removed.id, expectedRevision: 1, operationID: operation)
        try recovered.deletePiece(id: removed.id, expectedRevision: 1, operationID: operation)
        #expect(throws: (any Error).self) { try recovered.originalPhoto(id: photo) }
        #expect(throws: (any Error).self) { try recovered.thumbnailPhoto(id: photo) }
        #expect(try recovered.piece(id: survivor.id) == survivor)
        #expect(try recovered.originalPhoto(id: keptPhoto.id) == keptPhoto.originalData)
    }

    @Test func cleanupRetainsPhotosOwnedOnlyByDraftsAndSurvivingSaveOrArchiveReceipts() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let receiptPhoto = try await preparedPhoto()
        let livePhoto = try await preparedPhoto()
        let draftPhoto = try await preparedPhoto()
        let unreferenced = try await preparedPhoto()
        for photo in [receiptPhoto, livePhoto, draftPhoto, unreferenced] { _ = try store.acceptPhoto(photo) }
        let survivor = try store.savePiece(PieceDraft(name: "Stay", category: .tops, photoID: receiptPhoto.id), operationID: UUID())
        let edited = try store.savePiece(PieceDraft(itemID: survivor.id, name: "Stay", category: .tops,
                                                   photoID: livePhoto.id, baseRevision: 1), operationID: UUID())
        let archiveOperation = UUID()
        let archived = try store.setArchived(id: edited.id, archived: true, expectedRevision: 2, operationID: archiveOperation)
        let otherDraft = PieceDraft(name: "Unfinished", photoID: draftPhoto.id)
        try store.saveDraft(otherDraft, operationID: UUID())
        var removed = try store.savePiece(PieceDraft(name: "Remove", category: .tops, photoID: receiptPhoto.id), operationID: UUID())
        for photo in [livePhoto, draftPhoto, unreferenced] {
            removed = try store.savePiece(PieceDraft(itemID: removed.id, name: "Remove", category: .tops,
                                                     photoID: photo.id, baseRevision: removed.revision), operationID: UUID())
        }
        try store.deletePiece(id: removed.id, expectedRevision: 4, operationID: UUID())
        for photo in [receiptPhoto, livePhoto, draftPhoto] {
            #expect(try store.originalPhoto(id: photo.id) == photo.originalData)
            #expect(try store.thumbnailPhoto(id: photo.id) == photo.thumbnailData)
        }
        #expect(throws: (any Error).self) { try store.originalPhoto(id: unreferenced.id) }
        #expect(throws: (any Error).self) { try store.thumbnailPhoto(id: unreferenced.id) }
        #expect(try store.piece(id: survivor.id) == archived)
        #expect(try store.latestDraft()?.draft == otherDraft)
        #expect(try store.setArchived(id: survivor.id, archived: true, expectedRevision: 2, operationID: archiveOperation) == archived)
    }

    @Test func pendingCleanupRechecksNewReferencesInsteadOfItsOldGraph() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let prepared = try await preparedPhoto()
        var store: PieceStore? = try PieceStore(directory: directory, removeMediaFile: { _ in throw CocoaError(.fileWriteNoPermission) })
        _ = try #require(store).acceptPhoto(prepared)
        let removed = try #require(store).savePiece(PieceDraft(name: "Remove", category: .tops, photoID: prepared.id), operationID: UUID())
        let operation = UUID()
        #expect(throws: (any Error).self) { try #require(store).deletePiece(id: removed.id, expectedRevision: 1, operationID: operation) }
        store = nil
        let reopened = try PieceStore(directory: directory)
        let newDraft = PieceDraft(name: "New owner", photoID: prepared.id)
        try reopened.saveDraft(newDraft, operationID: UUID())
        try reopened.deletePiece(id: removed.id, expectedRevision: 1, operationID: operation)
        #expect(try reopened.originalPhoto(id: prepared.id) == prepared.originalData)
        #expect(try reopened.thumbnailPhoto(id: prepared.id) == prepared.thumbnailData)
        #expect(try reopened.latestDraft()?.draft == newDraft)
        // Keeping a referenced candidate must keep its accepted photo record too.
        let newPiece = try reopened.savePiece(PieceDraft(name: "New piece", category: .tops, photoID: prepared.id), operationID: UUID())
        #expect(newPiece.photoID == prepared.id)
    }

    @Test func cleanupRefusesForeignSymlinksAndUnknownDirectoryContents() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let prepared = try await preparedPhoto()
        _ = try store.acceptPhoto(prepared)
        let removed = try store.savePiece(PieceDraft(name: "Remove", category: .tops, photoID: prepared.id), operationID: UUID())
        let foreign = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let foreignData = Data("Original Photos are not AQD-owned".utf8)
        try foreignData.write(to: foreign)
        let original = directory.appendingPathComponent("media/\(prepared.id.uuidString).jpg")
        let thumbnail = directory.appendingPathComponent("media/\(prepared.id.uuidString)-thumbnail.jpg")
        try FileManager.default.removeItem(at: original)
        try FileManager.default.createSymbolicLink(at: original, withDestinationURL: foreign)
        let operation = UUID()
        #expect(throws: PieceStore.StoreError.unsafeMediaPath) {
            try store.deletePiece(id: removed.id, expectedRevision: 1, operationID: operation)
        }
        #expect(try store.piece(id: removed.id) == nil)
        #expect(try Data(contentsOf: foreign) == foreignData)
        #expect(try store.thumbnailPhoto(id: prepared.id) == prepared.thumbnailData)
        try FileManager.default.removeItem(at: original)
        try prepared.originalData.write(to: original)
        try FileManager.default.removeItem(at: thumbnail)
        try FileManager.default.createDirectory(at: thumbnail, withIntermediateDirectories: false)
        let unknown = thumbnail.appendingPathComponent("unknown")
        try foreignData.write(to: unknown)
        #expect(throws: PieceStore.StoreError.unsafeMediaPath) {
            try store.deletePiece(id: removed.id, expectedRevision: 1, operationID: operation)
        }
        #expect(try Data(contentsOf: unknown) == foreignData)
        #expect(try Data(contentsOf: foreign) == foreignData)
        try FileManager.default.removeItem(at: thumbnail)
        try store.deletePiece(id: removed.id, expectedRevision: 1, operationID: operation)
        #expect(throws: (any Error).self) { try store.originalPhoto(id: prepared.id) }
        #expect(throws: (any Error).self) { try store.thumbnailPhoto(id: prepared.id) }
        #expect(try Data(contentsOf: foreign) == foreignData)
    }

    @Test func redirectedMediaFolderCannotDeleteForeignFiles() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let prepared = try await preparedPhoto()
        _ = try store.acceptPhoto(prepared)
        let piece = try store.savePiece(PieceDraft(name: "Remove", category: .tops, photoID: prepared.id), operationID: UUID())
        let media = directory.appendingPathComponent("media")
        let heldMedia = directory.appendingPathComponent("held-media")
        let foreign = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: foreign, withIntermediateDirectories: false)
        let foreignOriginal = foreign.appendingPathComponent("\(prepared.id.uuidString).jpg")
        let foreignThumbnail = foreign.appendingPathComponent("\(prepared.id.uuidString)-thumbnail.jpg")
        let sentinel = Data("Foreign original Photos".utf8)
        try sentinel.write(to: foreignOriginal)
        try sentinel.write(to: foreignThumbnail)
        // Only media is moved; never rename/unlink an open SQLite store or its sidecars.
        try FileManager.default.moveItem(at: media, to: heldMedia)
        try FileManager.default.createSymbolicLink(at: media, withDestinationURL: foreign)
        let operation = UUID()
        #expect(throws: PieceStore.StoreError.unsafeMediaPath) {
            try store.deletePiece(id: piece.id, expectedRevision: 1, operationID: operation)
        }
        #expect(try store.piece(id: piece.id) == piece)
        #expect(try Data(contentsOf: foreignOriginal) == sentinel)
        #expect(try Data(contentsOf: foreignThumbnail) == sentinel)
        try FileManager.default.removeItem(at: media)
        try FileManager.default.moveItem(at: heldMedia, to: media)
        try store.deletePiece(id: piece.id, expectedRevision: 1, operationID: operation)
        #expect(try store.piece(id: piece.id) == nil)
        #expect(throws: (any Error).self) { try store.originalPhoto(id: prepared.id) }
        #expect(try Data(contentsOf: foreignOriginal) == sentinel)
        #expect(try Data(contentsOf: foreignThumbnail) == sentinel)
    }

    @Test func unsupportedAndCorruptStoresRefuseOpeningWithoutReplacingBytes() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        let photo = try #require(store).acceptPhoto(try await preparedPhoto())
        let saved = try #require(store).savePiece(PieceDraft(name: "Retain", category: .tops, photoID: photo), operationID: UUID())
        store = nil
        let database = directory.appendingPathComponent("wardrobe.store")
        let marker = directory.appendingPathComponent("schema-version")
        let originalMarker = try Data(contentsOf: marker)
        let bytes = try Data(contentsOf: database)
        try Data("AQD-piece-store:999".utf8).write(to: marker)
        #expect(throws: PieceStore.StoreError.unsupportedStore) { try PieceStore(directory: directory) }
        #expect(try Data(contentsOf: database) == bytes)
        #expect(try Data(contentsOf: marker) == Data("AQD-piece-store:999".utf8))
        try originalMarker.write(to: marker)
        let recovered = try PieceStore(directory: directory)
        #expect(try recovered.piece(id: saved.id) == saved)

        let corruptDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: corruptDirectory, withIntermediateDirectories: true)
        let corruptURL = corruptDirectory.appendingPathComponent("wardrobe.store")
        let corrupt = Data("not a database".utf8)
        try corrupt.write(to: corruptURL)
        try originalMarker.write(to: corruptDirectory.appendingPathComponent("schema-version"))
        #expect(throws: PieceStore.StoreError.corruptStore) { try PieceStore(directory: corruptDirectory) }
        #expect(try Data(contentsOf: corruptURL) == corrupt)
    }

    @Test func unfinishedAndOverLimitDraftsRemainRecoverableAndDiscardIsExact() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        let first = PieceDraft(name: "Unfinished")
        try #require(store).saveDraft(first, operationID: UUID())
        let second = PieceDraft(name: String(repeating: "n", count: 81), details: PieceDetails(notes: String(repeating: "x", count: 2001)))
        let operation = UUID()
        try #require(store).saveDraft(second, operationID: operation)
        store = nil
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.latestDraft() == RecoverablePieceDraft(draft: second, operationID: operation))
        try reopened.discardDraft(id: first.id)
        #expect(try reopened.latestDraft()?.draft == second)
        try reopened.discardDraft(id: second.id)
        #expect(try reopened.latestDraft() == nil)
    }

    @Test func failedSaveKeepsDurableDraftAndSameOperationCanSucceedLater() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var writable: PieceStore? = try PieceStore(directory: directory)
        let photo = try #require(writable).acceptPhoto(try await preparedPhoto())
        let draft = PieceDraft(name: "Retain draft", category: .tops, photoID: photo)
        let operation = UUID()
        try #require(writable).saveDraft(draft, operationID: operation)
        writable = nil
        var readOnly: PieceStore? = try PieceStore(directory: directory, allowsSave: false)
        #expect(throws: (any Error).self) { try #require(readOnly).savePiece(draft, operationID: operation) }
        #expect(try #require(readOnly).latestDraft()?.draft == draft)
        #expect(try #require(readOnly).piece(id: draft.itemID) == nil)
        readOnly = nil
        let recovered = try PieceStore(directory: directory)
        #expect(try recovered.latestDraft()?.operationID == operation)
        let saved = try recovered.savePiece(draft, operationID: operation)
        #expect(saved.id == draft.itemID)
        #expect(try recovered.latestDraft() == nil)
    }

    @Test func missingOriginalDoesNotPreventMetadataEditsOfExistingIdentity() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let photo = try store.acceptPhoto(try await preparedPhoto())
        let saved = try store.savePiece(PieceDraft(name: "Existing", category: .tops, photoID: photo), operationID: UUID())
        // Simulate external loss of a media file, never unlink an open database.
        try FileManager.default.removeItem(at: directory.appendingPathComponent("media/\(photo.uuidString).jpg"))
        let edit = PieceDraft(itemID: saved.id, name: "Still editable", category: .tops, photoID: photo, baseRevision: 1)
        let updated = try store.savePiece(edit, operationID: UUID())
        #expect(updated.name == "Still editable")
        #expect(updated.photoID == photo)
        #expect(try store.piece(id: saved.id) == updated)
        #expect(throws: PieceStore.StoreError.missingPhoto) {
            try store.savePiece(PieceDraft(name: "New", category: .tops, photoID: photo), operationID: UUID())
        }
    }

    @Test func ownedDatabaseSidecarsOriginalsAndThumbnailsAreProtectedAndExcludedFromBackup() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let photo = try store.acceptPhoto(try await preparedPhoto())
        _ = try store.savePiece(PieceDraft(name: "Protected", category: .tops, photoID: photo), operationID: UUID())
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        #expect(files.contains { $0.lastPathComponent == "wardrobe.store" })
        #expect(files.contains { $0.lastPathComponent == "wardrobe.store-wal" })
        #expect(files.contains { $0.lastPathComponent == "wardrobe.store-shm" })
        let media = try FileManager.default.contentsOfDirectory(at: directory.appendingPathComponent("media"), includingPropertiesForKeys: nil)
        #expect(media.count == 2)
        for file in files + media {
            #expect(try file.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true)
            let protection = try FileManager.default.attributesOfItem(atPath: file.path)[.protectionKey] as? FileProtectionType
            #if targetEnvironment(simulator)
            // Simulator host filesystems can omit NSFileProtectionKey. Backup exclusions
            // are still checked here; actual locked-device protection remains a device gate.
            #expect(protection == nil || protection == .complete)
            #else
            #expect(protection == .complete)
            #endif
        }
    }

    @Test func acceptedThumbnailCanBeReadWithoutDecodingTheOriginal() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let prepared = try await preparedPhoto()
        let photo = try store.acceptPhoto(prepared)
        #expect(try store.thumbnailPhoto(id: photo) == prepared.thumbnailData)
        #expect(try store.originalPhoto(id: photo) == prepared.originalData)
    }

    private func preparedPhoto() async throws -> PreparedPhoto {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 30)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 30))
        }
        return try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 1)))
    }

    @Test func failedDatabaseWritePreservesPriorPieceAndCreatesNoReceipt() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        // Let the test host reclaim temporary stores after exit, never unlink open SQLite files.
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 30)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 30))
        }
        let prepared = try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 1)))
        var writable: PieceStore? = try PieceStore(directory: directory)
        let photo = try #require(writable).acceptPhoto(prepared)
        let originalDraft = PieceDraft(name: "Walking shoes", category: .shoes, photoID: photo)
        let original = try #require(writable).savePiece(originalDraft, operationID: UUID())
        writable = nil

        let rejected = PieceDraft(name: "Second pair", category: .shoes, photoID: photo)
        let operation = UUID()
        var readOnly: PieceStore? = try PieceStore(directory: directory, allowsSave: false)
        #expect(throws: (any Error).self) { try #require(readOnly).savePiece(rejected, operationID: operation) }
        let retained = try #require(readOnly).piece(id: original.id)
        #expect(retained == original)
        let absent = try #require(readOnly).piece(id: rejected.itemID)
        #expect(absent == nil)
        readOnly = nil
        let recovered = try PieceStore(directory: directory)
        let retried = try recovered.savePiece(rejected, operationID: operation)
        #expect(retried.name == "Second pair")
        #expect(retried.id == rejected.itemID)
    }

    @Test func retryAfterReopeningReturnsTheSameAcknowledgedSave() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        // Let the test host reclaim temporary stores after exit, never unlink open SQLite files.
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 30)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 30))
        }
        let prepared = try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 1)))
        var first: PieceStore? = try PieceStore(directory: directory)
        let photoID = try #require(first).acceptPhoto(prepared)
        let draft = PieceDraft(name: "Walking shoes", category: .shoes, photoID: photoID)
        let operation = UUID()
        let saved = try #require(first).savePiece(draft, operationID: operation)
        first = nil
        let reopened = try PieceStore(directory: directory)
        let retried = try reopened.savePiece(draft, operationID: operation)
        #expect(retried == saved)
    }

    @Test func savedPieceSurvivesStoreReopeningWithSameIdentityAndPhoto() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        // Let the test host reclaim temporary stores after exit, never unlink open SQLite files.
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 30)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 30))
        }
        let prepared = try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 1)))
        let itemID = UUID()
        var first: PieceStore? = try PieceStore(directory: directory)
        let photoID = try #require(first).acceptPhoto(prepared)
        let draft = PieceDraft(itemID: itemID, name: "  Walking shoes  ", category: .shoes, photoID: photoID)
        let saved = try #require(first).savePiece(draft, operationID: UUID())
        #expect(saved.id == itemID)
        first = nil

        let reopened = try PieceStore(directory: directory)
        let fetched = try reopened.piece(id: itemID)
        let piece = try #require(fetched)
        #expect(piece.name == "Walking shoes")
        #expect(piece.category == .shoes)
        #expect(piece.photoID == photoID)
        #expect(try reopened.originalPhoto(id: photoID).count > 0)
    }
}
