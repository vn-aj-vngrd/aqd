import AQDCore
import Foundation
import Observation

@MainActor @Observable final class AgentControlsModel {
    let store: PieceStore
    private(set) var settings: LocalSettings
    private(set) var pending: LocalSettingsRequest?
    var error: String?
    var hasPending: Bool { pending != nil }
    init(store: PieceStore) throws { self.store = store; settings = try store.localSettings() }
    func reload() {
        do { settings = try store.localSettings(); if pending == nil { error = nil } }
        catch { self.error = "AI settings couldn’t load. Your saved choices are retained." }
    }
    @discardableResult func save(preferences: AgentPreferences? = nil, feedback: [AgentFeedback]? = nil) -> Bool {
        guard pending == nil else { return retry() }
        do {
            let latest = try store.localSettings()
            pending = LocalSettingsRequest(base: latest, agentPreferences: preferences, feedback: feedback)
            return retry()
        } catch { self.error = "This change couldn’t be prepared. Your feedback and settings are retained."; return false }
    }
    @discardableResult func retry() -> Bool {
        guard let pending else { reload(); return error == nil }
        do {
            _ = try store.saveLocalSettings(pending)
            settings = try store.localSettings(); self.pending = nil; error = nil; return true
        } catch PieceStore.StoreError.staleRevision {
            self.pending = nil; reload(); error = "Settings changed elsewhere. Review your choices and save again."; return false
        } catch { self.error = "The save wasn’t confirmed. Retry checks the same change without creating a duplicate."; return false }
    }
    func saveGeneralFeedback(_ value: AgentFeedback, removing: Bool = false) -> Bool {
        do {
            if !removing { try value.validated() }
            var values = try store.localSettings().feedback ?? []
            values.removeAll { $0.id == value.id }
            if !removing { values.append(value) }
            return save(feedback: values)
        } catch { self.error = "Feedback couldn’t be read or is too long. Keep the note within 1,000 characters and try again."; return false }
    }
}

@MainActor @Observable final class AgentFeedbackLibrary {
    let agent: AgentModel
    let controls: AgentControlsModel
    var items: [AgentFeedback] = []
    var error: String? { agent.error ?? controls.error }
    var hasPending: Bool { agent.hasPendingOperation || controls.hasPending }
    init(agent: AgentModel, controls: AgentControlsModel? = nil) throws { self.agent = agent; self.controls = try controls ?? AgentControlsModel(store: agent.store); agent.controls = self.controls; reload() }
    func reload() {
        agent.reloadHistory(); controls.reload()
        items = ((controls.settings.feedback ?? []) + agent.history.flatMap(\.messages).flatMap { $0.feedback ?? [] })
            .sorted { $0.updatedAt == $1.updatedAt ? $0.id.uuidString < $1.id.uuidString : $0.updatedAt > $1.updatedAt }
    }
    func save(_ value: AgentFeedback, removing: Bool = false) -> Bool {
        let result = value.conversationID == nil ? controls.saveGeneralFeedback(value, removing: removing) : agent.saveFeedback(value, removing: removing)
        if result { reload() }; return result
    }
    func retry() -> Bool {
        if controls.hasPending { _ = controls.retry() }
        if agent.hasPendingOperation { agent.retryPending() }
        let success = !hasPending && error == nil
        if success { reload() }; return success
    }
}
