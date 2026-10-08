import AQDCore
import Foundation
import Observation
#if DEBUG
import SwiftData
#endif

@MainActor
@Observable
final class AppState {
    var selection = 0
    var closetPath: [UUID] = []
    var closetScope = "Pieces"
    var store: PieceStore?
    var openingError: String?
    var pieces: [WardrobePiece] = []
    var capture: CaptureModel?
    var collectionError: String?
    var today: TodayConfiguration?
    var todayError: String?
    var photoCleanupError: String?

    init() { openStore() }

    func openStore() {
        do {
            let support = try FileManager.default.url(for: .applicationSupportDirectory,
                                                     in: .userDomainMask, appropriateFor: nil, create: true)
            var directory = support.appendingPathComponent("AQD", isDirectory: true)
            #if DEBUG
            // UI automation uses a fresh, stable test-store identity. Never reset the ordinary closet.
            let process = ProcessInfo.processInfo
            var isolatedUITestStore = false
            if process.arguments.contains("--aqd-ui-testing"),
               let value = process.environment["AQD_TEST_STORE_ID"], let identifier = UUID(uuidString: value) {
                directory = support.appendingPathComponent("AQD-UITests", isDirectory: true)
                    .appendingPathComponent(identifier.uuidString, isDirectory: true)
                isolatedUITestStore = true
            }
            #endif
            store = try PieceStore(directory: directory)
            #if DEBUG
            if isolatedUITestStore, process.environment["AQD_TEST_CORRUPT_DRAFT"] == "1" {
                try seedUnreadableUITestDraft(in: directory)
            }
            #endif
            openingError = nil
            reloadPieces()
            reloadToday()
            retryPhotoCleanup()
        } catch {
            store = nil
            openingError = "Your local closet couldn’t open. Existing data has not been replaced. Retry, or keep the app data for recovery."
        }
    }

    func reloadPieces() {
        guard let store else { return }
        do {
            pieces = try store.pieces()
            collectionError = nil
        } catch {
            collectionError = "Your pieces couldn’t be read. The saved collection has not been cleared."
        }
    }

    func retryPhotoCleanup() {
        guard let store else { return }
        guard capture == nil else {
            photoCleanupError = "Finish keeping or discarding the open draft before retrying photo cleanup."
            return
        }
        do {
            try store.reconcilePendingPhotoCleanup()
            photoCleanupError = nil
        } catch {
            photoCleanupError = "AQD photo cleanup couldn’t finish. Deleted records are not reported as fully erased while their photo cleanup remains pending. Retry without changing the reviewed deletion."
        }
    }

    func reloadToday() {
        guard let store else { return }
        do {
            today = try store.todayConfiguration()
            todayError = nil
        } catch {
            todayError = "Your saved Today layout couldn’t open. It has not been replaced with defaults. Retry or keep the app data for recovery."
        }
    }

    func addPiece() {
        guard let store else { return }
        do {
            let recovered = try store.newPieceDraft()
            capture = CaptureModel(state: self, draft: recovered?.draft ?? PieceDraft(),
                                   operationID: recovered?.operationID ?? UUID())
        } catch {
            collectionError = "The saved draft couldn’t open. It hasn’t been replaced."
        }
    }

    func editPiece(_ piece: WardrobePiece) {
        guard let store else { return }
        do {
            let recovered = try store.recoverableDraft(itemID: piece.id)
            let draft = recovered?.draft ?? PieceDraft(
                itemID: piece.id, name: piece.name, category: piece.category,
                photoID: piece.photoID, baseRevision: piece.revision, details: piece.details,
                availability: piece.availability, photoRecipe: piece.photoRecipe)
            capture = CaptureModel(state: self, draft: draft,
                                   operationID: recovered?.operationID ?? UUID())
        } catch {
            collectionError = "This piece’s saved draft couldn’t open. It hasn’t been replaced."
        }
    }

    #if DEBUG
    /// Real malformed native input, isolated to the explicitly identified UI-test store.
    /// This fixture cannot mutate the ordinary closet and is absent from Release.
    private func seedUnreadableUITestDraft(in directory: URL) throws {
        let schema = Schema(versionedSchema: LocalSchemaV2.self)
        let configuration = ModelConfiguration(schema: schema,
            url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
        let fixtureContainer = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(fixtureContainer)
        guard try context.fetch(FetchDescriptor<StoredPieceDraft>()).isEmpty else { return }
        let draft = PieceDraft(name: "Unreadable retained UI-test draft")
        context.insert(StoredPieceDraft(draft: draft, operationID: UUID(), payload: Data("not-json".utf8)))
        try context.save()
    }
    #endif
}

@MainActor
@Observable
final class CaptureModel: Identifiable {
    nonisolated let id: UUID
    var draft: PieceDraft
    var operationID: UUID
    var importGate = PhotoImportGate()
    var errorText: String?
    var draftSaveFailed = false
    var isSaving = false
    var saved: WardrobePiece?
    @ObservationIgnored private unowned let state: AppState
    @ObservationIgnored private let preparer = PhotoPreparer()
    @ObservationIgnored private var importTask: Task<Void, Never>?
    @ObservationIgnored private var previewCache: (id: UUID, recipe: PhotoEditRecipe, data: Data)?

