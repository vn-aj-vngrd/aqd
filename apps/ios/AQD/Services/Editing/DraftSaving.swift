import Foundation

/// The exactly-once save protocol shared by every draft editor.
///
/// An editor supplies small adapters (persist, commit, find receipt, messages). `runSave()` owns the
/// sequence: retain the draft, commit, and if the commit is not acknowledged reconcile against the
/// receipt of the *same operation* before anything is written again. When even the lookup fails the
/// outcome is `unknown`, and the next save only re-checks; it never starts a second write.
@MainActor
protocol DraftSaving: AnyObject {
    associatedtype Saved
    var pending: Bool { get set }
    var unknown: Bool { get set }
    var saved: Saved? { get set }
    var error: String? { get set }

    /// Retain the draft so edits survive a failed or interrupted save. Skipped while an outcome is unknown.
    func persistDraft() throws
    /// Perform the write. Throws when it was not acknowledged.
    func commit() throws -> Saved
    /// The receipt of this exact operation, or nil when it never committed.
    func receipt() throws -> Saved?
    /// Reload dependent state after a commit or a reconciliation (`recovered` after a failed commit).
    func didFinishSave(recovered: Bool)
    /// Shown when reconciliation proves nothing was saved. The draft is retained.
    func notSavedMessage() -> String
    /// Shown when neither the commit nor the receipt lookup could be confirmed.
    var unknownMessage: String { get }
}

extension DraftSaving {
    func didFinishSave(recovered: Bool) {}

    func runSave() async {
        guard !pending, saved == nil else { return }
        pending = true
        defer { pending = false }
        await Task.yield()
        do {
            if !unknown { try persistDraft() }
            saved = try commit()
            unknown = false
            error = nil
            didFinishSave(recovered: false)
        } catch {
            do {
                saved = try receipt()
                unknown = false
                didFinishSave(recovered: true)
                self.error = saved == nil ? notSavedMessage() : nil
            } catch {
                unknown = true
                self.error = unknownMessage
            }
        }
    }
}
