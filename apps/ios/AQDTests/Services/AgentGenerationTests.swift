import Foundation
import Testing
import AQDCore
@testable import AQD

@Suite(.serialized) @MainActor struct AgentGenerationTests {
    private let qualification = AgentQualification(maximumPieces: 5, maximumPromptCharacters: 20000, responseTokens: 128, slowSeconds: 0.2, timeoutSeconds: 2)
    @Test func defaultTextAgentUsesRuntimeReadinessAndBoundedRequests() throws {
        let limits = try #require(AgentQualification.current)
        #expect(limits.isValid)
        #expect(limits.maximumPieces == 24 && limits.maximumPromptCharacters == 8000)
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let model = try AgentModel(store: store)
        model.availability = .available
        #expect(model.supportsGeneration && model.canGenerate)
        for unavailable in [OutfitSuggestionAvailability.unsupported, .intelligenceOff, .preparing, .localeUnavailable] {
            model.availability = unavailable
            #expect(!model.supportsGeneration && !model.canGenerate)
        }
    }

    private func waitUntilStopped(_ model: AgentModel) async throws {
        for _ in 0..<200 { if !model.active { return }; try await Task.sleep(for: .milliseconds(5)) }
        Issue.record("Synthetic attempt did not stop")
    }
    @Test(arguments: [false, true], [false, true]) func styleIncludesColorsAndPatternsWithoutBypassingBodyConsent(includeStyle: Bool, allowBody: Bool) async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        var answers = StylePreferences(); for index in 0..<4 { answers.choose("No preference", at: index) }
        answers.colors.preferredColors = "Navy"; answers.colors.avoidedColors = "Orange"
        answers.colors.preferredPatterns = "Stripes"; answers.colors.avoidedPatterns = "Polka dots"
        answers.body.response = .provided; answers.body.shape = "PRIVATE_BODY_CONTEXT"; answers.body.useForSuggestions = allowBody
        var style = StylePreferenceDraft(source: .settings, answers: answers); style.page = 6
        try store.saveStyleDraft(style); _ = try store.saveStylePreferences(style); try store.acknowledgeStyleReceipt(operationID: style.operationID)
        var prompt = ""
        let model = try AgentModel(store: store, qualification: qualification) { text, _ in
            prompt = text; return AsyncThrowingStream { $0.yield("A considered look"); $0.finish() }
        }
        model.availability = .awaitingQualification; model.updateDraft("General styling please")
        model.conversation.context.scope = .general; model.conversation.context.includesStyle = includeStyle
        model.send(); try await waitUntilStopped(model)
        for text in ["Preferred colors: Navy", "Colors to avoid: Orange", "Preferred patterns: Stripes", "Patterns to avoid: Polka dots"] {
            #expect(prompt.contains(text) == includeStyle)
        }
        #expect(prompt.contains("PRIVATE_BODY_CONTEXT") == (includeStyle && allowBody))
        #expect(model.conversation.messages.last?.status == .complete)
    }
    @Test func automaticGroundingSelectsWithinBudgetWithoutRejectingLargerClosets() async throws {
        let fixture = try await LocalDataFixture(), store = fixture.store
        _ = try store.savePiece(PieceDraft(name: "SECOND_BLUE_SHIRT", category: .tops, photoID: fixture.processed.id), operationID: UUID())
        let limits = AgentQualification(maximumPieces: 1, maximumPromptCharacters: 20000, responseTokens: 128, slowSeconds: 0.2, timeoutSeconds: 2)
        var prompts: [String] = []
        let model = try AgentModel(store: store, qualification: limits) { text, _ in
            prompts.append(text); return AsyncThrowingStream { $0.yield("Try a shirt."); $0.finish() }
        }
        model.availability = .awaitingQualification; model.updateDraft("What blue shirt can I wear?"); model.send(); try await waitUntilStopped(model)
        #expect(prompts.count == 1)
        #expect(model.conversation.messages.last?.status == .complete)
        #expect(model.conversation.messages.last?.diagnostics?.included == 1)
        #expect((model.conversation.messages.last?.diagnostics?.omitted ?? 0) > 0)
    }
    @Test func legacyRestrictedClosetRetainsTheRequestUntilExplicitBoundedSelection() async throws {
        let fixture = try await LocalDataFixture(), store = fixture.store
        let other = try store.savePiece(PieceDraft(name: "EXCLUDED_OTHER_PIECE", category: .tops, photoID: fixture.processed.id), operationID: UUID())
        let limits = AgentQualification(maximumPieces: 1, maximumPromptCharacters: 20000, responseTokens: 128, slowSeconds: 0.2, timeoutSeconds: 2)
        var prompts: [String] = []
        let model = try AgentModel(store: store, qualification: limits) { text, _ in
            prompts.append(text); return AsyncThrowingStream { $0.yield("One reviewed piece"); $0.finish() }
        }
        model.availability = .awaitingQualification; model.updateDraft("What can I wear?")
        model.conversation.context.automatic = false
        model.send()
        #expect(prompts.isEmpty && model.conversation.messages.isEmpty && model.conversation.draft == "What can I wear?")
        #expect(model.error?.contains("Choose Selected pieces") == true)
        model.conversation.context.scope = .selected
        model.conversation.context.selected = [AgentSelectedRecord(id: fixture.piece.id, kind: .piece, revision: fixture.piece.revision)]
        model.send(); try await waitUntilStopped(model)
        #expect(prompts.count == 1 && prompts.first?.contains(fixture.piece.name) == true && prompts.first?.contains(other.name) == false)
        #expect(model.conversation.messages.last?.contextSummary?.contains("1 of 2 eligible pieces") == true)
        #expect(model.conversation.messages.last?.status == .complete)
    }
    @Test func actualProviderSnapshotsPersistAndRetryKeepsOneUserTurn() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        var prompts: [String] = []
        let model = try AgentModel(store: store, qualification: qualification) { prompt, _ in
            prompts.append(prompt)
            return AsyncThrowingStream { continuation in continuation.yield("**A"); continuation.yield("**A look**"); continuation.finish() }
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
        #expect(prompts.last?.contains("user: General styling please") == true)
        #expect(prompts.last?.contains("assistant: **A look**") == false)
        #expect(model.conversation.messages.count == 2 && model.conversation.messages.last?.versions.count == 1)
        #expect(try store.agentConversations().first?.messages.last?.source == "**A look**")
        #expect(try store.pieces().isEmpty && store.planEntries().isEmpty)
    }
    @Test func streamingThrottlesSavesToFirstTextThenOncePerSecondThenFinal() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let model = try AgentModel(store: store, qualification: qualification) { _, _ in
            AsyncThrowingStream { continuation in
                var text = ""
                for _ in 0..<200 { text += "word "; continuation.yield(text) }
                continuation.finish()
            }
        }
        model.availability = .awaitingQualification; model.updateDraft("General styling please"); model.conversation.context.scope = .general
        model.send()
        var revisions = Set<Int>()
        for _ in 0..<400 where model.active { revisions.insert(model.conversation.revision); try await Task.sleep(for: .milliseconds(1)) }
        try await waitUntilStopped(model)
        let saved = try #require(try store.agentConversations().first)
        #expect(saved.messages.last?.status == .complete && saved.messages.last?.source.split(separator: " ").count == 200)
        // Start-of-attempt save, first text, final save: one stream burst adds at most 3 intermediate revisions.
        #expect(saved.revision <= 4)
    }
    @Test func budgetRejectsOversizeAndAcceptsFittingRequests() {
        #expect(NativeAgentProvider.fits(input: 1000, system: 400, tools: 900, response: 768, contextSize: 4096))
        #expect(!NativeAgentProvider.fits(input: 2500, system: 400, tools: 900, response: 768, contextSize: 4096))
        #expect(!NativeAgentProvider.fits(input: 1000, system: 400, tools: 2000, response: 768, contextSize: 4096))
        #expect(NativeAgentProvider.fits(input: 1000, system: 400, tools: 0, response: 768, contextSize: 4096))
    }
    @Test func providerErrorsHaveClearMessages() {
        for error in [AgentProviderError.contextLimit, .guardrail, .unsupportedLanguage, .unavailable] {
            #expect(!error.message.contains("could not finish"))
        }
        #expect(Set([AgentProviderError.contextLimit, .guardrail, .unsupportedLanguage, .unavailable].map(\.message)).count == 4)
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
        let model = try AgentModel(store: store, qualification: nil) { _, _ in calls += 1; return AsyncThrowingStream { $0.finish() } }
        model.availability = .available
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
