import AQDCore
import Foundation
import Observation

@MainActor @Observable final class AgentModel {
    let store: PieceStore
    var conversation: AgentConversation
    var history: [AgentConversation] = []
    var error: String?
    var availability = OutfitSuggestions.availability()
    private var pending: (AgentConversation, UUID)?
    private var retention: Task<Void, Never>?
    private var deletion: (UUID, Int, UUID)?
    init(store: PieceStore) throws {
        self.store = store
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
                let acknowledged = try store.saveAgentConversation(value, operationID: operation)
                conversation.revision = acknowledged.revision; pending = nil
                // Input may have changed while an earlier save was unconfirmed.
                if conversation == value { conversation = acknowledged }
            }
            if let saved = history.first(where: { $0.id == conversation.id }),
               saved.draft == conversation.draft, saved.context == conversation.context, saved.messages == conversation.messages { error = nil; return true }
            if conversation.revision == 0 && conversation.draft.isEmpty && conversation.messages.isEmpty && conversation.context == AgentContext() { return true }
            pending = (conversation, UUID())
            let result = try store.saveAgentConversation(conversation, operationID: pending!.1)
            pending = nil; conversation = result; reloadHistory(); return true
        } catch { self.error = "The conversation save wasn’t confirmed. Your text is still here. Retry checks the same save before writing again."; return false }
    }
    func newConversation() { guard persist() else { return }; conversation = AgentConversation(ownerID: conversation.ownerID) }
    func open(_ id: UUID) {
        guard persist() else { return }; reloadHistory()
        guard let value = history.first(where: { $0.id == id }) else { error = "This conversation is unavailable. Start a new conversation."; return }
        conversation = value
        if conversation.messages.contains(where: \.isActive) { conversation.interruptActiveAttempt(); _ = persist() }
    }
    func delete(_ value: AgentConversation) {
        guard deletion == nil || deletion?.0 == value.id else { return }
        deletion = deletion ?? (value.id, value.revision, UUID())
        do {
            guard let deletion else { return }
            try store.deleteAgentConversation(id: deletion.0, expectedRevision: deletion.1, operationID: deletion.2)
            self.deletion = nil
            if conversation.id == value.id { pending = nil; retention?.cancel(); conversation = AgentConversation(ownerID: value.ownerID) }
            reloadHistory()
        } catch { self.error = "Deletion wasn’t confirmed. Retry checks the same conversation operation. Saved outfits and plans are unaffected." }
    }
    func retryPending() {
        if let deletion, let value = history.first(where: { $0.id == deletion.0 }) { delete(value) }
        else { _ = persist() }
    }
    func recheckAvailability() { availability = OutfitSuggestions.availability() }
}
