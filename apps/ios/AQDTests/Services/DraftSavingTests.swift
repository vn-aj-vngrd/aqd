import Foundation
import Testing
@testable import AQD

@MainActor
private final class FakeEditor: DraftSaving {
    struct Failure: Error {}
    var pending = false
    var unknown = false
    var saved: Int?
    var error: String?
    var commitResults: [Result<Int, Failure>] = []
    var receiptResults: [Result<Int?, Failure>] = []
    var persisted = 0
    var commits = 0
    var finished: [Bool] = []

    func persistDraft() throws { persisted += 1 }
    func commit() throws -> Int { commits += 1; return try commitResults.removeFirst().get() }
    func receipt() throws -> Int? { try receiptResults.removeFirst().get() }
    func didFinishSave(recovered: Bool) { finished.append(recovered) }
    func notSavedMessage() -> String { "not saved" }
    var unknownMessage: String { "unknown" }
}

@MainActor
struct DraftSavingTests {
    @Test func acknowledgedCommitSavesOnceAndClearsError() async {
        let editor = FakeEditor()
        editor.error = "old"
        editor.commitResults = [.success(7)]
        await editor.runSave()
        #expect(editor.saved == 7 && editor.error == nil && !editor.unknown && !editor.pending)
        #expect(editor.persisted == 1 && editor.commits == 1 && editor.finished == [false])
        await editor.runSave()
        #expect(editor.commits == 1, "a saved editor never commits again")
    }

    @Test func lostAcknowledgmentIsRecoveredFromTheReceiptWithoutRewriting() async {
        let editor = FakeEditor()
        editor.commitResults = [.failure(.init())]
        editor.receiptResults = [.success(9)]
        await editor.runSave()
        #expect(editor.saved == 9 && editor.error == nil && !editor.unknown)
        #expect(editor.commits == 1 && editor.finished == [true])
    }

    @Test func noReceiptKeepsTheDraftAndReportsNotSaved() async {
        let editor = FakeEditor()
        editor.commitResults = [.failure(.init())]
        editor.receiptResults = [.success(nil)]
        await editor.runSave()
        #expect(editor.saved == nil && editor.error == "not saved" && !editor.unknown)
    }

    @Test func unreadableReceiptMarksUnknownAndTheRetrySkipsPersistingTheDraft() async {
        let editor = FakeEditor()
        editor.commitResults = [.failure(.init()), .success(3)]
        editor.receiptResults = [.failure(.init())]
        await editor.runSave()
        #expect(editor.unknown && editor.error == "unknown" && editor.saved == nil)
        await editor.runSave()
        #expect(editor.persisted == 1, "the unknown retry does not overwrite the retained draft")
        #expect(editor.saved == 3 && !editor.unknown && editor.error == nil)
    }
}
