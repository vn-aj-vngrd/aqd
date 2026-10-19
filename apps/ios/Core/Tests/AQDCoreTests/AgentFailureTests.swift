import Foundation
import Testing
@testable import AQDCore

struct AgentFailureTests {
    @Test func everyFailureHasATitleACauseAndAWayForward() {
        for kind in AgentFailure.Kind.allCases {
            let failure = AgentFailure.make(kind)
            #expect(!failure.title.isEmpty && !failure.cause.isEmpty && !failure.actions.isEmpty)
            #expect(!failure.title.contains(" · ") && !failure.cause.contains(" · ") && Set(failure.actions).count == failure.actions.count)
        }
    }
    @Test func actionsMatchWhatWentWrong() {
        #expect(AgentFailure.make(.intelligenceOff).actions.first == .openSettings)
        #expect(AgentFailure.make(.contextTooLong).actions == [.shorten, .continueWithoutCloset, .newChat])
        #expect(AgentFailure.make(.contextTooLong, closetIncluded: false).actions == [.shorten, .newChat])
        #expect(AgentFailure.make(.timedOut).actions.contains(.retry) && AgentFailure.make(.guardrail).actions.contains(.edit))
        #expect(AgentFailure.make(.modelPreparing).actions == [.retry])
        #expect(AgentFailure.Action.shorten.title == "Try a shorter request" && AgentFailure.Action.newChat.title == "New chat")
    }
    @Test func revisingAFailedRequestReturnsItsTextAndRemovesTheTurn() throws {
        var conversation = AgentConversation(ownerID: UUID())
        conversation.draft = "Plan a very long trip"
        let attempt = try conversation.beginAttempt()
        conversation.messages[1].status = .failed; conversation.messages[1].failure = .make(.contextTooLong)
        var proposal = AgentActionProposal(action: .theme(ThemeDraft(ownerID: conversation.ownerID))); proposal.attemptID = attempt
        conversation.proposals = [proposal]
        #expect(conversation.reviseFailedRequest() == "Plan a very long trip")
        #expect(conversation.messages.isEmpty && conversation.draft == "Plan a very long trip" && conversation.proposals == nil)
    }
    @Test func aSuccessfulTurnCannotBeRevised() throws {
        var conversation = AgentConversation(ownerID: UUID())
        conversation.draft = "Hi"; _ = try conversation.beginAttempt()
        conversation.messages[1].status = .complete
        #expect(conversation.reviseFailedRequest() == nil && conversation.messages.count == 2)
    }
    @Test func oldMessagesWithoutNewFieldsStillDecode() throws {
        let message = AgentMessage(role: .assistant, source: "x", status: .complete, attemptID: UUID())
        var json = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(message)) as? [String: Any])
        for key in ["failure", "groundingNote", "toolSteps", "diagnostics"] { json[key] = nil }
        let decoded = try JSONDecoder().decode(AgentMessage.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(decoded.failure == nil && decoded.groundingNote == nil)
    }
}
