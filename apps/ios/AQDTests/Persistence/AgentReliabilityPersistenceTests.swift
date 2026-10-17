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

@MainActor struct AgentAttachmentSelectionOrderTests {
    @Test func completionOrderDoesNotChangeSelectedOrderInSavedDraftOrMessage() throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let model = try AgentModel(store: store)
        let first = AgentAttachment(kind: .document, name: "first.txt", text: "First", method: "Document text")
        let second = AgentAttachment(kind: .document, name: "second.txt", text: "Second", method: "Document text")
        let order = [first.id, second.id]
        model.addAttachment(second, to: model.conversation.id, order: order)
        model.addAttachment(first, to: model.conversation.id, order: order)
        #expect(try store.agentConversations().first?.draftAttachments?.map(\.id) == order)
        _ = try model.conversation.beginAttempt(); try #require(model.persist())
        #expect(try store.agentConversations().first?.messages.first?.attachments?.map(\.id) == order)
    }
}

@Suite(.serialized) @MainActor struct AgentMutationToolPersistenceTests {
    private func activeModel() throws -> (PieceStore, AgentModel, UUID) {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let model = try AgentModel(store: store)
        model.conversation.draft = "Set my bio to Everyday looks"
        let attempt = try model.conversation.beginAttempt(); try #require(model.persist())
        return (store, model, attempt)
    }
    @Test func toolCreatesOneDurableReviewWithoutMutatingAndApplyCreatesReceipt() throws {
        let (store, model, attempt) = try activeModel()
        let request = AgentMutationRequest(kind: .updateProfile, caption: "Everyday looks")
        _ = try model.prepareToolChange(request, conversationID: model.conversation.id, attemptID: attempt)
        _ = try model.prepareToolChange(request, conversationID: model.conversation.id, attemptID: attempt)
        #expect(try store.localIdentity() == nil)
        #expect(try store.agentConversations().first?.proposals?.count == 1)
        let proposal = try #require(model.conversation.proposals?.first)
        model.approveProposal(proposal.id, version: 1)
        #expect(try store.localIdentity() == nil) // A running model cannot approve its own tool output.
        try model.conversation.complete(attemptID: attempt); try #require(model.persist())
        model.approveProposal(proposal.id, version: 1)
        model.approveProposal(proposal.id, version: 1)
        #expect(try store.localIdentity()?.caption == "Everyday looks")
        #expect(try store.localIdentity()?.revision == 1)
        #expect(try store.agentConversations().first?.proposals?.first?.receipt?.kind == "profile")
        let reopened = try AgentModel(store: PieceStore(directory: store.localDirectory))
        #expect(reopened.conversation.proposals?.first?.status == .succeeded)
    }
    @Test func cancellationPreventsToolUse() throws {
        let (store, model, attempt) = try activeModel()
        let request = AgentMutationRequest(kind: .updateProfile, name: "Van")
        model.stop()
        #expect(throws: (any Error).self) { try model.prepareToolChange(request, conversationID: model.conversation.id, attemptID: attempt) }
        #expect(try store.localIdentity() == nil && model.conversation.proposals == nil)
    }
    @Test func staleProfileAndManualDraftAreNeverOverwritten() throws {
        let (store, model, attempt) = try activeModel()
        _ = try model.prepareToolChange(.init(kind: .updateProfile, caption: "Agent bio"), conversationID: model.conversation.id, attemptID: attempt)
        try model.conversation.complete(attemptID: attempt); try #require(model.persist())
        var manual = LocalIdentityDraft(ownerID: model.conversation.ownerID); manual.name = "Manual name"
        try store.saveIdentityDraft(manual)
        let proposal = try #require(model.conversation.proposals?.first)
        model.approveProposal(proposal.id, version: proposal.version)
        #expect(try store.identityDraft() == manual && store.localIdentity() == nil)
        // Reconcile the same proposal after the manual draft is saved. Its old base must be refused.
        _ = try store.saveIdentity(manual); try store.finishIdentityDraft(manual)
        model.approveProposal(proposal.id, version: proposal.version)
        #expect(try store.localIdentity()?.name == "Manual name" && store.localIdentity()?.caption == nil)
        #expect(try store.identityDraft() == nil)
    }
    @Test func generalContextAndBoundedCallsDoNotExposeRecordsOrPrepareChanges() throws {
        let (_, model, attempt) = try activeModel()
        model.conversation.context.scope = .general
        #expect(throws: (any Error).self) { try model.lookupToolRecords("profile", conversationID: model.conversation.id, attemptID: attempt) }
        model.conversation.context.scope = .closet
        for _ in 0..<8 { _ = try model.lookupToolRecords("profile", conversationID: model.conversation.id, attemptID: attempt) }
        #expect(throws: (any Error).self) { try model.prepareToolChange(.init(kind: .updateProfile, name: "Van"), conversationID: model.conversation.id, attemptID: attempt) }
        #expect(model.conversation.proposals == nil)
    }
}

@MainActor extension AgentMutationToolPersistenceTests {
    @Test func lookupReturnsExactIDsAndRevokedSourceBlocksApproval() throws {
        let (store, model, attempt) = try activeModel()
        var identity = LocalIdentityDraft(ownerID: model.conversation.ownerID); identity.name = "Van"
        try store.saveIdentityDraft(identity); _ = try store.saveIdentity(identity); try store.finishIdentityDraft(identity)
        let lookup = try model.lookupToolRecords("Van profile", conversationID: model.conversation.id, attemptID: attempt)
        #expect(lookup.contains(model.conversation.ownerID.uuidString))
        _ = try model.prepareToolChange(.init(kind: .updateProfile, caption: "New bio"), conversationID: model.conversation.id, attemptID: attempt)
        var preferences = AgentPreferences(); preferences.set(.profile, enabled: false)
        _ = try store.saveLocalSettings(LocalSettingsRequest(base: store.localSettings(), agentPreferences: preferences))
        let hidden = try model.lookupToolRecords("Van profile", conversationID: model.conversation.id, attemptID: attempt)
        #expect(!hidden.contains("Van") && !hidden.contains(model.conversation.ownerID.uuidString))
        try model.conversation.complete(attemptID: attempt); try #require(model.persist())
        let proposal = try #require(model.conversation.proposals?.first)
        model.approveProposal(proposal.id, version: 1)
        #expect(try store.localIdentity()?.caption == nil && model.conversation.proposals?.first?.receipt == nil)
    }
}
