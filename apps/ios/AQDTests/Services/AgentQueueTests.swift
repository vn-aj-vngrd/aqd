import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct AgentQueueTests {
    private let qualification = AgentQualification(maximumPieces: 5, maximumPromptCharacters: 20000, responseTokens: 128, slowSeconds: 0.5, timeoutSeconds: 5)

    private func model(slow: Bool, prompts: Box) throws -> AgentModel {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let model = try AgentModel(store: store, qualification: qualification) { text, _ in
            prompts.values.append(text)
            return AsyncThrowingStream { continuation in
                Task { if slow { try? await Task.sleep(for: .milliseconds(250)) }; continuation.yield("A considered look"); continuation.finish() }
            }
        }
        model.availability = .awaitingQualification
        model.conversation.context.scope = .general
        return model
    }
    final class Box { var values: [String] = [] }

    private func settle(_ model: AgentModel, until done: () -> Bool) async throws {
        for _ in 0..<600 { if done() { return }; try await Task.sleep(for: .milliseconds(10)) }
        Issue.record("The queue did not settle")
    }

    @Test func aMessageTypedMidReplyWaitsAndIsSentWhenTheReplyFinishes() async throws {
        let prompts = Box(), model = try model(slow: true, prompts: prompts)
        model.updateDraft("First question"); model.send()
        try await settle(model) { model.active }
        model.updateDraft("Second question")
        #expect(model.canQueue && model.queueDraft())
        #expect(model.queuedMessages == ["Second question"] && model.conversation.draft.isEmpty)
        try await settle(model) { prompts.values.count == 2 && !model.active && model.queuedMessages.isEmpty }
        let sent = model.conversation.messages.filter { $0.role == .user }.map(\.source)
        #expect(sent == ["First question", "Second question"])
        #expect(model.conversation.messages.last?.status == .complete)
    }

    @Test func stoppingGivesTheQueuedWordsBackToTheComposer() async throws {
        let prompts = Box(), model = try model(slow: true, prompts: prompts)
        model.updateDraft("First question"); model.send()
        try await settle(model) { model.active }
        model.updateDraft("Second question"); model.queueDraft()
        model.stop()
        #expect(model.queuedMessages.isEmpty && model.conversation.draft == "Second question")
        try await settle(model) { !model.active }
        #expect(prompts.values.count == 1)
    }

    @Test func theQueueHoldsAtMostThreeAndOnlyWhileAReplyIsRunning() async throws {
        let prompts = Box(), model = try model(slow: true, prompts: prompts)
        model.updateDraft("Idle message")
        #expect(!model.queueDraft())
        model.send()
        try await settle(model) { model.active }
        for word in ["a", "b", "c", "d"] { model.updateDraft(word); model.queueDraft() }
        #expect(model.queuedMessages == ["a", "b", "c"])
        model.removeQueued(at: 1)
        #expect(model.queuedMessages == ["a", "c"])
        model.stop()
    }

    @Test func aTypedDraftIsNeverOverwrittenByTheQueue() async throws {
        let prompts = Box(), model = try model(slow: true, prompts: prompts)
        model.updateDraft("First"); model.send()
        try await settle(model) { model.active }
        model.updateDraft("Queued"); model.queueDraft()
        model.updateDraft("Typed meanwhile")
        try await settle(model) { !model.active && model.queuedMessages.isEmpty }
        #expect(model.conversation.draft == "Queued\nTyped meanwhile" && prompts.values.count == 1)
    }
}
