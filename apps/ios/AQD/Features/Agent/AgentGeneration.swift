import AQDCore
import Foundation

/// Thrown after the reason has already been shown to the owner, so the send silently stops without starting an attempt.
struct AgentTurnRefused: Error {}

@MainActor extension AgentModel {
    /// One turn of model work: the router's preflight, the streamed reply, the grounding check and the clean-up. A reply the model could
    /// not finish still ends well when the app already holds the answer (cards plus a plain sentence); otherwise the failure is typed.
    func generate(turn initial: AgentTurn, images: [AgentAttachment], attempt: UUID, conversationID: UUID, start: ContinuousClock.Instant, qualification: AgentQualification) async {
        var turn = initial
        var lastSave: ContinuousClock.Instant?
        if let script = turn.plan.scriptedReply, let i = conversation.messages.lastIndex(where: { $0.attemptID == attempt && $0.role == .assistant }) {
            conversation.messages[i].source = script; conversation.messages[i].status = .streaming
            if (try? conversation.complete(attemptID: attempt)) != nil { finalizeReply(attempt: attempt) }
            return
        }
        do {
            // The router carries out plain commands and look requests itself; the model then only writes the sentence about the result.
            if turn.plan.fast == nil, let preflight = turn.plan.preflight, let result = try await runPreflight(preflight, attempt: attempt, conversationID: conversationID) {
                if result.exact, let i = conversation.messages.lastIndex(where: { $0.attemptID == attempt && $0.role == .assistant }) {
                    conversation.messages[i].source = result.fallback; conversation.messages[i].status = .streaming
                    if (try? conversation.complete(attemptID: attempt)) != nil { finalizeReply(attempt: attempt) }
                    return
                }
                turn.plan.fast = result; turn.plan.tools = []; turn.parts.context += "\n" + result.note
            }
            let maximumTokens = turn.plan.responseTokens
            let response = usesNativeProvider
                ? NativeAgentProvider.streamAttached(parts: turn.parts, instructions: turn.plan.instructions, responseTokens: maximumTokens, attachments: images,
                    tools: turn.plan.tools.isEmpty ? nil : toolSelection(ids: turn.plan.tools, conversationID: conversationID, attemptID: attempt))
                : provider(turn.parts.render(), maximumTokens)
            try await streamPass(response, attempt: attempt, conversationID: conversationID, start: start, lastSave: &lastSave)
            try Task.checkCancellation()
            try await groundReply(turn: turn, attempt: attempt, conversationID: conversationID, start: start, lastSave: &lastSave, qualification: qualification)
            try Task.checkCancellation(); try conversation.complete(attemptID: attempt)
            finalizeReply(attempt: attempt)
        } catch {
            if !(error is CancellationError), !timedOut, let fallback = turn.plan.fast?.fallback, !fallback.isEmpty,
               let i = conversation.messages.lastIndex(where: { $0.attemptID == attempt && $0.role == .assistant }), conversation.messages[i].status != .stopping {
                conversation.messages[i].source = fallback; conversation.messages[i].status = .streaming
                if (try? conversation.complete(attemptID: attempt)) != nil { finalizeReply(attempt: attempt); return }
            }
            recordFailure(error, attempt: attempt)
        }
    }

    func recordFailure(_ error: any Error, attempt: UUID) {
        guard let i = conversation.messages.firstIndex(where: { $0.attemptID == attempt }) else { return }
        if conversation.messages[i].status != .interrupted {
            conversation.messages[i].status = conversation.messages[i].status == .stopping ? .stopped : (conversation.messages[i].source.isEmpty ? .failed : .interrupted)
        }
        if conversation.messages[i].diagnostics != nil {
            if conversation.messages[i].status == .stopped { conversation.messages[i].diagnostics?.failure = nil }
            else if let providerError = error as? AgentProviderError { conversation.messages[i].diagnostics?.failure = providerError.category }
            else if hasPendingOperation { conversation.messages[i].diagnostics?.failure = .storage }
            else if timedOut { conversation.messages[i].diagnostics?.failure = .timeout }
            else { conversation.messages[i].diagnostics?.failure = error is CancellationError ? .interrupted : .generation }
        }
        if conversation.messages[i].status != .stopped {
            conversation.messages[i].failure = .make(failureKind(for: error, message: conversation.messages[i]), keptPartialReply: !conversation.messages[i].source.isEmpty,
                                                     closetIncluded: conversation.context.automatic == true && conversation.context.scope == .closet)
        }
        conversation.messages[i].failureReason = (error as? AgentProviderError)?.message ?? self.error
            ?? (conversation.messages[i].status == .stopped ? "Stopped by you. The partial response is retained."
                : timedOut ? "The response timed out. Your message and any partial response are retained." : "The response could not finish. Your message and any partial response are retained; try again.")
    }

