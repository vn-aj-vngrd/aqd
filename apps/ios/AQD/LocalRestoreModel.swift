import Foundation
import Observation

@MainActor @Observable final class LocalRestoreModel: Identifiable {
    enum Phase { case choose, validating, review, committing, complete, failed, newer, unknown }
    let id = UUID()
    let coordinator: LocalDataCoordinator
    let source: PieceStore?
    let requestedKind: LocalDataChange
    var kind: LocalDataChange { review?.kind ?? requestedKind }
    var phase = Phase.choose
    var review: LocalDataReview?
    var installed: PieceStore?
    var error: String?
    var sourceName: String?
    private var task: Task<Void, Never>?
    private var token = UUID()
    init(coordinator: LocalDataCoordinator, source: PieceStore?, kind: LocalDataChange = .restore) {
        self.coordinator = coordinator; self.source = source; requestedKind = kind
        do {
            try coordinator.recover()
            if let pending = try coordinator.pendingReview() {
                review = pending
                if try coordinator.isInstalled(pending.operationID) { try finish(coordinator.commit(pending, source: source)) }
                else if pending.phase == .review { phase = .review }
                else if pending.phase == .failed { phase = .failed; error = "The installed copy couldn’t reopen. The original closet is active; choose another archive." }
            }
        } catch { self.error = "The previous data operation needs recovery. Your existing data is retained. Retry before starting another replacement."; phase = .unknown }
    }
    func choose(_ url: URL) {
        guard phase != .committing else { return }
        if let review {
            if (try? coordinator.isInstalled(review.operationID)) == true, source == nil {
                do { try coordinator.retainInstalledOperationForRecovery(review.operationID); self.review = nil }
                catch { self.error = "The retained recovery receipt couldn’t be preserved. Keep the current files and retry."; phase = .unknown; return }
            } else {
                guard (try? coordinator.isInstalled(review.operationID)) == false else { phase = .unknown; return }
                guard cancelReview() else { return }
            }
        }
        let token = UUID(); self.token = token; phase = .validating; error = nil; sourceName = url.lastPathComponent
        task = Task {
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            do {
                let reading = Task.detached(priority: .utility) { try LocalArchivePackage.decode(LocalArchiveIO.read(url)) }
                let package = try await withTaskCancellationHandler { try await reading.value } onCancel: { reading.cancel() }
                guard !Task.isCancelled, self.token == token else { return }
                let value = try await coordinator.prepareRestore(package, source: source)
                guard !Task.isCancelled, self.token == token else { try? coordinator.cancel(value.operationID); return }
                review = value; phase = .review
            } catch {
                guard !Task.isCancelled, self.token == token else { return }
                if case LocalArchiveError.newer = error { phase = .newer; self.error = "This archive needs a newer AQD. Your current closet has not changed." }
                else { phase = .failed; self.error = "This archive could not be validated. Check the file, storage and media. Your current closet has not been replaced." }
            }
        }
    }
    func prepareErase() {
        guard kind == .erase, review == nil, phase == .choose || phase == .failed else { return }
        phase = .validating; error = nil
        task = Task {
            do { await Task.yield(); try Task.checkCancellation(); review = try await coordinator.prepareErase(source: source); phase = .review }
            catch { self.error = "Erase review couldn’t be prepared. Your local data has not changed."; phase = .failed }
        }
    }
    func commit(confirmation: String? = nil) {
        guard let review, phase == .review || phase == .failed || phase == .unknown else { return }
        phase = .committing; error = nil
        task = Task {
            await Task.yield()
            do { try finish(coordinator.commit(review, source: source, confirmation: confirmation)) }
            catch {
                let published = try? coordinator.isInstalled(review.operationID)
                phase = published == false ? .failed : .unknown
                self.error = published == false ? "The replacement wasn’t installed. Your previous closet is retained. If local data changed, review the current replacement again." : "The replacement outcome isn’t confirmed. Check this same operation before choosing another file."
            }
        }
    }
    private func finish(_ result: LocalDataInstallation) throws {
        installed = result.store; review = result.review
        try coordinator.acknowledge(result.review.operationID); phase = .complete; error = nil
    }
    func refresh() {
        guard let review else { return }
        do { self.review = try coordinator.refreshReview(review.operationID, source: source); phase = .review; error = nil }
        catch { self.error = "This review could not be refreshed. Check the existing operation or cancel it before choosing another file." }
    }
    func checkOutcome() {
        do {
            try coordinator.recover()
            guard let review = try coordinator.pendingReview() else { phase = .choose; self.review = nil; error = nil; return }
            self.review = review
            if try coordinator.isInstalled(review.operationID) { try finish(coordinator.commit(review, source: source)) }
            else if review.phase == .failed { phase = .failed; error = "The original closet is active. The staged copy needs replacement; choose another archive." }
            else { phase = .review; error = nil }
        } catch { self.error = "The operation still needs recovery. Your original data is retained; retry this same operation." }
    }
    private func cancelReview() -> Bool {
        guard let review else { return true }
        do { try coordinator.cancel(review.operationID); self.review = nil; return true }
        catch { self.error = "The staged copy could not be removed or the switch may already be installed. Check the existing operation."; return false }
    }
    @discardableResult func cancel() -> Bool {
        guard phase != .committing, installed == nil else { return false }
        token = UUID(); task?.cancel(); task = nil
        guard cancelReview() else { return false }; phase = .choose; return true
    }
}
