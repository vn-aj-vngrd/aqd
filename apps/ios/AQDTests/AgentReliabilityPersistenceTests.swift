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

@Suite(.serialized) @MainActor struct AgentComposerAttachmentPersistenceTests {
    @Test(arguments: [false, true]) func attachmentSaveRetryKeepsOnePhotoAndNewTypedText(lostAcknowledgment: Bool) throws {
        var before = false, after = false
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), beforeOutfitSave: { if before { throw CocoaError(.fileWriteNoPermission) } }, afterOutfitSave: { if after { throw CocoaError(.fileReadUnknown) } })
        let model = try AgentModel(store: store)
        let image = AgentAttachment(kind: .image, name: "Photo", preview: Data([1, 2, 3]), text: "Navy coat", method: "Image reference")
        before = !lostAcknowledgment; after = lostAcknowledgment
        model.addAttachment(image, to: model.conversation.id)
        #expect(model.hasPendingOperation && model.conversation.draftAttachments == [image])
        model.updateDraft("A newer question")
        let document = AgentAttachment(kind: .document, name: "notes.txt", text: "Relaxed navy looks", method: "Document text")
        model.addAttachment(document, to: model.conversation.id)
        before = false; after = false; model.retryPending()
        let saved = try #require(store.agentConversations().first)
        #expect(saved.draft == "A newer question" && saved.draftAttachments == [image, document])
        let reopened = try AgentModel(store: PieceStore(directory: store.localDirectory))
        #expect(reopened.conversation.draftAttachments == [image, document])
        reopened.removeAttachment(image.id)
        #expect(try store.agentConversations().first?.draftAttachments == [document])
    }
    @Test func attachmentOnlySendIncludesReferencesAndKeepsPreviewOnRetry() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        var prompts: [String] = []
        let model = try AgentModel(store: store) { text, _ in prompts.append(text); return AsyncThrowingStream { $0.yield("Try navy."); $0.finish() } }
        model.availability = .available
        let photo = AgentAttachment(kind: .image, name: "Photo", preview: Data([1, 2, 3]), text: "Navy coat", method: "Image reference")
        model.addAttachment(photo, to: model.conversation.id); model.send()
        for _ in 0..<100 { if !model.active { break }; try await Task.sleep(for: .milliseconds(10)) }
        #expect(prompts.count == 1 && prompts[0].contains("Navy coat"))
        #expect(model.conversation.messages.first?.attachments == [photo] && model.conversation.draftAttachments == nil)
        model.send(retrying: try #require(model.conversation.messages.last?.id))
        for _ in 0..<100 { if !model.active { break }; try await Task.sleep(for: .milliseconds(10)) }
        #expect(prompts.count == 2 && model.conversation.messages.count == 2)
        #expect(model.conversation.messages.first?.attachments == [photo])
    }
}
