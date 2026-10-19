import AQDCore
import Foundation
import ImageIO
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
    /// The single open task editor (capture, outfit, theme, plan, wear, style, fit, identity or Today).
    var activeEditor: ActiveEditor?
    var store: PieceStore?
    func requireStore() throws -> PieceStore {
        guard let store else { throw PieceStore.StoreError.corruptStore }
        return store
    }
    var localDataRoot: URL?
    var dataCoordinator: LocalDataCoordinator?
    var restoreModel: LocalRestoreModel?
    /// True when restore or reset was opened from Settings, where it is pushed as a page instead of covering the app.
    var restoreInSettings = false
    /// True while the launch splash covers the app, so entrances underneath wait for it to leave.
    var showingSplash = true
    /// Swaps in a replaced closet; set by the root view so a pushed page can finish an install.
    var installReplacement: ((PieceStore, LocalDataCoordinator, Int) -> Void)?
    var localDataCleanupError: String?
    var openingError: String?
    var isOpening = false
    var pieces: [WardrobePiece] = []
    var pieceCategories = WardrobeCategory.defaults
    var archivedPieces: [WardrobePiece] = []
    var ownedPieces: [WardrobePiece] { pieces + archivedPieces }
    var pendingOutfitEditID: UUID?
    var collectionRefreshID = UUID()
    var collectionError: String?
    var pieceReadError: String?
    var agentModel: AgentModel?
    var agentControlsModel: AgentControlsModel?
    var weatherClient: WeatherClient?
    var today: TodayConfiguration?
    var todayUndoAvailable = false
    var todayError: String?
    var photoCleanupError: String?
    var wearHistoryDay = LocalPlanDay()
    var wearHistoryMode = PlannerCalendarMode.month
    var wearHistoryCalendar = false
    var wearRecords: [OutfitWearRecord] = []
    var wearError: String?
    var planDefinitions: [PlanDefinition] = []
    var plannerDay = LocalPlanDay()
    var plannerMode = PlannerCalendarMode.week
    var plannerPath: [PlannerRoute] = []
    var recentPlan: OutfitPlanEntry?
    var planUndoDeadline: Date?
    var planUndoRequest: PlanEntryDeletionRequest?
    var planUndoPending = false
    var planEntries: [OutfitPlanEntry] = []
    var planError: String?
    var pendingPlanOutfitID: UUID?
    var pendingOutfitCaptureCategory: PieceCategory?
    var pendingFirstOutfitPieceID: UUID?
    var outfits: [Outfit] = []
    var outfitError: String?
    var fitMemories: [FitMemory] = []
    var fitError: String?
    var fitAnchor: UUID?
    /// Set when a saved fit asked to open Record wear once its sheet has closed.
    var pendingFitWear: (outfitID: UUID?, day: LocalPlanDay)?
    var localIdentity: LocalProfileIdentity?
    var identityError: String?
    var settings: LocalSettings?
    var settingsError: String?
    private var pendingSettings: LocalSettingsRequest?
    private var desiredAppearance: LocalAppearance?
    var agentLaunchID: UUID?
    var appearance: AppAppearance { AppAppearance(rawValue: settings?.appearance.rawValue ?? "system") ?? .system }
    var profileSettings = false
    var isSettingsVisible: Bool { selection == 4 && profileSettings }
    var secondaryPageOwners: [UUID: Int] = [:]
    var isRootTabBarHidden: Bool {
        secondaryPageOwners.values.contains(selection)
            || (selection == 1 && !closetPath.isEmpty)
            || (selection == 2 && !plannerPath.isEmpty)
            || (selection == 4 && (profileSettings || profileInsights || profileHistory))
    }
    var profileHistory = false
    var profileInsights = false
    var entry = PrivateEntryState(alreadyEntered: true)

    init(deferOpening: Bool = false) {
        if deferOpening { isOpening = true } else { openStore() }
    }

    /// Use an explicitly isolated store without opening the ordinary local closet.
    init(store: PieceStore, dataRoot: URL? = nil, coordinator: LocalDataCoordinator? = nil) {
        self.store = store
        localDataRoot = dataRoot ?? store.localDirectory
        dataCoordinator = coordinator ?? LocalDataCoordinator(legacyRoot: dataRoot ?? store.localDirectory)
        weatherClient = WeatherClient(store: store)
        reloadPieces()
        reloadToday()
        retryPhotoCleanup()
        reloadEntry()
        reloadIdentity()
        resumeIdentity()
        resumeStyleDraft()
        reloadOutfits()
        resumeOutfitDraft()
        reloadPlanEntries()
        resumePlanAuthoring()
        resumePlanDraft()
        reloadWear()
        resumeWearDraft()
        reloadFits()
        resumeFit()
        reloadThemes()
        resumeThemeDraft()
        resumeTodayDraft()
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
            localDataRoot = directory
            let coordinator = LocalDataCoordinator(legacyRoot: directory); dataCoordinator = coordinator
            try coordinator.recover()
            store = try PieceStore(directory: coordinator.currentDirectory())
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
            if let store { weatherClient = WeatherClient(store: store) }
            reloadPieces()
            reloadToday()
            retryPhotoCleanup()
            reloadEntry()
        reloadIdentity()
        resumeIdentity()
            resumeStyleDraft()
            reloadOutfits()
            resumeOutfitDraft()
            reloadPlanEntries()
            resumePlanAuthoring()
            resumePlanDraft()
            reloadWear()
            resumeWearDraft()
        reloadFits()
        resumeFit()
            reloadThemes()
            resumeThemeDraft()
        resumeTodayDraft()
        } catch {
            store = nil
            openingError = "Your local closet couldn’t open. Existing data has not been replaced. Retry, or keep the app data for recovery."
        }
    }

    func reloadEntry() {
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            settings = try store.localSettings()
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
        guard !hasActiveEditor else { return }
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
        guard !hasActiveEditor else { return }
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
            pieceCategories = try store.localExperience().pieceCategories ?? WardrobeCategory.defaults
            pieces = owned.filter { !$0.isArchived }
            archivedPieces = owned.filter(\.isArchived)
            collectionError = nil; pieceReadError = nil
            // Archived edits can change detail data without changing the active pieces array.
            collectionRefreshID = UUID()
        } catch {
            collectionError = "Your pieces couldn’t be read. The saved collection has not been cleared."
            pieceReadError = collectionError
        }
    }

    func category(for piece: WardrobePiece) -> WardrobeCategory? {
        if let id = piece.details.organizationCategoryID,
           let category = pieceCategories.first(where: { $0.id == id && $0.type == piece.category }) { return category }
        let defaultID = WardrobeCategory.defaults.first { $0.type == piece.category }?.id
        return pieceCategories.first { $0.id == defaultID && $0.type == piece.category }
    }

    /// Categories that hold at least one piece; filters never offer an empty one. `keeping` stays so an active filter can be cleared.
    func categoriesWithPieces(keeping selected: String? = nil) -> [WardrobeCategory] {
        let used = Set(pieces.compactMap { category(for: $0)?.id })
        return pieceCategories.filter { used.contains($0.id) || $0.id == selected }
    }

    func categoryName(for piece: WardrobePiece) -> String {
        category(for: piece)?.name ?? WardrobeCategory.defaults.first { $0.type == piece.category }?.name ?? piece.category.rawValue
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
            todayUndoAvailable = try store.todayUndo() != nil
            todayError = nil
        } catch {
            todayError = "Your saved Today layout couldn’t open. It has not been replaced with defaults. Retry or keep the app data for recovery."
        }
    }

    func addPiece() {
        guard !hasActiveEditor else { return }
        guard let store else { return }
        do {
            var recovered = try store.newPieceDraft()
            // A saved piece whose receipt was never acknowledged is finished quietly; Add piece always opens ready for a new piece.
            // If the acknowledgement cannot be written, the receipt is shown instead, so nothing is ever lost.
            if let pending = recovered, try store.pendingSavedPiece(for: pending) != nil,
               (try? store.acknowledgePiecePresentation(draftID: pending.draft.id, operationID: pending.operationID)) != nil {
                reloadPieces()
                retryPhotoCleanup()
                recovered = try store.newPieceDraft()
            }
            capture = CaptureModel(state: self, draft: recovered?.draft ?? PieceDraft(),
                                   operationID: recovered?.operationID ?? UUID(),
                                   saved: try recovered.flatMap { try store.pendingSavedPiece(for: $0) })
        } catch {
            collectionError = "The saved draft couldn’t open. It hasn’t been replaced."
        }
    }

    /// Opens the normal Add piece editor with a prefilled draft (for example guessed by the Agent). An existing
    /// recoverable draft is never replaced; `onSaved` runs once the save is acknowledged.
    @discardableResult
    func addPiece(prefilled draft: PieceDraft, onSaved: @escaping @MainActor (WardrobePiece) -> Void) -> Bool {
        guard !hasActiveEditor, let store else { return false }
        do {
            guard try store.newPieceDraft() == nil else {
                collectionError = "Finish or discard your open piece draft before adding another."
                return false
            }
            capture = CaptureModel(state: self, draft: draft, operationID: UUID())
            capture?.onSaved = onSaved
            return true
        } catch {
            collectionError = "The saved draft couldn’t open. It hasn’t been replaced."
            return false
        }
    }

    func editPiece(_ piece: WardrobePiece, openCutout: Bool = false) {
        guard !hasActiveEditor else { return }
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
            capture?.opensCutout = openCutout
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
            UIColor(AppTheme.secondary).setFill()
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
            UIColor(AppTheme.secondary).setFill()
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
    var completedPhotoImportID: UUID?
    var errorText: String?
    var draftSaveFailed = false
    var isSaving = false
    var saved: WardrobePiece?
    /// Called after a save is acknowledged, so a caller that prefilled the draft can show its own receipt.
    @ObservationIgnored var onSaved: (@MainActor (WardrobePiece) -> Void)?
    /// Progress of the automatic cutout for the draft photo.
    enum CutoutState: Equatable { case idle, working, applied, noSubject, failed }
    var cutoutState = CutoutState.idle
    /// Plain-language photo quality hints for the current draft photo.
    var photoHints: [PhotoQualityHint] = []
    /// True when the mode is "Ask each time" and a fresh photo is waiting for a decision.
    var offersCutout = false
    /// Set when the editor is opened straight to the cutout (for example from a piece's menu).
    var opensCutout = false
    @ObservationIgnored private unowned let state: AppState
    @ObservationIgnored private var cutoutTask: Task<Void, Never>?
    @ObservationIgnored private let preparer = PhotoPreparer()
    @ObservationIgnored private var importTask: Task<Void, Never>?
    @ObservationIgnored private var previewCache: (id: UUID, recipe: PhotoEditRecipe, data: Data)?
    private static let draftPersistenceError = "These changes couldn’t be kept as a recoverable draft. Keep editing or discard this draft before leaving."
    private static let photoImportError = "That photo couldn’t be prepared. Your fields and previous photo are unchanged. Choose another photo or keep the draft."
    private static let photoEditError = "These photo edits couldn’t be prepared. Your previous photo and framing are unchanged. Try again or keep the original."

    var categories: [WardrobeCategory] { state.pieceCategories }
    var categorySelectionID: String? {
        if let category = categories.first(where: { $0.id == draft.details.organizationCategoryID && $0.type == draft.category }) { return category.id }
        guard let type = draft.category, let id = WardrobeCategory.defaults.first(where: { $0.type == type })?.id else { return nil }
        return categories.first { $0.id == id && $0.type == type }?.id
    }
    var categoryName: String {
        if let category = categories.first(where: { $0.id == categorySelectionID }) { return category.name }
        return draft.category.flatMap { type in WardrobeCategory.defaults.first { $0.type == type }?.name } ?? "Choose category"
    }
    func selectCategory(_ category: WardrobeCategory) {
        guard !isSaving, saved == nil, categories.contains(category) else { return }
        draft.category = category.type
        draft.details.organizationCategoryID = category.id
        operationID = UUID()
        persistDraft()
    }

    var hasUnsavedChanges: Bool {
        guard saved == nil else { return false }
        if isImporting || draftSaveFailed { return true }
        if let revision = draft.baseRevision {
            guard let piece = try? state.store?.piece(id: draft.itemID), piece.revision == revision else { return true }
            return draft.name != piece.name || draft.category != piece.category || draft.photoID != piece.photoID
                || draft.photoRecipe != piece.photoRecipe || draft.details != piece.details || draft.availability != piece.availability
        }
        return draft.photoID != nil || !draft.name.isEmpty || draft.category != nil
            || draft.details != PieceDetails() || draft.availability != .available || draft.photoRecipe != .fitOriginal
    }

    var isImporting: Bool { importGate.pending != nil }
    var canSave: Bool { saved == nil && (draft.baseRevision == nil || hasUnsavedChanges) && (try? draft.validated()) != nil && !isSaving && !isImporting && !draftSaveFailed }
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
                if !draftSaveFailed {
                    completedPhotoImportID = photoID
                    photoImported(width: prepared.pixelWidth, height: prepared.pixelHeight)
                }
            } catch {
                guard importGate.canAccept(request, for: draft) else { return }
                importGate.cancel()
                if !draftSaveFailed { errorText = Self.photoImportError }
            }
        }
    }

    func cancelImport() {
        cancelCutout()
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
            if let saved { onSaved?(saved) }
            errorText = nil
        } catch PieceStore.StoreError.staleRevision {
            errorText = "This piece changed after your draft began. Your edits are retained. Keep them for reference, or review Discard draft to start again from the latest saved piece."
        } catch {
            errorText = "Save didn’t finish. Your draft is still here. Retry checks the same operation before writing again."
        }
    }

    func leave() {
        cancelImport()
        if let piece = saved {
            guard acknowledgePresentation() else { return }
            // Saving returns to the list with the new piece in view; it never starts another task.
            state.closetScope = "Pieces"
            state.closetPieceAnchor = piece.id
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

    func categoryName(for piece: WardrobePiece) -> String { state.categoryName(for: piece) }

    func openCloset() {
        guard let piece = saved, acknowledgePresentation() else { return }
        state.openClosetDestination()
        state.closetPieceAnchor = piece.id
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

struct BackgroundPhotoInput: Sendable {
    /// The saved cutout when the draft photo is already a derived cutout, so Refine can reopen its mask.
    let existingCutout: Data?
    let draftID: UUID
    let operationID: UUID
    let sourceID: UUID
    let originalID: UUID
    let recipe: PhotoEditRecipe
    let data: Data
}
extension CaptureModel {
    var hasProcessedPhoto: Bool {
        guard let id = draft.photoID else { return false }
        return (try? state.store?.backgroundOriginalID(for: id)) != nil
    }
    func backgroundInput() throws -> BackgroundPhotoInput {
        guard !isSaving, !isImporting, saved == nil, let source = draft.photoID, let store = state.store else { throw BackgroundPhotoError.staleSource }
        let original = try store.backgroundOriginalID(for: source) ?? source
        let existing = original == source ? nil : try store.originalPhoto(id: source)
        return BackgroundPhotoInput(existingCutout: existing, draftID: draft.id, operationID: operationID, sourceID: source, originalID: original, recipe: draft.photoRecipe, data: try store.originalPhoto(id: original))
    }
    func backgroundSourceIsCurrent(_ input: BackgroundPhotoInput) -> Bool {
        !isSaving && !isImporting && saved == nil && draft.id == input.draftID && operationID == input.operationID && draft.photoID == input.sourceID && draft.photoRecipe == input.recipe
    }
    func acceptBackground(_ prepared: PreparedPhoto?, input: BackgroundPhotoInput, crop: PhotoEditRecipe.NormalizedRect? = nil) -> Bool {
        guard backgroundSourceIsCurrent(input), let store = state.store else { return false }
        do {
            let id: UUID
            if let prepared { id = try store.acceptBackgroundPhoto(prepared, originalID: input.originalID) }
            else { _ = try store.originalPhoto(id: input.originalID); id = input.originalID }
            var recipe = crop.map { PhotoEditRecipe(crop: $0) } ?? .fitOriginal
            if (try? recipe.validated()) == nil { recipe = .fitOriginal }
            draft.photoID = id; draft.photoRecipe = recipe; operationID = UUID(); persistDraft()
            return !draftSaveFailed
        } catch { errorText = "The background result could not be applied. Your previous accepted photo is retained."; return false }
    }
    // MARK: Automatic cutout

    fileprivate func photoImported(width: Int, height: Int) {
        cutoutState = .idle
        photoHints = PhotoQuality.assess(pixelWidth: width, pixelHeight: height)
        switch CutoutMode.current {
        case .auto: autoCutout()
        case .ask: offersCutout = true
        case .off: break
        }
    }

    /// Cut the piece out of the draft photo in the background; the original is always kept.
    func autoCutout() {
        guard cutoutState != .working, !hasProcessedPhoto, let input = try? backgroundInput() else { return }
        cutoutTask?.cancel()
        cutoutState = .working
        offersCutout = false
        cutoutTask = Task { [weak self] in
            do {
                let outcome = try await CutoutPipeline.automatic(original: input.data)
                guard !Task.isCancelled, let self, self.backgroundSourceIsCurrent(input) else { return }
                if self.acceptBackground(outcome.prepared, input: input, crop: outcome.crop) {
                    self.cutoutState = .applied
                    self.photoHints = outcome.hints
                    self.opensCutout = CutoutMode.reviewsAfterCutout
                } else { self.cutoutState = .failed }
            } catch BackgroundPhotoError.noForeground {
                guard !Task.isCancelled, let self, self.backgroundSourceIsCurrent(input) else { return }
                let size = Self.pixelSize(of: input.data)
                self.cutoutState = .noSubject
                self.photoHints = PhotoQuality.assess(pixelWidth: size.width, pixelHeight: size.height, subjectFound: false)
                self.opensCutout = CutoutMode.reviewsAfterCutout
            } catch {
                guard !Task.isCancelled, let self, self.backgroundSourceIsCurrent(input) else { return }
                self.cutoutState = .failed
                self.opensCutout = CutoutMode.reviewsAfterCutout
            }
        }
    }

    func cancelCutout() {
        cutoutTask?.cancel()
        cutoutTask = nil
        if cutoutState == .working { cutoutState = .idle }
    }

    /// Replace a cutout with the untouched original photo.
    func useOriginalPhoto() {
        guard let input = try? backgroundInput(), acceptBackground(nil, input: input) else { return }
        cutoutState = .idle
        let size = Self.pixelSize(of: input.data)
        photoHints = PhotoQuality.assess(pixelWidth: size.width, pixelHeight: size.height)
    }

    private static func pixelSize(of data: Data) -> (width: Int, height: Int) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return (0, 0) }
        return ((properties[kCGImagePropertyPixelWidth] as? Int) ?? 0, (properties[kCGImagePropertyPixelHeight] as? Int) ?? 0)
    }

    func resetThumbnailData() -> Data? {
        guard let id = draft.photoID, let original = try? state.store?.backgroundOriginalID(for: id) else { return originalThumbnailData() }
        return try? state.store?.thumbnailPhoto(id: original)
    }
    func applyPhotoReset(_ recipe: PhotoEditRecipe, sourceID: UUID, previousRecipe: PhotoEditRecipe) async -> Bool {
        guard !isSaving, saved == nil, draft.photoID == sourceID, draft.photoRecipe == previousRecipe, let store = state.store else { return false }
        guard let original = try? store.backgroundOriginalID(for: sourceID) else { return await applyPhotoEdit(recipe, sourceID: sourceID, previousRecipe: previousRecipe) }
        cancelImport(); let request = importGate.begin(for: draft)
        do {
            let prepared = try await preparer.render(data: store.originalPhoto(id: original), sourcePhotoID: original, recipe: recipe)
            guard !Task.isCancelled, importGate.canAccept(request, for: draft), draft.photoRecipe == previousRecipe else { return false }
            try store.acceptPhotoEdit(prepared)
            guard importGate.apply(photoID: original, request: request, to: &draft) else { return false }
            draft.photoRecipe = recipe; operationID = UUID(); persistDraft(); return !draftSaveFailed
        } catch {
            guard importGate.canAccept(request, for: draft) else { return false }
            importGate.cancel(); errorText = "The original could not be restored. Your accepted photo and framing are retained."; return false
        }
    }
}

extension AppState {
    func reloadSettings() {
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            settings = try store.localSettings()
            if pendingSettings == nil && desiredAppearance == nil { settingsError = nil }
        }
        catch { settingsError = "Settings couldn’t be read. Saved preferences are retained. Try again." }
    }
    func saveAppearance(_ appearance: LocalAppearance) {
        desiredAppearance = appearance
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            if let pendingSettings { _ = try store.saveLocalSettings(pendingSettings); self.pendingSettings = nil }
            let current = try store.localSettings()
            guard current.appearance != appearance else { desiredAppearance = nil; reloadSettings(); return }
            let request = LocalSettingsRequest(base: current, appearance: appearance)
            pendingSettings = request
            _ = try store.saveLocalSettings(request); pendingSettings = nil; desiredAppearance = nil; reloadSettings()
        } catch { settingsError = "The appearance save wasn’t confirmed. Retry checks the same operation; your other data is retained." }
    }
    func retryAppearanceSave() {
        guard let appearance = desiredAppearance ?? pendingSettings?.appearance else { reloadSettings(); return }
        saveAppearance(appearance)
    }
}

