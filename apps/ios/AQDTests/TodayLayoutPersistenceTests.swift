import AQDCore
import Foundation
import SwiftData
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor
struct TodayLayoutPersistenceTests {
    @Test func visibilityIsDraftOnlyReversibleAndSurvivesSaveWithoutDroppingSettings() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let state = AppState(store: store), base = try store.todayConfiguration()
        #expect(base.instances.count == 12 && base.instances.allSatisfy(\.isVisible))
        state.openTodayEditor(); let model = try #require(state.todayEditor)
        let instance = try #require(model.catalog.first)
        model.setVisibility(instance.id, visible: false)
        #expect(model.draft.hasChanges)
        #expect(try store.todayConfiguration() == base)
        model.setVisibility(instance.id, visible: true)
        #expect(!model.draft.hasChanges)
        model.setVisibility(instance.id, visible: false)
        await model.save()
        #expect(state.todayEditor == nil)
        let reopened = try PieceStore(directory: store.localDirectory)
        let saved = try reopened.todayConfiguration()
        #expect(saved.instances.count == 12)
        #expect(saved.instances.first?.id == instance.id)
        #expect(saved.instances.first?.isVisible == false)
        #expect(saved.instances.first?.options == instance.options)
        #expect(try reopened.wearRecords().isEmpty)
        let decoded = try JSONDecoder().decode(TodayConfiguration.self, from: JSONEncoder().encode(saved))
        #expect(decoded == saved)
    }

    @Test func legacyMissingWidgetVisibilityCanBeRevertedWithoutChanges() throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        var base = try store.todayConfiguration()
        base.instances = Array(base.instances.prefix(3))
        let model = TodayEditorModel(state: AppState(store: store), draft: TodayLayoutDraft(base: base))
        let missing = try #require(model.catalog.first { $0.kind == .quickActions })
        model.setVisibility(missing.id, visible: true)
        #expect(model.draft.hasChanges)
        model.setVisibility(missing.id, visible: false)
        #expect(!model.draft.hasChanges)
        #expect(model.draft.value == base)
    }

    @Test func addOffersOnlyMissingKindsAndRemovingMakesThemAvailableAgain() throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let state = AppState(store: store)
        state.openTodayEditor()
        let model = try #require(state.todayEditor)
        #expect(!model.availableKinds.contains(.todayLook))
        let before = model.draft
        model.beginNew(.todayLook)
        #expect(model.draft == before)
        let originalQuick = try #require(model.draft.value.instances.first { $0.kind == .quickActions })
        model.update { try $0.remove(originalQuick.id) }
        model.beginNew(.quickActions)
        try #require(model.canApply)
        model.applyNested()
        #expect(!model.availableKinds.contains(.quickActions))
        let after = model.draft
        model.beginNew(.quickActions)
        #expect(model.draft == after)
        let added = try #require(model.draft.value.instances.first { $0.kind == .quickActions })
        model.update { try $0.remove(added.id) }
        #expect(model.availableKinds.contains(.quickActions))
        model.beginNew(.quickActions)
        model.nested { $0.kind = .todayLook }
        #expect(!model.canApply)
        let unchangedInstances = model.draft.value.instances
        model.applyNested()
        #expect(model.draft.value.instances == unchangedInstances)
        model.cancelNested()
        // Retained legacy duplicates remain editable without introducing another kind.
        let legacy = TodayWidgetInstance(kind: .todayLook)
        model.update { $0.value.instances.append(legacy) }
        model.begin(legacy)
        #expect(model.canApply)
        model.cancelNested()
        #expect(try store.todayConfiguration().instances.count == 12)
    }

    @Test func everyWidgetCanConfigureReorderDuplicateRestoreAndSaveWithoutChangingWear() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let base = try store.todayConfiguration()
        var themeDraft = ThemeDraft(ownerID: base.ownerID); themeDraft.name = "Widget capsule"
        try store.saveThemeDraft(themeDraft)
        let theme = try store.saveTheme(themeDraft); try store.finishThemeDraft(themeDraft)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in
            UIColor.brown.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32))
        }
        let data = try #require(image.jpegData(compressionQuality: 0.9))
        let photo = try await PhotoPreparer().prepare(data: data)
        let state = AppState(store: store); state.openTodayEditor()
        let model = try #require(state.todayEditor)
        for kind in TodayWidgetKind.allCases {
            model.begin(model.draft.value.instances.first(where: { $0.kind == kind }) ?? TodayWidgetInstance(kind: kind))
            switch kind {
            case .personalNote:
                #expect(!model.canApply)
                model.nested { $0.options?.personal?.text = "A private outfit thought" }
            case .personalPhoto:
                _ = try store.acceptPhoto(photo)
                #expect(!model.canApply)
                model.nested { $0.options?.personal?.photoID = photo.id }
            case .theme:
                #expect(!model.canApply)
                model.nested { $0.options?.pinnedID = theme.id }
            case .upcomingPlans: model.nested { $0.options?.upcomingDays = 14 }
            case .quickActions: model.nested { $0.options?.actions = [.addFit, .recordWear] }
            default: break
            }
            try #require(model.canApply)
            model.applyNested()
            #expect(model.draft.nested == nil)
            #expect(model.error == nil)
        }
        #expect(try store.todayConfiguration() == base)
        let note = try #require(model.draft.value.instances.first { $0.kind == .personalNote })
        let duplicate = note.independentCopy()
        model.update { $0.value.instances.append(duplicate) }
        #expect(duplicate.options?.personal?.id != note.options?.personal?.id)
        model.move(duplicate.id, by: -1)
        #expect(model.draft.value.instances.dropLast().last?.id == duplicate.id)
        model.update { try $0.remove(note.id) }
        let beforeDefaults = model.draft.value.instances
        model.update { $0.restoreDefaults() }
        #expect(model.draft.value.instances.map(\.kind) == TodayWidgetKind.allCases)
        model.update { $0.undoDefaults() }
        #expect(model.draft.value.instances == beforeDefaults)
        model.begin(try #require(model.draft.value.instances.first))
        model.cancelNested()
        #expect(model.draft.value.instances == beforeDefaults)
        await model.save()
        #expect(state.todayEditor == nil)
        let reopened = try PieceStore(directory: store.localDirectory)
        #expect(try reopened.todayConfiguration().instances == beforeDefaults)
        #expect(try reopened.wearRecords().isEmpty)
        #expect(try reopened.todayPersonalCards().contains { $0.photoID == photo.id })
        let personalBefore = try reopened.todayPersonalCards()
        let photoWidget = try #require(try reopened.todayConfiguration().instances.first { $0.kind == .personalPhoto })
        let nextState = AppState(store: reopened); nextState.openTodayEditor()
        let visibility = try #require(nextState.todayEditor)
        visibility.setVisibility(photoWidget.id, visible: false)
        await visibility.save()
        #expect(nextState.todayEditor == nil)
        #expect(try reopened.todayConfiguration().instances.first { $0.id == photoWidget.id }?.isVisible == false)
        #expect(try reopened.todayPersonalCards() == personalBefore)
        let retainedPhoto = try reopened.photoRendition(id: photo.id, recipe: .fitOriginal)
        #expect(!retainedPhoto.isEmpty)
    }

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
        #expect(defaults.value.instances.map(\.kind) == TodayWidgetKind.allCases)
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
        model.begin(try #require(model.draft.value.instances.first { $0.kind == .personalNote }))
        let fullText = String(repeating: "A complete private note. ", count: 1000)
        model.nested { $0.options?.personal?.text = fullText }
        #expect(model.canApply)
        #expect(try store.todayConfiguration() == base)
        model.cancelNested()
        #expect(model.draft.value == base)
        model.begin(try #require(model.draft.value.instances.first { $0.kind == .personalNote })); model.nested { $0.options?.personal?.text = fullText }; model.applyNested()
        #expect(try store.todayConfiguration() == base)
        let original = try #require(model.draft.value.instances.first { $0.kind == .personalNote })
        let copy = original.independentCopy()
        #expect(copy.id != original.id)
        #expect(copy.options?.personal?.id != original.options?.personal?.id)
        #expect(copy.options?.personal?.text == fullText)
        deny = true; await model.save()
        #expect(model.saved == nil && model.error != nil)
        #expect(model.draft.value.instances.first { $0.kind == .personalNote }?.options?.personal?.text == fullText)
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
    @Test func reopeningFromAnOldCardSnapshotKeepsTheAcknowledgedNewerText() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), store = try PieceStore(directory: directory)
        let state = AppState(store: store)
        state.openTodayEditor(); let first = try #require(state.todayEditor)
        first.begin(try #require(first.draft.value.instances.first { $0.kind == .personalNote })); first.nested { $0.options?.personal?.text = "Original note" }; first.applyNested(); await first.save()
        let oldSnapshot = try #require(state.today?.instances.first { $0.kind == .personalNote })
        state.openTodayEditor(); let edit = try #require(state.todayEditor)
        edit.begin(oldSnapshot); edit.nested { $0.options?.personal?.text = "Acknowledged new note" }; edit.applyNested(); await edit.save()
        state.openTodayEditor(); let reopened = try #require(state.todayEditor)
        reopened.begin(oldSnapshot)
        #expect(reopened.draft.nested?.options?.personal?.text == "Acknowledged new note")
        reopened.cancelNested(); reopened.finish(discarding: true)
        #expect(try store.todayPersonalCards().first?.text == "Acknowledged new note")
    }

}
