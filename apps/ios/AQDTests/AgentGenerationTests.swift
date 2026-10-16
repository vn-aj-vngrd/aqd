import Foundation
import Testing
import AQDCore
@testable import AQD

@Suite(.serialized) @MainActor struct AgentGenerationTests {
    private let qualification = AgentQualification(maximumPieces: 5, maximumPromptCharacters: 20000, responseTokens: 128, slowSeconds: 0.2, timeoutSeconds: 2)
    private func waitUntilStopped(_ model: AgentModel) async throws {
        for _ in 0..<200 { if !model.active { return }; try await Task.sleep(for: .milliseconds(5)) }
        Issue.record("Synthetic attempt did not stop")
    }
    @Test func actualProviderSnapshotsPersistAndRetryKeepsOneUserTurn() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let model = try AgentModel(store: store, qualification: qualification) { _, _ in
            AsyncThrowingStream { continuation in continuation.yield("**A"); continuation.yield("**A look**"); continuation.finish() }
        }
        model.availability = .awaitingQualification
        model.updateDraft("General styling please"); model.conversation.context.scope = .general
        model.send(); try await waitUntilStopped(model)
        #expect(model.conversation.messages.count == 2)
        #expect(model.conversation.messages.last?.source == "**A look**")
        #expect(model.conversation.messages.last?.status == .complete)
        let message = try #require(model.conversation.messages.last)
        #expect(message.firstTextSeconds != nil && message.elapsedSeconds != nil)
        model.send(retrying: message.id); try await waitUntilStopped(model)
        #expect(model.conversation.messages.count == 2 && model.conversation.messages.last?.versions.count == 1)
        #expect(try store.agentConversations().first?.messages.last?.source == "**A look**")
        #expect(try store.pieces().isEmpty && store.planEntries().isEmpty)
    }
    @Test func stopAcknowledgesCancellationAndRefusesLateProviderText() async throws {
        let pair = AsyncThrowingStream<String, any Error>.makeStream()
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let model = try AgentModel(store: store, qualification: qualification) { _, _ in pair.stream }
        model.availability = .awaitingQualification; model.updateDraft("A look"); model.send()
        pair.continuation.yield("Partial")
        for _ in 0..<100 { if model.conversation.messages.last?.source == "Partial" { break }; try await Task.sleep(for: .milliseconds(5)) }
        model.stop(); try await waitUntilStopped(model)
        pair.continuation.yield("Partial and a late overwrite"); pair.continuation.finish()
        #expect(model.conversation.messages.last?.status == .stopped)
        #expect(model.conversation.messages.last?.source == "Partial")
        #expect(try AgentModel(store: store).conversation.messages.last?.status == .stopped)
    }
    @Test func unqualifiedRuntimeNeverCallsProviderAndPreservesTypedDraft() throws {
        var calls = 0
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let model = try AgentModel(store: store) { _, _ in calls += 1; return AsyncThrowingStream { $0.finish() } }
        model.updateDraft("Retained"); model.send()
        #expect(calls == 0 && model.conversation.messages.isEmpty && model.conversation.draft == "Retained")
        #expect(model.persist())
    }
    @Test func emptyProviderResponseIsFailedAndBackgroundInterruptionIsNotUserStop() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let empty = try AgentModel(store: store, qualification: qualification) { _, _ in AsyncThrowingStream { $0.finish() } }
        empty.availability = .awaitingQualification; empty.updateDraft("A look"); empty.send()
        try await waitUntilStopped(empty)
        #expect(empty.conversation.messages.last?.status == .failed)
        let pair = AsyncThrowingStream<String, any Error>.makeStream()
        let model = try AgentModel(store: store, qualification: qualification) { _, _ in pair.stream }
        model.newConversation(); model.availability = .awaitingQualification
        model.updateDraft("Another look"); model.send(); model.suspend()
        // Interruption immediately makes the message inactive; allow the cancellation handler to finish too.
        try await Task.sleep(for: .milliseconds(30))
        pair.continuation.yield("Late text"); pair.continuation.finish()
        #expect(model.conversation.messages.last?.status == .interrupted)
        #expect(model.conversation.messages.last?.source.isEmpty == true)
        #expect(try AgentModel(store: store).conversation.messages.last?.status == .interrupted)
    }
}
