import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct WardrobeCategoryPersistenceTests {
    @Test func catalogPersistsStableRenamesAndUsesCompareAndSwapWithoutTouchingOtherPreferences() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        let before = try store.localExperience()
        let defaults = WardrobeCategory.defaults
        var categories = defaults + [WardrobeCategory(name: "Work shirts", type: .tops)]
        try store.savePieceCategories(categories, expected: defaults)
        var renamed = categories
        renamed[renamed.count - 1].name = "Office shirts"
        try store.savePieceCategories(renamed, expected: categories)
        try store.savePieceCategories(renamed, expected: categories) // Reconcile a repeated acknowledged write.
        #expect(throws: PieceStore.StoreError.staleRevision) { try store.savePieceCategories(defaults, expected: categories) }
        categories = renamed
        var expected = before; expected.pieceCategories = categories
        #expect(try store.localExperience() == expected)
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.localExperience().pieceCategories == categories)
        #expect(renamed.last?.id == categories.last?.id)
    }
    @Test func renamedDefaultResolvesLegacyDraftAndSelectionByStableID() throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        var categories = WardrobeCategory.defaults
        categories[0].name = "Tees"
        try store.savePieceCategories(categories, expected: WardrobeCategory.defaults)
        let state = AppState(store: store)
        state.reloadPieces()
        let draft = PieceDraft(name: "Legacy top", category: .tops)
        let model = CaptureModel(state: state, draft: draft, operationID: UUID())
        #expect(model.categorySelectionID == "tops")
        #expect(model.categoryName == "Tees")
        #expect(model.draft.details.organizationCategoryID == nil)
        model.selectCategory(categories[0])
        #expect(model.draft.details.organizationCategoryID == "tops")
        #expect(model.categoryName == "Tees")
        let beforeManagement = model.draft
        let custom = WardrobeCategory(name: "Work shirts", type: .tops)
        try store.savePieceCategories(categories + [custom], expected: categories)
        state.reloadPieces()
        #expect(model.draft == beforeManagement)
        #expect(model.categories.contains(custom))
        model.selectCategory(custom)
        #expect(model.categorySelectionID == custom.id)
        #expect(model.draft.name == beforeManagement.name)
        #expect(model.draft.photoID == beforeManagement.photoID)
        #expect(try store.newPieceDraft()?.draft == model.draft)
    }

    @Test func catalogAndCategoryReferencesSurviveArchiveRoundTrip() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let custom = WardrobeCategory(name: "Work shirts", type: .tops)
        try store.savePieceCategories(WardrobeCategory.defaults + [custom], expected: WardrobeCategory.defaults)
        let draft = PieceDraft(name: "Office shirt", category: .tops, details: PieceDetails(organizationCategoryID: custom.id))
        try store.saveDraft(draft, operationID: UUID())
        let archive = try await LocalArchiveService.create(store: store)
        let restored = try await LocalArchiveService.stage(LocalArchivePackage.decode(archive.data))
        defer { try? FileManager.default.removeItem(at: restored.directory) }
        #expect(try restored.store.localExperience().pieceCategories == WardrobeCategory.defaults + [custom])
        #expect(try restored.store.newPieceDraft()?.draft == draft)
    }

    @Test func legacyExperienceDecodesDefaultsAndInvalidCatalogCannotReplaceThem() throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let before = try store.localExperience()
        let legacy = try JSONDecoder().decode(LocalExperience.self, from: JSONEncoder().encode(before))
        #expect(legacy.pieceCategories == nil)
        #expect(throws: WardrobeCategoryError.self) { try store.savePieceCategories([], expected: WardrobeCategory.defaults) }
        #expect(try store.localExperience() == before)
    }
}