    /// Streams one model pass into the active reply. Saves on the first text, then at most once a second.
    func streamPass(_ response: AsyncThrowingStream<String, any Error>, attempt: UUID, conversationID: UUID, start: ContinuousClock.Instant, lastSave: inout ContinuousClock.Instant?) async throws {
        for try await text in response {
            try Task.checkCancellation()
            guard conversation.id == conversationID, let i = conversation.messages.firstIndex(where: { $0.attemptID == attempt && $0.isActive && $0.status != .stopping }) else { throw CancellationError() }
            guard text.hasPrefix(conversation.messages[i].source) else { throw CocoaError(.coderInvalidValue) }
            conversation.messages[i].source = text; conversation.messages[i].status = .streaming
            if conversation.messages[i].firstTextSeconds == nil && !text.isEmpty { conversation.messages[i].firstTextSeconds = seconds(since: start) }
            if lastSave.map({ $0.duration(to: .now) >= Self.streamSaveInterval }) ?? !text.isEmpty {
                guard persist() else { throw CocoaError(.fileWriteUnknown) }
                lastSave = .now
            }
        }
    }

    /// Checks the finished reply against the owner's records. A violation regenerates once with the problems as feedback; if it still fails,
    /// the reply stays with an inline note. Fast-path replies fall back to a plain sentence the app wrote itself.
    func groundReply(turn: AgentTurn, attempt: UUID, conversationID: UUID, start: ContinuousClock.Instant, lastSave: inout ContinuousClock.Instant?, qualification: AgentQualification) async throws {
        guard let i = conversation.messages.lastIndex(where: { $0.attemptID == attempt && $0.role == .assistant }), turn.diagnostics != nil else { return }
        let check = AgentGroundingCheck(catalog: nameCatalog())
        let cards = (conversation.messages[i].toolSteps ?? []).flatMap { $0.results ?? [] }.count
        // Requests that prepare a review must never be answered as if the change had been made.
        let changes: Set<AgentIntent> = [.editPiece, .tidy, .relabel, .theme, .planDays, .planTrip, .suggestOutfit, .recordWear, .profile, .addPiece, .whatToWear]
        let forbidClaims = changes.contains(turn.plan.intent)
        var first = check.violations(in: conversation.messages[i].source, hasCards: cards > 0, forbidCompletionClaims: forbidClaims)
        guard !first.isEmpty else { return }
        conversation.messages[i].diagnostics?.firstViolations = Array(first.map(\.label).prefix(32))
        // A repeated handle, id or revision is removed outright; only other problems need the model to try again.
        if first.contains(where: { $0.isLeak }) {
            conversation.messages[i].source = AgentReplyPolish.scrubIdentifiers(conversation.messages[i].source)
            first = check.violations(in: conversation.messages[i].source, hasCards: cards > 0, forbidCompletionClaims: forbidClaims)
            guard !first.isEmpty else { conversation.messages[i].diagnostics?.groundingViolations = []; return }
        }
        if let fallback = turn.plan.fast?.fallback, !fallback.isEmpty {
            conversation.messages[i].source = fallback; conversation.messages[i].diagnostics?.groundingViolations = []
            return
        }
        let request = turn.parts.userTurn
        let repair = AgentGroundingRepair.prompt(request: request, previousReply: conversation.messages[i].source, violations: first, catalog: check.catalog, cardsShown: cards)
        conversation.messages[i].source = ""; conversation.messages[i].status = .waiting
        let response = usesNativeProvider
            ? NativeAgentProvider.streamAttached(parts: repair, instructions: AgentInstructions.compose(.chat), responseTokens: turn.plan.responseTokens, attachments: [])
            : provider(repair.render(), turn.plan.responseTokens)
        try await streamPass(response, attempt: attempt, conversationID: conversationID, start: start, lastSave: &lastSave)
        guard let j = conversation.messages.lastIndex(where: { $0.attemptID == attempt && $0.role == .assistant }) else { return }
        // Identifiers are removed when the reply is finalized, so they never count against it.
        let second = check.violations(in: conversation.messages[j].source, hasCards: cards > 0, forbidCompletionClaims: forbidClaims).filter { !$0.isLeak }
        conversation.messages[j].diagnostics?.groundingViolations = Array(second.map(\.label).prefix(32))
        if !second.isEmpty { conversation.messages[j].groundingNote = AgentGroundingRepair.note }
    }

    /// Everything done to a reply once the model has finished: cards for the pieces it named, the safety nets, the summary of older turns.
    func finalizeReply(attempt: UUID) {
        attachMentionedRecords(attemptID: attempt)
        ensureTripProposal(attemptID: attempt)
        let intent = conversation.messages.last(where: { $0.attemptID == attempt })?.diagnostics?.intent.flatMap(AgentIntent.init(rawValue:))
        if ![.chat, .outOfScope].contains(intent) { ensureQuestion(attemptID: attempt) }
        if let i = conversation.messages.lastIndex(where: { $0.attemptID == attempt && $0.role == .assistant }) {
            let titles = (conversation.messages[i].toolSteps ?? []).flatMap { $0.results ?? [] }.map(\.title)
            conversation.messages[i].source = AgentReplyPolish.polish(conversation.messages[i].source, cardTitles: titles)
        }
        conversation.summary = AgentConversationMemory.rollingSummary(conversation.messages)
        recordToolCalls(attemptID: attempt)
    }
}
