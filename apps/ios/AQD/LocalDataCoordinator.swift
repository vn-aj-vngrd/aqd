import Foundation

enum LocalDataError: Error { case busy, staleReview, missingReview, invalidPointer, cleanupPending }
enum LocalDataChange: String, Codable { case restore, erase }
struct LocalDataSourceToken: Codable, Equatable {
    let generation: UUID?
    let ownerID: UUID?
    let stamp: UUID?
    let unreadableFingerprint: String?
}
struct LocalDataReview: Identifiable, Codable, Equatable {
    enum Phase: String, Codable { case preparing, review, installed, acknowledged, failed }
    var id: UUID { operationID }
    let operationID: UUID
    let kind: LocalDataChange
    var source: LocalDataSourceToken
    var originalSummary: LocalArchiveSummary?
    let incomingSummary: LocalArchiveSummary
    let migratedFrom: Int?
    var version = 1
    var candidateStamp: UUID?
    var phase: Phase
}
struct LocalDataInstallation {
    let review: LocalDataReview
    let store: PieceStore
}

/// SQLite paths never move. An atomic pointer publishes one validated store generation.
/// One durable review also owns uncertain acknowledgment and retired-directory cleanup.
@MainActor final class LocalDataCoordinator {
    private struct Pointer: Codable { var schemaVersion = 1; let generation: UUID; let operationID: UUID }
    let legacyRoot: URL
    let controlDirectory: URL
    private let beforeSwitch: () throws -> Void
    private let afterSwitch: () throws -> Void
    private let removeDirectory: (URL) throws -> Void
    private weak var retiredStore: PieceStore?
    init(legacyRoot: URL, beforeSwitch: @escaping () throws -> Void = {}, afterSwitch: @escaping () throws -> Void = {},
         removeDirectory: @escaping (URL) throws -> Void = { try FileManager.default.removeItem(at: $0) }) {
        self.legacyRoot = legacyRoot.standardizedFileURL
        controlDirectory = legacyRoot.deletingLastPathComponent().appendingPathComponent(legacyRoot.lastPathComponent + "-local-data", isDirectory: true).standardizedFileURL
        self.beforeSwitch = beforeSwitch; self.afterSwitch = afterSwitch; self.removeDirectory = removeDirectory
    }
    private var pointerURL: URL { controlDirectory.appendingPathComponent("active.json") }
    private var reviewURL: URL { controlDirectory.appendingPathComponent("operation.json") }
    func generationDirectory(_ id: UUID) -> URL { controlDirectory.appendingPathComponent(id.uuidString, isDirectory: true) }
    private func exists(_ url: URL) -> Bool { (try? FileManager.default.attributesOfItem(atPath: url.path)) != nil }
    private func checkDirectory(_ url: URL) throws {
        guard try FileManager.default.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType == .typeDirectory else { throw LocalDataError.invalidPointer }
    }
    private func ensureControl() throws {
        if exists(controlDirectory) { try checkDirectory(controlDirectory) }
        else { try LocalArchiveIO.protectedDirectory(controlDirectory) }
    }
    private func pointer() throws -> Pointer? {
        guard exists(controlDirectory) else { return nil }; try checkDirectory(controlDirectory)
        guard exists(pointerURL) else { return nil }
        let pointer = try JSONDecoder().decode(Pointer.self, from: LocalArchiveIO.read(pointerURL, maximum: 4096))
        guard pointer.schemaVersion == 1, pointer.generation == pointer.operationID else { throw LocalDataError.invalidPointer }; return pointer
    }
    func currentDirectory() throws -> URL { try resolveDirectory(allowIncomplete: false) }
    private func resolveDirectory(allowIncomplete: Bool) throws -> URL {
        if let pointer = try pointer() {
            let directory = generationDirectory(pointer.generation)
            if exists(directory) { try checkDirectory(directory) } else if !allowIncomplete { throw LocalDataError.invalidPointer }
            if !allowIncomplete {
                for name in ["wardrobe.store", "schema-version"] {
                    guard try FileManager.default.attributesOfItem(atPath: directory.appendingPathComponent(name).path)[.type] as? FileAttributeType == .typeRegular else { throw LocalDataError.invalidPointer }
                }
            }
            return directory
        }
        if exists(legacyRoot) { try checkDirectory(legacyRoot) }; return legacyRoot
    }
    func pendingReview() throws -> LocalDataReview? {
        guard exists(controlDirectory) else { return nil }; try checkDirectory(controlDirectory)
        guard exists(reviewURL) else { return nil }
        let value = try JSONDecoder().decode(LocalDataReview.self, from: LocalArchiveIO.read(reviewURL, maximum: 65536))
        guard value.source.generation != value.operationID else { throw LocalDataError.invalidPointer }; return value
    }
    private func write(_ review: LocalDataReview) throws { try ensureControl(); try LocalArchiveIO.write(JSONEncoder().encode(review), to: reviewURL) }
    private func sourceToken(_ source: PieceStore?) throws -> LocalDataSourceToken {
        let pointer = try pointer(), current = try resolveDirectory(allowIncomplete: source == nil)
        if let source {
            guard source.localDirectory.standardizedFileURL == current else { throw LocalDataError.staleReview }
            return LocalDataSourceToken(generation: pointer?.generation, ownerID: try source.todayConfiguration().ownerID,
                stamp: try source.mutationStamp(), unreadableFingerprint: nil)
        }
        // A closed/corrupt store is never opened or seeded just to inspect replacement impact.
        var facts: [String] = []
        for name in ["wardrobe.store", "wardrobe.store-wal", "wardrobe.store-shm", "schema-version"] {
            let url = current.appendingPathComponent(name)
            if exists(url) {
                let value = try FileManager.default.attributesOfItem(atPath: url.path)
                guard value[.type] as? FileAttributeType == .typeRegular else { throw LocalDataError.invalidPointer }
                let bytes = try LocalArchiveIO.read(url)
                facts.append(name + ":" + LocalArchivePackage.hash(bytes))
            }
        }
        return LocalDataSourceToken(generation: pointer?.generation, ownerID: nil, stamp: nil,
            unreadableFingerprint: LocalArchivePackage.hash(Data(facts.joined(separator: "\n").utf8)))
    }
    func prepareRestore(_ package: LocalArchivePackage, source: PieceStore?) async throws -> LocalDataReview {
        guard try pendingReview() == nil else { throw LocalDataError.busy }
        guard package.header.databaseSchema <= LocalArchivePackage.schema else { throw LocalArchiveError.newer }
        let id = UUID(), token = try sourceToken(source)
        var review = LocalDataReview(operationID: id, kind: .restore, source: token,
            originalSummary: try? source?.validateArchiveContents(), incomingSummary: package.header.summary,
            migratedFrom: package.header.databaseSchema < LocalArchivePackage.schema ? package.header.databaseSchema : nil, candidateStamp: nil, phase: .preparing)
        try write(review)
        do {
            let staged = try await LocalArchiveService.stage(package, directory: generationDirectory(id))
            guard token == (try sourceToken(source)) else { throw LocalDataError.staleReview }
            review.candidateStamp = try staged.store.mutationStamp(); review.phase = .review; try write(review); return review
        } catch { try? cancel(id); throw error }
    }
    func isInstalled(_ operationID: UUID) throws -> Bool { try pointer()?.operationID == operationID }
    func refreshReview(_ operationID: UUID, source: PieceStore?) throws -> LocalDataReview {
        guard var review = try pendingReview(), review.operationID == operationID, review.phase == .review,
              try !isInstalled(operationID), review.version < Int.max else { throw LocalDataError.busy }
        review.source = try sourceToken(source); review.originalSummary = try? source?.validateArchiveContents()
        review.version += 1; try write(review); return review
    }
    func cancel(_ operationID: UUID) throws {
        guard let review = try pendingReview(), review.operationID == operationID else { throw LocalDataError.missingReview }
        guard try pointer()?.operationID != operationID, review.phase == .preparing || review.phase == .review || review.phase == .failed else { throw LocalDataError.busy }
        let directory = generationDirectory(operationID)
        if exists(directory) { try checkDirectory(directory); try removeDirectory(directory); guard !exists(directory) else { throw LocalDataError.cleanupPending } }
        try FileManager.default.removeItem(at: reviewURL)
    }
    func commit(_ requested: LocalDataReview, source: PieceStore?) throws -> LocalDataInstallation {
        guard var review = try pendingReview(), review.operationID == requested.operationID else { throw LocalDataError.missingReview }
        var expected = review; expected.phase = requested.phase
        guard expected == requested else { throw LocalDataError.staleReview }
        // Read the publication receipt first: retry cannot replace a newer edited store.
        if try pointer()?.operationID == review.operationID {
            let store = try PieceStore(directory: generationDirectory(review.operationID))
            if review.phase != .acknowledged { review.phase = .installed; try write(review) }
            return LocalDataInstallation(review: review, store: store)
        }
        guard review == requested, review.phase == .review, review.source == (try sourceToken(source)) else { throw LocalDataError.staleReview }
        let installed = try PieceStore(directory: generationDirectory(review.operationID))
        guard try installed.mutationStamp() == review.candidateStamp,
              try installed.validateArchiveContents() == review.incomingSummary else { throw LocalDataError.staleReview }
        try beforeSwitch()
        try LocalArchiveIO.write(JSONEncoder().encode(Pointer(generation: review.operationID, operationID: review.operationID)), to: pointerURL)
        retiredStore = source
        try afterSwitch()
        review.phase = .installed; try write(review)
        return LocalDataInstallation(review: review, store: installed)
    }
    func acknowledge(_ operationID: UUID) throws {
        guard var review = try pendingReview(), review.operationID == operationID,
              try pointer()?.operationID == operationID else { throw LocalDataError.missingReview }
        review.phase = .acknowledged; try write(review)
    }
    /// Returns false while a previous UI/store owner is alive or cleanup is denied.
    @discardableResult func cleanupRetired() throws -> Bool {
        guard let review = try pendingReview() else { return true }
        guard review.phase == .acknowledged, try pointer()?.operationID == review.operationID else { return false }
        guard retiredStore == nil else { return false }
        let previous = review.source.generation.map(generationDirectory) ?? legacyRoot
        guard previous != (try currentDirectory()), previous != controlDirectory else { throw LocalDataError.invalidPointer }
        if exists(previous) { try checkDirectory(previous); try removeDirectory(previous); guard !exists(previous) else { throw LocalDataError.cleanupPending } }
        try FileManager.default.removeItem(at: reviewURL); return true
    }
    /// Interrupted staging never changes the active pointer; an installed pointer is authoritative.
    func recover() throws {
        guard var review = try pendingReview() else { return }
        if try pointer()?.operationID == review.operationID {
            guard review.phase != .acknowledged else { return }
            do {
                let installed = try PieceStore(directory: currentDirectory()); _ = try installed.validateArchiveContents()
                review.phase = .installed; try write(review)
            } catch {
                // No acknowledgment was issued. Retain the failed candidate and recover the validated original.
                let original = review.source.generation.map(generationDirectory) ?? legacyRoot
                for name in ["wardrobe.store", "schema-version"] {
                    guard try FileManager.default.attributesOfItem(atPath: original.appendingPathComponent(name).path)[.type] as? FileAttributeType == .typeRegular else { throw LocalDataError.invalidPointer }
                }
                _ = try PieceStore(directory: original).validateArchiveContents()
                if let generation = review.source.generation { try LocalArchiveIO.write(JSONEncoder().encode(Pointer(generation: generation, operationID: generation)), to: pointerURL) }
                else { try FileManager.default.removeItem(at: pointerURL) }
                review.phase = .failed; try write(review)
            }
        } else if review.phase == .preparing { try cancel(review.operationID) }
        else if review.phase == .installed || review.phase == .acknowledged { throw LocalDataError.invalidPointer }
    }
}
