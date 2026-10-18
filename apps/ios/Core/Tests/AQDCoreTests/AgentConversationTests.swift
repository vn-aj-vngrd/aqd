import Foundation
import Testing
@testable import AQDCore

struct AgentConversationTests {
    @Test func emptyCompletionIsRefusedAndRetryClearsPriorFailure() throws {
        var conversation = AgentConversation(ownerID: UUID())
        conversation.draft = "A look"
        let attempt = try conversation.beginAttempt()
        #expect(throws: (any Error).self) { try conversation.complete(attemptID: attempt) }
        conversation.interruptActiveAttempt()
        conversation.messages[1].failureReason = "Previous failure"
        let retry = try conversation.retry(messageID: conversation.messages[1].id)
        #expect(conversation.messages[1].failureReason == nil)
        try conversation.append("A new response", attemptID: retry)
        try conversation.complete(attemptID: retry)
        #expect(conversation.messages[1].status == .complete && conversation.messages[1].failureReason == nil)
    }
    @Test func anInterruptedAttemptPreservesInputAndPartialOutputWithoutDuplicatingTheTurn() throws {
        var conversation = AgentConversation(ownerID: UUID())
        conversation.draft = "A relaxed look"
        let attempt = try conversation.beginAttempt()
        try conversation.append("A **relaxed", attemptID: attempt)
        conversation.interruptActiveAttempt()
        #expect(conversation.messages.count == 2)
        #expect(conversation.messages[0].source == "A relaxed look")
        #expect(conversation.messages[1].source == "A **relaxed")
        #expect(conversation.messages[1].status == .interrupted)
        #expect(throws: (any Error).self) { try conversation.append("late", attemptID: attempt) }
        let retry = try conversation.retry(messageID: conversation.messages[1].id)
        #expect(conversation.messages.count == 2 && retry != attempt)
        #expect(conversation.messages[0].source == "A relaxed look")
        try conversation.append("New actual response", attemptID: retry)
        try conversation.complete(attemptID: retry)
        #expect(conversation.messages[1].status == .complete)
        #expect(conversation.messages[1].versions.first?.source == "A **relaxed")
    }
    @Test func aProposalStaysLinkedToItsMessageThroughRetryAndReload() throws {
        var conversation = AgentConversation(ownerID: UUID())
        conversation.draft = "Make an outfit"
        let attempt = try conversation.beginAttempt()
        try conversation.append("Here is a draft.", attemptID: attempt)
        try conversation.complete(attemptID: attempt)
        var proposal = AgentActionProposal(action: .outfit(OutfitDraft(ownerID: conversation.ownerID)))
        proposal.attemptID = attempt
        conversation.proposals = [proposal]
        let message = conversation.messages[1]
        #expect(conversation.proposals(for: message).map(\.id) == [proposal.id])
        #expect(conversation.proposals(for: conversation.messages[0]).isEmpty && conversation.unlinkedProposals.isEmpty)

        let retry = try conversation.retry(messageID: message.id)
        #expect(retry != attempt)
        #expect(conversation.proposals(for: conversation.messages[1]).map(\.id) == [proposal.id])

        let data = try JSONEncoder().encode(conversation)
        let reloaded = try JSONDecoder().decode(AgentConversation.self, from: data)
        #expect(reloaded.proposals(for: reloaded.messages[1]).map(\.id) == [proposal.id])
        #expect(reloaded.unlinkedProposals.isEmpty)
    }
}
