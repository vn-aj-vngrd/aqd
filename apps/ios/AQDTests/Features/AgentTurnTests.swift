import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct AgentTurnTests {
    private let qualification = AgentQualification(maximumPieces: 8, maximumPromptCharacters: 20000, responseTokens: 300, slowSeconds: 0.2, timeoutSeconds: 3)

    private func wait(_ model: AgentModel) async throws {
        for _ in 0..<400 { if !model.active { return }; try await Task.sleep(for: .milliseconds(5)) }
        Issue.record("Attempt did not stop")
    }
    private func closet() async throws -> (LocalDataFixture, PieceStore) {
        let fixture = try await LocalDataFixture()
        for (name, color, category) in [("Black blazer", "Black", PieceCategory.layers), ("Black trousers", "Black", .bottoms), ("Cream blouse", "Cream", .tops)] {
            _ = try fixture.store.savePiece(PieceDraft(name: name, category: category, photoID: fixture.processed.id, details: PieceDetails(color: color)), operationID: UUID())
        }
        return (fixture, fixture.store)
    }
    private func model(_ store: PieceStore, _ replies: @escaping @MainActor ([String]) -> String, prompts: PromptLog) throws -> AgentModel {
        let model = try AgentModel(store: store, qualification: qualification) { text, _ in
            prompts.values.append(text)
            let reply = replies(prompts.values)
            return AsyncThrowingStream { $0.yield(reply); $0.finish() }
        }
        model.availability = .awaitingQualification
        return model
    }
    @MainActor final class PromptLog { var values: [String] = [] }

    @Test func showingRecordsIsDoneByTheAppAndTheModelOnlyFramesIt() async throws {
        let (_, store) = try await closet()
        let log = PromptLog()
        let model = try model(store, { _ in "Here are your black pieces." }, prompts: log)
        model.updateDraft("Show my black pieces"); model.send(); try await wait(model)
        let reply = try #require(model.conversation.messages.last)
        let cards = (reply.toolSteps ?? []).flatMap { $0.results ?? [] }.map(\.title)
        #expect(Set(cards) == ["Black blazer", "Black trousers"] && reply.status == .complete)
        #expect(log.values.count == 1 && log.values[0].contains("The app is already showing 2 of 2 matching pieces") && log.values[0].contains("Black blazer"))
        #expect(reply.diagnostics?.intent == "show" && reply.diagnostics?.toolCalls == ["showRecords (router)"])
    }
    @Test func aFramingThatDeniesTheCardsFallsBackToTheAppsOwnSentence() async throws {
        let (_, store) = try await closet()
        let log = PromptLog()
        let model = try model(store, { _ in "I couldn’t find any black pieces." }, prompts: log)
        model.updateDraft("Show my black pieces"); model.send(); try await wait(model)
        let reply = try #require(model.conversation.messages.last)
        #expect(reply.source == "Here are your 2 black pieces." && log.values.count == 1)
        #expect(reply.diagnostics?.firstViolations?.first?.hasPrefix("contradiction") == true && reply.groundingNote == nil)
    }
    @Test func aReplyThatInventsAPieceIsRegeneratedOnceWithTheProblemsAsFeedback() async throws {
        let (_, store) = try await closet()
        let log = PromptLog()
        let model = try model(store, { $0.count == 1 ? "Try the **Red tunic** with the Black blazer." : "Try the Black blazer with the Cream blouse." }, prompts: log)
        model.updateDraft("Hello, my closet is new."); model.send(); try await wait(model)
        let reply = try #require(model.conversation.messages.last)
        #expect(log.values.count == 2 && log.values[1].contains("Red tunic") && log.values[1].contains("Black blazer"))
        #expect(reply.source == "Try the Black blazer with the Cream blouse." && reply.groundingNote == nil && reply.status == .complete)
        #expect(reply.diagnostics?.firstViolations == ["invented: Red tunic"] && reply.diagnostics?.groundingViolations?.isEmpty == true)
    }
    @Test func aReplyThatStaysUngroundedKeepsAnInlineNoteAndIsNotRegeneratedTwice() async throws {
        let (_, store) = try await closet()
        let log = PromptLog()
        let model = try model(store, { _ in "Try the **Red tunic** today." }, prompts: log)
        model.updateDraft("Hello, my closet is new."); model.send(); try await wait(model)
        let reply = try #require(model.conversation.messages.last)
        #expect(log.values.count == 2 && reply.groundingNote == AgentGroundingRepair.note && reply.diagnostics?.groundingViolations == ["invented: Red tunic"])
    }
    @Test func aMissingTripLengthIsAskedByTheAppWithTappableAnswers() async throws {
        let (_, store) = try await closet()
        let log = PromptLog()
        let model = try model(store, { _ in "How long are you going?" }, prompts: log)
        model.updateDraft("Plan a trip for me"); model.send(); try await wait(model)
        let reply = try #require(model.conversation.messages.last)
        let question = try #require((reply.toolSteps ?? []).compactMap(\.question).first)
        #expect(question.prompt == "How many days is the trip?" && question.options.count == 3 && reply.diagnostics?.toolCalls == ["askUser (router)"])
        #expect(reply.diagnostics?.intent == "planTrip" && log.values[0].contains("tappable answers"))
        // The answer continues the same request.
        model.updateDraft("5 days"); model.send(); try await wait(model)
        #expect(model.conversation.messages.last?.diagnostics?.intent == "planTrip")
    }
    @Test func aFailedTurnExplainsItselfAndTheRequestComesBackForEditing() async throws {
        let (_, store) = try await closet()
        let model = try AgentModel(store: store, qualification: qualification) { _, _ in AsyncThrowingStream { $0.finish(throwing: AgentProviderError.contextLimit) } }
        model.availability = .awaitingQualification
        model.updateDraft("Hello, my closet is new."); model.send(); try await wait(model)
        let failed = try #require(model.conversation.messages.last)
        #expect(failed.status == .failed && failed.failure?.kind == .contextTooLong && failed.failure?.actions.contains(.continueWithoutCloset) == true)
        model.reviseLastRequest()
        #expect(model.conversation.messages.isEmpty && model.conversation.draft == "Hello, my closet is new.")
    }
    @Test func continuingWithoutTheClosetRetriesInGeneralMode() async throws {
        let (_, store) = try await closet()
        let log = PromptLog()
        var failFirst = true
        let model = try AgentModel(store: store, qualification: qualification) { text, _ in
            log.values.append(text)
            defer { failFirst = false }
            return failFirst ? AsyncThrowingStream { $0.finish(throwing: AgentProviderError.contextLimit) } : AsyncThrowingStream { $0.yield("A general answer."); $0.finish() }
        }
        model.availability = .awaitingQualification
        model.updateDraft("Hello, my closet is new."); model.send(); try await wait(model)
        let failed = try #require(model.conversation.messages.last)
        model.performFailureAction(.continueWithoutCloset, messageID: failed.id); try await wait(model)
        #expect(model.conversation.context.scope == .general && model.conversation.messages.last?.source == "A general answer." && model.conversation.messages.last?.failure == nil)
        #expect(log.values.last?.contains("Black blazer") == false)
    }
    @Test func longChatsSendOnlyTheLastFourTurnsAndASummaryOfTheRest() async throws {
        let (_, store) = try await closet()
        let log = PromptLog()
        let model = try model(store, { _ in "Noted." }, prompts: log)
        for n in 1...6 { model.updateDraft("Hello number \(n)"); model.send(); try await wait(model) }
        let last = try #require(log.values.last)
        #expect(last.contains("user: Hello number 5") && last.contains("user: Hello number 2") && !last.contains("user: Hello number 1"))
        #expect(last.contains("Earlier in this chat") && last.contains("Hello number 1"))
        #expect(model.conversation.summary?.contains("Hello number 2") == true)
    }
    @Test func promptsCarryNoUUIDsAndStayInsideTheBudget() async throws {
        let (fixture, store) = try await closet()
        let log = PromptLog()
        let model = try model(store, { _ in "Fine." }, prompts: log)
        model.updateDraft("Hello, my closet is new."); model.send(); try await wait(model)
        let prompt = try #require(log.values.first)
        #expect(!prompt.contains(fixture.piece.id.uuidString) && !prompt.contains(fixture.outfit.id.uuidString) && prompt.count < 8000)
        #expect(prompt.contains("Black blazer"))
    }

    @Test func aPlainCommandIsPreparedByTheRouterAndOnlyDraftsAReview() async throws {
        let (_, store) = try await closet()
        let log = PromptLog()
        let model = try model(store, { _ in "I prepared that for you to review." }, prompts: log)
        model.updateDraft("Mark my Black blazer as laundry"); model.send(); try await wait(model)
        let reply = try #require(model.conversation.messages.last)
        guard case .availability(let change)? = model.conversation.proposals?.first?.action else { Issue.record("expected an availability review"); return }
        #expect(change.pieceName == "Black blazer" && change.value == .laundry && reply.diagnostics?.toolCalls == ["editCloset (router)"])
        #expect(log.values[0].contains("Marks “Black blazer” as laundry.") && reply.status == .complete)
        #expect(try store.pieces().first { $0.name == "Black blazer" }?.availability == .available)
    }
    @Test func aNameThatFitsSeveralPiecesAsksWhichAndPreparesNothing() async throws {
        let (fixture, store) = try await closet()
        _ = try store.savePiece(PieceDraft(name: "Oatmeal blazer", category: .layers, photoID: fixture.processed.id), operationID: UUID())
        let model = try model(store, { _ in "Which one do you mean?" }, prompts: PromptLog())
        model.updateDraft("Rename my blazer to Work blazer"); model.send(); try await wait(model)
        let reply = try #require(model.conversation.messages.last)
        let question = try #require((reply.toolSteps ?? []).compactMap(\.question).first)
        #expect(Set(question.options) == ["Black blazer", "Oatmeal blazer"] && model.conversation.proposals == nil)
        #expect((reply.toolSteps ?? []).contains { $0.rejection != nil })
    }
    @Test func aNameThatFitsNothingIsAQuietStepNotAGuess() async throws {
        let (_, store) = try await closet()
        let model = try model(store, { _ in "I couldn’t find “red tunic” in your closet." }, prompts: PromptLog())
        model.updateDraft("Mark my red tunic as laundry"); model.send(); try await wait(model)
        let reply = try #require(model.conversation.messages.last)
        #expect(model.conversation.proposals == nil && (reply.toolSteps ?? []).contains { $0.summary == "Couldn’t find “red tunic” in your closet" })
    }
    @Test func findingARecordShowsCardsAndNothingElseIsInvented() async throws {
        let (_, store) = try await closet()
        let log = PromptLog()
        let model = try model(store, { _ in "Yes, you have the Black blazer." }, prompts: log)
        model.updateDraft("Do I own a blazer?"); model.send(); try await wait(model)
        let reply = try #require(model.conversation.messages.last)
        #expect((reply.toolSteps ?? []).flatMap { $0.results ?? [] }.map(\.title) == ["Black blazer"] && reply.diagnostics?.toolCalls == ["findRecords (router)"])
        model.updateDraft("Do I own a purple tuxedo?"); model.send(); try await wait(model)
        #expect(log.values.last?.contains("nothing matches") == true)
    }

    @Test func aRequestOutsideTheAgentGetsAScopeNoteWithoutCallingTheModel() async throws {
        let (_, store) = try await closet()
        let log = PromptLog()
        let model = try model(store, { _ in "Paris." }, prompts: log)
        model.updateDraft("What’s the capital of France?"); model.send(); try await wait(model)
        let reply = try #require(model.conversation.messages.last)
        #expect(log.values.isEmpty && reply.source.contains("outside what I can help with") && reply.diagnostics?.toolCalls == [] && reply.status == .complete)
    }
    @Test func aDeclinedFramingStillLeavesCardsAndAPlainSentence() async throws {
        let (_, store) = try await closet()
        let model = try AgentModel(store: store, qualification: qualification) { _, _ in AsyncThrowingStream { $0.finish(throwing: AgentProviderError.guardrail) } }
        model.availability = .awaitingQualification
        model.updateDraft("Show my black pieces"); model.send(); try await wait(model)
        let reply = try #require(model.conversation.messages.last)
        #expect(reply.status == .complete && reply.source == "Here are your 2 black pieces." && reply.failure == nil && !(reply.toolSteps ?? []).flatMap { $0.results ?? [] }.isEmpty)
    }
    @Test func theNextDaysArePlannedByTheRouterFromSavedOutfits() async throws {
        let (_, store) = try await closet()
        let model = try model(store, { _ in "I drafted a plan for you to review." }, prompts: PromptLog())
        model.updateDraft("Plan my week"); model.send(); try await wait(model)
        let reply = try #require(model.conversation.messages.last)
        guard case .plan(let draft)? = model.conversation.proposals?.first?.action else { Issue.record("expected a plan review"); return }
        #expect(draft.slots.count == 7 && draft.slots.allSatisfy { $0.outfit != nil } && reply.diagnostics?.toolCalls == ["proposePlan (router)"])
        #expect(try store.planDefinitions().count == 1) // only the fixture's own trip; nothing was saved
    }
    @Test func repeatedHandlesInAReplyAreScrubbedNotShown() async throws {
        let (_, store) = try await closet()
        let model = try model(store, { _ in "Try p3 Black blazer with o2 Cream blouse." }, prompts: PromptLog())
        model.updateDraft("Hello, my closet is new."); model.send(); try await wait(model)
        let source = try #require(model.conversation.messages.last?.source)
        #expect(source == "Try Black blazer with Cream blouse." && model.conversation.messages.last?.diagnostics?.firstViolations?.contains { $0.hasPrefix("leak") } == true)
    }
}
