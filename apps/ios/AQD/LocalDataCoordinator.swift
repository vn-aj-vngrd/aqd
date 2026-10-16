import Foundation

enum LocalDataError: Error { case busy, staleReview, missingReview, invalidPointer, cleanupPending, invalidConfirmation }
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
    private let beforeEraseStore: (URL) throws -> Void
    private let beforeSwitch: () throws -> Void
    private let afterSwitch: () throws -> Void
    private let removeDirectory: (URL) throws -> Void
    private var retiredStores: [URL: WeakLocalStore] = [:]
    var isWaitingForPreviousStore: Bool { retiredStores.values.contains { $0.value != nil } }
    init(legacyRoot: URL, beforeEraseStore: @escaping (URL) throws -> Void = { _ in }, beforeSwitch: @escaping () throws -> Void = {}, afterSwitch: @escaping () throws -> Void = {},
         removeDirectory: @escaping (URL) throws -> Void = { try FileManager.default.removeItem(at: $0) }) {
        self.legacyRoot = legacyRoot.standardizedFileURL
        controlDirectory = legacyRoot.deletingLastPathComponent().appendingPathComponent(legacyRoot.lastPathComponent + "-local-data", isDirectory: true).standardizedFileURL
        self.beforeEraseStore = beforeEraseStore
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
    private func controlFiles() throws -> [URL] {
        guard exists(controlDirectory) else { return [] }; try checkDirectory(controlDirectory)
        return try FileManager.default.contentsOfDirectory(at: controlDirectory, includingPropertiesForKeys: nil)
    }
    private func isMalformedMetadata(_ error: any Error) -> Bool {
        if error is DecodingError { return true }
        switch error {
        case LocalDataError.invalidPointer, LocalArchiveError.tooLarge: return true
        default: return false
        }
    }
    private func quarantineMetadata(_ url: URL) throws {
        guard try FileManager.default.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType == .typeRegular else { throw LocalDataError.invalidPointer }
        let retained = controlDirectory.appendingPathComponent("unreadable-\(UUID().uuidString)-" + url.lastPathComponent)
        try FileManager.default.moveItem(at: url, to: retained); try LocalArchiveIO.protect(retained)
    }
    private func hasUnreadableMetadata() throws -> Bool {
        try controlFiles().contains { $0.lastPathComponent.hasPrefix("unreadable-") }
    }
    private func preparationURL(_ id: UUID) -> URL { controlDirectory.appendingPathComponent("preparing-\(id.uuidString).json") }
    private func preparationReceipts() throws -> [(URL, UUID)] {
        var result: [(URL, UUID)] = []
        for url in try controlFiles() where url.lastPathComponent.hasPrefix("preparing-") && url.pathExtension == "json" {
            guard let id = UUID(uuidString: String(url.deletingPathExtension().lastPathComponent.dropFirst(10))) else { continue }
            do {
                guard try LocalArchiveIO.read(url, maximum: 128) == Data(id.uuidString.utf8) else { throw LocalDataError.invalidPointer }
                result.append((url, id))
            } catch {
                guard isMalformedMetadata(error) else { throw error }; try quarantineMetadata(url)
            }
        }
        return result
    }
    private func pointer() throws -> Pointer? {
        guard exists(controlDirectory) else { return nil }; try checkDirectory(controlDirectory)
        guard exists(pointerURL) else { return nil }
        let pointer = try JSONDecoder().decode(Pointer.self, from: LocalArchiveIO.read(pointerURL, maximum: 4096))
        guard pointer.schemaVersion == 1, pointer.generation == pointer.operationID else { throw LocalDataError.invalidPointer }; return pointer
    }
    private func generationDirectories() throws -> [URL] {
        guard exists(controlDirectory) else { return [] }
        try checkDirectory(controlDirectory)
        return try FileManager.default.contentsOfDirectory(at: controlDirectory, includingPropertiesForKeys: nil).filter {
            UUID(uuidString: $0.lastPathComponent) != nil
        }.map { try checkDirectory($0); return $0.standardizedFileURL }
    }
    func currentDirectory() throws -> URL { try resolveDirectory(allowIncomplete: false) }
    private func resolveDirectory(allowIncomplete: Bool) throws -> URL {
        if let pointer = try pointer() {
            let directory = generationDirectory(pointer.generation)
            if exists(directory) { try checkDirectory(directory) } else if !allowIncomplete { throw LocalDataError.invalidPointer }
            if !allowIncomplete {
                let retained = try retainedReceipts(), pending = try pendingReview()
                guard !retained.contains(where: { $0.1.phase == .failed && $0.1.operationID == pointer.generation }) else { throw LocalDataError.invalidPointer }
                if try hasUnreadableMetadata() {
                    guard let pending, pending.operationID == pointer.operationID,
                          pending.phase == .installed || pending.phase == .acknowledged else { throw LocalDataError.invalidPointer }
                }
                for name in ["wardrobe.store", "schema-version"] {
                    guard try FileManager.default.attributesOfItem(atPath: directory.appendingPathComponent(name).path)[.type] as? FileAttributeType == .typeRegular else { throw LocalDataError.invalidPointer }
                }
            }
            return directory
        }
        if exists(legacyRoot) { try checkDirectory(legacyRoot) }
        if !allowIncomplete {
            _ = try pendingReview(); _ = try retainedReceipts(); _ = try preparationReceipts()
            guard try !hasUnreadableMetadata() else { throw LocalDataError.invalidPointer }
        }
        if !allowIncomplete, try !generationDirectories().isEmpty {
            for name in ["wardrobe.store", "schema-version"] {
                guard try FileManager.default.attributesOfItem(atPath: legacyRoot.appendingPathComponent(name).path)[.type] as? FileAttributeType == .typeRegular else { throw LocalDataError.invalidPointer }
            }
            _ = try PieceStore(directory: legacyRoot).validateArchiveContents()
        }
        return legacyRoot
    }
    func pendingReview() throws -> LocalDataReview? {
        guard exists(controlDirectory) else { return nil }; try checkDirectory(controlDirectory)
        guard exists(reviewURL) else { return nil }
        do {
            let value = try JSONDecoder().decode(LocalDataReview.self, from: LocalArchiveIO.read(reviewURL, maximum: 65536))
            guard value.source.generation != value.operationID else { throw LocalDataError.invalidPointer }; return value
        } catch {
            guard isMalformedMetadata(error) else { throw error }; try quarantineMetadata(reviewURL); return nil
        }
    }

    private func write(_ review: LocalDataReview) throws { try ensureControl(); try LocalArchiveIO.write(JSONEncoder().encode(review), to: reviewURL) }
    private func sourceToken(_ source: PieceStore?) throws -> LocalDataSourceToken {
        let pointer = try pointer(), current = try resolveDirectory(allowIncomplete: true)
        if let source {
            guard source.localDirectory.standardizedFileURL.path == current.standardizedFileURL.path else { throw LocalDataError.staleReview }
            return LocalDataSourceToken(generation: pointer?.generation, ownerID: try source.todayConfiguration().ownerID,
                stamp: try source.mutationStamp(), unreadableFingerprint: nil)
        }
        // Fingerprint closed storage without opening or seeding it. Exclude only this review's
        // candidate, whose integrity/stamp has its own validation before publication.
        let candidate = try pendingReview()?.operationID
        var directories = [current]
        directories += try generationDirectories().filter {
            UUID(uuidString: $0.lastPathComponent) != candidate && $0.standardizedFileURL.path != current.standardizedFileURL.path
        }
        var facts: [String] = []
        for directory in directories.sorted(by: { $0.path < $1.path }) {
            for name in ["wardrobe.store", "wardrobe.store-wal", "wardrobe.store-shm", "schema-version"] {
                let url = directory.appendingPathComponent(name)
                if exists(url) { facts.append(directory.lastPathComponent + "/" + name + ":" + (try LocalArchiveIO.fingerprint(url))) }
            }
        }
        for file in try controlFiles().sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) where file.lastPathComponent.hasPrefix("unreadable-") {
            facts.append(file.lastPathComponent + ":" + (try LocalArchiveIO.fingerprint(file)))
        }
        return LocalDataSourceToken(generation: pointer?.generation, ownerID: nil, stamp: nil,
            unreadableFingerprint: LocalArchivePackage.hash(Data(facts.joined(separator: "\n").utf8)))
    }
    func prepareRestore(_ package: LocalArchivePackage, source: PieceStore?) async throws -> LocalDataReview {
        guard try pendingReview() == nil else { throw LocalDataError.busy }
        guard package.header.databaseSchema <= LocalArchivePackage.schema else { throw LocalArchiveError.newer }
        if source == nil { try recover() }
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
    func commit(_ requested: LocalDataReview, source: PieceStore?, confirmation: String? = nil) throws -> LocalDataInstallation {
        guard var review = try pendingReview(), review.operationID == requested.operationID else { throw LocalDataError.missingReview }
        var expected = review; expected.phase = requested.phase
        guard expected == requested else { throw LocalDataError.staleReview }
        // Read the publication receipt first: retry cannot replace a newer edited store.
        if try pointer()?.operationID == review.operationID {
            let store = try PieceStore(directory: currentDirectory())
            if review.phase != .acknowledged { review.phase = .installed; try write(review) }
            return LocalDataInstallation(review: review, store: store)
        }
        guard review.kind != .erase || confirmation == "ERASE" else { throw LocalDataError.invalidConfirmation }
        guard review == requested, review.phase == .review, review.source == (try sourceToken(source)) else { throw LocalDataError.staleReview }
        let installed = try PieceStore(directory: generationDirectory(review.operationID))
        guard try installed.mutationStamp() == review.candidateStamp,
              try installed.validateArchiveContents() == review.incomingSummary else { throw LocalDataError.staleReview }
        try beforeSwitch()
        try LocalArchiveIO.write(JSONEncoder().encode(Pointer(generation: review.operationID, operationID: review.operationID)), to: pointerURL)
        if let source { retiredStores[source.localDirectory.standardizedFileURL] = WeakLocalStore(source) }
        try afterSwitch()
        review.phase = .installed; try write(review)
        return LocalDataInstallation(review: review, store: installed)
    }
    func acknowledge(_ operationID: UUID) throws {
        guard var review = try pendingReview(), review.operationID == operationID,
              try pointer()?.operationID == operationID else { throw LocalDataError.missingReview }
        _ = try PieceStore(directory: currentDirectory()).validateArchiveContents()
        review.phase = .acknowledged; try write(review)
    }
    private func retainedReceipts() throws -> [(URL, LocalDataReview)] {
        guard exists(controlDirectory) else { return [] }; try checkDirectory(controlDirectory)
        var result: [(URL, LocalDataReview)] = []
        for url in try controlFiles() where url.lastPathComponent.hasPrefix("retired-") && url.pathExtension == "json" {
            guard let id = UUID(uuidString: String(url.deletingPathExtension().lastPathComponent.dropFirst(8))) else { continue }
            do {
                let review = try JSONDecoder().decode(LocalDataReview.self, from: LocalArchiveIO.read(url, maximum: 65536))
                guard review.operationID == id, review.source.generation != id else { throw LocalDataError.invalidPointer }
                result.append((url, review))
            } catch {
                guard isMalformedMetadata(error) else { throw error }; try quarantineMetadata(url)
            }
        }
        return result
    }
    func hasRetainedOperations() throws -> Bool {
        let retained = try retainedReceipts(), preparing = try preparationReceipts()
        return try !retained.isEmpty || !preparing.isEmpty || hasUnreadableMetadata()
    }
    private func retainForRecovery(_ review: LocalDataReview) throws {
        try LocalArchiveIO.write(JSONEncoder().encode(review), to: controlDirectory.appendingPathComponent("retired-\(review.operationID.uuidString).json"))
        try FileManager.default.removeItem(at: reviewURL)
    }
    /// Only an unacknowledged replacement may roll back to its retained, validated original.
    private func recoverOriginal(_ review: LocalDataReview) throws -> Bool {
        guard review.phase != .acknowledged else { return false }
        let original = review.source.generation.map(generationDirectory) ?? legacyRoot
        do {
            try checkDirectory(original)
            for name in ["wardrobe.store", "schema-version"] {
                guard try FileManager.default.attributesOfItem(atPath: original.appendingPathComponent(name).path)[.type] as? FileAttributeType == .typeRegular else { throw LocalDataError.invalidPointer }
            }
            let summary = try PieceStore(directory: original).validateArchiveContents()
            if let ownerID = review.source.ownerID, summary.ownerID != ownerID { return false }
        } catch { return false }
        if let generation = review.source.generation {
            try LocalArchiveIO.write(JSONEncoder().encode(Pointer(generation: generation, operationID: generation)), to: pointerURL)
        } else if exists(pointerURL) { try FileManager.default.removeItem(at: pointerURL) }
        var failed = review; failed.phase = .failed; try write(failed)
        return true
    }
    /// An exact publication receipt may reconcile this candidate before its installed phase
    /// is recorded. Validate files/ownership directly instead of applying opening UI policy.
    private func validatedCandidate(_ review: LocalDataReview) throws -> PieceStore {
        let directory = generationDirectory(review.operationID)
        try checkDirectory(directory)
        guard try !retainedReceipts().contains(where: { $0.1.phase == .failed && $0.1.operationID == review.operationID }) else { throw LocalDataError.invalidPointer }
        for name in ["wardrobe.store", "schema-version"] {
            guard try FileManager.default.attributesOfItem(atPath: directory.appendingPathComponent(name).path)[.type] as? FileAttributeType == .typeRegular else { throw LocalDataError.invalidPointer }
        }
        let store = try PieceStore(directory: directory)
        guard try store.validateArchiveContents().ownerID == review.incomingSummary.ownerID else { throw LocalDataError.invalidPointer }
        return store
    }
    private func repairPointer(_ review: LocalDataReview) throws {
        var valid = false
        do { _ = try validatedCandidate(review); valid = true } catch { valid = false }
        if !valid, try recoverOriginal(review) { return }
        try LocalArchiveIO.write(JSONEncoder().encode(Pointer(generation: review.operationID, operationID: review.operationID)), to: pointerURL)
        if !valid {
            var retained = review; retained.phase = .failed
            try retainForRecovery(retained)
        }
    }
    /// A corrupt installed copy can be replaced from another archive without deleting either retained generation.
    func retainInstalledOperationForRecovery(_ id: UUID) throws {
        guard let review = try pendingReview(), review.operationID == id, try isInstalled(id) else { throw LocalDataError.missingReview }
        try retainForRecovery(review)
    }
    /// Returns false while a previous UI/store or an archive worker still owns private files.
    @discardableResult func cleanupRetired() throws -> Bool {
        let pending = try pendingReview()
        var receipts = try retainedReceipts()
        let preparing = try preparationReceipts()
        guard try !hasUnreadableMetadata() else { return false }
        if let pending {
            guard pending.phase == .acknowledged, try isInstalled(pending.operationID) else { return false }
            receipts.append((reviewURL, pending))
        }
        guard !receipts.isEmpty else { return preparing.isEmpty }
        // A quarantined receipt needs a newly acknowledged replacement before any cleanup.
        guard pending != nil else { return false }
        guard !isWaitingForPreviousStore, !LocalArchiveService.hasInFlightWork else { return false }
        let current = try currentDirectory()
        _ = try PieceStore(directory: current).validateArchiveContents()
        // Missing publication metadata cannot authorize deleting untracked private generations,
        // or a claim that all retired files have been removed. Keep the receipt and recovery warning.
        let known = Set(([current] + preparing.map { generationDirectory($0.1) } + receipts.flatMap { _, review in
            [review.source.generation.map(generationDirectory) ?? legacyRoot, generationDirectory(review.operationID)]
        }).map { $0.standardizedFileURL.path })
        guard try generationDirectories().allSatisfy({ known.contains($0.path) }) else { throw LocalDataError.cleanupPending }
        for (receiptURL, id) in preparing {
            let directory = generationDirectory(id)
            if directory.standardizedFileURL.path != current.standardizedFileURL.path, exists(directory) {
                try checkDirectory(directory); try removeDirectory(directory)
                guard !exists(directory) else { throw LocalDataError.cleanupPending }
            }
            try FileManager.default.removeItem(at: receiptURL)
        }
        for (receiptURL, review) in receipts {
            var previousDirectories = [review.source.generation.map(generationDirectory) ?? legacyRoot]
            if receiptURL != reviewURL { previousDirectories.append(generationDirectory(review.operationID)) }
            for previous in Set(previousDirectories) where previous != current {
                guard previous != controlDirectory else { throw LocalDataError.invalidPointer }
                if exists(previous) { try checkDirectory(previous); try removeDirectory(previous); guard !exists(previous) else { throw LocalDataError.cleanupPending } }
                retiredStores.removeValue(forKey: previous.standardizedFileURL)
            }
            if review.kind == .erase, try !LocalArchiveService.cleanupTemporaryArchives() { return false }
            try FileManager.default.removeItem(at: receiptURL)
        }
        return true
    }
    func prepareErase(source: PieceStore?) async throws -> LocalDataReview {
        guard try pendingReview() == nil else { throw LocalDataError.busy }
        let id = UUID(), token = try sourceToken(source)
        try ensureControl()
        let directory = generationDirectory(id)
        let preparation = preparationURL(id)
        try LocalArchiveIO.write(Data(id.uuidString.utf8), to: preparation)
        do {
            try beforeEraseStore(directory)
            let empty = try PieceStore(directory: directory)
            let summary = try empty.validateArchiveContents()
            let review = LocalDataReview(operationID: id, kind: .erase, source: token, originalSummary: try? source?.validateArchiveContents(),
                incomingSummary: summary, migratedFrom: nil, candidateStamp: try empty.mutationStamp(), phase: .review)
            try write(review); try? FileManager.default.removeItem(at: preparation); return review
        } catch {
            if exists(directory) { try? removeDirectory(directory) }
            if !exists(directory) { try? FileManager.default.removeItem(at: preparation) }
            throw error
        }
    }
    /// Interrupted staging never changes the active pointer; an installed pointer is authoritative.
    func recover() throws {
        guard var review = try pendingReview() else {
            _ = try retainedReceipts(); _ = try preparationReceipts()
            do { _ = try pointer() }
            catch { guard isMalformedMetadata(error) else { throw error }; try quarantineMetadata(pointerURL) }
            return
        }
        let active: Pointer?
        do { active = try pointer() }
        catch {
            guard isMalformedMetadata(error) else { throw error }
            if review.phase == .installed || review.phase == .acknowledged { try repairPointer(review) }
            else if try !recoverOriginal(review) {
                try quarantineMetadata(pointerURL)
                review.phase = .failed; try retainForRecovery(review)
            }
            return
        }
        if active?.operationID == review.operationID {
            guard review.phase != .acknowledged else { return }
            do {
                _ = try validatedCandidate(review)
                review.phase = .installed; try write(review)
            } catch {
                if try !recoverOriginal(review) {
                    review.phase = .failed; try retainForRecovery(review)
                }
            }
        } else if review.phase == .preparing { try cancel(review.operationID) }
        else if review.phase == .installed || review.phase == .acknowledged {
            if active == nil { try repairPointer(review) }
            else { try retainForRecovery(review) }
        }
    }
}

@MainActor final class WeakLocalStore {
    weak var value: PieceStore?
    init(_ value: PieceStore) { self.value = value }
}
