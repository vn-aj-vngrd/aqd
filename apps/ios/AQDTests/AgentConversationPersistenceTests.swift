import Foundation
import Testing
import SwiftData
@testable import AQD
import AQDCore

@Suite(.serialized) @MainActor struct AgentConversationPersistenceTests {
    @Test(arguments: [false, true]) func unknownDeletionReconcilesAfterHistoryReloadRemovesItsRow(deletingCurrent: Bool) throws {
        var unknown = false
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            afterOutfitSave: { if unknown { throw CocoaError(.fileReadUnknown) } })
        let model = try AgentModel(store: store)
        model.updateDraft("Private draft"); #expect(model.persist())
        let saved = try #require(model.history.first)
        if !deletingCurrent { model.newConversation(); model.updateDraft("Current draft"); #expect(model.persist()) }
        let currentID = model.conversation.id
        unknown = true; model.delete(saved)
        #expect(model.hasPendingOperation)
        model.reloadHistory()
        #expect(!model.history.contains { $0.id == saved.id })
        model.suspend()
        #expect(model.error != nil)
        unknown = false; model.retryPending()
        #expect(!model.hasPendingOperation)
        #expect(deletingCurrent ? model.conversation.id != saved.id && model.conversation.draft.isEmpty : model.conversation.id == currentID && model.conversation.draft == "Current draft")
        #expect(try store.agentConversations().count == (deletingCurrent ? 0 : 1))
    }
    @Test(arguments: [false, true]) func unchangedSaveRetryAcknowledgesExactlyOneRevision(lostAcknowledgment: Bool) throws {
        var before = false, after = false, submissions = 0
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            beforeOutfitSave: { submissions += 1; if before { throw CocoaError(.fileWriteNoPermission) } },
            afterOutfitSave: { if after { throw CocoaError(.fileReadUnknown) } })
        let model = try AgentModel(store: store)
        model.updateDraft("Unchanged input")
        before = !lostAcknowledgment; after = lostAcknowledgment
        #expect(!model.persist())
        before = false; after = false
        let previous = submissions
        #expect(model.persist())
        #expect(model.conversation.revision == 1)
        #expect(try store.agentConversations().first?.revision == 1)
        #expect(submissions == previous + (lostAcknowledgment ? 0 : 1))
        #expect(!model.hasPendingOperation)
    }
    @Test func retainedTextAndUnknownSaveReconcileOneConversationThenDeleteOnlyThatHistory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var fail = false, unknown = false
        let store = try PieceStore(directory: directory,
            beforeOutfitSave: { if fail { throw CocoaError(.fileWriteNoPermission) } },
            afterOutfitSave: { if unknown { throw CocoaError(.fileReadUnknown) } })
        var value = AgentConversation(ownerID: try store.todayConfiguration().ownerID); value.draft = "Keep my typed draft"
        let operation = UUID()
        fail = true
        #expect(throws: (any Error).self) { try store.saveAgentConversation(value, operationID: operation) }
        #expect(try store.agentConversations().isEmpty)
        fail = false; unknown = true
        #expect(throws: (any Error).self) { try store.saveAgentConversation(value, operationID: operation) }
        let saved = try store.saveAgentConversation(value, operationID: operation)
        #expect(saved.revision == 1 && saved.draft == value.draft)
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.agentConversations() == [saved])
        unknown = false
        var other = AgentConversation(ownerID: value.ownerID); other.draft = "Other"
        let second = try store.saveAgentConversation(other, operationID: UUID())
        let deletion = UUID(); unknown = true
        #expect(throws: (any Error).self) { try store.deleteAgentConversation(id: saved.id, expectedRevision: saved.revision, operationID: deletion) }
        try store.deleteAgentConversation(id: saved.id, expectedRevision: saved.revision, operationID: deletion)
        #expect(try store.agentConversations() == [second])
        #expect(try store.pieces().isEmpty && store.planEntries().isEmpty && store.wearRecords().isEmpty)
        #expect(throws: (any Error).self) { try store.saveAgentConversation(value, operationID: operation) }
    }
    @Test func retryingAnUnknownDraftSavePreservesNewerTyping() throws {
        var unknown = false
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            afterOutfitSave: { if unknown { throw CocoaError(.fileReadUnknown) } })
        let model = try AgentModel(store: store)
        model.updateDraft("Earlier input"); unknown = true
        #expect(!model.persist())
        model.updateDraft("Latest typed input"); unknown = false
        #expect(model.persist())
        #expect(try store.agentConversations().count == 1)
        #expect(try store.agentConversations().first?.draft == "Latest typed input")
        #expect(try AgentModel(store: store).conversation.draft == "Latest typed input")
    }
    @Test func populatedV20MigrationPreservesTodayOwnerAndPrivateIdentity() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let today = TodayConfiguration(ownerID: UUID())
        let identity = LocalProfileIdentity(ownerID: today.ownerID, name: "Private", photoID: nil, revision: 1)
        do {
            let schema = Schema(versionedSchema: LocalSchemaV20.self)
            let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
            let context = ModelContext(try ModelContainer(for: schema, configurations: [config]))
            context.insert(StoredTodayConfiguration(today)); context.insert(try StoredTodayLayout(today))
            context.insert(try StoredLocalExperience(LocalExperience(enteredPrivateSpace: true)))
            context.insert(try StoredLocalIdentity(identity)); try context.save()
        }
        try Data("AQD-piece-store:20".utf8).write(to: directory.appendingPathComponent("schema-version"))
        let store = try PieceStore(directory: directory)
        #expect(try store.todayConfiguration() == today)
        #expect(try store.localIdentity() == identity)
        #expect(try store.agentConversations().isEmpty)
    }

}
