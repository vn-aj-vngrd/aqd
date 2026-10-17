import AQDCore
import Foundation
import Observation

/// A pending picker import never changes typed text or sends a message.
@MainActor @Observable final class AgentAttachmentImporter {
    struct Pending: Identifiable { let id: UUID; let name: String; var error: String? }
    private(set) var pending: [Pending] = []
    private var jobs: [UUID: Task<Void, Never>] = [:]
    private var deadlines: [UUID: Task<Void, Never>] = [:]
    let model: AgentModel
    init(model: AgentModel) { self.model = model }
    var count: Int { (model.conversation.draftAttachments ?? []).count + pending.count }
    func add(name: String, operation: @escaping @Sendable () async throws -> AgentAttachment) {
        guard count < AgentAttachment.maximumCount, !model.active, !model.hasPendingOperation else { model.error = "Attach up to four photos or files per message."; return }
        let id = UUID(), conversationID = model.conversation.id
        pending.append(Pending(id: id, name: name)); updateCount()
        jobs[id] = Task { [weak self] in
            do {
                let value = try await AgentAttachmentReader.perform(operation)
                guard let self, !Task.isCancelled, pending.contains(where: { $0.id == id }), model.conversation.id == conversationID else { return }
                model.addAttachment(value, to: conversationID); remove(id)
            } catch {
                guard let self, !Task.isCancelled, let index = pending.firstIndex(where: { $0.id == id }) else { return }
                pending[index].error = (error as? LocalizedError)?.errorDescription ?? "Couldn’t load this attachment. Remove it and choose again."
                jobs[id] = nil; deadlines[id]?.cancel(); deadlines[id] = nil; updateCount()
            }
        }
        deadlines[id] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(60)); guard !Task.isCancelled, let self, let index = pending.firstIndex(where: { $0.id == id }) else { return }
            jobs[id]?.cancel(); jobs[id] = nil; pending[index].error = "Attachment loading timed out. Remove it and choose again."; deadlines[id] = nil; updateCount()
        }
    }
    func remove(_ id: UUID) {
        jobs[id]?.cancel(); jobs[id] = nil; deadlines[id]?.cancel(); deadlines[id] = nil
        pending.removeAll { $0.id == id }; updateCount()
    }
    func cancel() { for item in pending { remove(item.id) } }
    private func updateCount() { model.attachmentImportCount = pending.count }
}
