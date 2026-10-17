import Foundation
import SwiftData
import Testing
import AQDCore
@testable import AQD

@Suite(.serialized) @MainActor struct AgentReliabilityPersistenceTests {
    @Test(arguments: [false, true]) func responseFeedbackRetryIsBoundToOneAttemptAndKeepsTypedDraft(lostAcknowledgment: Bool) throws {
        var before = false, after = false
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            beforeOutfitSave: { if before { throw CocoaError(.fileWriteNoPermission) } },
            afterOutfitSave: { if after { throw CocoaError(.fileReadUnknown) } })
        let agent = try AgentModel(store: store)
        agent.conversation.draft = "An outfit"
        let attempt = try agent.conversation.beginAttempt(); try agent.conversation.append("Try your blue shirt.", attemptID: attempt); try agent.conversation.complete(attemptID: attempt)
        try #require(agent.persist())
        let message = try #require(agent.conversation.messages.last)
        let feedback = AgentFeedback(rating: .helpful, conversationID: agent.conversation.id, messageID: message.id, attemptID: attempt)
        before = !lostAcknowledgment; after = lostAcknowledgment
        #expect(!agent.saveFeedback(feedback) && agent.hasPendingOperation)
        agent.updateDraft("A newer typed draft")
        before = false; after = false; agent.retryPending()
        #expect(!agent.hasPendingOperation && agent.conversation.draft == "A newer typed draft")
        let saved = try #require(store.agentConversations().first)
        #expect(saved.messages.last?.feedback?.map(\.id) == [feedback.id])
        #expect(saved.messages.last?.feedback?.first?.attemptID == attempt)
    }
    @Test func feedbackDeletionRedactsReceiptsWithoutBreakingAcknowledgmentRetry() throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let model = try AgentControlsModel(store: store)
        var feedback = AgentFeedback(isReport: true); feedback.comment = "PRIVATE_REPORT_SENTINEL"
        let original = LocalSettingsRequest(base: try store.localSettings(), feedback: [feedback])
        _ = try store.saveLocalSettings(original); model.reload()
        try #require(model.saveGeneralFeedback(feedback, removing: true))
        #expect(try store.localSettings().feedback?.isEmpty == true)
        #expect(try store.saveLocalSettings(original).feedback?.isEmpty == true)
        #expect(try PieceStore(directory: store.localDirectory).localSettings().feedback?.isEmpty == true)
    }
    @Test func disabledSourcesDoNotContributeFactsOrRecords() throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        var preferences = AgentPreferences()
        for source in AgentDataSource.allCases { preferences.set(source, enabled: false) }
        let result = try AgentKnowledgeSource.build(store: store, preferences: preferences, query: "What can I wear?", currentConversationID: UUID(), weather: nil, selection: nil, maximumCharacters: 1500, maximumRecords: 4)
        #expect(result.retrieval.included == 0 && result.sources.isEmpty)
        #expect(!result.retrieval.text.contains("Profile name"))
    }
}
