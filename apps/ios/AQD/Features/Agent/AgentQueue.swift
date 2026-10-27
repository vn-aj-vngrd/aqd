import AQDCore
import Foundation

/// Messages typed while a reply is still being written. They wait in order, are sent one at a time when the reply finishes, and come back
/// to the composer if the reply was stopped or failed, so nothing the owner typed is lost.
@MainActor extension AgentModel {
    var canQueue: Bool { active && supportsGeneration && !hasPendingOperation && queuedMessages.count < Self.queueLimit }

    /// Moves the typed text to the queue. Photos and files are not queued: they need the reply that is running to finish first.
    @discardableResult func queueDraft() -> Bool {
        let text = conversation.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canQueue, !text.isEmpty, (conversation.draftAttachments ?? []).isEmpty else { return false }
        queuedMessages.append(String(text.prefix(2_000)))
        updateDraft("")
        return true
    }

    func removeQueued(at index: Int) {
        guard queuedMessages.indices.contains(index) else { return }
        queuedMessages.remove(at: index)
    }

    /// Gives the queued words back to the composer, ahead of anything typed since.
    func restoreQueueToDraft() {
        guard !queuedMessages.isEmpty else { return }
        let joined = queuedMessages.joined(separator: "\n")
        queuedMessages = []
        let current = conversation.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        updateDraft(current.isEmpty ? joined : joined + "\n" + current)
    }

    /// Called when a reply has ended. Only a finished reply continues the queue.
    func drainQueue() {
        guard !queuedMessages.isEmpty else { return }
        let finished = conversation.messages.last { $0.role == .assistant }?.status == .complete
        guard finished, conversation.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { restoreQueueToDraft(); return }
        // The ended reply's task is still unwinding; sending from inside it would let its cleanup clear the next reply's handle.
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            self?.sendNextQueued()
        }
    }

    func sendNextQueued() {
        guard !queuedMessages.isEmpty else { return }
        guard canGenerate, conversation.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { restoreQueueToDraft(); return }
        updateDraft(queuedMessages.removeFirst())
        send()
    }
}
