import Foundation
import Testing
@testable import AQDCore

struct AgentTidyTests {
    private func piece(_ name: String, archived: Bool = false, revision: Int = 2) -> WardrobePiece {
        WardrobePiece(id: UUID(), name: name, category: .tops, photoID: UUID(), revision: revision, isArchived: archived)
    }

    @Test func archiveReviewNamesEveryPieceAndStartsSelected() throws {
        let shirt = piece("Linen shirt"), tee = piece("White tee")
        let request = AgentMutationRequest(kind: .tidyPieces, pieceIDs: [shirt.id, tee.id], tidyOp: .archive)
        guard case .tidy(let change) = try request.prepare(ownerID: UUID(), pieces: [shirt, tee]) else { Issue.record("Expected a tidy review"); return }
        #expect(change.op == .archive && change.items.map(\.name) == ["Linen shirt", "White tee"])
        #expect(change.selectedItems.count == 2 && change.items.allSatisfy { $0.expectedRevision == 2 })
        #expect(change.summary == "Archive 2 pieces")
    }

    @Test func unticking_aPieceRemovesItFromTheApprovedSet() throws {
        let a = piece("A"), b = piece("B")
        var change = AgentTidyChange(op: .archive, pieces: [a, b])
        change.setSelected(a.id, false)
        #expect(change.selectedItems.map(\.id) == [b.id] && change.summary == "Archive 1 piece")
        change.setSelected(UUID(), false)
        #expect(change.items.count == 2)
    }

    @Test func tidyRejectsUnknownMissingAndWrongStatePieces() {
        let live = piece("Live"), shelved = piece("Shelved", archived: true)
        func prepare(_ ids: [UUID], _ op: AgentTidyOp?) throws -> AgentReviewedAction {
            try AgentMutationRequest(kind: .tidyPieces, pieceIDs: ids, tidyOp: op).prepare(ownerID: UUID(), pieces: [live, shelved])
        }
        #expect(throws: (any Error).self) { try prepare([UUID()], .archive) }
        #expect(throws: (any Error).self) { try prepare([], .archive) }
        #expect(throws: (any Error).self) { try prepare([live.id], nil) }
        #expect(throws: (any Error).self) { try prepare([shelved.id], .archive) }
        #expect(throws: (any Error).self) { try prepare([shelved.id], .delete) }
        #expect(throws: (any Error).self) { try prepare([live.id], .unarchive) }
        #expect(throws: Never.self) { _ = try prepare([shelved.id], .unarchive) }
    }

    @Test func aTidyNeverNamesMoreThanTwelvePieces() {
        let pieces = (0..<13).map { piece("P\($0)") }
        #expect(throws: (any Error).self) {
            try AgentMutationRequest(kind: .tidyPieces, pieceIDs: pieces.map(\.id), tidyOp: .archive).prepare(ownerID: UUID(), pieces: pieces)
        }
    }

    @Test func deleteSummaryStatesItCannotBeUndone() {
        let change = AgentTidyChange(op: .delete, pieces: [piece("Old coat")])
        #expect(AgentReviewedAction.tidy(change).savesSummary.contains("can’t be undone"))
        #expect(AgentTidyOp.delete.isDestructive && !AgentTidyOp.archive.isDestructive)
    }

    @Test func undoIsOfferedOnlyWhileTheRecordIsUnchanged() {
        let id = UUID()
        let undo = AgentUndo.availability(pieceID: id, previous: .available, appliedRevision: 5)
        #expect(undo.isEligible(currentRevisions: [id: 5]))
        #expect(!undo.isEligible(currentRevisions: [id: 6]))
        #expect(!undo.isEligible(currentRevisions: [:]))
        let archive = AgentUndo.archive([.init(pieceID: id, wasArchived: false, appliedRevision: 3), .init(pieceID: UUID(), wasArchived: false, appliedRevision: 1)])
        #expect(!archive.isEligible(currentRevisions: [id: 3]))
    }

    @Test func receiptOffersUndoUntilItIsUsed() {
        var receipt = AgentActionReceipt(recordID: UUID(), kind: "piece", undo: .availability(pieceID: UUID(), previous: .available, appliedRevision: 2))
        #expect(receipt.canOfferUndo)
        receipt.undoneAt = Date()
        #expect(!receipt.canOfferUndo)
        #expect(!AgentActionReceipt(recordID: UUID(), kind: "outfit").canOfferUndo)
    }

    @Test func proposalsSavedBeforeUndoStillDecode() throws {
        let old = #"{"recordID":"\#(UUID().uuidString)","kind":"piece","acknowledgedAt":0}"#
        let receipt = try JSONDecoder().decode(AgentActionReceipt.self, from: Data(old.utf8))
        #expect(receipt.undo == nil && receipt.count == nil && !receipt.canOfferUndo)
    }

    @Test func tidyRoutesToTheTidyToolWithBoundedTools() {
        #expect(AgentIntent.classify("Archive my old summer tops").tools(weatherAvailable: false) == [.tidyCloset, .findRecords, .askUser])
        #expect(AgentIntent.classify("Delete the old blue shirt from my closet") == .tidy)
        #expect(AgentIntent.classify("Restore my linen shirt to my closet") == .tidy)
        #expect(AgentIntent.classify("Delete my Date night outfit") != .tidy)
        #expect(AgentIntent.classify("Plan my week of outfits") == .planDays)
        #expect(AgentIntent.allCases.allSatisfy { $0.tools(weatherAvailable: true).count <= 3 })
    }

    @Test func notesStayOutOfTheModelUntilTheOwnerSwitchesThemOn() throws {
        var preferences = AgentPreferences()
        #expect(!preferences.allows(.notes) && preferences.allows(.pieces))
        // A list stored before this rule still names notes, but they do not count.
        var legacy = AgentPreferences()
        legacy.sources = AgentDataSource.allCases
        #expect(!legacy.allows(.notes))
        preferences.set(.notes, enabled: true)
        #expect(preferences.allows(.notes))
        preferences.set(.notes, enabled: false)
        #expect(!preferences.allows(.notes))
        let decoded = try JSONDecoder().decode(AgentPreferences.self, from: JSONEncoder().encode(legacy))
        #expect(!decoded.allows(.notes))
    }
}
