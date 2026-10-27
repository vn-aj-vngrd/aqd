import AQDCore
import Foundation
import Observation

@MainActor @Observable final class AgentModel {
    let store: PieceStore
    var conversation: AgentConversation
    var history: [AgentConversation] = []
    /// When each conversation was last seen on screen; kept on this device only.
    private(set) var readMarks: [UUID: Date] = AgentModel.loadReadMarks()
    var error: String?
    var availability = OutfitSuggestions.modelAvailability()
    var weatherClient: WeatherClient?
    var controls: AgentControlsModel?
    let qualification: AgentQualification?
    var attachmentImportCount = 0
    let usesNativeProvider: Bool
    static let toolRecordLimit = 6
    static let streamSaveInterval: Duration = .seconds(1)
    let provider: @MainActor (String, Int) -> AsyncThrowingStream<String, any Error>
    var toolCalls = 0
    /// Names of the tools the current turn called, for diagnostics and the eval. The app's own fallbacks carry a " (app)" suffix.
    var calledTools: [String] = []
    /// Set by the timeout task so the failure reads as a timeout, not a generic interruption.
    var timedOut = false
    /// Handles for this turn's records and attached images; the model sees these and names, never UUIDs.
    var recordIndex = AgentRecordIndex()
    var attachmentHandles: [String: UUID] = [:]
    var toolProposals: [(AgentMutationRequest, UUID)] = []
    /// Messages typed while a reply is still being written. They are sent one at a time, in order, once it finishes.
    var queuedMessages: [String] = []
    static let queueLimit = 3
    var stagedPlanDays: [String: [AgentPlanAssignment]] = [:]
    private var generation: Task<Void, Never>?
    private var timeout: Task<Void, Never>?
    var slow = false
    var active: Bool { conversation.messages.contains(where: \.isActive) }
    var supportsGeneration: Bool { qualification?.isValid == true && [.available, .awaitingQualification].contains(availability) }
    /// True for the moment the model takes to choose an intent when no rule is sure; sending is paused meanwhile.
    var classifying = false
    var canGenerate: Bool { supportsGeneration && attachmentImportCount == 0 && !active && !classifying && pending == nil && deletion == nil && metadataSave == nil && controls?.hasPending != true }
    var hasPendingOperation: Bool { pending != nil || deletion != nil || metadataSave != nil }
    private var pending: (AgentConversation, UUID)?
    private var retention: Task<Void, Never>?
    private var metadataSave: (AgentConversation, UUID)?
    private var deletion: (UUID, Int, UUID)?
    init(store: PieceStore, qualification: AgentQualification? = AgentQualification.current, reconcileInterruptedAttempt: Bool = true,
         provider: (@MainActor (String, Int) -> AsyncThrowingStream<String, any Error>)? = nil) throws {
        self.store = store; self.qualification = qualification; self.provider = provider ?? NativeAgentProvider.stream; usesNativeProvider = provider == nil
        conversation = AgentConversation(ownerID: try store.todayConfiguration().ownerID)
        reloadHistory()
        if provider == nil { Task { await NativeAgentProvider.prime(instructions: AgentIntent.allCases.map(AgentInstructions.compose)) } }
        if let latest = history.first(where: { !$0.isArchived }) { conversation = latest }
        if conversation.messages.contains(where: \.isActive) {
            conversation.interruptActiveAttempt()
            if reconcileInterruptedAttempt { _ = persist() }
        }
    }
    func reloadHistory() {
        do { history = try store.agentConversations(); if !hasPendingOperation { error = nil } }
        catch { self.error = "Conversations couldn’t load. Your saved history and draft are retained. Try again." }
    }
    func updateDraft(_ text: String) {
        conversation.draft = text; retention?.cancel()
        retention = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }; _ = self?.persist()
        }
    }
    func addAttachment(_ value: AgentAttachment, to conversationID: UUID, order: [UUID] = []) {
        guard conversation.id == conversationID, !active else { return }
        do {
            var values = conversation.draftAttachments ?? []; values.append(value)
            try AgentAttachment.validate(values)
            if !order.isEmpty { values.sort { (order.firstIndex(of: $0.id) ?? Int.max) < (order.firstIndex(of: $1.id) ?? Int.max) } }
            conversation.draftAttachments = values; _ = persist()
        } catch { self.error = "Attach up to four photos or documents. This attachment couldn’t be added; your draft is retained." }
    }
    func removeAttachment(_ id: UUID) {
        guard !active, !hasPendingOperation else { return }
        conversation.draftAttachments?.removeAll { $0.id == id }
        if conversation.draftAttachments?.isEmpty == true { conversation.draftAttachments = nil }
        _ = persist()
    }
    @discardableResult func persist() -> Bool {
        retention?.cancel()
        guard metadataSave == nil else { return false }
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
               saved.draft == conversation.draft, saved.draftAttachments == conversation.draftAttachments, saved.context == conversation.context, saved.messages == conversation.messages, saved.proposals == conversation.proposals, saved.pinnedAt == conversation.pinnedAt, saved.archivedAt == conversation.archivedAt {
                if !hasPendingOperation { error = nil }; return true
            }
            if conversation.revision == 0 && conversation.draft.isEmpty && (conversation.draftAttachments ?? []).isEmpty && conversation.messages.isEmpty && (conversation.proposals ?? []).isEmpty && conversation.context == AgentContext() { return true }
            pending = (conversation, UUID())
            let result = try store.saveAgentConversation(conversation, operationID: pending!.1)
            pending = nil; conversation = result; reloadHistory(); return true
        } catch { self.error = "The conversation save wasn’t confirmed. Your text is still here. Retry checks the same save before writing again."; return false }
    }
    private static let readMarksKey = "agent.readMarks"
    private static func loadReadMarks() -> [UUID: Date] {
        let stored = UserDefaults.standard.dictionary(forKey: readMarksKey) as? [String: Double] ?? [:]
        return Dictionary(uniqueKeysWithValues: stored.compactMap { key, value in UUID(uuidString: key).map { ($0, Date(timeIntervalSince1970: value)) } })
    }
    /// A finished reply the user has not seen yet.
    func isUnread(_ value: AgentConversation) -> Bool {
        guard let last = value.messages.last, last.role == .assistant, last.status == .complete else { return false }
        return last.createdAt.addingTimeInterval(last.elapsedSeconds ?? 0) > (readMarks[value.id] ?? .distantPast)
    }
    func markCurrentRead() {
        guard !conversation.messages.isEmpty else { return }
        readMarks[conversation.id] = Date()
        UserDefaults.standard.set(Dictionary(uniqueKeysWithValues: readMarks.map { ($0.key.uuidString, $0.value.timeIntervalSince1970) }), forKey: Self.readMarksKey)
    }
    func newConversation() { guard !active, attachmentImportCount == 0, deletion == nil, persist() else { return }; conversation = AgentConversation(ownerID: conversation.ownerID) }
    func open(_ id: UUID) {
        guard !active, attachmentImportCount == 0, deletion == nil, persist() else { return }; reloadHistory()
        guard let value = history.first(where: { $0.id == id }) else { error = "This conversation is unavailable. Start a new conversation."; return }
        conversation = value
        if conversation.messages.contains(where: \.isActive) { conversation.interruptActiveAttempt(); _ = persist() }
    }
    func setOrganization(_ value: AgentConversation, pinned: Bool? = nil, archived: Bool? = nil) {
        guard !active, !hasPendingOperation, persist() else { return }
        guard var latest = history.first(where: { $0.id == value.id }) else { return }
        if let pinned { latest.pinnedAt = pinned ? Date() : nil }
        if let archived { latest.archivedAt = archived ? Date() : nil }
        metadataSave = (latest, UUID())
        reconcileOrganization()
    }
    private func reconcileOrganization() {
        guard let (value, operation) = metadataSave else { return }
        do {
            let saved = try store.saveAgentConversation(value, operationID: operation)
            metadataSave = nil
            if conversation.id == saved.id {
                conversation.revision = saved.revision
                conversation.updatedAt = saved.updatedAt
                conversation.pinnedAt = saved.pinnedAt
                conversation.archivedAt = saved.archivedAt
            }
            reloadHistory()
        } catch PieceStore.StoreError.staleRevision {
            metadataSave = nil; reloadHistory()
            self.error = "This conversation changed. Reopen it before trying again."
        } catch {
            self.error = "The conversation update wasn’t confirmed. Try again to check the same change."
        }
    }
    @discardableResult func saveFeedback(_ value: AgentFeedback, removing: Bool = false) -> Bool {
        guard !active, !hasPendingOperation, persist() else { return false }
        do {
            if !removing { try value.validated() }
            guard let conversationID = value.conversationID, let messageID = value.messageID,
                  var target = try store.agentConversations().first(where: { $0.id == conversationID }),
                  let index = target.messages.firstIndex(where: { $0.id == messageID && $0.role == .assistant }) else { throw PieceStore.StoreError.staleRevision }
            var feedback = target.messages[index].feedback ?? []
            guard removing || target.messages[index].attemptID == value.attemptID || feedback.contains(where: { $0.id == value.id && $0.attemptID == value.attemptID }) else { throw PieceStore.StoreError.staleRevision }
            if removing { feedback.removeAll { $0.id == value.id } }
            else { feedback.removeAll { $0.attemptID == value.attemptID }; feedback.append(value) }
            target.messages[index].feedback = feedback
            if conversation.id == target.id {
                conversation.messages[index].feedback = feedback
                return persist()
            }
            metadataSave = (target, UUID()); reconcileOrganization()
            return metadataSave == nil && error == nil
        } catch {
            self.error = "This response changed or couldn’t be read. Your feedback hasn’t replaced another response. Refresh and try again."
            return false
        }
    }

    func delete(_ value: AgentConversation) {
        guard !active, metadataSave == nil, pending == nil else { return }
        guard deletion == nil || deletion?.0 == value.id else { return }
        deletion = deletion ?? (value.id, value.revision, UUID())
        reconcileDeletion()
    }
    private func reconcileDeletion() {
        guard !active, let request = deletion else { return }
        do {
            try store.deleteAgentConversation(id: request.0, expectedRevision: request.1, operationID: request.2)
            self.deletion = nil
            if conversation.id == request.0 { pending = nil; retention?.cancel(); conversation = AgentConversation(ownerID: conversation.ownerID) }
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
    func propose(_ action: AgentReviewedAction, attemptID: UUID? = nil) {
        guard !active, !hasPendingOperation else { return }
        do {
            var proposal = AgentActionProposal(action: action)
            proposal.attemptID = attemptID
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
        // A new piece from a photo is saved only through the Closet editor, which owns the full-quality photo.
        if case .piece(let change) = proposal.action, change.isNewPiece { return }
        do {
            if let request = proposal.toolRequest {
                let preferences = try store.localSettings().agentPreferences ?? AgentPreferences()
                guard conversation.context.automatic == true, conversation.context.scope == .closet,
                      request.kind.requiredSources.allSatisfy(preferences.allows) else { throw PieceStore.StoreError.staleRevision }
            }
            // Undo needs the record as it was, which only the first attempt can still read; a retry after an unconfirmed save finds it already changed.
            let firstAttempt = proposal.status == .proposed
            try conversation.proposals?[i].approve(version: version)
            guard persist(), let proposal = conversation.proposals?[i] else { return }
            let receipt: AgentActionReceipt
            switch proposal.effectiveAction {
            case .piece(let change):
                let before = firstAttempt ? try priorPieceDraft(change.draft.itemID) : nil
                let value = try store.savePiece(change.draft, operationID: change.operationID)
                receipt = AgentActionReceipt(recordID: value.id, kind: "piece", undo: before.map { .piece(previous: $0, appliedRevision: value.revision) })
            case .profile(let draft):
                if try store.savedIdentity(for: draft) == nil {
                    guard try store.localIdentity() == draft.base else { throw PieceStore.StoreError.staleRevision }
                    guard try store.identityDraft().map({ $0 == draft }) ?? true else { throw PieceStore.StoreError.staleDraft }
                    try store.saveIdentityDraft(draft)
                }
                let before = firstAttempt ? try store.localIdentity() : nil
                let value = try store.saveIdentity(draft)
                if try store.identityDraft() == draft { try store.finishIdentityDraft(draft) }
                receipt = AgentActionReceipt(recordID: value.ownerID, kind: "profile", undo: before.map { .profile(previous: $0, appliedRevision: value.revision) })
            case .availability(let change):
                let before = firstAttempt ? try priorPieceDraft(change.pieceID)?.availability : nil
                let piece = try store.setAvailability(id: change.pieceID, value: change.value, expectedRevision: change.expectedRevision, operationID: change.operationID)
                receipt = AgentActionReceipt(recordID: piece.id, kind: "piece", undo: before.map { .availability(pieceID: piece.id, previous: $0, appliedRevision: piece.revision) })
            case .tidy(let change):
                receipt = try applyTidy(change)
            case .theme(let draft):
                if try store.savedTheme(for: draft) == nil { guard try store.themeDraft().map({ $0 == draft }) ?? true else { throw PieceStore.StoreError.staleDraft }; try validateSources(proposal); try store.saveThemeDraft(draft) }
                let before = draft.baseRevision > 0 && firstAttempt ? try store.themes().first { $0.id == draft.themeID } : nil
                let value = try store.saveTheme(draft)
                if try store.themeDraft() == draft { try store.finishThemeDraft(draft) }
                receipt = AgentActionReceipt(recordID: value.id, kind: "theme", undo: draft.baseRevision == 0 ? .themeCreate(id: value.id, appliedRevision: value.revision) : before.map { .themeEdit(previous: $0, appliedRevision: value.revision) })
            case .outfit(let draft):
                if try store.savedOutfit(for: draft) == nil { guard try store.outfitDraft().map({ $0 == draft }) ?? true else { throw PieceStore.StoreError.staleDraft }; try validateSources(proposal); try store.saveOutfitDraft(draft) }
                let before = draft.baseRevision > 0 && firstAttempt ? try store.outfit(id: draft.outfitID) : nil
                let value = try store.saveOutfit(draft)
                if try store.outfitDraft() == draft { try store.acknowledgeOutfitReceipt(draft) }
                receipt = AgentActionReceipt(recordID: value.id, kind: "outfit", undo: draft.baseRevision == 0 ? .outfitCreate(id: value.id, appliedRevision: value.revision) : before.map { .outfitEdit(previous: $0, appliedRevision: value.revision) })
            case .plan(let draft):
                if try store.savedPlanAuthoring(draft) == nil { guard try store.planAuthoringDraft().map({ $0 == draft }) ?? true else { throw PieceStore.StoreError.staleDraft }; try validateSources(proposal); try store.savePlanAuthoringDraft(draft) }
                let value = try store.savePlanAuthoring(draft)
                if try store.planAuthoringDraft() == draft { try store.finishPlanAuthoring(draft) }
                let entries = value.entries.map { AgentUndo.Entry(id: $0.id, revision: $0.revision) }
                var undo: AgentUndo?
                if let base = draft.basePlan {
                    // The days as they were reviewed; an edit can only be put back if that picture is known.
                    if firstAttempt, let was = draft.baseEntries { undo = .planEdit(planID: base.id, previous: .init(name: base.name, days: was.map { .init(dayKey: $0.day.key, outfitID: $0.outfitID) }), appliedRevision: value.plan.revision, entries: entries) }
                } else { undo = .planCreate(id: value.plan.id, appliedRevision: value.plan.revision, entries: entries) }
                receipt = AgentActionReceipt(recordID: value.plan.id, kind: "plan", undo: undo)
            case .trip(let draft):
                receipt = try applyTrip(draft)
            case .wear(let draft):
                if try store.savedWear(for: draft) == nil { guard try store.wearDraft().map({ $0 == draft }) ?? true else { throw PieceStore.StoreError.staleDraft }; try store.saveWearDraft(draft) }
                let value = try store.saveWear(draft)
                if try store.wearDraft() == draft { try store.finishWearDraft(draft) }
                receipt = AgentActionReceipt(recordID: value.id, kind: "wear", undo: .wear(id: value.id, appliedRevision: value.revision))
            }
            conversation.proposals?[i].receipt = receipt; conversation.proposals?[i].status = .succeeded; _ = persist()
        } catch {
            switch error {
            case is ThemeValidationError, is OutfitValidationError, is PlanValidationError, is PlanAuthoringError, is WearValidationError, PieceStore.StoreError.staleRevision, PieceStore.StoreError.staleDraft:
                // An outfit that changed since the review cannot be applied; the proposal closes so a fresh review can be prepared.
                let outdated = error as? PieceStore.StoreError == .staleRevision && !(conversation.proposals?[i].sources ?? []).isEmpty
                conversation.proposals?[i].status = outdated ? .cancelled : .proposed; _ = persist()
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
    /// Sends the draft, or retries a reply. When no rule is sure what the request is, the model chooses its intent first (a moment's pause).
    func send(retrying messageID: UUID? = nil) {
        guard canGenerate, qualification != nil else { return }
        guard usesNativeProvider, conversation.context.automatic == true, conversation.context.scope == .closet else { performSend(retrying: messageID); return }
        let request = messageID == nil ? conversation.draft : conversation.messages.last(where: { $0.role == .user })?.source ?? ""
        var prior = conversation
        if messageID != nil, prior.messages.count >= 2 { prior.messages.removeLast(2) }
        let rules = AgentIntent.decide(request, conversation: prior, hasImage: !turnImages(retrying: messageID).isEmpty)
        guard !rules.confident else { performSend(retrying: messageID, intent: (rules.intent, "rules")); return }
        classifying = true
        let draft = conversation.draft, previous = AgentIntent.context(of: prior).previous
        Task { [weak self] in
            let chosen = await AgentIntentClassifier.classify(request, rule: rules.intent, previous: previous)
            guard let self else { return }
            classifying = false
            // An edit, a new chat or a stop during that moment cancels the send.
            guard conversation.draft == draft, supportsGeneration, !active else { return }
            performSend(retrying: messageID, intent: chosen.map { ($0, "model") } ?? (rules.intent, "rules"))
        }
    }

    func performSend(retrying messageID: UUID? = nil, intent decided: (intent: AgentIntent, source: String)? = nil) {
        guard canGenerate, let qualification else { return }
        do {
            let preferences = try store.localSettings().agentPreferences ?? AgentPreferences()
            let turn = try buildTurn(retrying: messageID, preferences: preferences, qualification: qualification, intent: decided)
            let images = turn.images
            attachmentHandles = Dictionary(uniqueKeysWithValues: images.enumerated().map { ("a\($0.offset + 1)", $0.element.id) })
            let attempt = try messageID.map { try conversation.retry(messageID: $0) } ?? conversation.beginAttempt()
            conversation.messages[conversation.messages.count - 1].contextSummary = turn.contextSummary
            conversation.messages[conversation.messages.count - 1].diagnostics = turn.diagnostics
            toolCalls = 0; toolProposals = []; stagedPlanDays = [:]; calledTools = []; timedOut = false
            if let diagnostics = turn.diagnostics, diagnostics.included > 0 || !diagnostics.sources.isEmpty {
                let summary = turn.catalogSummary.isEmpty ? "Read \(diagnostics.included) closet item" + (diagnostics.included == 1 ? "" : "s") : "Read your closet: " + turn.catalogSummary
                appendToolStep(AgentToolStep(tool: "context", summary: summary, count: diagnostics.included), attemptID: attempt)
            }
            // A request the app can answer from records shows its cards first; the model only frames them.
            if let fast = turn.plan.fast {
                for step in fast.steps { appendToolStep(step, attemptID: attempt) }
                calledTools += fast.calls
            }
            guard persist() else {
                conversation.messages[conversation.messages.count - 1].diagnostics?.failure = .storage
                conversation.interruptActiveAttempt(); return
            }
            let conversationID = conversation.id, start = ContinuousClock.now
            slow = false
            timeout = Task { [weak self] in
                try? await Task.sleep(for: .seconds(qualification.slowSeconds)); guard !Task.isCancelled else { return }
                self?.slow = true
                try? await Task.sleep(for: .seconds(qualification.timeoutSeconds - qualification.slowSeconds)); guard !Task.isCancelled else { return }
                self?.timedOut = true; self?.generation?.cancel()
            }
            generation = Task { [weak self] in
                guard let self else { return }
                defer { timeout?.cancel(); timeout = nil; generation = nil; slow = false }
                await generate(turn: turn, images: images, attempt: attempt, conversationID: conversationID, start: start, qualification: qualification)
                recordToolCalls(attemptID: attempt)
                if let i = conversation.messages.firstIndex(where: { $0.attemptID == attempt }) { conversation.messages[i].elapsedSeconds = seconds(since: start) }
                _ = persist()
                drainQueue()
            }
        } catch is AgentTurnRefused {
            return
        } catch AgentContextError.budgetExceeded {
            failTurnBeforeStart(.contextTooLong, retrying: messageID)
        } catch AgentContextError.selectionRequired {
            self.error = "This request can include up to \(qualification.maximumPieces) pieces. Choose Selected pieces and reduce your selection, or continue Without closet. Your draft is retained."
        } catch { self.error = "Context changed or could not be read. Review the selected records and try again. Your draft is retained." }
    }
    /// The typed reason a reply failed, from the error that ended it.
    func failureKind(for error: any Error, message: AgentMessage) -> AgentFailure.Kind {
        if let provider = error as? AgentProviderError {
            switch provider {
            case .contextLimit: return .contextTooLong
            case .guardrail: return .guardrail
            case .unsupportedLanguage: return .unsupportedLanguage
            case .unavailable: return .modelUnavailable
            case .preparing: return .modelPreparing
            case .intelligenceOff: return .intelligenceOff
            }
        }
        if timedOut { return .timedOut }
        if hasPendingOperation { return .storage }
        if error is AgentContextError { return .contextTooLong }
        if error is CancellationError { return .interrupted }
        if message.source.isEmpty, (message.toolSteps ?? []).contains(where: { $0.rejection != nil }) { return .toolRejected }
        return .generation
    }

    /// A request too large to send still gets a turn, so the owner sees why and can shorten it, drop the closet or start over.
    func failTurnBeforeStart(_ kind: AgentFailure.Kind, retrying messageID: UUID?) {
        do {
            let attempt = try messageID.map { try conversation.retry(messageID: $0) } ?? conversation.beginAttempt()
            guard let i = conversation.messages.lastIndex(where: { $0.attemptID == attempt }) else { return }
            conversation.messages[i].status = .failed
            conversation.messages[i].failure = .make(kind, closetIncluded: conversation.context.automatic == true && conversation.context.scope == .closet)
            conversation.messages[i].failureReason = "The request did not fit the on-device model. Your message is kept."
            conversation.messages[i].elapsedSeconds = 0
            _ = persist()
        } catch { self.error = "This chat has reached its on-device context limit. Start a new conversation; your messages and draft stay here." }
    }

    func performFailureAction(_ action: AgentFailure.Action, messageID: UUID) {
        switch action {
        case .retry: send(retrying: messageID)
        case .continueWithoutCloset:
            guard !active else { return }
            conversation.context.scope = .general; conversation.context.automatic = false
            send(retrying: messageID)
        case .newChat:
            let text = conversation.messages.last(where: { $0.role == .user })?.source ?? conversation.draft
            guard !active, persist() else { return }
            newConversation(); updateDraft(text)
        case .shorten, .edit: reviseLastRequest()
        case .openSettings: break
        }
    }

    /// Puts the failed request back in the composer so it can be edited, and drops the failed turn.
    func reviseLastRequest() {
        guard !active, !hasPendingOperation, conversation.reviseFailedRequest() != nil else { return }
        _ = persist()
    }

    func recordToolCalls(attemptID: UUID) {
        guard let i = conversation.messages.lastIndex(where: { $0.attemptID == attemptID && $0.role == .assistant }), conversation.messages[i].diagnostics != nil else { return }
        conversation.messages[i].diagnostics?.toolCalls = Array(calledTools.prefix(64))
    }
    func seconds(since start: ContinuousClock.Instant) -> Double {
        let value = start.duration(to: .now).components
        return Double(value.seconds) + Double(value.attoseconds) / 1e18
    }
    func stop() {
        restoreQueueToDraft()
        guard let i = conversation.messages.firstIndex(where: \.isActive), conversation.messages[i].status != .stopping else { return }
        conversation.messages[i].status = .stopping; _ = persist(); generation?.cancel()
    }
    func suspend() {
        restoreQueueToDraft()
        conversation.interruptActiveAttempt()
        generation?.cancel(); _ = persist()
    }
    func retryPending() {
        if metadataSave != nil { reconcileOrganization(); if metadataSave == nil { _ = persist() } }
        else if deletion != nil { reconcileDeletion() }
        else { _ = persist() }
    }
    func recheckAvailability() { availability = OutfitSuggestions.modelAvailability(); if active && !supportsGeneration { suspend() } }
}
