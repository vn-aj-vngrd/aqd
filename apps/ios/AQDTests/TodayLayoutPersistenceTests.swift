import AQDCore
import Foundation
import SwiftData
import Testing
@testable import AQD

@Suite(.serialized) @MainActor
struct TodayLayoutPersistenceTests {
    @Test func noteLayoutIsAtomicUnknownRetryAndRestartKeepIndependentContentAndUndo() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var deny = false, unknown = false
        let store = try PieceStore(directory: directory, beforeOutfitSave: { if deny { throw CocoaError(.fileWriteNoPermission) } }, afterOutfitSave: { if unknown { throw CocoaError(.fileReadUnknown) } })
        let base = try store.todayConfiguration()
        var draft = TodayLayoutDraft(base: base)
        let card = TodayPersonalCard(ownerID: base.ownerID, kind: .personalNote, text: "Full private text")
        draft.value.instances = [TodayWidgetInstance(kind: .personalNote, options: TodayWidgetOptions(personal: card))]
        try store.saveTodayDraft(draft)
        deny = true
        #expect(throws: (any Error).self) { try store.saveTodayLayout(draft) }
        #expect(try store.todayConfiguration() == base)
        #expect(try store.todayPersonalCards().isEmpty)
        deny = false; unknown = true
        #expect(throws: (any Error).self) { try store.saveTodayLayout(draft) }
        let result = try store.saveTodayLayout(draft)
        #expect(result.instances.count == 1)
        #expect(try store.todayPersonalCards() == [card])
        try store.finishTodayDraft(draft)
        unknown = false
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.todayConfiguration() == result)
        #expect(try reopened.todayUndo()?.previous == base)
        var defaults = TodayLayoutDraft(base: result); defaults.restoreDefaults()
        #expect(defaults.value.instances.map(\.kind) == [.todayLook, .weekInWear, .closetInUse])
        defaults.undoDefaults()
        #expect(defaults.value.instances == result.instances)
        defaults.restoreDefaults(); try reopened.saveTodayDraft(defaults)
        _ = try reopened.saveTodayLayout(defaults); try reopened.finishTodayDraft(defaults)
        #expect(try reopened.todayPersonalCards() == [card])
        #expect(try reopened.wearRecords().isEmpty)
    }
    @Test func nestedApplyAndCancelStayDraftOnlyAndFailedSaveKeepsFullInput() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var deny = false
        let store = try PieceStore(directory: directory, beforeOutfitSave: { if deny { throw CocoaError(.fileWriteNoPermission) } })
        let base = try store.todayConfiguration(), state = AppState(store: store)
        state.openTodayEditor(); let clean = try #require(state.todayEditor)
        #expect(try store.todayDraft() == nil)
        clean.finish(discarding: true)
        #expect(state.todayEditor == nil)
        #expect(try store.todayConfiguration() == base)
        state.openTodayEditor(); let model = try #require(state.todayEditor)
        model.begin(TodayWidgetInstance(kind: .personalNote))
        let fullText = String(repeating: "A complete private note. ", count: 1000)
        model.nested { $0.options?.personal?.text = fullText }
        #expect(model.canApply)
        #expect(try store.todayConfiguration() == base)
        model.cancelNested()
        #expect(model.draft.value == base)
        model.begin(TodayWidgetInstance(kind: .personalNote)); model.nested { $0.options?.personal?.text = fullText }; model.applyNested()
        #expect(try store.todayConfiguration() == base)
        let original = try #require(model.draft.value.instances.last)
        let copy = original.independentCopy()
        #expect(copy.id != original.id)
        #expect(copy.options?.personal?.id != original.options?.personal?.id)
        #expect(copy.options?.personal?.text == fullText)
        deny = true; await model.save()
        #expect(model.saved == nil && model.error != nil)
        #expect(model.draft.value.instances.last?.options?.personal?.text == fullText)
        #expect(try store.todayConfiguration() == base)
        deny = false; await model.save()
        #expect(state.todayEditor == nil)
        #expect(try store.todayPersonalCards().first?.text == fullText)
        #expect(try store.wearRecords().isEmpty)
    }
    @Test func populatedV16MigrationKeepsOwnerOrderAndJournalPayload() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var layout = TodayConfiguration(ownerID: UUID()); layout.instances = [TodayWidgetInstance(kind: .wearAgain)]
        let identity = LocalProfileIdentity(ownerID: layout.ownerID, name: "Kept", photoID: nil, revision: 1)
        do {
            let schema = Schema(versionedSchema: LocalSchemaV16.self)
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)])
            let context = ModelContext(container)
            context.insert(StoredTodayConfiguration(layout)); context.insert(try StoredLocalExperience(LocalExperience(enteredPrivateSpace: true)))
            context.insert(try StoredLocalIdentity(identity)); try context.save()
        }
        try Data("AQD-piece-store:16".utf8).write(to: directory.appendingPathComponent("schema-version"))
        let migrated = try PieceStore(directory: directory)
        #expect(try migrated.todayConfiguration() == layout)
        #expect(try migrated.localIdentity() == identity)
        #expect(try migrated.todayPersonalCards().isEmpty)
        #expect(try PieceStore(directory: directory).todayConfiguration() == layout)
    }
}
