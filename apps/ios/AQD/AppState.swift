import AQDCore
import Foundation
import Observation
#if DEBUG
import SwiftData
import UIKit
#endif

enum ClosetRoute: Hashable { case piece(UUID), outfit(UUID), theme(UUID), archivedPieces }

@MainActor
@Observable
final class AppState {
    var selection = 0
    var closetPath: [ClosetRoute] = []
    var closetScope = "Pieces"
    var closetSearchActive = false
    var closetSearchQuery = ""
    var closetSearchScope = "Pieces"
    var closetSearchSourceScope = "Pieces"
    var closetSearchRestoresSource = true
    var closetPieceAnchor: UUID?
    var closetOutfitAnchor: UUID?
    var closetThemeAnchor: UUID?
    var themes: [OutfitTheme] = []
    var themeError: String?
    var themeEditor: ThemeEditorModel?
    var store: PieceStore?
    var openingError: String?
    var isOpening = false
    var pieces: [WardrobePiece] = []
    var archivedPieces: [WardrobePiece] = []
    var ownedPieces: [WardrobePiece] { pieces + archivedPieces }
    var pendingOutfitEditID: UUID?
    var collectionRefreshID = UUID()
    var capture: CaptureModel?
    var collectionError: String?
    var today: TodayConfiguration?
    var todayError: String?
    var photoCleanupError: String?
    var wearEditor: OutfitWearEditorModel?
    var wearHistoryDay = LocalPlanDay()
    var wearHistoryMode = PlannerCalendarMode.month
    var wearHistoryCalendar = false
    var wearRecords: [OutfitWearRecord] = []
    var wearError: String?
    var planDefinitions: [PlanDefinition] = []
    var planAuthoringEditor: PlanAuthoringModel?
    var plannerDay = LocalPlanDay()
    var plannerMode = PlannerCalendarMode.week
    var plannerPath: [PlannerRoute] = []
    var recentPlan: OutfitPlanEntry?
    var planUndoDeadline: Date?
    var planUndoRequest: PlanEntryDeletionRequest?
    var planUndoPending = false
    var planEditor: OutfitPlanEditorModel?
    var planEntries: [OutfitPlanEntry] = []
    var planError: String?
    var pendingPlanOutfitID: UUID?
    var outfitEditor: OutfitEditorModel?
    var pendingOutfitCaptureCategory: PieceCategory?
    var pendingFirstOutfitPieceID: UUID?
    var outfits: [Outfit] = []
    var outfitError: String?
    var styleEditor: StyleEditorModel?
    var profileSettings = false
    var profileHistory = false
    var profileInsights = false
    var entry = PrivateEntryState(alreadyEntered: true)
    var reloadEntryAfterStyle = false

    init(deferOpening: Bool = false) {
        if deferOpening { isOpening = true } else { openStore() }
    }

    /// Use an explicitly isolated store without opening the ordinary local closet.
    init(store: PieceStore) {
        self.store = store
        reloadPieces()
        reloadToday()
        retryPhotoCleanup()
        reloadEntry()
        resumeStyleDraft()
        reloadOutfits()
        resumeOutfitDraft()
        reloadPlanEntries()
        resumePlanAuthoring()
        resumePlanDraft()
        reloadWear()
        resumeWearDraft()
        reloadThemes()
        resumeThemeDraft()
    }

