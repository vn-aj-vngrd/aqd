import AQDCore
import Foundation
import Testing
import SwiftData
@testable import AQD

@Suite(.serialized) @MainActor
struct PersonalEditorRecoveryTests {
    @Test func failedIdentityDraftRetentionCanBeDiscardedAfterStorageRecovers() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), writable = try PieceStore(directory: directory), state = AppState(store: writable)
        state.openIdentity(); let model = try #require(state.identityEditor)
        let retained = try #require(try writable.identityDraft())
        state.store = try PieceStore(directory: directory, allowsSave: false)
        model.update { $0.name = "Unsaved name" }
        #expect(model.error != nil && model.draft.name == "Unsaved name")
        #expect(try writable.identityDraft() == retained)
        state.store = writable
        model.finish(discarding: true)
        #expect(state.identityEditor == nil)
        #expect(try writable.identityDraft() == nil)
        #expect(try writable.localIdentity() == nil)
    }
    @Test func failedFitDraftRetentionCanBeDiscardedAfterStorageRecovers() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), writable = try PieceStore(directory: directory), state = AppState(store: writable)
        state.openFit(); let model = try #require(state.fitEditor)
        let retained = try #require(try writable.fitDraft())
        state.store = try PieceStore(directory: directory, allowsSave: false)
        model.update { $0.note = "Unsaved note" }
        #expect(model.error != nil && model.draft.value.note == "Unsaved note")
        #expect(try writable.fitDraft() == retained)
        state.store = writable
        model.finish(discarding: true)
        #expect(state.fitEditor == nil)
        #expect(try writable.fitDraft() == nil)
        #expect(try writable.fitMemories().isEmpty && writable.wearRecords().isEmpty)
    }
    @Test func wardrobeReadFailureSurvivesAlertDismissalUntilARealSuccessfulRead() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), store = try PieceStore(directory: directory)
        let piece = WardrobePiece(id: UUID(), name: "Existing owned piece", category: .tops, photoID: UUID())
        let schema = Schema(versionedSchema: LocalSchemaV22.self)
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)])
        let context = ModelContext(container), record = StoredPiece(piece)
        record.category = "Unreadable category"; context.insert(record); try context.save()
        let state = AppState(store: store)
        #expect(state.pieces.isEmpty && state.pieceReadError != nil)
        state.collectionError = nil
        #expect(state.pieceReadError != nil)
        record.category = PieceCategory.tops.rawValue; try context.save()
        state.reloadPieces()
        #expect(state.pieces.map(\.id) == [piece.id])
        #expect(state.pieceReadError == nil)
    }

}
