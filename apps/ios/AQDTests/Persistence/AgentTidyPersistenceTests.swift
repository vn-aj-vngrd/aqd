import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct AgentTidyPersistenceTests {
    private func setUp() async throws -> (LocalDataFixture, AgentModel, [WardrobePiece]) {
        let fixture = try await LocalDataFixture()
        var pieces = [fixture.piece]
        for name in ["Linen shirt", "Wool scarf"] {
            pieces.append(try fixture.store.savePiece(PieceDraft(name: name, category: .tops, photoID: fixture.processed.id), operationID: UUID()))
        }
        return (fixture, try AgentModel(store: fixture.store), pieces)
    }
    private func review(_ model: AgentModel, _ op: AgentTidyOp, _ pieces: [WardrobePiece], store: PieceStore) throws -> AgentActionProposal {
        var change = AgentTidyChange(op: op, pieces: pieces)
        if op == .delete { for i in change.items.indices { change.items[i].impact = try store.pieceDeletionImpact(id: change.items[i].id) } }
        model.propose(.tidy(change))
        return try #require(model.conversation.proposals?.last)
    }

    @Test func nothingChangesUntilApprovedAndARejectedReviewWritesNothing() async throws {
        let (fixture, model, pieces) = try await setUp()
        let proposal = try review(model, .archive, Array(pieces.dropFirst()), store: fixture.store)
        #expect(try fixture.store.pieces().count == 3 && fixture.store.pieces(archived: true).isEmpty)
        model.cancelProposal(proposal.id)
        model.approveProposal(proposal.id, version: 1)
        #expect(try fixture.store.pieces().count == 3 && model.conversation.proposals?.last?.status == .cancelled)
    }

    @Test func approvingArchivesOnlyTheTickedPiecesThenUndoRestoresThem() async throws {
        let (fixture, model, pieces) = try await setUp()
        let targets = Array(pieces.dropFirst())
        let proposal = try review(model, .archive, targets, store: fixture.store)
        model.setTidySelection(proposal.id, item: targets[1].id, selected: false)
        model.approveProposal(proposal.id, version: 1)
        #expect(try fixture.store.pieces(archived: true).map(\.id) == [targets[0].id])
        let applied = try #require(model.conversation.proposals?.last)
        #expect(applied.status == .succeeded && applied.receipt?.count == 1 && model.canUndo(applied))
        model.undoProposal(proposal.id)
        #expect(try fixture.store.pieces(archived: true).isEmpty && fixture.store.pieces().count == 3)
        let undone = try #require(model.conversation.proposals?.last)
        #expect(undone.receipt?.undoneAt != nil && !model.canUndo(undone))
    }

    @Test func undoIsRefusedOnceThePieceChangedSinceTheApply() async throws {
        let (fixture, model, pieces) = try await setUp()
        let proposal = try review(model, .archive, [pieces[1]], store: fixture.store)
        model.approveProposal(proposal.id, version: 1)
        let archived = try #require(fixture.store.pieces(archived: true).first)
        _ = try fixture.store.setArchived(id: archived.id, archived: false, expectedRevision: archived.revision, operationID: UUID())
        #expect(!model.canUndo(try #require(model.conversation.proposals?.last)))
        model.undoProposal(proposal.id)
        #expect(model.error != nil && model.conversation.proposals?.last?.receipt?.undoneAt == nil)
    }

    @Test func aTidyReviewedBeforeAPieceChangedIsNotApplied() async throws {
        let (fixture, model, pieces) = try await setUp()
        let proposal = try review(model, .archive, [pieces[1], pieces[2]], store: fixture.store)
        _ = try fixture.store.setAvailability(id: pieces[2].id, value: .laundry, expectedRevision: pieces[2].revision, operationID: UUID())
        model.approveProposal(proposal.id, version: 1)
        #expect(try fixture.store.pieces(archived: true).isEmpty)
        #expect(model.conversation.proposals?.last?.status == .proposed)
    }

    @Test func deleteRemovesTheTickedPiecesAndCannotBeUndone() async throws {
        let (fixture, model, pieces) = try await setUp()
        let proposal = try review(model, .delete, [pieces[1]], store: fixture.store)
        model.approveProposal(proposal.id, version: 1)
        #expect(try fixture.store.pieces().map(\.id).contains(pieces[1].id) == false)
        let applied = try #require(model.conversation.proposals?.last)
        #expect(applied.status == .succeeded && applied.receipt?.undo == nil && !model.canUndo(applied))
    }

    @Test func approvingAnAvailabilityChangeKeepsAnUndoForTheFirstApply() async throws {
        let (fixture, model, pieces) = try await setUp()
        let change = AgentAvailabilityChange(piece: pieces[1], value: .laundry)
        model.propose(.availability(change))
        let proposal = try #require(model.conversation.proposals?.last)
        model.approveProposal(proposal.id, version: 1)
        #expect(try fixture.store.pieces().first { $0.id == pieces[1].id }?.availability == .laundry)
        #expect(model.canUndo(try #require(model.conversation.proposals?.last)))
        model.undoProposal(proposal.id)
        #expect(try fixture.store.pieces().first { $0.id == pieces[1].id }?.availability == .available)
    }

    @Test func rejectingWithAReasonCancelsAndQueuesAFollowUp() async throws {
        let (fixture, model, pieces) = try await setUp()
        let proposal = try review(model, .archive, [pieces[1]], store: fixture.store)
        model.rejectProposal(proposal.id, reason: "keep the linen one")
        #expect(model.conversation.proposals?.last?.status == .cancelled)
        #expect(try fixture.store.pieces(archived: true).isEmpty)
        #expect(model.conversation.draft.contains("keep the linen one") || model.conversation.messages.contains { $0.source.contains("keep the linen one") })
    }
}