    var isImporting: Bool { importGate.pending != nil }
    var canSave: Bool { (try? draft.validated()) != nil && !isSaving && !isImporting && !draftSaveFailed }

    init(state: AppState, draft: PieceDraft, operationID: UUID) {
        self.id = draft.id
        self.state = state
        self.draft = draft
        self.operationID = operationID
        persistDraft()
    }

    func update<Value>(_ keyPath: WritableKeyPath<PieceDraft, Value>, value: Value) {
        guard !isSaving, saved == nil else { return }
        draft[keyPath: keyPath] = value
        operationID = UUID()
        persistDraft()
    }

    func applyDetails(_ details: PieceDetails, availability: PieceAvailability) {
        guard !isSaving, saved == nil else { return }
        draft.details = details
        draft.availability = availability
        operationID = UUID()
        persistDraft()
    }

    func persistDraft() {
        guard let store = state.store, saved == nil else { return }
        do {
            try store.saveDraft(draft, operationID: operationID)
            draftSaveFailed = false
        } catch {
            draftSaveFailed = true
            errorText = "These changes couldn’t be kept as a recoverable draft. Keep editing or discard this draft before leaving."
        }
    }

    func importPhoto(load: @escaping @MainActor () async throws -> Data?) {
        cancelImport()
        let request = importGate.begin(for: draft)
        errorText = nil
        importTask = Task { [weak self] in
            guard let self else { return }
            do {
                guard let data = try await load() else {
                    if importGate.canAccept(request, for: draft) { importGate.cancel() }
                    return
                }
                let prepared = try await preparer.prepare(data: data)
                guard !Task.isCancelled, importGate.canAccept(request, for: draft), let store = state.store else { return }
                let photoID = try store.acceptPhoto(prepared)
                guard importGate.apply(photoID: photoID, request: request, to: &draft) else { return }
                operationID = UUID()
                persistDraft()
            } catch {
                guard importGate.canAccept(request, for: draft) else { return }
                importGate.cancel()
                errorText = "That photo couldn’t be prepared. Your fields and previous photo are unchanged. Choose another photo or keep the draft."
            }
        }
    }

    func cancelImport() {
        importGate.cancel()
        importTask?.cancel()
        importTask = nil
    }

    func removePhoto() {
        cancelImport()
        update(\.photoID, value: nil)
    }

    func save() {
        guard canSave, let store = state.store else { return }
        cancelImport()
        isSaving = true
        defer { isSaving = false }
        do {
            saved = try store.savePiece(draft, operationID: operationID)
            state.reloadPieces()
            errorText = nil
        } catch PieceStore.StoreError.staleRevision {
            errorText = "This piece changed after your draft began. Your edits are retained. Keep them for reference, or review Discard draft to start again from the latest saved piece."
        } catch {
            errorText = "Save didn’t finish. Your draft is still here. Retry checks the same operation before writing again."
        }
    }

    func leave() {
        cancelImport()
        persistDraft()
        if !draftSaveFailed {
            state.capture = nil
            state.retryPhotoCleanup()
        }
    }

    func discard() {
        cancelImport()
        guard let store = state.store else { return }
        do {
            try store.discardDraft(id: draft.id)
            state.capture = nil
            state.retryPhotoCleanup()
        } catch {
            errorText = "The draft couldn’t be discarded. Keep it open and retry."
        }
    }

    func openCloset() {
        guard saved != nil else { return }
        state.closetPath = []
        state.closetScope = "Pieces"
        state.selection = 1
        state.capture = nil
        state.retryPhotoCleanup()
    }

    func photoData() -> Data? {
        guard let photoID = draft.photoID else { return nil }
        if let previewCache, previewCache.id == photoID, previewCache.recipe == draft.photoRecipe { return previewCache.data }
        guard let data = try? state.store?.photoThumbnail(id: photoID, recipe: draft.photoRecipe) else { return nil }
        previewCache = (photoID, draft.photoRecipe, data)
        return data
    }

    func originalPhotoData() -> Data? {
        guard let photoID = draft.photoID else { return nil }
        return try? state.store?.originalPhoto(id: photoID)
    }

    func originalThumbnailData() -> Data? {
        guard let photoID = draft.photoID else { return nil }
        return try? state.store?.thumbnailPhoto(id: photoID)
    }

    /// Framing confirms only the current draft, never a saved piece.
    func applyPhotoEdit(_ recipe: PhotoEditRecipe, sourceID: UUID, previousRecipe: PhotoEditRecipe) async -> Bool {
        guard !isSaving, saved == nil, draft.photoID == sourceID,
              draft.photoRecipe == previousRecipe, let data = originalPhotoData() else { return false }
        cancelImport()
        let request = importGate.begin(for: draft)
        do {
            let prepared = try await preparer.render(data: data, sourcePhotoID: sourceID, recipe: recipe)
            guard !Task.isCancelled, importGate.canAccept(request, for: draft),
                  draft.photoRecipe == previousRecipe, let store = state.store else { return false }
            try store.acceptPhotoEdit(prepared)
            importGate.cancel()
            draft.photoRecipe = recipe
            operationID = UUID()
            persistDraft()
            return true
        } catch {
            guard importGate.canAccept(request, for: draft) else { return false }
            importGate.cancel()
            errorText = "These photo edits couldn’t be prepared. Your previous photo and framing are unchanged. Try again or keep the original."
            return false
        }
    }
}