extension AppState {
    func openRestore(inSettings: Bool = false) {
        guard restoreModel == nil, let dataCoordinator else { return }
        restoreInSettings = inSettings
        restoreModel = LocalRestoreModel(coordinator: dataCoordinator, source: store)
    }
    func openErase(inSettings: Bool = false) {
        guard restoreModel == nil, let dataCoordinator else { return }
        restoreInSettings = inSettings
        restoreModel = LocalRestoreModel(coordinator: dataCoordinator, source: store, kind: .erase)
    }
    /// Leaving the page abandons a review that can still be cancelled; a failed cancel keeps the page so its error stays visible.
    func closeSettingsDataOperation() {
        guard let model = restoreModel, restoreInSettings else { return }
        if model.cancel() { restoreModel = nil; restoreInSettings = false }
    }
    func finishSettingsDataOperation(_ store: PieceStore, _ coordinator: LocalDataCoordinator, _ destination: Int) {
        restoreModel = nil; restoreInSettings = false
        installReplacement?(store, coordinator, destination)
    }
    func retryLocalDataCleanup() {
        do {
            guard let coordinator = dataCoordinator else { localDataCleanupError = nil; return }
            guard let pending = try coordinator.pendingReview() else {
                localDataCleanupError = try coordinator.hasRetainedOperations() ? "Recovery files are retained. Use Settings → Restore to review a validated replacement before cleanup." : nil
                return
            }
            if try coordinator.isInstalled(pending.operationID) {
                guard let store else { localDataCleanupError = "Current data needs recovery. Previous AQD files are retained; choose a validated archive before cleanup."; return }
                guard !coordinator.isWaitingForPreviousStore else { localDataCleanupError = "Local records are active. Previous AQD files are awaiting the old store to close."; return }
                if pending.phase != .acknowledged { try coordinator.acknowledge(pending.operationID) }
                localDataCleanupError = try coordinator.cleanupRetired() ? nil : "Local records are active. Previous AQD files are still awaiting safe cleanup."
            } else { localDataCleanupError = "A validated local-data review is retained. Continue it from Settings → Restore, or cancel it there." }
        } catch { localDataCleanupError = "Local records are retained. Previous AQD files could not be removed; retry local data cleanup." }
    }
    func detachForDataReplacement() {
        agentModel?.suspend(); agentModel = nil; agentControlsModel = nil
        weatherClient?.suspend(); weatherClient = nil
        capture = nil; outfitEditor = nil; themeEditor = nil; wearEditor = nil; planEditor = nil; planAuthoringEditor = nil
        styleEditor = nil; fitEditor = nil; identityEditor = nil; todayEditor = nil; restoreModel = nil
        store = nil
    }
}
