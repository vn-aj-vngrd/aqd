import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct AgentHandleTests {
    private func setUp() async throws -> (LocalDataFixture, AgentModel, UUID) {
        let fixture = try await LocalDataFixture()
        _ = try fixture.store.savePiece(PieceDraft(name: "Linen shirt", category: .tops, photoID: fixture.processed.id, details: PieceDetails(color: "Sand")), operationID: UUID())
        let model = try AgentModel(store: fixture.store)
        model.conversation.draft = "Rename my shirt"
        let attempt = try model.conversation.beginAttempt(); try #require(model.persist())
        return (fixture, model, attempt)
    }
    private func limits() -> AgentContextLimits { AgentContextLimits(catalogCharacters: 800, recordCharacters: 1500, maximumRecords: 6) }

    @Test func promptFactsRecordsAndCatalogUseHandlesAndNamesNeverUUIDs() async throws {
        let (fixture, _, _) = try await setUp()
        let result = try AgentKnowledgeSource.build(store: fixture.store, preferences: AgentPreferences(), query: "Which shirt can I wear?", currentConversationID: UUID(),
                                                    weather: nil, selection: nil, limits: limits())
        let text = result.retrieval.text
        #expect(text.contains("Synthetic shirt") && text.contains("Linen shirt") && text.contains("p1 ") && text.contains("o1 "))
        let ids = [fixture.piece.id, fixture.outfit.id, fixture.plan.id].map(\.uuidString)
        #expect(ids.allSatisfy { !text.contains($0) } && !text.lowercased().contains("revision"))
        #expect(result.index.entry(handle: "p1") != nil && result.index.entries(of: .outfit).count == 1)
    }
    @Test func lookupReturnsHandleLinesWithoutIDsOrRevisions() async throws {
        let (fixture, model, attempt) = try await setUp()
        model.recordIndex = AgentKnowledgeSource.recordIndex(pieces: try fixture.store.pieces(), outfits: try fixture.store.outfits(), themes: [], plans: [])
        let reply = try model.lookupToolRecords("shirt", conversationID: model.conversation.id, attemptID: attempt)
        #expect(reply.contains("Synthetic shirt") && reply.contains("Linen shirt") && !reply.contains(fixture.piece.id.uuidString) && !reply.lowercased().contains("revision"))
        #expect(reply.range(of: #"\bp\d+ "#, options: .regularExpression) != nil)
    }
    @Test func ambiguousReferenceAsksTheOwnerAndAMissAddsAQuietStep() async throws {
        let (fixture, model, attempt) = try await setUp()
        let index = AgentKnowledgeSource.recordIndex(pieces: try fixture.store.pieces(), outfits: [], themes: [], plans: [])
        #expect(try model.resolveToolReference("Linen shirt", kinds: [.piece], index: index, attemptID: attempt).name == "Linen shirt")
        #expect(throws: AgentToolRejection.ambiguous("shirt", ["Linen shirt", "Synthetic shirt"])) {
            try model.resolveToolReference("shirt", kinds: [.piece], index: index, attemptID: attempt)
        }
        #expect(throws: AgentToolRejection.notFound("red tunic")) {
            try model.resolveToolReference("red tunic", kinds: [.piece], index: index, attemptID: attempt)
        }
        let steps = try #require(model.conversation.messages.last?.toolSteps)
        let question = try #require(steps.compactMap(\.question).first)
        #expect(Set(question.options) == ["Linen shirt", "Synthetic shirt"])
        #expect(steps.contains { $0.summary == "Couldn’t find “red tunic” in your closet" && $0.rejection != nil })
    }
    @Test func resolvedTargetPreparesAReviewWithoutAnyModelSuppliedRevision() async throws {
        let (fixture, model, attempt) = try await setUp()
        let index = AgentKnowledgeSource.recordIndex(pieces: try fixture.store.pieces(), outfits: [], themes: [], plans: [])
        let entry = try model.resolveToolReference("Linen shirt", kinds: [.piece], index: index, attemptID: attempt)
        let message = try model.prepareToolChange(AgentMutationRequest(kind: .editPiece, targetID: entry.id, name: "Sand shirt"), conversationID: model.conversation.id, attemptID: attempt)
        #expect(message.contains("Prepared a review") && !message.contains(entry.id.uuidString))
        #expect(model.conversation.proposals?.count == 1)
        // Records are only drafted: nothing was renamed.
        #expect(try fixture.store.pieces().contains { $0.name == "Linen shirt" })
    }
    @Test func recordWearAcceptsASavedOutfitInsteadOfPieces() async throws {
        let (fixture, model, attempt) = try await setUp()
        let request = AgentMutationRequest(kind: .recordWear, date: LocalPlanDay().key, wearOutfitID: fixture.outfit.id)
        _ = try model.prepareToolChange(request, conversationID: model.conversation.id, attemptID: attempt)
        guard case .wear(let draft)? = model.conversation.proposals?.first?.action else { Issue.record("expected a wear review"); return }
        #expect(draft.outfitID == fixture.outfit.id && draft.pieceIDs == fixture.outfit.pieceIDs)
    }
}
