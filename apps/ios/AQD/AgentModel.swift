import AQDCore
import Foundation
import Observation

@MainActor @Observable final class AgentModel {
    let store: PieceStore
    var conversation: AgentConversation
    var history: [AgentConversation] = []
    var error: String?
    var availability = OutfitSuggestions.availability()
    var weatherClient: WeatherClient?
    let qualification: AgentQualification?
    private let provider: @MainActor (String, Int) -> AsyncThrowingStream<String, any Error>
    private var generation: Task<Void, Never>?
    private var timeout: Task<Void, Never>?
    var slow = false
    var active: Bool { conversation.messages.contains(where: \.isActive) }
    var supportsGeneration: Bool { qualification?.isValid == true && [.available, .awaitingQualification].contains(availability) }
    var canGenerate: Bool { supportsGeneration && !active && pending == nil && deletion == nil }
    var hasPendingOperation: Bool { pending != nil || deletion != nil }
    private var pending: (AgentConversation, UUID)?
    private var retention: Task<Void, Never>?
    private var deletion: (UUID, Int, UUID)?
    init(store: PieceStore, qualification: AgentQualification? = AgentQualification.current,
         provider: @escaping @MainActor (String, Int) -> AsyncThrowingStream<String, any Error> = NativeAgentProvider.stream) throws {
        self.store = store; self.qualification = qualification; self.provider = provider
        conversation = AgentConversation(ownerID: try store.todayConfiguration().ownerID)
        reloadHistory()
        if let latest = history.first { conversation = latest }
        if conversation.messages.contains(where: \.isActive) {
            conversation.interruptActiveAttempt(); _ = persist()
        }
    }
    func reloadHistory() {
        do { history = try store.agentConversations(); error = nil }
        catch { self.error = "Conversations couldn’t load. Your saved history and draft are retained. Try again." }
    }
    func updateDraft(_ text: String) {
        conversation.draft = text; retention?.cancel()
        retention = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }; _ = self?.persist()
        }
    }
    @discardableResult func persist() -> Bool {
        retention?.cancel()
        do {
            if let (value, operation) = pending {
                let unchanged = conversation == value
                let acknowledged = try store.saveAgentConversation(value, operationID: operation)
                pending = nil
                // Input may have changed while an earlier save was unconfirmed.
                if unchanged { conversation = acknowledged; reloadHistory(); return true }
                conversation.revision = acknowledged.revision
            }
            if let saved = history.first(where: { $0.id == conversation.id }),
               saved.draft == conversation.draft, saved.context == conversation.context, saved.messages == conversation.messages, saved.proposals == conversation.proposals { error = nil; return true }
            if conversation.revision == 0 && conversation.draft.isEmpty && conversation.messages.isEmpty && (conversation.proposals ?? []).isEmpty && conversation.context == AgentContext() { return true }
            pending = (conversation, UUID())
            let result = try store.saveAgentConversation(conversation, operationID: pending!.1)
            pending = nil; conversation = result; reloadHistory(); return true
        } catch { self.error = "The conversation save wasn’t confirmed. Your text is still here. Retry checks the same save before writing again."; return false }
    }
    func newConversation() { guard !active, deletion == nil, persist() else { return }; conversation = AgentConversation(ownerID: conversation.ownerID) }
    func open(_ id: UUID) {
        guard !active, deletion == nil, persist() else { return }; reloadHistory()
        guard let value = history.first(where: { $0.id == id }) else { error = "This conversation is unavailable. Start a new conversation."; return }
        conversation = value
        if conversation.messages.contains(where: \.isActive) { conversation.interruptActiveAttempt(); _ = persist() }
    }
    func delete(_ value: AgentConversation) {
        guard !active else { return }
        guard deletion == nil || deletion?.0 == value.id else { return }
        deletion = deletion ?? (value.id, value.revision, UUID())
        do {
            guard let deletion else { return }
            try store.deleteAgentConversation(id: deletion.0, expectedRevision: deletion.1, operationID: deletion.2)
            self.deletion = nil
            if conversation.id == value.id { pending = nil; retention?.cancel(); conversation = AgentConversation(ownerID: value.ownerID) }
            reloadHistory()
        } catch PieceStore.StoreError.operationConflict {
            deletion = nil
            error = "Deletion was refused. Check any unconfirmed reviewed change before deleting this conversation."
        } catch PieceStore.StoreError.staleRevision {
            deletion = nil
            reloadHistory()
            error = "The conversation changed. Reopen its current version before deleting."
        } catch { self.error = "Deletion wasn’t confirmed. Retry checks the same conversation operation. Saved outfits and plans are unaffected." }
    }
    func propose(_ action: AgentReviewedAction) {
        guard !active, !hasPendingOperation else { return }
        do {
            var proposal = AgentActionProposal(action: action)
            let outfitIDs: [UUID]
            switch action { case .theme(let draft): outfitIDs = draft.outfitIDs; case .plan(let draft): outfitIDs = draft.slots.compactMap { $0.outfit?.id }; default: outfitIDs = [] }
            let outfits = try store.outfits()
            proposal.sources = try Set(outfitIDs).map { id in
                guard let value = outfits.first(where: { $0.id == id }) else { throw PieceStore.StoreError.staleRevision }
                return AgentSelectedRecord(id: id, kind: .outfit, revision: value.revision)
            }
            conversation.proposals = (conversation.proposals ?? []) + [proposal]; _ = persist()
        } catch { self.error = "A selected record is unavailable. Review the draft again." }
    }
    func cancelProposal(_ id: UUID) {
        guard let i = conversation.proposals?.firstIndex(where: { $0.id == id }), !hasPendingOperation else { return }
        do { try conversation.proposals?[i].cancel(); _ = persist() }
        catch { self.error = "This operation may already have committed. Check its result before continuing." }
    }
    func approveProposal(_ id: UUID, version: Int) {
        guard !active, !hasPendingOperation, let i = conversation.proposals?.firstIndex(where: { $0.id == id }),
              let proposal = conversation.proposals?[i], proposal.version == version,
              proposal.status == .proposed || proposal.status == .executing else { return }
        do {
            try conversation.proposals?[i].approve(version: version)
            guard persist(), let proposal = conversation.proposals?[i] else { return }
            let receipt: AgentActionReceipt
            switch proposal.action {
            case .availability(let change):
                let piece = try store.setAvailability(id: change.pieceID, value: change.value, expectedRevision: change.expectedRevision, operationID: change.operationID)
                receipt = AgentActionReceipt(recordID: piece.id, kind: "piece")
            case .theme(let draft):
                if try store.savedTheme(for: draft) == nil { try validateSources(proposal); try store.saveThemeDraft(draft) }
                let value = try store.saveTheme(draft)
                if try store.themeDraft() == draft { try store.finishThemeDraft(draft) }
                receipt = AgentActionReceipt(recordID: value.id, kind: "theme")
            case .outfit(let draft):
                if try store.savedOutfit(for: draft) == nil { try validateSources(proposal); try store.saveOutfitDraft(draft) }
                let value = try store.saveOutfit(draft)
                if try store.outfitDraft() == draft { try store.acknowledgeOutfitReceipt(draft) }
                receipt = AgentActionReceipt(recordID: value.id, kind: "outfit")
            case .plan(let draft):
                if try store.savedPlanAuthoring(draft) == nil { try validateSources(proposal); try store.savePlanAuthoringDraft(draft) }
                let value = try store.savePlanAuthoring(draft)
                if try store.planAuthoringDraft() == draft { try store.finishPlanAuthoring(draft) }
                receipt = AgentActionReceipt(recordID: value.plan.id, kind: "plan")
            case .wear(let draft):
                if try store.savedWear(for: draft) == nil { try store.saveWearDraft(draft) }
                let value = try store.saveWear(draft)
                if try store.wearDraft() == draft { try store.finishWearDraft(draft) }
                receipt = AgentActionReceipt(recordID: value.id, kind: "wear")
            }
            conversation.proposals?[i].receipt = receipt; conversation.proposals?[i].status = .succeeded; _ = persist()
        } catch {
            switch error {
            case is ThemeValidationError, is OutfitValidationError, is PlanValidationError, is PlanAuthoringError, is WearValidationError, PieceStore.StoreError.staleRevision:
                conversation.proposals?[i].status = .proposed; _ = persist()
            default: break
            }
            self.error = "The reviewed change wasn’t confirmed. Changed records require a new review. For an unconfirmed save, check the same operation before making another draft."
        }
    }
    private func validateSources(_ proposal: AgentActionProposal) throws {
        let outfits = try store.outfits()
        for source in proposal.sources ?? [] {
            guard source.kind == .outfit, outfits.contains(where: { $0.id == source.id && $0.revision == source.revision }) else { throw PieceStore.StoreError.staleRevision }
        }
    }
    func send(retrying messageID: UUID? = nil) {
        guard canGenerate, let qualification else { return }
        do {
            let context = conversation.context
            let pieces = context.scope == .general ? [] : try store.pieces()
            let outfits = context.scope == .selected ? try store.outfits() : []
            let themes = context.scope == .selected ? try store.themes() : []
            let snapshot = try AgentContextSnapshot.build(context, pieces: pieces, outfits: outfits, themes: themes, maximumPieces: qualification.maximumPieces)
            let data = try JSONEncoder().encode(snapshot)
            var prompt = "Authorized context: " + String(decoding: data, as: UTF8.self)
            if context.includesStyle, let style = try store.localExperience().style?.answers {
                prompt += "\nAllowed style: " + (0..<4).map { style.summary(at: $0) }.joined(separator: "; ")
                if let body = style.body.suggestionContext(styleContextEnabled: true) { prompt += "\nOptional self-described body: \(body)" }
            }
            if context.includesWear && context.scope != .general {
                let through = LocalPlanDay()
                let ids = Set(snapshot.pieces.map(\.id))
                let records = try store.wearRecords().filter { record in record.day.key <= through.key && (context.scope != .selected || record.pieces.contains { ids.contains($0.id) }) }
                prompt += "\nTrusted recorded wear through \(through.key): \(records.count) records across \(Set(records.map(\.day.key)).count) distinct dates. Plans are not wear."
            }
            if let selected = context.weather, let client = weatherClient,
               let snapshot = client.cached(selected), let reading = snapshot.reading(for: selected.day, now: Date(), qualified: client.qualified), reading.freshness(at: Date()) == .fresh {
                prompt += "\nExplicit Apple Weather context: \(selected.place.name), \(selected.day.key), \(selected.day.timeZoneID). Provider \(reading.providerDate), fetched \(reading.fetchedAt). " + String(decoding: try JSONEncoder().encode(reading), as: UTF8.self)
            } else { prompt += "\nWeather not checked or unavailable. Do not infer current weather." }
            // Keep every prior user instruction or request a new conversation. Never silently drop turns.
            prompt += "\nConversation:\n" + conversation.messages.filter {
                $0.id != messageID && ($0.role == .user || $0.status == .complete)
            }.map { "\($0.role.rawValue): \($0.source)" }.joined(separator: "\n")
            if messageID == nil { prompt += "\nuser: " + conversation.draft }
            guard prompt.count <= qualification.maximumPromptCharacters else { error = "This conversation exceeds the on-device context budget. Start a new conversation; this history and draft will stay."; return }
            let attempt = try messageID.map { try conversation.retry(messageID: $0) } ?? conversation.beginAttempt()
            conversation.messages[conversation.messages.count - 1].contextSummary = snapshot.summary
            guard persist() else { conversation.interruptActiveAttempt(); return }
            let conversationID = conversation.id, start = ContinuousClock.now
            slow = false
            timeout = Task { [weak self] in
                try? await Task.sleep(for: .seconds(qualification.slowSeconds)); guard !Task.isCancelled else { return }
                self?.slow = true
                try? await Task.sleep(for: .seconds(qualification.timeoutSeconds - qualification.slowSeconds)); guard !Task.isCancelled else { return }
                self?.error = "The response timed out. Your message and any partial response are retained."; self?.generation?.cancel()
            }
            generation = Task { [weak self] in
                guard let self else { return }
                defer { timeout?.cancel(); timeout = nil; generation = nil; slow = false }
                do {
                    for try await text in provider(prompt, qualification.responseTokens) {
                        try Task.checkCancellation()
                        guard conversation.id == conversationID, let i = conversation.messages.firstIndex(where: { $0.attemptID == attempt && $0.isActive && $0.status != .stopping }) else { throw CancellationError() }
                        guard text.hasPrefix(conversation.messages[i].source) else { throw CocoaError(.coderInvalidValue) }
                        conversation.messages[i].source = text; conversation.messages[i].status = .streaming
                        if conversation.messages[i].firstTextSeconds == nil && !text.isEmpty { conversation.messages[i].firstTextSeconds = seconds(since: start) }
                        guard persist() else { throw CocoaError(.fileWriteUnknown) }
                    }
                    try Task.checkCancellation(); try conversation.complete(attemptID: attempt)
                } catch {
                    if let i = conversation.messages.firstIndex(where: { $0.attemptID == attempt }) {
                        if conversation.messages[i].status != .interrupted {
                            conversation.messages[i].status = conversation.messages[i].status == .stopping ? .stopped : (conversation.messages[i].source.isEmpty ? .failed : .interrupted)
                        }
                        conversation.messages[i].failureReason = self.error ?? (conversation.messages[i].status == .stopped ? "Stopped by you. The partial response is retained." : "The response could not finish. Your message and any partial response are retained; try again.")
                    }
                }
                if let i = conversation.messages.firstIndex(where: { $0.attemptID == attempt }) { conversation.messages[i].elapsedSeconds = seconds(since: start) }
                _ = persist()
            }
        } catch { self.error = "Context changed or could not be read. Review the selected records and try again. Your draft is retained." }
    }
    private func seconds(since start: ContinuousClock.Instant) -> Double {
        let value = start.duration(to: .now).components
        return Double(value.seconds) + Double(value.attoseconds) / 1e18
    }
    func stop() {
        guard let i = conversation.messages.firstIndex(where: \.isActive), conversation.messages[i].status != .stopping else { return }
        conversation.messages[i].status = .stopping; _ = persist(); generation?.cancel()
    }
    func suspend() {
        conversation.interruptActiveAttempt()
        generation?.cancel(); _ = persist()
    }
    func retryPending() {
        if let deletion, let value = history.first(where: { $0.id == deletion.0 }) { delete(value) }
        else { _ = persist() }
    }
    func recheckAvailability() { availability = OutfitSuggestions.availability(); if active && !supportsGeneration { suspend() } }
}
