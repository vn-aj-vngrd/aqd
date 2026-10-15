import AQDCore
import Foundation
import SwiftData
import Testing
@testable import AQD

@Suite(.serialized) @MainActor
struct StylePersistenceTests {
    private func complete() -> StylePreferences {
        var value = StylePreferences()
        for step in 0..<4 { value.choose("No preference", at: step) }
        value.body.decline(); value.colors.declined = true
        return value
    }

    @Test func editingUsesAnIndependentValueWhileClosureReadsTheCurrentStep() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let state = AppState(store: try PieceStore(directory: directory))
        defer { state.styleEditor = nil; state.store = nil }
        state.openStyle(source: .profile)
        let editor = try #require(state.styleEditor)
        editor.update { $0.answers.choose("Wear more of my closet", at: editor.draft.page) }
        #expect(editor.draft.answers.goals == ["Wear more of my closet"])
        #expect(try #require(state.store).localExperience().styleDraft == editor.draft)
    }

    @Test func draftResumesSourceAndDiscardPreservesSavedPreferences() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        var draft = StylePreferenceDraft(source: .settings, answers: complete())
        draft.page = 6
        try #require(store).saveStyleDraft(draft)
        let saved = try #require(store).saveStylePreferences(draft)
        #expect(saved.revision == 1)
        #expect(try #require(store).saveStylePreferences(draft) == saved)
        try #require(store).acknowledgeStyleReceipt(operationID: draft.operationID)
        var edit = StylePreferenceDraft(source: .profile, baseRevision: 1, answers: saved.answers)
        edit.answers.choose("Classic", at: 2); edit.page = 2
        try #require(store).saveStyleDraft(edit)
        store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).localExperience().styleDraft == edit)
        try #require(store).discardStyleDraft(id: edit.id)
        #expect(try #require(store).localExperience().style == saved)
        #expect(try #require(store).pieces().isEmpty)
        store = nil
    }

    @Test func deniedAtomicSaveKeepsDraftAndPriorSavedAnswersAcrossRestart() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var denied = false
        var store: PieceStore? = try PieceStore(directory: directory, beforeStyleSave: {
            if denied { throw CocoaError(.fileWriteNoPermission) }
        })
        let first = StylePreferenceDraft(source: .profile, answers: complete())
        try #require(store).saveStyleDraft(first)
        let saved = try #require(store).saveStylePreferences(first)
        try #require(store).acknowledgeStyleReceipt(operationID: first.operationID)
        var edit = StylePreferenceDraft(source: .settings, baseRevision: 1, answers: complete())
        edit.answers.choose("Classic", at: 2)
        try #require(store).saveStyleDraft(edit)
        denied = true
        #expect(throws: (any Error).self) { try #require(store).saveStylePreferences(edit) }
        store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).localExperience().style == saved)
        #expect(try #require(store).localExperience().styleDraft == edit)
        let retried = try #require(store).saveStylePreferences(edit)
        #expect(retried.revision == 2)
        #expect(retried.operationID == edit.operationID)
        #expect(try #require(store).saveStylePreferences(edit) == retried)
        store = nil
    }

    @Test func lostAcknowledgmentReconcilesSameOperationWithoutDuplicateWrite() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory, afterStyleSave: { throw CocoaError(.fileReadUnknown) })
        let draft = StylePreferenceDraft(source: .settings, answers: complete())
        try #require(store).saveStyleDraft(draft)
        #expect(throws: (any Error).self) { try #require(store).saveStylePreferences(draft) }
        store = nil
        store = try PieceStore(directory: directory)
        let result = try #require(store).saveStylePreferences(draft)
        #expect(result.revision == 1)
        #expect(result.answers == draft.answers)
        #expect(try #require(store).localExperience().styleDraft == nil)
        #expect(try #require(store).localExperience().pendingStyleReceipt == draft)
        let state = AppState(store: try #require(store))
        #expect(state.styleEditor?.saved == result)
        #expect(state.profileSettings)
        state.styleEditor?.finish()
        #expect(state.styleEditor == nil)
        #expect(try #require(store).localExperience().pendingStyleReceipt == nil)
        state.store = nil
        store = nil
    }

    @Test func populatedV2MigrationPreservesPiecesDraftsTodayAndMediaAcrossReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("media"), withIntermediateDirectories: true)
        let today = TodayConfiguration(ownerID: UUID())
        let photoID = UUID()
        let piece = WardrobePiece(id: UUID(), name: "Existing private piece", category: .tops, photoID: photoID)
        let draft = PieceDraft(name: "Existing interrupted capture")
        let operationID = UUID()
        let media = Data([1, 2, 3, 4])
        let photoURL = directory.appendingPathComponent("media/\(photoID.uuidString).jpg")
        try media.write(to: photoURL)
        do {
            let schema = Schema(versionedSchema: LocalSchemaV2.self)
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema,
                url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)])
            let context = ModelContext(container)
            context.insert(StoredTodayConfiguration(today))
            context.insert(StoredPiece(piece))
            context.insert(StoredPhoto(id: photoID, pixelWidth: 1, pixelHeight: 1))
            context.insert(StoredPieceDraft(draft: draft, operationID: operationID, payload: try JSONEncoder().encode(draft)))
            try context.save()
        }
        try Data("AQD-piece-store:2".utf8).write(to: directory.appendingPathComponent("schema-version"))
        var store: PieceStore? = try PieceStore(directory: directory)
        #expect(try #require(store).piece(id: piece.id) == piece)
        #expect(try #require(store).todayConfiguration() == today)
        #expect(try #require(store).latestDraft()?.draft == draft)
        #expect(try #require(store).localExperience().enteredPrivateSpace)
        #expect(try #require(store).localExperience().style == nil)
        store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).piece(id: piece.id) == piece)
        #expect(try #require(store).todayConfiguration() == today)
        #expect(try Data(contentsOf: photoURL) == media)
        store = nil
    }
}
