import Foundation
import Observation

@MainActor @Observable final class LocalExportModel {
    enum Phase { case idle, preparing, ready, failed }
    let store: PieceStore
    var phase = Phase.idle
    var data: Data?
    var summary: LocalArchiveSummary?
    var error: String?
    var fileResult: String?
    private var task: Task<Void, Never>?
    private var token = UUID()
    init(store: PieceStore) { self.store = store }
    func start() {
        guard phase != .preparing else { return }
        let token = UUID(); self.token = token; phase = .preparing; error = nil; data = nil; fileResult = nil
        task = Task {
            do {
                await Task.yield()
                let bytes = try await LocalArchiveService.create(store: store)
                guard !Task.isCancelled, self.token == token else { return }
                let archive = try LocalArchivePackage.decode(bytes)
                summary = archive.header.summary; data = bytes; phase = .ready
            } catch {
                guard !Task.isCancelled, self.token == token else { return }
                self.error = "The archive couldn’t be prepared. Your closet is retained. Check available storage and media, then try again. Archives are limited to 512 MB."; phase = .failed
            }
        }
    }
    func cancel() { token = UUID(); task?.cancel(); task = nil; data = nil; summary = nil; phase = .idle }
}
