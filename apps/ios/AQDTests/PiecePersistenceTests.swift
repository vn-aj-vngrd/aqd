import AQDCore
import Foundation
import CryptoKit
import SwiftData
import SwiftUI
import Testing
import UIKit
@testable import AQD

@Suite(.serialized)
@MainActor
struct PiecePersistenceTests {
    // Stage A native runner observed runtime RED before the recovery handler.
    // Actual record acknowledgment followed by denied unlink, not fake error state.
    @Test func acknowledgedDeletionWithDeniedPhotoCleanupRefreshesCollectionAndPublishesRecovery() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        let original = directory.appendingPathComponent("media/\(source.id.uuidString).jpg")
        let thumbnail = directory.appendingPathComponent("media/\(source.id.uuidString)-thumbnail.jpg")
        var deniedOwnedUnlink = false
        let state = AppState(store: try PieceStore(directory: directory, removeMediaFile: { url in
            if url == original || url == thumbnail {
                deniedOwnedUnlink = true
                throw CocoaError(.fileWriteNoPermission)
            }
            try FileManager.default.removeItem(at: url)
        }))
        defer { state.store = nil }
        _ = try #require(state.store).acceptPhoto(source)
        let piece = try #require(state.store).savePiece(
            PieceDraft(name: "Reviewed deletion", category: .tops, photoID: source.id), operationID: UUID())
        state.reloadPieces()
        try #require(state.pieces.contains { $0.id == piece.id })
        try #require(state.photoCleanupError == nil)
        let refreshID = state.collectionRefreshID

        let operationID = UUID()
        try state.deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: operationID)
        try #require(deniedOwnedUnlink)
        #expect(try #require(state.store).piece(id: piece.id) == nil)
        #expect(try #require(state.store).hasPendingPhotoCleanup())
        #expect(!state.pieces.contains { $0.id == piece.id })
        #expect(state.photoCleanupError != nil)
        #expect(state.collectionRefreshID != refreshID)
        #expect(try Data(contentsOf: original) == source.originalData)
        #expect(try Data(contentsOf: thumbnail) == source.thumbnailData)

        state.store = nil
        var reopened: PieceStore? = try PieceStore(directory: directory, allowsSave: false)
        #expect(try #require(reopened).piece(id: piece.id) == nil)
        #expect(try #require(reopened).hasPendingPhotoCleanup())
        #expect(try #require(reopened).isPieceDeletionAcknowledged(id: piece.id,
            expectedRevision: piece.revision, operationID: operationID))
        #expect(try Data(contentsOf: original) == source.originalData)
        #expect(try Data(contentsOf: thumbnail) == source.thumbnailData)
        reopened = nil
        state.store = try PieceStore(directory: directory)
        // The exact reviewed retry completes cleanup and clears old global feedback.
        try state.deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: operationID)
        #expect(state.photoCleanupError == nil)
        #expect(state.pieces.isEmpty)
        #expect(try !#require(state.store).hasPendingPhotoCleanup())
        #expect(!FileManager.default.fileExists(atPath: original.path))
        #expect(!FileManager.default.fileExists(atPath: thumbnail.path))
        #expect(throws: PieceStore.StoreError.deletedPiece) {
            try #require(state.store).saveDraft(PieceDraft(itemID: piece.id, name: "Cannot resurrect"), operationID: UUID())
        }
    }

    // Stage A regression: render and stage real synthetic media, then retry the
    // same framing through CaptureModel, without assigning an error or source.
    @Test func successfulPhotoEditRetryPersistsAcceptedFramingAndClearsItsFailure() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        var denyNextDerivativeWrite = true
        var deniedDerivativeWrite = false
        let state = AppState(store: try PieceStore(directory: directory, writeMediaFile: { data, url in
            if denyNextDerivativeWrite && url.lastPathComponent.contains("-edit-") {
                denyNextDerivativeWrite = false
                deniedDerivativeWrite = true
                throw CocoaError(.fileWriteNoPermission)
            }
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        }))
        defer { state.store = nil }
        _ = try #require(state.store).acceptPhoto(source)
        let initial = PieceDraft(name: "Retained framing draft", category: .tops, photoID: source.id,
            details: PieceDetails(color: "Blue", notes: "Keep this metadata through the framing retry"))
        try #require(state.store).saveDraft(initial, operationID: UUID())
        state.addPiece()
        let model = try #require(state.capture)
        let recipe = PhotoEditRecipe(quarterTurns: 1)
        let failed = await model.applyPhotoEdit(recipe, sourceID: source.id, previousRecipe: .fitOriginal)
        try #require(deniedDerivativeWrite)
        try #require(!failed)
        try #require(model.draft == initial)
        try #require(!model.draftSaveFailed)
        try #require(model.errorText == "These photo edits couldn’t be prepared. Your previous photo and framing are unchanged. Try again or keep the original.")
        #expect(try #require(state.store).newPieceDraft()?.draft == initial)
        #expect(model.originalPhotoData() == source.originalData)

        let accepted = await model.applyPhotoEdit(recipe, sourceID: source.id, previousRecipe: .fitOriginal)
        try #require(accepted)
        var expectedDraft = initial
        expectedDraft.photoRecipe = recipe
        #expect(model.draft == expectedDraft)
        #expect(!model.draftSaveFailed)
        #expect(model.errorText == nil)
        let expected = RecoverablePieceDraft(draft: model.draft, operationID: model.operationID)
        #expect(try #require(state.store).newPieceDraft() == expected)
        #expect(model.originalPhotoData() == source.originalData)
        #expect(try #require(state.store).thumbnailPhoto(id: source.id) == source.thumbnailData)
        #expect(try !#require(state.store).photoRendition(id: source.id, recipe: recipe).isEmpty)

        state.capture = nil
        state.store = nil
        let reopened = try PieceStore(directory: directory, allowsSave: false)
        #expect(try reopened.newPieceDraft() == expected)
        #expect(try reopened.originalPhoto(id: source.id) == source.originalData)
        #expect(try reopened.thumbnailPhoto(id: source.id) == source.thumbnailData)
    }

    @Test(arguments: [0, 1, 2])
    func unacknowledgedDeletionPreservesReviewedRecordAndCollection(failure: Int) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        let saveOperation = UUID()
        let piece: WardrobePiece
        do {
            let store = try PieceStore(directory: directory)
            _ = try store.acceptPhoto(source)
            piece = try store.savePiece(PieceDraft(name: "Keep reviewed record", category: .tops,
                photoID: source.id), operationID: saveOperation)
            try store.reconcilePendingPhotoCleanup()
        }
        let state = AppState(store: try PieceStore(directory: directory, allowsSave: failure != 0))
        defer { state.store = nil }
        let operation = failure == 2 ? saveOperation : UUID()
        let revision = failure == 1 ? piece.revision + 1 : piece.revision
        let refreshID = state.collectionRefreshID
        let cleanupError = state.photoCleanupError
        let bytes = try authoritativeStoreBytes(directory)
        #expect(throws: (any Error).self) {
            try state.deletePiece(id: piece.id, expectedRevision: revision, operationID: operation)
        }
        #expect(try !#require(state.store).isPieceDeletionAcknowledged(id: piece.id,
            expectedRevision: revision, operationID: operation))
        #expect(try #require(state.store).piece(id: piece.id) == piece)
        #expect(state.pieces == [piece])
        #expect(state.collectionRefreshID == refreshID)
        #expect(state.photoCleanupError == cleanupError)
        #expect(try authoritativeStoreBytes(directory) == bytes)
        #expect(try #require(state.store).originalPhoto(id: source.id) == source.originalData)
        #expect(try #require(state.store).thumbnailPhoto(id: source.id) == source.thumbnailData)
    }

    @Test func deletionAcknowledgmentIsExactReadOnlyAndCompletedRetryNeverResurrects() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        let state = AppState(store: try PieceStore(directory: directory))
        defer { state.store = nil }
        _ = try #require(state.store).acceptPhoto(source)
        let draft = PieceDraft(name: "Deleted identity", category: .tops, photoID: source.id)
        let piece = try #require(state.store).savePiece(draft, operationID: UUID())
        let retained = try #require(state.store).savePiece(PieceDraft(name: "Shared source remains", category: .tops,
            photoID: source.id), operationID: UUID())
        let operation = UUID()
        try state.deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: operation)
        let bytes = try authoritativeStoreBytes(directory)
        for _ in 0..<2 {
            #expect(try #require(state.store).isPieceDeletionAcknowledged(id: piece.id,
                expectedRevision: piece.revision, operationID: operation))
            #expect(try !#require(state.store).isPieceDeletionAcknowledged(id: piece.id,
                expectedRevision: piece.revision, operationID: UUID()))
            #expect(throws: PieceStore.StoreError.operationConflict) {
                try #require(state.store).isPieceDeletionAcknowledged(id: retained.id,
                    expectedRevision: retained.revision, operationID: operation)
            }
            #expect(throws: PieceStore.StoreError.operationConflict) {
                try #require(state.store).isPieceDeletionAcknowledged(id: piece.id,
                    expectedRevision: piece.revision + 1, operationID: operation)
            }
            #expect(throws: PieceStore.StoreError.operationConflict) {
                try state.deletePiece(id: retained.id, expectedRevision: retained.revision, operationID: operation)
            }
            try state.deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: operation)
            #expect(try authoritativeStoreBytes(directory) == bytes)
            #expect(state.pieces == [retained])
            #expect(state.photoCleanupError == nil)
        }
        #expect(throws: PieceStore.StoreError.deletedPiece) {
            try #require(state.store).savePiece(draft, operationID: UUID())
        }
        #expect(try #require(state.store).piece(id: piece.id) == nil)
        #expect(try #require(state.store).piece(id: retained.id) == retained)
        #expect(try #require(state.store).originalPhoto(id: source.id) == source.originalData)
    }

    @Test(arguments: [0, 1, 2, 3])
    func corruptDeletionProofCannotAcknowledgeOrDismissReviewedRetry(corruption: Int) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        let operation = UUID()
        let piece: WardrobePiece
        do {
            let store = try PieceStore(directory: directory, removeMediaFile: { _ in
                throw CocoaError(.fileWriteNoPermission)
            })
            _ = try store.acceptPhoto(source)
            piece = try store.savePiece(PieceDraft(name: "Corrupt proof guard", category: .tops,
                photoID: source.id), operationID: UUID())
            #expect(throws: CocoaError(.fileWriteNoPermission)) {
                try store.deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: operation)
            }
        }
        do {
            let schema = Schema(versionedSchema: LocalSchemaV2.self)
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema,
                url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)])
            let context = ModelContext(container)
            let proof = try #require(context.fetch(FetchDescriptor<StoredPieceDeletion>()).first)
            switch corruption {
            case 0: proof.expectedRevision = 0
            case 1: proof.pendingPhotoIDs = [source.id, source.id]
            case 2: context.insert(StoredPiece(piece))
            default: context.insert(StoredPieceSave(id: operation, itemID: UUID(), draftDigest: "Contradictory operation", snapshot: Data()))
            }
            try context.save()
        }
        let state = AppState(store: try PieceStore(directory: directory, allowsSave: false))
        defer { state.store = nil }
        let refreshID = state.collectionRefreshID
        let cleanupError = state.photoCleanupError
        let bytes = try authoritativeStoreBytes(directory)
        #expect(throws: PieceStore.StoreError.invalidRecord) {
            try #require(state.store).isPieceDeletionAcknowledged(id: piece.id,
                expectedRevision: piece.revision, operationID: operation)
        }
        #expect(throws: PieceStore.StoreError.invalidRecord) {
            try state.deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: operation)
        }
        #expect(state.collectionRefreshID == refreshID)
        #expect(state.photoCleanupError == cleanupError)
        #expect(try authoritativeStoreBytes(directory) == bytes)
        #expect(try #require(state.store).originalPhoto(id: source.id) == source.originalData)
        #expect(try #require(state.store).thumbnailPhoto(id: source.id) == source.thumbnailData)
    }

    @Test(arguments: [0, 1, 2])
    func acceptedPhotoEditPreservesUnrelatedErrorsAndActiveDraftWriteFailure(errorKind: Int) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        weak var activeState: AppState?
        let writable = try PieceStore(directory: directory, writeMediaFile: { data, url in
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            if errorKind == 2 && url.lastPathComponent.contains("-edit-")
                && url.lastPathComponent.hasSuffix("-thumbnail.jpg") {
                // Actual derivative staging succeeds, but the subsequent draft commit is refused.
                activeState?.store = try PieceStore(directory: directory, allowsSave: false)
            }
        })
        let state = AppState(store: writable)
        activeState = state
        defer { state.store = nil }
        _ = try writable.acceptPhoto(source)
        let initial = PieceDraft(name: "Preserve unrelated failure", category: .tops, photoID: source.id,
            details: PieceDetails(color: "Blue", notes: "Retain fields despite the unrelated failure"))
        try writable.saveDraft(initial, operationID: UUID())
        state.addPiece()
        let model = try #require(state.capture)
        let expectedError: String
        if errorKind == 0 {
            state.store = try PieceStore(directory: directory, allowsSave: false)
            model.save()
            expectedError = "Save didn’t finish. Your draft is still here. Retry checks the same operation before writing again."
            try #require(model.errorText == expectedError)
            state.store = writable
        } else if errorKind == 1 {
            model.importPhoto { Data("not an image".utf8) }
            while model.isImporting { await Task.yield() }
            expectedError = "That photo couldn’t be prepared. Your fields and previous photo are unchanged. Choose another photo or keep the draft."
            try #require(model.errorText == expectedError)
        } else {
            expectedError = "These changes couldn’t be kept as a recoverable draft. Keep editing or discard this draft before leaving."
        }
        let recipe = PhotoEditRecipe(quarterTurns: 1)
        let accepted = await model.applyPhotoEdit(recipe, sourceID: source.id, previousRecipe: .fitOriginal)
        #expect(accepted)
        var expectedDraft = initial
        expectedDraft.photoRecipe = recipe
        #expect(model.draft == expectedDraft)
        #expect(model.errorText == expectedError)
        #expect(model.draftSaveFailed == (errorKind == 2))
        if errorKind == 2 {
            #expect(try writable.newPieceDraft()?.draft == initial)
            #expect(!model.canSave)
        } else {
            #expect(try writable.newPieceDraft() == RecoverablePieceDraft(draft: model.draft, operationID: model.operationID))
        }
        #expect(model.saved == nil)
        #expect(try writable.originalPhoto(id: source.id) == source.originalData)
        #expect(try writable.thumbnailPhoto(id: source.id) == source.thumbnailData)
    }

    // Postimplementation observation guard; no test-first RED is claimed.
    @Test(arguments: [0, 2])
    func heldPhotoCleanupFooterObservesActualFailureAndRecovery(pendingRequests: Int) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let state = AppState(store: try PieceStore(directory: directory))
        defer { state.store = nil }
        let marker = directory.appendingPathComponent("schema-version")
        let markerBytes = try Data(contentsOf: marker)
        try #require(state.photoCleanupError == nil)

        // Construct once, just like the native root builders. Never replace
        // rootView: the existing SwiftUI body must observe both transitions.
        let host = UIHostingController(rootView: PhotoCleanupRecoveryView().environment(state))
        let heldView = try #require(host.view)
        heldView.frame = CGRect(x: 0, y: 0, width: 390, height: 1000)
        let proposal = CGSize(width: 390, height: 1000)
        let initialHeight = await cleanupFooterHeight(host, proposal: proposal, visible: false)
        #expect(initialHeight == 0)

        state.store = nil
        if pendingRequests > 0 {
            // Real persisted cleanup intents, not fake error text or a mock
            // store. These unowned IDs intentionally have no media bytes.
            do {
                let schema = Schema(versionedSchema: LocalSchemaV2.self)
                let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema,
                    url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)])
                let context = ModelContext(container)
                for _ in 0..<pendingRequests { context.insert(StoredPhotoCleanup(photoID: UUID())) }
                try context.save()
                #expect(try context.fetch(FetchDescriptor<StoredPhotoCleanup>()).count == pendingRequests)
            }
        }
        state.store = try PieceStore(directory: directory, allowsSave: false)
        #expect(try #require(state.store).hasPendingPhotoCleanup() == (pendingRequests > 0))
        state.retryPhotoCleanup()
        try #require(state.photoCleanupError != nil)
        // Even the empty-queue case must surface the actual reconciliation
        // failure; it is not evidence of incomplete erasure of any bytes.
        let failureHeight = await cleanupFooterHeight(host, proposal: proposal, visible: true)
        #expect(failureHeight > 44)
        #expect(host.view === heldView)

        state.store = nil
        state.store = try PieceStore(directory: directory)
        state.retryPhotoCleanup()
        try #require(state.photoCleanupError == nil)
        #expect(try !#require(state.store).hasPendingPhotoCleanup())
        let recoveredHeight = await cleanupFooterHeight(host, proposal: proposal, visible: false)
        #expect(recoveredHeight == 0)
        #expect(host.view === heldView)
        #expect(try Data(contentsOf: marker) == markerBytes)
    }

    private func cleanupFooterHeight<Content: View>(
        _ host: UIHostingController<Content>, proposal: CGSize, visible: Bool
    ) async -> CGFloat {
        var height: CGFloat = 0
        // Bounded main-actor scheduling and native layout, without taking over
        // any application window or assuming screenshots prove observation.
        for _ in 0..<100 {
            await Task.yield()
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            height = host.sizeThatFits(in: proposal).height
            if visible ? height > 44 : height == 0 { break }
        }
        return height
    }

    @Test func keepingDraftAfterReadOnlyFailureRecoversExactChangesAndClearsFailureMessage() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let initial = PieceDraft(name: "Before retry", category: .tops)
        let initialOperation = UUID()
        do {
            let store = try PieceStore(directory: directory)
            try store.saveDraft(initial, operationID: initialOperation)
        }
        let state = AppState(store: try PieceStore(directory: directory, allowsSave: false))
        state.addPiece()
        let model = try #require(state.capture)
        #expect(model.draft == initial)
        model.update(\.name, value: "Keep these exact changes")
        let expectedDraft = model.draft
        let expectedOperation = model.operationID
        model.leave()
        try #require(model.draftSaveFailed)
        #expect(model.errorText == "These changes couldn’t be kept as a recoverable draft. Keep editing or discard this draft before leaving.")
        #expect(state.capture === model)
        #expect(try #require(state.store).newPieceDraft() == RecoverablePieceDraft(
            draft: initial, operationID: initialOperation))

        // Retry Keep draft against the same durable store, now writable.
        state.store = nil
        state.store = try PieceStore(directory: directory)
        model.leave()
        #expect(!model.draftSaveFailed)
        #expect(model.errorText == nil)
        #expect(state.capture == nil)
        #expect(model.draft == expectedDraft)
        #expect(model.operationID == expectedOperation)
        state.store = nil
        let reopened = try PieceStore(directory: directory, allowsSave: false)
        #expect(try reopened.newPieceDraft() == RecoverablePieceDraft(
            draft: expectedDraft, operationID: expectedOperation))
        #expect(try reopened.pieces().isEmpty)
    }

    @Test(arguments: [false, true])
    func emptyOrCancelledPhotoImportPreservesActiveDraftFailure(cancelPending: Bool) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        let initial = PieceDraft(name: "Before failed update", category: .tops, photoID: source.id,
            details: PieceDetails(notes: "Retain these fields"))
        let initialOperation = UUID()
        do {
            let store = try PieceStore(directory: directory)
            _ = try store.acceptPhoto(source)
            try store.saveDraft(initial, operationID: initialOperation)
        }
        let state = AppState(store: try PieceStore(directory: directory, allowsSave: false))
        state.addPiece()
        let model = try #require(state.capture)
        #expect(model.draft == initial)
        model.update(\.name, value: "Unsaved exact changes")
        let expectedDraft = model.draft
        let expectedOperation = model.operationID
        let expectedError = "These changes couldn’t be kept as a recoverable draft. Keep editing or discard this draft before leaving."
        try #require(model.draftSaveFailed)
        try #require(model.errorText == expectedError)
        // Valid fields/photo isolate the Save block to the persistence failure.
        _ = try expectedDraft.validated()

        var pendingLoad: CheckedContinuation<Data?, Never>?
        var loadCompleted = false
        defer { pendingLoad?.resume(returning: nil) }
        model.importPhoto {
            let data = await withCheckedContinuation { pendingLoad = $0 }
            loadCompleted = true
            return data
        }
        // Bounded scheduling, with a released continuation even if setup fails.
        for _ in 0..<100 {
            if pendingLoad != nil { break }
            await Task.yield()
        }
        let load = try #require(pendingLoad)
        try #require(model.isImporting)
        if cancelPending { model.cancelImport() }
        pendingLoad = nil
        load.resume(returning: nil)
        for _ in 0..<100 {
            if loadCompleted && !model.isImporting { break }
            await Task.yield()
        }
        try #require(loadCompleted)
        try #require(!model.isImporting)

        #expect(model.errorText == expectedError)
        #expect(model.draftSaveFailed)
        #expect(!model.canSave)
        #expect(model.draft == expectedDraft)
        #expect(model.operationID == expectedOperation)
        #expect(model.originalPhotoData() == source.originalData)
        #expect(state.capture === model)
        #expect(model.saved == nil)
        #expect(try #require(state.store).newPieceDraft() == RecoverablePieceDraft(
            draft: initial, operationID: initialOperation))
        #expect(try #require(state.store).pieces().isEmpty)
    }

    // Added after the draft retry fix; no test-first RED is claimed for this guardrail.
    @Test(arguments: [false, true])
    func successfulDraftUpdatePreservesUnrelatedImportAndSaveErrors(importFailure: Bool) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let state = AppState(store: try PieceStore(directory: directory))
        // A missing source is recoverable in a draft, but cannot become a saved piece.
        let draft = PieceDraft(name: "Retained fields", category: .tops, photoID: UUID())
        let model = CaptureModel(state: state, draft: draft, operationID: UUID())
        let expectedError: String
        if importFailure {
            model.importPhoto { throw CocoaError(.fileReadNoPermission) }
            while model.isImporting { await Task.yield() }
            expectedError = "That photo couldn’t be prepared. Your fields and previous photo are unchanged. Choose another photo or keep the draft."
        } else {
            try #require(model.canSave)
            model.save()
            expectedError = "Save didn’t finish. Your draft is still here. Retry checks the same operation before writing again."
        }
        try #require(model.errorText == expectedError)
        #expect(model.saved == nil)
        model.update(\.name, value: "Updated recoverable fields")
        #expect(!model.draftSaveFailed)
        #expect(model.errorText == expectedError)
        #expect(try #require(state.store).newPieceDraft() == RecoverablePieceDraft(
            draft: model.draft, operationID: model.operationID))
    }

    @Test(arguments: [false, true])
    func interruptedFirstUseWithoutMarkerFinishesAndPreservesTodayIdentities(todayWasCommitted: Bool) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let today = TodayConfiguration(ownerID: UUID())
        // Both crash windows use the real current native schema: before the first
        // Today commit, and after it but before the external marker is written.
        do {
            let schema = Schema(versionedSchema: LocalSchemaV2.self)
            let configuration = ModelConfiguration(schema: schema,
                url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            if todayWasCommitted { context.insert(StoredTodayConfiguration(today)) }
            try context.save()
        }
        let marker = directory.appendingPathComponent("schema-version")
        #expect(!FileManager.default.fileExists(atPath: marker.path))
        var recovered: PieceStore? = try PieceStore(directory: directory)
        let first = try #require(recovered).todayConfiguration()
        if todayWasCommitted { #expect(first == today) }
        #expect(first.revision == 1)
        #expect(first.instances.map(\.kind) == [.todayLook, .weekInWear, .closetInUse])
        #expect(Set(first.instances.map(\.id)).count == 3)
        #expect(try #require(recovered).pieces().isEmpty)
        #expect(try #require(recovered).latestDraft() == nil)
        #expect(try !#require(recovered).hasPendingPhotoCleanup())
        #expect(try Data(contentsOf: marker) == Data("AQD-piece-store:2".utf8))
        recovered = nil
        let reopened = try PieceStore(directory: directory, allowsSave: false)
        #expect(try reopened.todayConfiguration() == first)
        #expect(try reopened.pieces().isEmpty)
    }

    @Test(arguments: Array(0...13))
    func unmarkedNonBootstrapLayoutsAreRefusedWithoutChangingBytes(layout: Int) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let media = directory.appendingPathComponent("media", isDirectory: true)
        try FileManager.default.createDirectory(at: media, withIntermediateDirectories: true)
        let sentinel = media.appendingPathComponent("unknown.jpg")
        let sentinelBytes = Data("Preserve unrecognized media".utf8)
        try sentinelBytes.write(to: sentinel)
        let database = directory.appendingPathComponent("wardrobe.store")
        // Keep the fixture's writer alive through the preservation assertions.
        // Scope exit alone cannot certify that native teardown/checkpointing ended.
        var fixtureContainer: ModelContainer?
        var fixtureContext: ModelContext?
        if layout < 10 || layout > 11 {
            do {
                let schema: Schema
                switch layout {
                case 8: schema = Schema(versionedSchema: LocalSchemaV1.self)
                case 9: schema = Schema([StoredPhoto.self]) // Valid SQLite, not the app schema.
                default: schema = Schema(versionedSchema: LocalSchemaV2.self)
                }
                let configuration = ModelConfiguration(schema: schema, url: database, cloudKitDatabase: .none)
                let container = try ModelContainer(for: schema, configurations: [configuration])
                let context = ModelContext(container)
                let draft = PieceDraft(name: "Not first use")
                if layout < 6 { context.insert(StoredTodayConfiguration(TodayConfiguration(ownerID: UUID()))) }
                switch layout {
                case 0: context.insert(StoredPiece(WardrobePiece(id: UUID(), name: "Keep", category: .tops, photoID: UUID())))
                case 1: context.insert(StoredPhoto(id: UUID(), pixelWidth: 20, pixelHeight: 30))
                case 2: context.insert(StoredPieceDraft(draft: draft, operationID: UUID(), payload: try JSONEncoder().encode(draft)))
                case 3: context.insert(StoredPieceSave(id: UUID(), itemID: UUID(), draftDigest: "Keep proof", snapshot: Data()))
                case 4: context.insert(StoredPieceDeletion(operationID: UUID(), itemID: UUID(), expectedRevision: 1, pendingPhotoIDs: []))
                case 5: context.insert(StoredPhotoCleanup(photoID: UUID()))
                case 6:
                    let invalid = StoredTodayConfiguration(TodayConfiguration(ownerID: UUID()))
                    invalid.kindIDs = ["unknown"]
                    context.insert(invalid)
                case 7:
                    var customized = TodayConfiguration(ownerID: UUID())
                    customized.revision = 2
                    customized.instances = [TodayWidgetInstance(kind: .personalNote)]
                    context.insert(StoredTodayConfiguration(customized))
                case 12:
                    var nonStock = TodayConfiguration(ownerID: UUID())
                    nonStock.instances = [TodayWidgetInstance(kind: .personalNote)]
                    context.insert(StoredTodayConfiguration(nonStock))
                case 13:
                    context.insert(StoredTodayConfiguration(TodayConfiguration(ownerID: UUID())))
                    let extra = StoredTodayConfiguration(TodayConfiguration(ownerID: UUID()))
                    extra.id = 2
                    context.insert(extra)
                default: break
                }
                try context.save()
                fixtureContainer = container
                fixtureContext = context
            }
        } else if layout == 10 {
            try Data("Not SQLite".utf8).write(to: database)
        }
        let marker = directory.appendingPathComponent("schema-version")
        if layout == 11 {
            // A recognized marker without its database is corruption, unlike a
            // fresh directory containing unrelated media, which may initialize.
            try Data("AQD-piece-store:2".utf8).write(to: marker)
        }
        // SQLite's shared-memory reader index changes even on read-only opens.
        // Preserve authoritative database/WAL/marker bytes, not volatile reader bookkeeping.
        try withExtendedLifetime((fixtureContainer, fixtureContext)) {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                .filter { $0.lastPathComponent != "media" && !$0.lastPathComponent.hasSuffix("-shm") }
            let bytes = try files.map { try Data(contentsOf: $0) }
            #expect(throws: (any Error).self) { try PieceStore(directory: directory) }
            for (file, original) in zip(files, bytes) {
                #expect(try Data(contentsOf: file) == original, "Refused store changed \(file.lastPathComponent)")
            }
            #expect(try Data(contentsOf: sentinel) == sentinelBytes)
            if layout == 11 {
                #expect(try Data(contentsOf: marker) == Data("AQD-piece-store:2".utf8))
            } else {
                #expect(!FileManager.default.fileExists(atPath: marker.path))
            }
            #expect(FileManager.default.fileExists(atPath: database.path) == (layout != 11))
        }
    }

    @Test func fitOriginalUseSavesWithoutCreatingOrRetainingUnusedEditFiles() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let media = directory.appendingPathComponent("media")
        let source = try await preparedPhoto()
        var store: PieceStore? = try PieceStore(directory: directory)
        _ = try #require(store).acceptPhoto(source)
        let originalFiles = Set(["\(source.id.uuidString).jpg", "\(source.id.uuidString)-thumbnail.jpg"])
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: media.path)) == originalFiles)
        let fit = try await PhotoPreparer().render(data: source.originalData,
            sourcePhotoID: source.id, recipe: .fitOriginal)
        try #require(store).acceptPhotoEdit(fit)
        // Public Fit reads bypass edit files, so inventory is the external media
        // boundary that detects otherwise invisible persistent duplicates.
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: media.path)) == originalFiles)
        let saved = try #require(store).savePiece(PieceDraft(name: "Unchanged Fit", category: .tops,
            photoID: source.id, photoRecipe: .fitOriginal), operationID: UUID())
        try #require(store).reconcilePendingPhotoCleanup()
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: media.path)) == originalFiles)
        #expect(try #require(store).photoRendition(id: source.id, recipe: .fitOriginal) == source.originalData)
        #expect(try #require(store).photoThumbnail(id: source.id, recipe: .fitOriginal) == source.thumbnailData)
        store = nil
        let reopened = try PieceStore(directory: directory)
        try reopened.reconcilePendingPhotoCleanup()
        #expect(try reopened.piece(id: saved.id) == saved)
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: media.path)) == originalFiles)
        #expect(try reopened.originalPhoto(id: source.id) == source.originalData)
        #expect(try reopened.thumbnailPhoto(id: source.id) == source.thumbnailData)
        #expect(try !reopened.hasPendingPhotoCleanup())
    }

    @Test func legacyFitCleanupPreservesPieceAndDraftSourcesSharedRecipesAndUnknownFiles() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let media = directory.appendingPathComponent("media")
        let pieceSource = try await preparedPhoto()
        let draftSource = try await preparedPhoto()
        var store: PieceStore? = try PieceStore(directory: directory)
        for source in [pieceSource, draftSource] { _ = try #require(store).acceptPhoto(source) }
        let saved = try #require(store).savePiece(PieceDraft(name: "Live original Fit", category: .tops,
            photoID: pieceSource.id), operationID: UUID())
        let draft = PieceDraft(name: "Draft-only original Fit", photoID: draftSource.id)
        let draftOperation = UUID()
        try #require(store).saveDraft(draft, operationID: draftOperation)
        let rotation = try await PhotoPreparer().render(data: pieceSource.originalData,
            sourcePhotoID: pieceSource.id, recipe: .init(quarterTurns: 1))
        let portraitRecipe = try PhotoEditRecipe.portrait(originalWidth: pieceSource.pixelWidth,
            originalHeight: pieceSource.pixelHeight)
        let portrait = try await PhotoPreparer().render(data: pieceSource.originalData,
            sourcePhotoID: pieceSource.id, recipe: portraitRecipe)
        try #require(store).acceptPhotoEdit(rotation)
        try #require(store).acceptPhotoEdit(portrait)
        let rotatedDraft = PieceDraft(name: "Shared rotated Fit", photoID: pieceSource.id, photoRecipe: rotation.recipe)
        let rotatedOperation = UUID()
        try #require(store).saveDraft(rotatedDraft, operationID: rotatedOperation)
        let portraitPiece = try #require(store).savePiece(PieceDraft(name: "Shared portrait", category: .tops,
            photoID: pieceSource.id, photoRecipe: portrait.recipe), operationID: UUID())
        try #require(store).reconcilePendingPhotoCleanup()
        #expect(try !#require(store).hasPendingPhotoCleanup())
        let retainedFiles = Set(try FileManager.default.contentsOfDirectory(atPath: media.path))
        #expect(retainedFiles.count == 8) // Two source pairs and two derived pairs.
        store = nil
        // Old Fit staging may already have been acknowledged. Arrange artifacts
        // without a cleanup intent, independently of the now no-write acceptance.
        let fitDigest = try PhotoPreparer.recipeDigest(.fitOriginal)
        var legacyFiles: [URL] = []
        for source in [pieceSource, draftSource] {
            for (kind, bytes) in [("rendition", source.originalData), ("thumbnail", source.thumbnailData)] {
                let file = media.appendingPathComponent("\(source.id.uuidString)-edit-\(fitDigest)-\(kind).jpg")
                try bytes.write(to: file)
                legacyFiles.append(file)
            }
        }
        // Even a well-formed derived filename must survive when its recipe is
        // unknown: live-source legacy cleanup probes only the exact Fit paths.
        let unknownName = "\(pieceSource.id.uuidString)-edit-\(String(repeating: "a", count: 64))-rendition.jpg"
        let unknown = media.appendingPathComponent(unknownName)
        let unknownBytes = Data("Keep unrelated recipe bytes".utf8)
        try unknownBytes.write(to: unknown)
        var recovered: PieceStore? = try PieceStore(directory: directory)
        try #require(recovered).reconcilePendingPhotoCleanup()
        for file in legacyFiles { #expect(!FileManager.default.fileExists(atPath: file.path)) }
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: media.path)) == retainedFiles.union([unknownName]))
        recovered = nil
        let reopened = try PieceStore(directory: directory)
        try reopened.reconcilePendingPhotoCleanup()
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: media.path)) == retainedFiles.union([unknownName]))
        #expect(try reopened.piece(id: saved.id) == saved)
        #expect(try reopened.piece(id: portraitPiece.id) == portraitPiece)
        #expect(try reopened.recoverableDraft(itemID: draft.itemID) == RecoverablePieceDraft(draft: draft, operationID: draftOperation))
        #expect(try reopened.recoverableDraft(itemID: rotatedDraft.itemID) == RecoverablePieceDraft(draft: rotatedDraft, operationID: rotatedOperation))
        for source in [pieceSource, draftSource] {
            #expect(try reopened.originalPhoto(id: source.id) == source.originalData)
            #expect(try reopened.thumbnailPhoto(id: source.id) == source.thumbnailData)
            #expect(try reopened.photoRendition(id: source.id, recipe: .fitOriginal) == source.originalData)
            #expect(try reopened.photoThumbnail(id: source.id, recipe: .fitOriginal) == source.thumbnailData)
        }
        for edit in [rotation, portrait] {
            #expect(try reopened.photoRendition(id: pieceSource.id, recipe: edit.recipe) == edit.renditionData)
            #expect(try reopened.photoThumbnail(id: pieceSource.id, recipe: edit.recipe) == edit.thumbnailData)
        }
        #expect(try Data(contentsOf: unknown) == unknownBytes)
        #expect(try !reopened.hasPendingPhotoCleanup())
    }

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

    @Test func stagingCleanupReleasesSupersededMediaButPreservesExactSaveAndArchiveAcknowledgments() async throws {
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
        #expect(throws: (any Error).self) { try store.originalPhoto(id: source.id) }
        #expect(throws: (any Error).self) { try store.thumbnailPhoto(id: source.id) }
        #expect(throws: (any Error).self) { try store.photoRendition(id: source.id, recipe: recipe) }
        #expect(throws: (any Error).self) { try store.photoThumbnail(id: source.id, recipe: recipe) }
        #expect(try store.savePiece(initial, operationID: saveOperation) == saved)
        #expect(try store.setArchived(id: saved.id, archived: true, expectedRevision: 1, operationID: archiveOperation) == archived)
        #expect(try store.latestDraft()?.draft == shared)
        #expect(try store.originalPhoto(id: replacement.id) == replacement.originalData)
        #expect(try !store.hasPendingPhotoCleanup())
    }

    // Test-first regression: native RED must be recorded before changing PieceStore.
    @Test(arguments: [false, true])
    func completedReplacementCleanupDoesNotRewriteStoreOnHeldOrReopenedReconciliation(replaceSource: Bool) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let media = directory.appendingPathComponent("media")
        // Synthetic preparedPhoto pixels only; no application store or user media.
        let source = try await preparedPhoto()
        let replacement = replaceSource ? try await preparedPhoto() : source
        let recipe = PhotoEditRecipe(quarterTurns: 1)
        let edit = try await PhotoPreparer().render(data: source.originalData, sourcePhotoID: source.id, recipe: recipe)
        var store: PieceStore? = try PieceStore(directory: directory)
        _ = try #require(store).acceptPhoto(source)
        try #require(store).acceptPhotoEdit(edit)
        let initial = PieceDraft(name: "Immutable old framing", category: .tops, photoID: source.id, photoRecipe: recipe)
        let operation = UUID()
        let saved = try #require(store).savePiece(initial, operationID: operation)
        try #require(store).reconcilePendingPhotoCleanup() // Acknowledge staging while it is still owned.
        if replaceSource { _ = try #require(store).acceptPhoto(replacement) }
        let updated = try #require(store).savePiece(PieceDraft(itemID: saved.id, name: "Current original Fit",
            category: .tops, photoID: replacement.id, baseRevision: saved.revision), operationID: UUID())
        try #require(try #require(store).hasPendingPhotoCleanup())

        // Well-formed but unknown recipe on the live source is outside the exact
        // relinquished candidates. Reconciliation must not turn into a media sweep.
        let unknown = media.appendingPathComponent("\(replacement.id.uuidString)-edit-\(String(repeating: "a", count: 64))-rendition.jpg")
        let unknownBytes = Data("Preserve unrelated recipe bytes".utf8)
        try unknownBytes.write(to: unknown)
        // Freeze only controlled media metadata, not SQLite metadata or sidecars.
        let fixtureDate = Date(timeIntervalSince1970: 1_700_000_000)
        for file in try FileManager.default.contentsOfDirectory(at: media, includingPropertiesForKeys: nil) {
            try FileManager.default.setAttributes([.modificationDate: fixtureDate], ofItemAtPath: file.path)
        }
        try #require(store).reconcilePendingPhotoCleanup()
        try #require(try !#require(store).hasPendingPhotoCleanup())
        let digest = try PhotoPreparer.recipeDigest(recipe)
        for kind in ["rendition", "thumbnail"] {
            #expect(!FileManager.default.fileExists(atPath:
                media.appendingPathComponent("\(source.id.uuidString)-edit-\(digest)-\(kind).jpg").path))
        }
        if replaceSource {
            for name in ["\(source.id.uuidString).jpg", "\(source.id.uuidString)-thumbnail.jpg"] {
                #expect(!FileManager.default.fileExists(atPath: media.appendingPathComponent(name).path))
            }
        }
        #expect(try #require(store).savePiece(initial, operationID: operation) == saved)
        #expect(try #require(store).piece(id: saved.id) == updated)
        #expect(try #require(store).originalPhoto(id: replacement.id) == replacement.originalData)
        #expect(try #require(store).thumbnailPhoto(id: replacement.id) == replacement.thumbnailData)
        let retainedMedia: Set<String> = ["\(replacement.id.uuidString).jpg",
            "\(replacement.id.uuidString)-thumbnail.jpg", unknown.lastPathComponent]
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: media.path)) == retainedMedia)

        // No framework reopen between baseline and repeated checks: transient
        // queue insertion/deletion can finish empty yet append real SQLite WAL frames.
        let heldBytes = try authoritativeStoreBytes(directory)
        for _ in 0..<2 {
            try #require(store).reconcilePendingPhotoCleanup()
            #expect(try authoritativeStoreBytes(directory) == heldBytes,
                "Completed cleanup rewrote the held database/WAL from immutable historical proof")
            #expect(try !#require(store).hasPendingPhotoCleanup())
        }
        store = nil
        let reopened = try PieceStore(directory: directory)
        // Opening SwiftData may checkpoint/change sidecars. Establish a separate
        // baseline AFTER reopening, before its first reconciliation.
        let reopenedBytes = try authoritativeStoreBytes(directory)
        for _ in 0..<2 {
            try reopened.reconcilePendingPhotoCleanup()
            #expect(try authoritativeStoreBytes(directory) == reopenedBytes,
                "Completed cleanup rewrote the reopened database/WAL from immutable historical proof")
            #expect(try !reopened.hasPendingPhotoCleanup())
        }
        #expect(try reopened.savePiece(initial, operationID: operation) == saved)
        #expect(try reopened.piece(id: saved.id) == updated)
        #expect(try reopened.photoRendition(id: replacement.id, recipe: .fitOriginal) == replacement.originalData)
        #expect(try reopened.photoThumbnail(id: replacement.id, recipe: .fitOriginal) == replacement.thumbnailData)
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: media.path)) == retainedMedia)
        #expect(try Data(contentsOf: unknown) == unknownBytes)
    }

    private func authoritativeStoreBytes(_ directory: URL) throws -> [String: Data] {
        // Include WAL contents AND presence, never volatile SHM reader bookkeeping
        // or file timestamps. Do not open a second SQLite/SwiftData connection.
        var bytes = ["wardrobe.store": try Data(contentsOf: directory.appendingPathComponent("wardrobe.store"))]
        let wal = directory.appendingPathComponent("wardrobe.store-wal")
        do { bytes[wal.lastPathComponent] = try Data(contentsOf: wal) }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile { }
        return bytes
    }

    // Postimplementation discovery guard; no test-first RED is claimed.
    @Test(arguments: [0, 1, 2])
    func legacyExactReceiptArtifactIsDiscoveredWithoutAnExistingCleanupQueue(artifact: Int) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let media = directory.appendingPathComponent("media", isDirectory: true)
        try FileManager.default.createDirectory(at: media, withIntermediateDirectories: true)
        let old = try await preparedPhoto()
        let current = try await preparedPhoto()
        let recipe: PhotoEditRecipe = artifact == 0 ? .fitOriginal : .init(quarterTurns: 1)
        let draft = PieceDraft(name: "Legacy immutable proof", category: .tops, photoID: old.id, photoRecipe: recipe)
        let saved = WardrobePiece(id: draft.itemID, name: draft.name, category: .tops, photoID: old.id,
            photoRecipe: recipe)
        let latest = WardrobePiece(id: saved.id, name: "Current source", category: .tops, photoID: current.id,
            revision: 2, createdAt: saved.createdAt)
        let operation = UUID()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let digest = SHA256.hash(data: try encoder.encode(draft)).map { String(format: "%02x", $0) }.joined()
        // Match the supported V1 migration fixture, but seed NO cleanup intent.
        // Only historical proof can discover the solitary remaining old artifact.
        do {
            let schema = Schema(versionedSchema: LocalSchemaV1.self)
            let configuration = ModelConfiguration(schema: schema,
                url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            context.insert(StoredPiece(latest))
            for photo in [old, current] {
                context.insert(StoredPhoto(id: photo.id, pixelWidth: photo.pixelWidth, pixelHeight: photo.pixelHeight))
            }
            context.insert(StoredPieceSave(id: operation, itemID: saved.id, draftDigest: digest,
                snapshot: try encoder.encode(saved)))
            context.insert(StoredTodayConfiguration(TodayConfiguration(ownerID: UUID())))
            try context.save()
        }
        try Data("AQD-piece-store:1".utf8).write(to: directory.appendingPathComponent("schema-version"))
        try current.originalData.write(to: media.appendingPathComponent("\(current.id.uuidString).jpg"))
        try current.thumbnailData.write(to: media.appendingPathComponent("\(current.id.uuidString)-thumbnail.jpg"))
        let candidate: URL
        if artifact == 0 {
            // Source thumbnail ONLY: its original has already disappeared.
            candidate = media.appendingPathComponent("\(old.id.uuidString)-thumbnail.jpg")
            try old.thumbnailData.write(to: candidate)
        } else {
            let edit = try await PhotoPreparer().render(data: old.originalData, sourcePhotoID: old.id, recipe: recipe)
            let kind = artifact == 1 ? "rendition" : "thumbnail"
            candidate = media.appendingPathComponent("\(old.id.uuidString)-edit-\(edit.recipeDigest)-\(kind).jpg")
            try (artifact == 1 ? edit.renditionData : edit.thumbnailData).write(to: candidate)
        }
        let unknownNames = ["unknown.jpg", "\(old.id.uuidString)-edit-not-a-digest-rendition.jpg"]
        let unknownBytes = Data("Keep files outside managed candidates".utf8)
        for name in unknownNames { try unknownBytes.write(to: media.appendingPathComponent(name)) }
        let retained: Set<String> = Set(unknownNames + ["\(current.id.uuidString).jpg", "\(current.id.uuidString)-thumbnail.jpg"])
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: media.path)) == retained.union([candidate.lastPathComponent]))
        let store = try PieceStore(directory: directory)
        try #require(try !store.hasPendingPhotoCleanup())
        try #require(FileManager.default.fileExists(atPath: candidate.path))
        try store.reconcilePendingPhotoCleanup()
        #expect(!FileManager.default.fileExists(atPath: candidate.path))
        #expect(try !store.hasPendingPhotoCleanup())
        #expect(try store.savePiece(draft, operationID: operation) == saved)
        #expect(try store.piece(id: saved.id) == latest)
        let completedBytes = try authoritativeStoreBytes(directory)
        for _ in 0..<2 {
            try store.reconcilePendingPhotoCleanup()
            #expect(try authoritativeStoreBytes(directory) == completedBytes,
                "Discovered legacy cleanup must stay completed without database/WAL writes")
        }
        #expect(try store.originalPhoto(id: current.id) == current.originalData)
        #expect(try store.thumbnailPhoto(id: current.id) == current.thumbnailData)
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: media.path)) == retained)
        for name in unknownNames { #expect(try Data(contentsOf: media.appendingPathComponent(name)) == unknownBytes) }
    }

    @Test func legacyCompletedSaveAndArchiveProofsReleaseSupersededMediaAfterMigration() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let media = directory.appendingPathComponent("media", isDirectory: true)
        try FileManager.default.createDirectory(at: media, withIntermediateDirectories: true)
        let old = try await preparedPhoto()
        let current = try await preparedPhoto()
        for photo in [old, current] {
            try photo.originalData.write(to: media.appendingPathComponent("\(photo.id.uuidString).jpg"))
            try photo.thumbnailData.write(to: media.appendingPathComponent("\(photo.id.uuidString)-thumbnail.jpg"))
        }
        let draft = PieceDraft(name: "Legacy initial", category: .tops, photoID: old.id)
        let saved = WardrobePiece(id: draft.itemID, name: draft.name, category: .tops, photoID: old.id)
        let archived = WardrobePiece(id: saved.id, name: saved.name, category: .tops, photoID: old.id,
            revision: 2, isArchived: true, createdAt: saved.createdAt)
        let latest = WardrobePiece(id: saved.id, name: saved.name, category: .tops, photoID: current.id,
            revision: 3, isArchived: true, createdAt: saved.createdAt)
        let saveOperation = UUID()
        let archiveOperation = UUID()
        struct ArchiveFixture: Encodable {
            let id: UUID
            let archived: Bool
            let expectedRevision: Int
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let saveDigest = SHA256.hash(data: try encoder.encode(draft)).map { String(format: "%02x", $0) }.joined()
        let archiveDigest = "archive:" + SHA256.hash(data: try encoder.encode(ArchiveFixture(id: saved.id, archived: true, expectedRevision: 1)))
            .map { String(format: "%02x", $0) }.joined()
        do {
            let schema = Schema(versionedSchema: LocalSchemaV1.self)
            let configuration = ModelConfiguration(schema: schema,
                url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            context.insert(StoredPiece(latest))
            for photo in [old, current] {
                context.insert(StoredPhoto(id: photo.id, pixelWidth: photo.pixelWidth, pixelHeight: photo.pixelHeight))
            }
            context.insert(StoredPieceSave(id: saveOperation, itemID: saved.id, draftDigest: saveDigest, snapshot: try encoder.encode(saved)))
            context.insert(StoredPieceSave(id: archiveOperation, itemID: saved.id, draftDigest: archiveDigest, snapshot: try encoder.encode(archived)))
            context.insert(StoredTodayConfiguration(TodayConfiguration(ownerID: UUID())))
            try context.save()
        }
        try Data("AQD-piece-store:1".utf8).write(to: directory.appendingPathComponent("schema-version"))
        var migrated: PieceStore? = try PieceStore(directory: directory)
        try #require(migrated).reconcilePendingPhotoCleanup()
        migrated = nil
        let reopened = try PieceStore(directory: directory)
        #expect(throws: (any Error).self) { try reopened.originalPhoto(id: old.id) }
        #expect(throws: (any Error).self) { try reopened.thumbnailPhoto(id: old.id) }
        #expect(try reopened.savePiece(draft, operationID: saveOperation) == saved)
        #expect(try reopened.setArchived(id: saved.id, archived: true, expectedRevision: 1, operationID: archiveOperation) == archived)
        #expect(try reopened.piece(id: latest.id) == latest)
        #expect(try reopened.originalPhoto(id: current.id) == current.originalData)
        try reopened.reconcilePendingPhotoCleanup()
        #expect(try !reopened.hasPendingPhotoCleanup())
        #expect(throws: (any Error).self) { try reopened.originalPhoto(id: old.id) }
    }

    @Test func replacementRetainsSharedCurrentAndDraftRecipesAndResetSource() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let source = try await preparedPhoto()
        let replacement = try await preparedPhoto()
        _ = try store.acceptPhoto(source)
        let recipe = PhotoEditRecipe(quarterTurns: 1)
        let edit = try await PhotoPreparer().render(data: source.originalData, sourcePhotoID: source.id, recipe: recipe)
        try store.acceptPhotoEdit(edit)
        let first = try store.savePiece(PieceDraft(name: "First", category: .tops, photoID: source.id, photoRecipe: recipe), operationID: UUID())
        let sharedPiece = try store.savePiece(PieceDraft(name: "Shared", category: .tops, photoID: source.id, photoRecipe: recipe), operationID: UUID())
        let sharedDraft = PieceDraft(name: "Recoverable", photoID: source.id, photoRecipe: recipe)
        try store.saveDraft(sharedDraft, operationID: UUID())
        try store.reconcilePendingPhotoCleanup()
        _ = try store.acceptPhoto(replacement)
        _ = try store.savePiece(PieceDraft(itemID: first.id, name: first.name, category: .tops,
            photoID: replacement.id, baseRevision: first.revision), operationID: UUID())
        try store.reconcilePendingPhotoCleanup()
        #expect(try store.photoRendition(id: source.id, recipe: recipe) == edit.renditionData)
        // Reset releases only the old recipe; a current source remains resettable.
        let reset = try store.savePiece(PieceDraft(itemID: sharedPiece.id, name: sharedPiece.name, category: .tops,
            photoID: source.id, baseRevision: sharedPiece.revision), operationID: UUID())
        try store.reconcilePendingPhotoCleanup()
        #expect(try store.photoRendition(id: source.id, recipe: recipe) == edit.renditionData)
        #expect(try store.photoThumbnail(id: source.id, recipe: recipe) == edit.thumbnailData)
        try store.discardDraft(id: sharedDraft.id)
        try store.reconcilePendingPhotoCleanup()
        #expect(throws: (any Error).self) { try store.photoRendition(id: source.id, recipe: recipe) }
        #expect(throws: (any Error).self) { try store.photoThumbnail(id: source.id, recipe: recipe) }
        #expect(try store.originalPhoto(id: source.id) == source.originalData)
        #expect(try store.thumbnailPhoto(id: source.id) == source.thumbnailData)
        #expect(try store.piece(id: sharedPiece.id) == reset)
    }

    @Test func acceptedReplacementQueuesOldMediaAtomicallyAndRetriesNeverResurrectIt() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        let replacement = try await preparedPhoto()
        let recipe = PhotoEditRecipe(quarterTurns: 1)
        let edit = try await PhotoPreparer().render(data: source.originalData, sourcePhotoID: source.id, recipe: recipe)
        var store: PieceStore? = try PieceStore(directory: directory)
        _ = try #require(store).acceptPhoto(source)
        try #require(store).acceptPhotoEdit(edit)
        let initial = PieceDraft(name: "Initial", category: .tops, photoID: source.id, photoRecipe: recipe)
        let saveOperation = UUID()
        let saved = try #require(store).savePiece(initial, operationID: saveOperation)
        let archiveOperation = UUID()
        let archived = try #require(store).setArchived(id: saved.id, archived: true, expectedRevision: 1, operationID: archiveOperation)
        try #require(store).reconcilePendingPhotoCleanup() // Clear initial staging intents.
        _ = try #require(store).acceptPhoto(replacement)
        let replacementDraft = PieceDraft(itemID: saved.id, name: "Replacement", category: .tops,
            photoID: replacement.id, baseRevision: archived.revision)
        let replacementOperation = UUID()
        try #require(store).saveDraft(replacementDraft, operationID: replacementOperation)
        try #require(store).reconcilePendingPhotoCleanup() // Neither staged photo is unused yet.
        store = nil
        var failed: PieceStore? = try PieceStore(directory: directory, allowsSave: false)
        #expect(throws: (any Error).self) { try #require(failed).savePiece(replacementDraft, operationID: replacementOperation) }
        #expect(try #require(failed).piece(id: saved.id) == archived)
        #expect(try #require(failed).originalPhoto(id: source.id) == source.originalData)
        #expect(try #require(failed).photoRendition(id: source.id, recipe: recipe) == edit.renditionData)
        #expect(try #require(failed).recoverableDraft(itemID: saved.id)?.draft == replacementDraft)
        failed = nil
        var accepted: PieceStore? = try PieceStore(directory: directory, removeMediaFile: { url in
            if url.lastPathComponent == "\(source.id.uuidString)-thumbnail.jpg" {
                throw CocoaError(.fileWriteNoPermission)
            }
            try FileManager.default.removeItem(at: url)
        })
        let updated = try #require(accepted).savePiece(replacementDraft, operationID: replacementOperation)
        #expect(try #require(accepted).hasPendingPhotoCleanup())
        #expect(throws: (any Error).self) { try #require(accepted).reconcilePendingPhotoCleanup() }
        #expect(try #require(accepted).piece(id: saved.id) == updated)
        #expect(try #require(accepted).thumbnailPhoto(id: source.id) == source.thumbnailData)
        accepted = nil
        let reopened = try PieceStore(directory: directory)
        try reopened.reconcilePendingPhotoCleanup()
        #expect(try !reopened.hasPendingPhotoCleanup())
        #expect(throws: (any Error).self) { try reopened.originalPhoto(id: source.id) }
        #expect(throws: (any Error).self) { try reopened.thumbnailPhoto(id: source.id) }
        #expect(throws: (any Error).self) { try reopened.photoRendition(id: source.id, recipe: recipe) }
        #expect(throws: (any Error).self) { try reopened.photoThumbnail(id: source.id, recipe: recipe) }
        #expect(try reopened.savePiece(initial, operationID: saveOperation) == saved)
        #expect(try reopened.setArchived(id: saved.id, archived: true, expectedRevision: 1, operationID: archiveOperation) == archived)
        try reopened.saveDraft(initial, operationID: saveOperation)
        #expect(try reopened.recoverableDraft(itemID: saved.id) == nil)
        #expect(try reopened.piece(id: saved.id) == updated)
        #expect(try reopened.originalPhoto(id: replacement.id) == replacement.originalData)
        var conflict = initial
        conflict.name = "Different request"
        #expect(throws: PieceStore.StoreError.operationConflict) { try reopened.savePiece(conflict, operationID: saveOperation) }
        #expect(throws: (any Error).self) { try reopened.originalPhoto(id: source.id) }
    }

    @Test func newPieceRecoverySelectsNewestCreationWithoutConsumingRetainedEditOrStaleIdentity() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        let source = try await preparedPhoto()
        _ = try #require(store).acceptPhoto(source)
        let saved = try #require(store).savePiece(PieceDraft(name: "Saved", category: .tops, photoID: source.id), operationID: UUID())
        let older = PieceDraft(name: "Older creation")
        try #require(store).saveDraft(older, operationID: UUID())
        let newest = PieceDraft(name: "Newest creation")
        let operation = UUID()
        try #require(store).saveDraft(newest, operationID: operation)
        let retainedEdit = PieceDraft(itemID: saved.id, name: "Retained edit", baseRevision: saved.revision)
        let editOperation = UUID()
        try #require(store).saveDraft(retainedEdit, operationID: editOperation)
        // A nil base alone must not turn a saved identity into a creation.
        let stale = PieceDraft(itemID: saved.id, name: "Stale creation")
        try #require(store).saveDraft(stale, operationID: UUID())
        store = nil
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.newPieceDraft() == RecoverablePieceDraft(draft: newest, operationID: operation))
        try reopened.discardDraft(id: stale.id)
        #expect(try reopened.recoverableDraft(itemID: saved.id) == RecoverablePieceDraft(draft: retainedEdit, operationID: editOperation))
        try reopened.discardDraft(id: newest.id)
        #expect(try reopened.newPieceDraft()?.draft == older)
        try reopened.discardDraft(id: older.id)
        #expect(try reopened.newPieceDraft() == nil)
        #expect(try reopened.recoverableDraft(itemID: saved.id)?.draft == retainedEdit)
        #expect(try reopened.piece(id: saved.id) == saved)
    }

    @Test(arguments: [0, 1, 2])
    func newPieceRecoveryAndCleanupRefuseCorruptRecoveryGraphWithoutDeletingMedia(corruptionKind: Int) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        let unowned = try await preparedPhoto()
        var initial: PieceStore? = try PieceStore(directory: directory)
        _ = try #require(initial).acceptPhoto(source)
        _ = try #require(initial).acceptPhoto(unowned)
        let healthy = PieceDraft(name: "Healthy retained", photoID: source.id)
        try #require(initial).saveDraft(healthy, operationID: UUID())
        initial = nil
        // Native fixture setup represents interrupted/corrupt persisted input.
        // Assertions stay at the public recovery/media boundary.
        let corrupt = PieceDraft(name: "Unreadable", photoID: source.id)
        do {
            let schema = Schema(versionedSchema: LocalSchemaV2.self)
            let configuration = ModelConfiguration(schema: schema,
                url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, migrationPlan: LocalMigrationPlan.self, configurations: [configuration])
            let context = ModelContext(container)
            var invalidRecipe = corrupt
            invalidRecipe.photoRecipe = .init(quarterTurns: 4)
            let mismatchedIdentity = PieceDraft(name: corrupt.name, photoID: source.id)
            let payload: Data
            switch corruptionKind {
            case 0: payload = Data("unreadable".utf8)
            case 1: payload = try JSONEncoder().encode(mismatchedIdentity)
            default: payload = try JSONEncoder().encode(invalidRecipe)
            }
            context.insert(StoredPieceDraft(draft: corrupt, operationID: UUID(), payload: payload))
            try context.save()
        }
        let reopened = try PieceStore(directory: directory)
        #expect(throws: (any Error).self) { try reopened.newPieceDraft() }
        #expect(throws: (any Error).self) { try reopened.discardDraft(id: corrupt.id) }
        #expect(throws: (any Error).self) { try reopened.reconcilePendingPhotoCleanup() }
        #expect(try reopened.originalPhoto(id: source.id) == source.originalData)
        #expect(try reopened.thumbnailPhoto(id: source.id) == source.thumbnailData)
        #expect(try reopened.originalPhoto(id: unowned.id) == unowned.originalData)
        #expect(try reopened.thumbnailPhoto(id: unowned.id) == unowned.thumbnailData)
        #expect(try reopened.hasPendingPhotoCleanup())
    }

    @Test func newPieceRecoveryRefusesAlreadyAcknowledgedCreationWithoutResurrection() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var initial: PieceStore? = try PieceStore(directory: directory)
        let source = try await preparedPhoto()
        _ = try #require(initial).acceptPhoto(source)
        let savedDraft = PieceDraft(name: "Acknowledged", category: .tops, photoID: source.id)
        let operation = UUID()
        let saved = try #require(initial).savePiece(savedDraft, operationID: operation)
        initial = nil
        let stale = PieceDraft(name: "Wrong recovered identity", photoID: source.id)
        do {
            let schema = Schema(versionedSchema: LocalSchemaV2.self)
            let configuration = ModelConfiguration(schema: schema,
                url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, migrationPlan: LocalMigrationPlan.self, configurations: [configuration])
            let context = ModelContext(container)
            context.insert(StoredPieceDraft(draft: stale, operationID: operation, payload: try JSONEncoder().encode(stale)))
            try context.save()
        }
        let reopened = try PieceStore(directory: directory)
        #expect(throws: PieceStore.StoreError.invalidRecord) { try reopened.newPieceDraft() }
        #expect(try reopened.latestDraft()?.draft == stale)
        #expect(try reopened.piece(id: stale.itemID) == nil)
        #expect(try reopened.piece(id: saved.id) == saved)
        #expect(try reopened.originalPhoto(id: source.id) == source.originalData)
    }

    @Test func cleanupRefusesCorruptCompletedAcknowledgmentProofEvenThoughItIsNotAMediaOwner() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        var initial: PieceStore? = try PieceStore(directory: directory)
        _ = try #require(initial).acceptPhoto(source)
        initial = nil
        do {
            let schema = Schema(versionedSchema: LocalSchemaV2.self)
            let configuration = ModelConfiguration(schema: schema,
                url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, migrationPlan: LocalMigrationPlan.self, configurations: [configuration])
            let context = ModelContext(container)
            context.insert(StoredPieceSave(id: UUID(), itemID: UUID(), draftDigest: "legacy-proof", snapshot: Data("unreadable".utf8)))
            try context.save()
        }
        let reopened = try PieceStore(directory: directory)
        #expect(throws: (any Error).self) { try reopened.reconcilePendingPhotoCleanup() }
        #expect(try reopened.originalPhoto(id: source.id) == source.originalData)
        #expect(try reopened.thumbnailPhoto(id: source.id) == source.thumbnailData)
        #expect(try reopened.hasPendingPhotoCleanup())
    }

    @Test func cleanupFailureDoesNotBlockIndependentStagedPhotoReconciliation() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let first = try await preparedPhoto()
        let second = try await preparedPhoto()
        let blocked = first.id.uuidString < second.id.uuidString ? first : second
        let independent = first.id.uuidString < second.id.uuidString ? second : first
        var failing: PieceStore? = try PieceStore(directory: directory, removeMediaFile: { url in
            if url.lastPathComponent.hasPrefix(blocked.id.uuidString) { throw CocoaError(.fileWriteNoPermission) }
            try FileManager.default.removeItem(at: url)
        })
        _ = try #require(failing).acceptPhoto(blocked)
        _ = try #require(failing).acceptPhoto(independent)
        #expect(throws: (any Error).self) { try #require(failing).reconcilePendingPhotoCleanup() }
        #expect(try #require(failing).originalPhoto(id: blocked.id) == blocked.originalData)
        #expect(throws: (any Error).self) { try #require(failing).originalPhoto(id: independent.id) }
        #expect(throws: (any Error).self) { try #require(failing).thumbnailPhoto(id: independent.id) }
        #expect(try #require(failing).hasPendingPhotoCleanup())
        failing = nil
        let reopened = try PieceStore(directory: directory)
        try reopened.reconcilePendingPhotoCleanup()
        #expect(try !reopened.hasPendingPhotoCleanup())
        #expect(throws: (any Error).self) { try reopened.originalPhoto(id: blocked.id) }
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

    @Test func cleanupRetainsDraftAndCurrentArchivedMediaNotSupersededReceiptMedia() async throws {
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
        #expect(throws: (any Error).self) { try store.originalPhoto(id: receiptPhoto.id) }
        #expect(throws: (any Error).self) { try store.thumbnailPhoto(id: receiptPhoto.id) }
        for photo in [livePhoto, draftPhoto] {
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

    @Test(arguments: [false, true])
    func failedDatabaseWritePreservesPriorPieceAndCreatesNoReceipt(retainForPresentation: Bool) async throws {
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
        #expect(throws: (any Error).self) {
            try #require(readOnly).savePiece(rejected, operationID: operation, retainForPresentation: retainForPresentation)
        }
        #expect(try #require(readOnly).latestDraft() == nil)
        let retained = try #require(readOnly).piece(id: original.id)
        #expect(retained == original)
        let absent = try #require(readOnly).piece(id: rejected.itemID)
        #expect(absent == nil)
        readOnly = nil
        let recovered = try PieceStore(directory: directory)
        let retried = try recovered.savePiece(rejected, operationID: operation, retainForPresentation: retainForPresentation)
        #expect(try recovered.pendingSavedPiece(for: RecoverablePieceDraft(draft: rejected, operationID: operation)) == (retainForPresentation ? retried : nil))
        #expect(retried.name == "Second pair")
        #expect(retried.id == rejected.itemID)
    }

    @Test func addPieceAfterCommitBeforePresentationRecoversSavedReceiptWithoutCreatingDuplicate() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        let draft = PieceDraft(name: "Committed before receipt", category: .tops, photoID: source.id,
            details: PieceDetails(notes: "Recover this exact save"))
        let operation = UUID()
        let committed: WardrobePiece
        do {
            let store = try PieceStore(directory: directory)
            _ = try store.acceptPhoto(source)
            try store.saveDraft(draft, operationID: operation)
            let state = AppState(store: store)
            state.addPiece()
            let capture = try #require(state.capture)
            try #require(capture.draft == draft)
            try #require(capture.operationID == operation)
            try #require(capture.canSave)

            // Commit the real Save transaction, but never deliver its return to
            // CaptureModel.save(). Releasing this scope models process exit in
            // the gap before its `saved` assignment/presentation.
            // The original primitive produced six runtime issues in the 56-test
            // native RED run (/tmp/aqd-pending-receipt-red.log), before this API
            // existed. Opt in exactly as production now does; not a signature RED.
            committed = try store.savePiece(capture.draft, operationID: capture.operationID, retainForPresentation: true)
            #expect(capture.saved == nil)
            #expect(committed.id == draft.itemID)
            #expect(committed.revision == 1)
            #expect(try store.pieces() == [committed])
        }

        // Recovery must read the durable acknowledgment, not re-save the draft.
        // Read-only reopening makes a new commit impossible; no retry Save is
        // called, and the ordinary user's database is never opened.
        let reopened = try PieceStore(directory: directory, allowsSave: false)
        #expect(try reopened.piece(id: draft.itemID) == committed)
        #expect(try reopened.pieces() == [committed])
        let relaunched = AppState(store: reopened)
        relaunched.addPiece()
        let receipt = try #require(relaunched.capture)
        #expect(receipt.saved == committed)
        #expect(receipt.saved?.id == draft.itemID)
        #expect(receipt.saved?.revision == committed.revision)
        // Keep these non-optional identity checks even if saved is nil: a blank
        // creation must not silently replace the committed draft/operation.
        #expect(receipt.draft == draft)
        #expect(receipt.draft.itemID == committed.id)
        #expect(receipt.operationID == operation)
        #expect(try reopened.piece(id: committed.id) == committed)
        #expect(try reopened.pieces() == [committed])
        #expect(try reopened.originalPhoto(id: source.id) == source.originalData)
    }

    @Test(arguments: [false, true])
    func pendingReceiptAcknowledgmentFailureRetryAndFreshRoutes(edit: Bool) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        let operation = UUID()
        let draft: PieceDraft
        let committed: WardrobePiece
        do {
            let store = try PieceStore(directory: directory)
            _ = try store.acceptPhoto(source)
            if edit {
                let original = try store.savePiece(PieceDraft(name: "Original", category: .tops, photoID: source.id), operationID: UUID())
                draft = PieceDraft(itemID: original.id, name: "Pending edit", category: .tops,
                    photoID: source.id, baseRevision: original.revision)
            } else {
                draft = PieceDraft(name: "Pending creation", category: .tops, photoID: source.id)
            }
            // Direct saves also insert the link atomically, without prior saveDraft.
            committed = try store.savePiece(draft, operationID: operation, retainForPresentation: true)
        }
        let state = AppState(store: try PieceStore(directory: directory, allowsSave: false))
        if edit {
            #expect(try #require(state.store).newPieceDraft() == nil)
            state.editPiece(committed)
        } else { state.addPiece() }
        let model = try #require(state.capture)
        #expect(model.saved == committed)
        #expect(model.draft == draft)
        #expect(model.operationID == operation)
        #expect(!model.draftSaveFailed)
        #expect(!model.canSave)
        model.update(\.name, value: "Must not mutate")
        model.applyDetails(PieceDetails(notes: "Must not mutate"), availability: .unavailable)
        model.importPhoto { Issue.record("Saved receipt must not load a photo"); return nil }
        model.save()
        model.discard()
        #expect(!model.isImporting)
        #expect(model.draft == draft)
        #expect(model.operationID == operation)
        #expect(state.capture === model)
        state.selection = 4
        state.closetPath = [committed.id]
        state.closetScope = "Outfits"
        model.openCloset()
        #expect(state.capture === model)
        #expect(state.selection == 4)
        #expect(state.closetPath == [committed.id])
        #expect(state.closetScope == "Outfits")
        #expect(model.errorText != nil)
        model.leave()
        #expect(state.capture === model)
        #expect(try #require(state.store).pendingSavedPiece(for: RecoverablePieceDraft(draft: draft, operationID: operation)) == committed)

        state.store = nil
        state.store = try PieceStore(directory: directory)
        if edit { model.leave() } else { model.openCloset() }
        #expect(state.capture == nil)
        #expect(model.errorText == nil)
        if !edit {
            #expect(state.selection == 1)
            #expect(state.closetPath.isEmpty)
            #expect(state.closetScope == "Pieces")
        }
        let store = try #require(state.store)
        try store.acknowledgePiecePresentation(draftID: draft.id, operationID: operation)
        #expect(try store.savePiece(draft, operationID: operation, retainForPresentation: true) == committed)
        #expect(try store.latestDraft() == nil) // Historical retry must not recreate acknowledged links.
        state.editPiece(committed)
        let freshEdit = try #require(state.capture)
        #expect(freshEdit.saved == nil)
        #expect(freshEdit.draft.baseRevision == committed.revision)
        #expect(freshEdit.operationID != operation)
        freshEdit.discard()
        state.addPiece()
        let freshAdd = try #require(state.capture)
        #expect(freshAdd.saved == nil)
        #expect(freshAdd.draft.itemID != committed.id)
        #expect(freshAdd.draft.baseRevision == nil)
    }

    @Test func pendingHistoricalReceiptNeverRewindsCurrentAndDeletionNeverResurrects() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        let draft = PieceDraft(name: "Historical creation", category: .tops, photoID: source.id)
        let operation = UUID()
        let store = try PieceStore(directory: directory)
        _ = try store.acceptPhoto(source)
        let saved = try store.savePiece(draft, operationID: operation, retainForPresentation: true)
        let newer = try store.setArchived(id: saved.id, archived: true, expectedRevision: saved.revision, operationID: UUID())
        let state = AppState(store: store)
        state.addPiece()
        let model = try #require(state.capture)
        #expect(model.saved == saved)
        #expect(model.receiptIsHistorical)
        #expect(try store.piece(id: saved.id) == newer)
        model.openCloset()
        #expect(try store.piece(id: saved.id) == newer)
        #expect(try store.newPieceDraft() == nil)
        // Another pending edit is removed with the current record and all its proof.
        let edit = PieceDraft(itemID: saved.id, name: "Pending deletion", category: .tops,
            photoID: source.id, baseRevision: newer.revision)
        let editOperation = UUID()
        let edited = try store.savePiece(edit, operationID: editOperation, retainForPresentation: true)
        try store.deletePiece(id: edited.id, expectedRevision: edited.revision, operationID: UUID())
        #expect(try store.recoverableDraft(itemID: saved.id) == nil)
        #expect(try store.pendingSavedPiece(for: RecoverablePieceDraft(draft: edit, operationID: editOperation)) == nil)
        #expect(throws: (any Error).self) { try store.savePiece(edit, operationID: editOperation, retainForPresentation: true) }
        #expect(try store.piece(id: saved.id) == nil)
    }

    @Test(arguments: Array(0...12))
    func invalidPendingProofRefusesRecoveryAndAcknowledgmentWithoutBlankFallback(corruption: Int) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        let operation = UUID()
        let draft = PieceDraft(name: "Validate exact pending proof", category: .tops, photoID: source.id)
        let saved: WardrobePiece
        do {
            let store = try PieceStore(directory: directory)
            _ = try store.acceptPhoto(source)
            saved = try store.savePiece(draft, operationID: operation, retainForPresentation: true)
        }
        // Corrupt real native rows, not a mock adapter or synthetic filesystem.
        do {
            let schema = Schema(versionedSchema: LocalSchemaV2.self)
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema,
                url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)])
            let context = ModelContext(container)
            let link = try #require(context.fetch(FetchDescriptor<StoredPieceDraft>()).first)
            let proof = try #require(context.fetch(FetchDescriptor<StoredPieceSave>()).first)
            let current = try #require(context.fetch(FetchDescriptor<StoredPiece>()).first)
            let snapshot = StoredPiece(saved)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            switch corruption {
            case 0: proof.draftDigest = "wrong"
            case 1: proof.itemID = UUID()
            case 2: proof.snapshot = Data("not-json".utf8)
            case 3: link.itemID = UUID()
            case 4: link.operationID = UUID()
            case 5: link.payload = Data("not-json".utf8)
            case 6: snapshot.category = PieceCategory.shoes.rawValue; proof.snapshot = try encoder.encode(snapshot.value())
            case 7: snapshot.photoQuarterTurns = 1; proof.snapshot = try encoder.encode(snapshot.value())
            case 8: snapshot.revision += 1; proof.snapshot = try encoder.encode(snapshot.value())
            case 9: current.name = "Different same revision"
            case 10: context.delete(current)
            case 11:
                let competitor = PieceDraft(itemID: draft.itemID, name: "Competing")
                context.insert(StoredPieceDraft(draft: competitor, operationID: UUID(), payload: try encoder.encode(competitor)))
            default: proof.snapshot.append(0x20) // Noncanonical snapshot bytes.
            }
            try context.save()
        }
        let store = try PieceStore(directory: directory, allowsSave: false)
        let recovered = RecoverablePieceDraft(draft: draft, operationID: operation)
        #expect(throws: (any Error).self) { try store.pendingSavedPiece(for: recovered) }
        #expect(throws: (any Error).self) { try store.recoverableDraft(itemID: draft.itemID) }
        #expect(throws: (any Error).self) { try store.acknowledgePiecePresentation(draftID: draft.id, operationID: operation) }
        let state = AppState(store: store)
        state.addPiece()
        #expect(state.capture == nil)
        #expect(state.collectionError != nil)
        state.editPiece(saved)
        #expect(state.capture == nil)
        #expect(state.collectionError != nil)
    }

    @Test func pendingDraftAloneRetainsSupersededMediaUntilAcknowledgment() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        let replacement = try await preparedPhoto()
        let recipe = PhotoEditRecipe(quarterTurns: 1)
        let draft = PieceDraft(name: "Temporary receipt media owner", category: .tops, photoID: source.id, photoRecipe: recipe)
        let operation = UUID()
        let store = try PieceStore(directory: directory)
        _ = try store.acceptPhoto(source)
        _ = try store.acceptPhoto(replacement)
        let edit = try await PhotoPreparer().render(data: source.originalData, sourcePhotoID: source.id, recipe: recipe)
        try store.acceptPhotoEdit(edit)
        let saved = try store.savePiece(draft, operationID: operation, retainForPresentation: true)
        // Model a newer current revision in the native database; the original
        // pending draft must remain untouched as historical presentation proof.
        do {
            let schema = Schema(versionedSchema: LocalSchemaV2.self)
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema,
                url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)])
            let context = ModelContext(container)
            let current = try #require(context.fetch(FetchDescriptor<StoredPiece>()).first)
            let newer = WardrobePiece(id: saved.id, name: saved.name, category: saved.category,
                photoID: replacement.id, details: saved.details, availability: saved.availability,
                revision: saved.revision + 1, isArchived: saved.isArchived,
                createdAt: saved.createdAt, updatedAt: Date(), photoRecipe: .fitOriginal)
            current.apply(newer)
            try context.save()
        }
        try store.reconcilePendingPhotoCleanup()
        #expect(try store.originalPhoto(id: source.id) == source.originalData)
        #expect(try store.photoRendition(id: source.id, recipe: recipe) == edit.renditionData)
        #expect(try store.pendingSavedPiece(for: RecoverablePieceDraft(draft: draft, operationID: operation)) == saved)
        #expect(throws: (any Error).self) { try store.acknowledgePiecePresentation(draftID: draft.id, operationID: UUID()) }
        #expect(try store.latestDraft()?.draft == draft)
        try store.acknowledgePiecePresentation(draftID: draft.id, operationID: operation)
        try store.reconcilePendingPhotoCleanup()
        #expect(throws: (any Error).self) { try store.originalPhoto(id: source.id) }
        #expect(throws: (any Error).self) { try store.photoRendition(id: source.id, recipe: recipe) }
        #expect(try store.originalPhoto(id: replacement.id) == replacement.originalData)
        #expect(try store.savePiece(draft, operationID: operation, retainForPresentation: true) == saved)
        #expect(try store.latestDraft() == nil)
    }

    @Test func legacySaveReturnStillAcknowledgesWithoutPresentationLink() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = try await preparedPhoto()
        let store = try PieceStore(directory: directory)
        _ = try store.acceptPhoto(source)
        let draft = PieceDraft(name: "Legacy caller", category: .tops, photoID: source.id)
        let operation = UUID()
        try store.saveDraft(draft, operationID: operation)
        let saved = try store.savePiece(draft, operationID: operation)
        #expect(try store.latestDraft() == nil)
        #expect(try store.pendingSavedPiece(for: RecoverablePieceDraft(draft: draft, operationID: operation)) == nil)
        #expect(try store.savePiece(draft, operationID: operation, retainForPresentation: true) == saved)
        #expect(try store.newPieceDraft() == nil)
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
