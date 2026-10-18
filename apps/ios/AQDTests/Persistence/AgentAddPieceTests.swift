import AQDCore
import Foundation
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor struct AgentAddPieceTests {
    private func makeModel() throws -> (AgentModel, PieceStore, AgentActionProposal) {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let model = try AgentModel(store: store)
        let request = AgentMutationRequest(kind: .addPiece, name: "Navy tee", color: "Navy", category: "tops", attachmentID: UUID())
        model.propose(try request.prepare(ownerID: model.conversation.ownerID))
        return (model, store, model.conversation.proposals![0])
    }

    @Test func cancellingTheReviewWritesNothing() throws {
        let (model, store, proposal) = try makeModel()
        guard case .piece(let change) = proposal.action else { Issue.record("Expected piece"); return }
        #expect(change.draft.category == .tops && change.draft.photoID == nil)
        model.approveProposal(proposal.id, version: proposal.version)
        model.cancelProposal(proposal.id)
        model.approveProposal(proposal.id, version: proposal.version)
        #expect(try store.pieces().isEmpty && store.newPieceDraft() == nil)
        #expect(model.conversation.proposals?.first?.status == .cancelled)
    }

    @Test func aRepeatedSaveAcknowledgementCreatesOnePieceAndOneReceipt() throws {
        let (model, store, proposal) = try makeModel()
        guard case .piece(let change) = proposal.action else { Issue.record("Expected piece"); return }
        let data = try #require(UIGraphicsImageRenderer(size: CGSize(width: 20, height: 30)).image { _ in }.jpegData(compressionQuality: 1))
        var draft = change.draft
        draft.photoID = try store.acceptPhoto(PreparedPhoto(id: UUID(), originalData: data, thumbnailData: data, pixelWidth: 20, pixelHeight: 30))
        let operationID = UUID()
        // The first save's acknowledgement was lost; the retry reuses the operation and must find the same piece.
        let first = try store.savePiece(draft, operationID: operationID)
        let retry = try store.savePiece(draft, operationID: operationID)
        let count = try store.pieces().count
        #expect(first.id == retry.id && count == 1)
        model.completeAddedPiece(proposal.id, piece: first)
        model.completeAddedPiece(proposal.id, piece: retry)
        let saved = try #require(model.conversation.proposals?.first)
        #expect(saved.status == .succeeded && saved.receipt?.recordID == first.id && saved.receipt?.kind == "piece")
    }
}