    func openStore() {
        isOpening = true
        defer { isOpening = false }
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
            if isolatedUITestStore, process.environment["AQD_TEST_RETURNING_ENTRY"] == "1", let store {
                var entry = try store.localExperience().entryState
                entry.openMain()
                try store.saveEntryState(entry)
            }
            if isolatedUITestStore, process.environment["AQD_TEST_DENIED_DELETE_CLEANUP"] == "1" {
                store = nil
                let photoID = Self.deletionFixturePhotoID
                let fixtureStore = try PieceStore(directory: directory, removeMediaFile: { url in
                    if url.lastPathComponent == "\(photoID.uuidString).jpg"
                        || url.lastPathComponent == "\(photoID.uuidString)-thumbnail.jpg" {
                        throw CocoaError(.fileWriteNoPermission)
                    }
                    try FileManager.default.removeItem(at: url)
                })
                try seedDeniedDeletionUITestPiece(in: fixtureStore)
                store = fixtureStore
            }
            if isolatedUITestStore, process.environment["AQD_TEST_DENIED_CAPTURE_CLEANUP"] == "1" {
                store = nil
                let photoID = Self.captureFixturePhotoID
                let fixtureStore = try PieceStore(directory: directory, removeMediaFile: { url in
                    if url.lastPathComponent == "\(photoID.uuidString).jpg"
                        || url.lastPathComponent == "\(photoID.uuidString)-thumbnail.jpg" {
                        throw CocoaError(.fileWriteNoPermission)
                    }
                    try FileManager.default.removeItem(at: url)
                })
                try seedDeniedCaptureUITestDraft(in: fixtureStore)
                store = fixtureStore
            }
            if isolatedUITestStore, process.environment["AQD_TEST_CORRUPT_DRAFT"] == "1" {
                try seedUnreadableUITestDraft(in: directory)
            }
            if isolatedUITestStore, process.environment["AQD_TEST_READONLY_CLEANUP"] == "1" {
                store = nil
                try seedPendingUITestPhotoCleanup(in: directory)
                store = try PieceStore(directory: directory, allowsSave: false)
            }
            if isolatedUITestStore, process.environment["AQD_TEST_DENIED_STYLE_SAVE"] == "1" {
                store = nil
                store = try PieceStore(directory: directory, beforeStyleSave: { throw CocoaError(.fileWriteNoPermission) })
            }
            if isolatedUITestStore, process.environment["AQD_TEST_UNKNOWN_STYLE_SAVE"] == "1" {
                store = nil
                var unreadableAcknowledgments = 0
                store = try PieceStore(directory: directory, afterStyleSave: {
                    unreadableAcknowledgments = 1
                    throw CocoaError(.fileReadUnknown)
                }, beforeExperienceRead: {
                    if unreadableAcknowledgments > 0 {
                        unreadableAcknowledgments -= 1
                        throw CocoaError(.fileReadUnknown)
                    }
                })
            }
            #endif
            openingError = nil
            reloadPieces()
            reloadToday()
            retryPhotoCleanup()
            reloadEntry()
            resumeStyleDraft()
            reloadOutfits()
            resumeOutfitDraft()
            reloadPlanEntries()
            resumePlanAuthoring()
            resumePlanDraft()
            reloadWear()
            resumeWearDraft()
            reloadThemes()
            resumeThemeDraft()
        } catch {
            store = nil
            openingError = "Your local closet couldn’t open. Existing data has not been replaced. Retry, or keep the app data for recovery."
        }
    }

    func reloadEntry() {
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            entry = try store.localExperience().entryState
            if entry.tour?.source == .settings { selection = 4; profileSettings = true }
        } catch { openingError = "Your private entry state couldn’t open. Existing data hasn’t been replaced. Retry while keeping the app data." }
    }

    func updateEntry(_ change: (inout PrivateEntryState) throws -> Void) {
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            var changed = entry
            try change(&changed)
            try store.saveEntryState(changed)
            entry = changed
        } catch { collectionError = "This step couldn’t be saved. Your previous entry state and closet are unchanged. Retry this action." }
    }

    @discardableResult func markWelcomeArrival() -> Bool {
        let first = !entry.welcomeSeen
        if first { updateEntry { $0.welcomeSeen = true } }
        return first && entry.welcomeSeen
    }

    func beginTour(from source: PrivateEntryState.TourSource) {
        guard styleEditor == nil, capture == nil else { return }
        updateEntry { try $0.startTour(from: source) }
    }

    func enterMain(selection: Int = 0, capture: Bool = false) {
        updateEntry { $0.openMain() }
        guard entry.page == .main else { return }
        self.selection = selection
        if capture { addPiece() }
    }

    func openStyle(source: StylePreferenceSource) {
        guard planAuthoringEditor == nil else { return }
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            let experience = try store.localExperience()
            if let receipt = experience.pendingStyleReceipt {
                let model = StyleEditorModel(state: self, draft: receipt)
                model.saved = experience.style
                styleEditor = model
                return
            }
            let draft = experience.styleDraft ?? StylePreferenceDraft(
                source: source, baseRevision: experience.style?.revision ?? 0,
                answers: experience.style?.answers ?? .init())
            try store.saveStyleDraft(draft)
            styleEditor = StyleEditorModel(state: self, draft: draft)
        } catch { collectionError = "Your preference draft couldn’t open. Existing preferences and drafts haven’t been replaced." }
    }

    private func resumeStyleDraft() {
        do {
            if let experience = try store?.localExperience(), let draft = experience.styleDraft ?? experience.pendingStyleReceipt {
                if draft.source != .onboarding {
                    selection = 4
                    profileSettings = draft.source == .settings
                }
                styleEditor = StyleEditorModel(state: self, draft: draft)
                if experience.pendingStyleReceipt != nil { styleEditor?.saved = experience.style }
            }
        } catch { openingError = "Your local preferences couldn’t open. Keep the app data for recovery and retry." }
    }

    func reloadPieces() {
        guard let store else { return }
        do {
            let owned = try store.ownedPiecesForWear()
            pieces = owned.filter { !$0.isArchived }
            archivedPieces = owned.filter(\.isArchived)
            collectionError = nil
            // Archived edits can change detail data without changing the active pieces array.
            collectionRefreshID = UUID()
        } catch {
            collectionError = "Your pieces couldn’t be read. The saved collection has not been cleared."
        }
    }

    func deletePiece(id: UUID, expectedRevision: Int, operationID: UUID, impact: PieceDeletionImpact? = nil) throws {
        guard let store else { throw PieceStore.StoreError.corruptStore }
        do {
            try store.deletePiece(id: id, expectedRevision: expectedRevision, operationID: operationID, impact: impact)
        } catch {
            // Only exact, durable record-removal proof permits leaving the review.
            // Missing/conflicting/corrupt proof preserves the original local retry error.
            guard (try? store.isPieceDeletionAcknowledged(id: id, expectedRevision: expectedRevision,
                                                         operationID: operationID, impact: impact)) == true else { throw error }
        }
        reloadPieces(); reloadOutfits(); reloadThemes(); reloadPlanEntries()
        retryPhotoCleanup()
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
            photoCleanupError = "AQD photo cleanup couldn’t finish. Photo cleanup is still pending, so AQD does not report complete media erasure. Retry without changing saved records or retained drafts."
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
        guard planAuthoringEditor == nil else { return }
        guard let store else { return }
        do {
            let recovered = try store.newPieceDraft()
            capture = CaptureModel(state: self, draft: recovered?.draft ?? PieceDraft(),
                                   operationID: recovered?.operationID ?? UUID(),
                                   saved: try recovered.flatMap { try store.pendingSavedPiece(for: $0) })
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
                                   operationID: recovered?.operationID ?? UUID(),
                                   saved: try recovered.flatMap { try store.pendingSavedPiece(for: $0) })
        } catch {
            collectionError = "This piece’s saved draft couldn’t open. It hasn’t been replaced."
        }
    }

    #if DEBUG
    private static let deletionFixturePhotoID = UUID(uuidString: "DB016980-1347-4ABF-A809-D0477DE40B1B")!
    private static let captureFixturePhotoID = UUID(uuidString: "B9CE8A35-A322-456B-BDC3-4E77EA11D893")!

    /// Real creation draft and accepted synthetic media, never a saved piece.
    /// Retained drafts (including removed photos) are not reseeded on relaunch.
    /// Only the DEBUG argument/UUID/environment guard above can invoke this.
    private func seedDeniedCaptureUITestDraft(in store: PieceStore) throws {
        guard try store.newPieceDraft() == nil else { return }
        let draft = PieceDraft(name: "Synthetic retained capture", category: .tops,
                               photoID: Self.captureFixturePhotoID)
        try store.saveDraft(draft, operationID: UUID())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 30), format: format).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 30))
        }
        guard let data = image.jpegData(compressionQuality: 1) else { throw PhotoPreparationError.encodingFailed }
        _ = try store.acceptPhoto(PreparedPhoto(id: Self.captureFixturePhotoID, originalData: data,
                                              thumbnailData: data, pixelWidth: 20, pixelHeight: 30))
    }

    /// Known synthetic pixels only, through real draft/photo/piece persistence.
    /// Called only with the guarded isolated UI-test store; no erasure claim.
    private func seedDeniedDeletionUITestPiece(in store: PieceStore) throws {
        let itemID = UUID(uuidString: "EED2443D-EEEA-46AE-B24C-C4E889DC58AC")!
        guard try store.piece(id: itemID) == nil else { return }
        let operationID = UUID(uuidString: "63036EFD-E1B7-4F3F-9D06-F357024C6528")!
        let draft = PieceDraft(itemID: itemID, name: "Synthetic cleanup piece", category: .tops,
                               photoID: Self.deletionFixturePhotoID)
        // A deleted identity refuses this before any source is staged on relaunch.
        do { try store.saveDraft(draft, operationID: operationID) }
        catch PieceStore.StoreError.deletedPiece { return }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 30), format: format).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 30))
        }
        guard let data = image.jpegData(compressionQuality: 1) else { throw PhotoPreparationError.encodingFailed }
        _ = try store.acceptPhoto(PreparedPhoto(id: Self.deletionFixturePhotoID, originalData: data,
                                              thumbnailData: data, pixelWidth: 20, pixelHeight: 30))
        _ = try store.savePiece(draft, operationID: operationID)
    }

    /// A durable cleanup intent for a known synthetic missing source, not erased-byte proof.
    /// Called only after the DEBUG launch-argument/UUID guard selects an isolated writable store.
    private func seedPendingUITestPhotoCleanup(in directory: URL) throws {
        let photoID = UUID(uuidString: "E71EF667-186E-4E04-A676-115316C1B215")!
        let schema = Schema(versionedSchema: LocalSchemaV8.self)
        let configuration = ModelConfiguration(schema: schema,
            url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
        let fixtureContainer = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(fixtureContainer)
        let existing = try context.fetch(FetchDescriptor<StoredPhotoCleanup>(predicate: #Predicate { $0.id == photoID }))
        guard existing.isEmpty else { return }
        context.insert(StoredPhotoCleanup(photoID: photoID))
        try context.save()
    }

    /// Real malformed native input, isolated to the explicitly identified UI-test store.
    /// This fixture cannot mutate the ordinary closet and is absent from Release.
    private func seedUnreadableUITestDraft(in directory: URL) throws {
        let schema = Schema(versionedSchema: LocalSchemaV8.self)
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
    private static let draftPersistenceError = "These changes couldn’t be kept as a recoverable draft. Keep editing or discard this draft before leaving."
    private static let photoImportError = "That photo couldn’t be prepared. Your fields and previous photo are unchanged. Choose another photo or keep the draft."
    private static let photoEditError = "These photo edits couldn’t be prepared. Your previous photo and framing are unchanged. Try again or keep the original."

    var isImporting: Bool { importGate.pending != nil }
    var canSave: Bool { saved == nil && (try? draft.validated()) != nil && !isSaving && !isImporting && !draftSaveFailed }
    var receiptIsHistorical: Bool {
        guard let saved, let current = try? state.store?.piece(id: saved.id) else { return false }
        return current.revision > saved.revision
    }

    init(state: AppState, draft: PieceDraft, operationID: UUID, saved: WardrobePiece? = nil) {
        self.id = draft.id
        self.state = state
        self.draft = draft
        self.operationID = operationID
        self.saved = saved
        if saved == nil { persistDraft() }
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
            if errorText == Self.draftPersistenceError { errorText = nil }
        } catch {
            draftSaveFailed = true
            errorText = Self.draftPersistenceError
        }
    }

    func importPhoto(load: @escaping @MainActor () async throws -> Data?) {
        guard !isSaving, saved == nil else { return }
        cancelImport()
        let request = importGate.begin(for: draft)
        if errorText == Self.photoImportError { errorText = nil }
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
                if !draftSaveFailed { errorText = Self.photoImportError }
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
            saved = try store.savePiece(draft, operationID: operationID, retainForPresentation: true)
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
        if saved != nil {
            guard acknowledgePresentation() else { return }
            state.capture = nil
            state.retryPhotoCleanup()
            return
        }
        persistDraft()
        if !draftSaveFailed {
            state.capture = nil
            state.retryPhotoCleanup()
        }
    }

    func discard() {
        guard saved == nil else { return }
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

    private func acknowledgePresentation() -> Bool {
        guard let store = state.store else {
            errorText = "The saved receipt couldn’t be acknowledged. It is still here. Retry Back or Open my closet."
            return false
        }
        do {
            try store.acknowledgePiecePresentation(draftID: draft.id, operationID: operationID)
            state.reloadPieces() // Present current records, never the historical receipt snapshot.
            errorText = nil
            return true
        } catch {
            errorText = "The saved receipt couldn’t be acknowledged. It is still here. Retry Back or Open my closet."
            return false
        }
    }

    var isFirstOutfit: Bool { state.outfits.isEmpty }

    func buildFirstOutfit() {
        guard let saved, acknowledgePresentation() else { return }
        state.pendingFirstOutfitPieceID = saved.id
        state.capture = nil
        state.retryPhotoCleanup()
    }

    func openCloset() {
        guard saved != nil, acknowledgePresentation() else { return }
        state.openClosetDestination()
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
            if errorText == Self.photoEditError { errorText = nil }
            return true
        } catch {
            guard importGate.canAccept(request, for: draft) else { return false }
            importGate.cancel()
            if !draftSaveFailed { errorText = Self.photoEditError }
            return false
        }
    }
}
