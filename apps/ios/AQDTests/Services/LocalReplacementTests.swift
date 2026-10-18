import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct LocalReplacementTests {
    @Test(arguments: [false, true], [false, true]) func installedReceiptRepairsMissingOrCorruptPointerWithoutRewindingEdits(acknowledged: Bool, corrupt: Bool) async throws {
        let source = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let package = try LocalArchivePackage.decode(await LocalArchiveService.create(store: source).data)
        let coordinator = LocalDataCoordinator(legacyRoot: source.localDirectory)
        let request = try await coordinator.prepareRestore(package, source: source)
        let result = try coordinator.commit(request, source: source)
        if acknowledged { try coordinator.acknowledge(request.operationID) }
        _ = try result.store.saveLocalSettings(LocalSettingsRequest(base: result.store.localSettings(), appearance: .dark))
        let pointer = coordinator.controlDirectory.appendingPathComponent("active.json")
        if corrupt { try Data("damaged pointer".utf8).write(to: pointer) } else { try FileManager.default.removeItem(at: pointer) }
        let restarted = LocalDataCoordinator(legacyRoot: source.localDirectory)
        try restarted.recover()
        #expect(try restarted.isInstalled(request.operationID))
        #expect(try PieceStore(directory: restarted.currentDirectory()).localSettings().appearance == .dark)
    }
    @Test func staleInstalledReceiptDoesNotRewindAnotherGenerationOrBlockAnotherArchive() async throws {
        let source = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let package = try LocalArchivePackage.decode(await LocalArchiveService.create(store: source).data)
        let coordinator = LocalDataCoordinator(legacyRoot: source.localDirectory)
        let request = try await coordinator.prepareRestore(package, source: source)
        _ = try coordinator.commit(request, source: source); try coordinator.acknowledge(request.operationID)
        let nextID = UUID(), next = try PieceStore(directory: coordinator.generationDirectory(nextID))
        _ = try next.saveLocalSettings(LocalSettingsRequest(base: next.localSettings(), appearance: .light))
        let pointer = try JSONSerialization.data(withJSONObject: ["schemaVersion": 1, "generation": nextID.uuidString, "operationID": nextID.uuidString])
        try pointer.write(to: coordinator.controlDirectory.appendingPathComponent("active.json"))
        let restarted = LocalDataCoordinator(legacyRoot: source.localDirectory)
        try restarted.recover()
        #expect(try restarted.currentDirectory().standardizedFileURL.path == next.localDirectory.standardizedFileURL.path)
        #expect(try !restarted.cleanupRetired())
        #expect(try next.localSettings().appearance == .light)
        #expect(try restarted.pendingReview() == nil)
        let replacement = try await restarted.prepareRestore(package, source: next)
        try restarted.cancel(replacement.operationID)
        #expect(FileManager.default.fileExists(atPath: coordinator.generationDirectory(request.operationID).path))
    }
    @Test func corruptPointerAndMissingAcknowledgedStoreStillAllowReviewedArchiveRecovery() async throws {
        let source = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let package = try LocalArchivePackage.decode(await LocalArchiveService.create(store: source).data)
        let coordinator = LocalDataCoordinator(legacyRoot: source.localDirectory)
        let request = try await coordinator.prepareRestore(package, source: source)
        var result: LocalDataInstallation? = try coordinator.commit(request, source: source)
        #expect(result?.review.operationID == request.operationID)
        try coordinator.acknowledge(request.operationID); result = nil
        try FileManager.default.removeItem(at: coordinator.generationDirectory(request.operationID))
        try Data("damaged pointer".utf8).write(to: coordinator.controlDirectory.appendingPathComponent("active.json"))
        let restarted = LocalDataCoordinator(legacyRoot: source.localDirectory)
        try restarted.recover()
        #expect(throws: (any Error).self) { try restarted.currentDirectory() }
        #expect(!FileManager.default.fileExists(atPath: coordinator.generationDirectory(request.operationID).path))
        let replacement = try await restarted.prepareRestore(package, source: nil)
        let restored = try restarted.commit(replacement, source: nil)
        #expect(try restored.store.validateArchiveContents() == package.header.summary)
    }
    @Test func damagedStoreLargerThanArchiveBudgetCanBeReplacedWithoutLosingStaleDetection() async throws {
        let source = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let package = try LocalArchivePackage.decode(await LocalArchiveService.create(store: source).data)
        let damaged = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try LocalArchiveIO.protectedDirectory(damaged)
        let database = damaged.appendingPathComponent("wardrobe.store")
        try Data("damaged".utf8).write(to: database)
        let handle = try FileHandle(forWritingTo: database)
        defer { try? handle.close() }
        try handle.truncate(atOffset: UInt64(LocalArchivePackage.maximumBytes + 1))
        let coordinator = LocalDataCoordinator(legacyRoot: damaged)
        let request = try await coordinator.prepareRestore(package, source: nil)
        try handle.seek(toOffset: 0); try handle.write(contentsOf: Data("changed".utf8))
        #expect(throws: (any Error).self) { try coordinator.commit(request, source: nil) }
        let refreshed = try coordinator.refreshReview(request.operationID, source: nil)
        let restored = try coordinator.commit(refreshed, source: nil)
        #expect(try restored.store.validateArchiveContents() == package.header.summary)
    }
    @Test(arguments: [false, true], [false, true]) func invalidUnacknowledgedCandidateAndPointerRecoverValidatedOriginal(generatedSource: Bool, corruptPointer: Bool) async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var source = try PieceStore(directory: root)
        let coordinator = LocalDataCoordinator(legacyRoot: root)
        if generatedSource {
            let initial = try LocalArchivePackage.decode(await LocalArchiveService.create(store: source).data)
            let request = try await coordinator.prepareRestore(initial, source: source)
            source = try coordinator.commit(request, source: source).store
            try coordinator.acknowledge(request.operationID)
            #expect(try coordinator.cleanupRetired())
        }
        var chat = AgentConversation(ownerID: try source.todayConfiguration().ownerID); chat.draft = "Original survives broken pointer"
        _ = try source.saveAgentConversation(chat, operationID: UUID())
        let package = try LocalArchivePackage.decode(await LocalArchiveService.create(store: source).data)
        #expect(try source.localDirectory.standardizedFileURL.path == coordinator.currentDirectory().standardizedFileURL.path)
        let request = try await coordinator.prepareRestore(package, source: source)
        var installed: LocalDataInstallation? = try coordinator.commit(request, source: source)
        #expect(installed?.review.phase == .installed); installed = nil
        try FileManager.default.removeItem(at: coordinator.generationDirectory(request.operationID))
        let pointer = coordinator.controlDirectory.appendingPathComponent("active.json")
        if corruptPointer { try Data("damaged pointer".utf8).write(to: pointer) } else { try FileManager.default.removeItem(at: pointer) }
        let restarted = LocalDataCoordinator(legacyRoot: root)
        try restarted.recover()
        #expect(try restarted.currentDirectory().standardizedFileURL.path == source.localDirectory.standardizedFileURL.path)
        #expect(try PieceStore(directory: restarted.currentDirectory()).agentConversations().first?.draft == chat.draft)
        #expect(try restarted.pendingReview()?.phase == .failed)
        try restarted.cancel(request.operationID)
        #expect(try restarted.pendingReview() == nil)
    }
    @Test(arguments: [false, true]) func missingPointerAfterCleanupNeverSeedsEmptyDataAndRetainsUntrackedGenerations(emptyLegacy: Bool) async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var source: PieceStore? = try PieceStore(directory: root)
        let coordinator = LocalDataCoordinator(legacyRoot: root)
        #expect(try coordinator.currentDirectory().standardizedFileURL.path == root.standardizedFileURL.path)
        var chat = AgentConversation(ownerID: try #require(source).todayConfiguration().ownerID); chat.draft = "Keep the generated closet"
        _ = try #require(source).saveAgentConversation(chat, operationID: UUID())
        let package = try LocalArchivePackage.decode(await LocalArchiveService.create(store: #require(source)).data)
        let request = try await coordinator.prepareRestore(package, source: source)
        let installed = try coordinator.commit(request, source: source); source = nil
        try coordinator.acknowledge(request.operationID); #expect(try coordinator.cleanupRetired())
        #expect(!FileManager.default.fileExists(atPath: root.path))
        try FileManager.default.removeItem(at: coordinator.controlDirectory.appendingPathComponent("active.json"))
        if emptyLegacy { try LocalArchiveIO.protectedDirectory(root) }
        let restarted = LocalDataCoordinator(legacyRoot: root)
        #expect(throws: (any Error).self) { _ = try PieceStore(directory: restarted.currentDirectory()) }
        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("wardrobe.store").path))
        #expect(try installed.store.agentConversations().first?.draft == chat.draft)
        let replacement = try await restarted.prepareRestore(package, source: nil)
        let restored = try restarted.commit(replacement, source: nil); try restarted.acknowledge(replacement.operationID)
        #expect(try restored.store.agentConversations().first?.draft == chat.draft)
        #expect(throws: (any Error).self) { try restarted.cleanupRetired() }
        #expect(try restarted.pendingReview()?.phase == .acknowledged)
        #expect(FileManager.default.fileExists(atPath: coordinator.generationDirectory(request.operationID).path))
    }
    @Test func readableSourceWithMissingMediaCanBeReplacedFromAValidArchive() async throws {
        let fixture = try await LocalDataFixture(), source = fixture.store
        let package = try LocalArchivePackage.decode(await LocalArchiveService.create(store: source).data)
        try FileManager.default.removeItem(at: source.localDirectory.appendingPathComponent("media/\(fixture.processed.id.uuidString).jpg"))
        #expect(throws: (any Error).self) { try source.validateArchiveContents() }
        let coordinator = LocalDataCoordinator(legacyRoot: source.localDirectory)
        let review = try await coordinator.prepareRestore(package, source: source)
        let restored = try coordinator.commit(review, source: source)
        #expect(try restored.store.validateArchiveContents() == package.header.summary)
    }
    @Test func corruptPointerAfterPublicationBeforeReceiptRecoversOriginalAndAllowsAnotherArchive() async throws {
        let source = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let archive = try await LocalArchiveService.create(store: source), package = try LocalArchivePackage.decode(archive.data)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".aqdarchive")
        try archive.data.write(to: file); defer { try? FileManager.default.removeItem(at: file) }
        let coordinator = LocalDataCoordinator(legacyRoot: source.localDirectory, afterSwitch: { throw CocoaError(.fileReadUnknown) })
        let review = try await coordinator.prepareRestore(package, source: source)
        #expect(throws: (any Error).self) { try coordinator.commit(review, source: source) }
        #expect(try coordinator.pendingReview()?.phase == .review)
        try Data("damaged pointer".utf8).write(to: coordinator.controlDirectory.appendingPathComponent("active.json"))
        let restarted = LocalDataCoordinator(legacyRoot: source.localDirectory)
        let model = LocalRestoreModel(coordinator: restarted, source: source)
        #expect(model.phase == .failed)
        #expect(try restarted.currentDirectory().standardizedFileURL.path == source.localDirectory.standardizedFileURL.path)
        model.choose(file)
        for _ in 0..<200 { if model.phase != .validating { break }; try await Task.sleep(for: .milliseconds(5)) }
        #expect(model.phase == .review)
        #expect(model.review?.operationID != review.operationID)
    }
    @Test(arguments: ["pointer", "operation", "retired"]) func malformedControlMetadataAllowsFingerprintBoundReviewedRecovery(kind: String) async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var source: PieceStore? = try PieceStore(directory: root)
        let package = try LocalArchivePackage.decode(await LocalArchiveService.create(store: #require(source)).data)
        let coordinator = LocalDataCoordinator(legacyRoot: root)
        let first = try await coordinator.prepareRestore(package, source: source)
        _ = try coordinator.commit(first, source: source); source = nil
        try coordinator.acknowledge(first.operationID); #expect(try coordinator.cleanupRetired())
        let name = kind == "pointer" ? "active.json" : kind == "operation" ? "operation.json" : "retired-\(first.operationID.uuidString).json"
        try Data("invalid control metadata".utf8).write(to: coordinator.controlDirectory.appendingPathComponent(name))
        let restarted = LocalDataCoordinator(legacyRoot: root)
        try restarted.recover()
        #expect(throws: (any Error).self) { try restarted.currentDirectory() }
        let review = try await restarted.prepareRestore(package, source: nil)
        let quarantined = try #require(FileManager.default.contentsOfDirectory(at: restarted.controlDirectory, includingPropertiesForKeys: nil).first { $0.lastPathComponent.hasPrefix("unreadable-") })
        try Data("changed recovery metadata".utf8).write(to: quarantined)
        #expect(throws: (any Error).self) { try restarted.commit(review, source: nil) }
        let refreshed = try restarted.refreshReview(review.operationID, source: nil)
        let result = try restarted.commit(refreshed, source: nil)
        try restarted.acknowledge(result.review.operationID)
        #expect(try result.store.validateArchiveContents() == package.header.summary)
        #expect(try !restarted.cleanupRetired())
        #expect(try restarted.pendingReview()?.phase == .acknowledged)
        #expect(FileManager.default.fileExists(atPath: coordinator.generationDirectory(first.operationID).path))
    }
    @Test func failedEraseStoreCreationRetainsAttributionUntilSafeCleanup() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var source: PieceStore? = try PieceStore(directory: root)
        var failCreation = true, allowCleanup = false
        let coordinator = LocalDataCoordinator(legacyRoot: root, beforeEraseStore: { directory in
            if failCreation { try LocalArchiveIO.protectedDirectory(directory); throw CocoaError(.fileWriteUnknown) }
        }, removeDirectory: { directory in
            guard allowCleanup else { throw CocoaError(.fileWriteNoPermission) }; try FileManager.default.removeItem(at: directory)
        })
        do { _ = try await coordinator.prepareErase(source: source); Issue.record("Creation fault was ignored") } catch {}
        #expect(try coordinator.pendingReview() == nil)
        failCreation = false
        let review = try await coordinator.prepareErase(source: source)
        _ = try coordinator.commit(review, source: source, confirmation: "ERASE"); source = nil
        try coordinator.acknowledge(review.operationID); allowCleanup = true
        #expect(try coordinator.cleanupRetired())
        let remaining = try FileManager.default.contentsOfDirectory(at: coordinator.controlDirectory, includingPropertiesForKeys: nil).filter { UUID(uuidString: $0.lastPathComponent) != nil }
        #expect(remaining.count == 1 && remaining.first?.lastPathComponent == review.operationID.uuidString)
    }
    @Test func quarantinedRecoveryPublicationReconcilesBeforeInstalledReceipt() async throws {
        let external = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let package = try LocalArchivePackage.decode(await LocalArchiveService.create(store: external).data)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try LocalArchiveIO.protectedDirectory(root)
        try Data("broken database".utf8).write(to: root.appendingPathComponent("wardrobe.store"))
        try Data("AQD-piece-store:22".utf8).write(to: root.appendingPathComponent("schema-version"))
        let coordinator = LocalDataCoordinator(legacyRoot: root, afterSwitch: { throw CocoaError(.fileReadUnknown) })
        try LocalArchiveIO.protectedDirectory(coordinator.controlDirectory)
        try Data("broken receipt".utf8).write(to: coordinator.controlDirectory.appendingPathComponent("operation.json"))
        try coordinator.recover()
        let review = try await coordinator.prepareRestore(package, source: nil)
        #expect(throws: (any Error).self) { try coordinator.commit(review, source: nil) }
        #expect(try coordinator.pendingReview()?.phase == .review)
        let restarted = LocalDataCoordinator(legacyRoot: root)
        try restarted.recover()
        let pending = try #require(try restarted.pendingReview())
        #expect(pending.phase == .installed)
        let result = try restarted.commit(pending, source: nil)
        #expect(try result.store.validateArchiveContents() == package.header.summary)
        try restarted.acknowledge(pending.operationID)
        #expect(try !restarted.cleanupRetired())
    }
    @Test func invalidCandidateAndOriginalAllowAnotherArchiveWithIntactPointer() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var source: PieceStore? = try PieceStore(directory: root)
        let archive = try await LocalArchiveService.create(store: #require(source)), package = try LocalArchivePackage.decode(archive.data)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".aqdarchive")
        try archive.data.write(to: file); defer { try? FileManager.default.removeItem(at: file) }
        let coordinator = LocalDataCoordinator(legacyRoot: root)
        let review = try await coordinator.prepareRestore(package, source: source)
        var installed: LocalDataInstallation? = try coordinator.commit(review, source: source)
        #expect(installed?.review.phase == .installed); installed = nil; source = nil
        try FileManager.default.removeItem(at: root)
        try FileManager.default.removeItem(at: coordinator.generationDirectory(review.operationID))
        let restarted = LocalDataCoordinator(legacyRoot: root)
        let model = LocalRestoreModel(coordinator: restarted, source: nil)
        #expect(model.phase == .choose)
        #expect(throws: (any Error).self) { try restarted.currentDirectory() }
        model.choose(file)
        for _ in 0..<200 { if model.phase != .validating { break }; try await Task.sleep(for: .milliseconds(5)) }
        #expect(model.phase == .review && model.review?.operationID != review.operationID)
        model.commit()
        for _ in 0..<200 { if model.phase != .committing { break }; try await Task.sleep(for: .milliseconds(5)) }
        #expect(model.phase == .complete)
        #expect(try model.installed?.validateArchiveContents() == package.header.summary)
    }
    @Test func cancellingAValidatedReplacementKeepsTheCurrentCloset() async throws {
        let source = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        var chat = AgentConversation(ownerID: try source.todayConfiguration().ownerID); chat.draft = "Keep this"
        _ = try source.saveAgentConversation(chat, operationID: UUID())
        let package = try LocalArchivePackage.decode(await LocalArchiveService.create(store: source).data)
        let coordinator = LocalDataCoordinator(legacyRoot: source.localDirectory)
        let request = try await coordinator.prepareRestore(package, source: source)
        try coordinator.cancel(request.operationID)
        #expect(try coordinator.currentDirectory().standardizedFileURL.path == source.localDirectory.standardizedFileURL.path)
        #expect(try source.agentConversations().first?.draft == "Keep this")
    }
    @Test func staleReviewRefusesReplacementAndFreshReviewRequiresTheNewVersion() async throws {
        let source = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let package = try LocalArchivePackage.decode(await LocalArchiveService.create(store: source).data)
        let coordinator = LocalDataCoordinator(legacyRoot: source.localDirectory)
        let first = try await coordinator.prepareRestore(package, source: source)
        _ = try source.saveLocalSettings(LocalSettingsRequest(base: source.localSettings(), appearance: .dark))
        #expect(throws: (any Error).self) { try coordinator.commit(first, source: source) }
        #expect(try source.localSettings().appearance == .dark)
        let refreshed = try coordinator.refreshReview(first.operationID, source: source)
        #expect(refreshed.version == 2)
        #expect(throws: (any Error).self) { try coordinator.commit(first, source: source) }
        let result = try coordinator.commit(refreshed, source: source)
        #expect(try result.store.localSettings().appearance == .system)
        #expect(try source.localSettings().appearance == .dark)
        try coordinator.acknowledge(result.review.operationID)
        #expect(try !coordinator.cleanupRetired())
    }
    @Test func failedSwitchPreservesOriginalAndLostAcknowledgmentReconcilesOnePublishedGeneration() async throws {
        let fixture = try await LocalDataFixture(), source = fixture.store
        let package = try LocalArchivePackage.decode(await LocalArchiveService.create(store: source).data)
        var before = true, after = true
        let coordinator = LocalDataCoordinator(legacyRoot: source.localDirectory,
            beforeSwitch: { if before { throw CocoaError(.fileWriteNoPermission) } },
            afterSwitch: { if after { throw CocoaError(.fileReadUnknown) } })
        let request = try await coordinator.prepareRestore(package, source: source)
        #expect(throws: (any Error).self) { try coordinator.commit(request, source: source) }
        #expect(try !coordinator.isInstalled(request.operationID))
        #expect(try source.pieces() == [fixture.piece])
        before = false
        #expect(throws: (any Error).self) { try coordinator.commit(request, source: source) }
        #expect(try coordinator.isInstalled(request.operationID))
        let restarted = LocalDataCoordinator(legacyRoot: source.localDirectory)
        try restarted.recover()
        let pending = try #require(try restarted.pendingReview())
        #expect(pending.phase == .installed)
        let result = try restarted.commit(pending, source: nil)
        #expect(try result.store.pieces() == source.pieces() && result.store.todayDraft() == source.todayDraft())
        #expect(try result.store.agentConversations() == source.agentConversations())
        after = false
        _ = try result.store.saveLocalSettings(LocalSettingsRequest(base: result.store.localSettings(), appearance: .light))
        let retried = try restarted.commit(pending, source: nil)
        #expect(try retried.store.localSettings().appearance == .light)
        try restarted.acknowledge(request.operationID)
        #expect(FileManager.default.fileExists(atPath: source.localDirectory.path))
    }

    @Test func aMissingUnacknowledgedInstalledDatabaseRecoversTheOriginalWithoutSeedingEmptyData() async throws {
        let source = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        var chat = AgentConversation(ownerID: try source.todayConfiguration().ownerID); chat.draft = "Original remains"
        _ = try source.saveAgentConversation(chat, operationID: UUID())
        let coordinator = LocalDataCoordinator(legacyRoot: source.localDirectory, afterSwitch: { throw CocoaError(.fileReadUnknown) })
        let package = try LocalArchivePackage.decode(await LocalArchiveService.create(store: source).data)
        let request = try await coordinator.prepareRestore(package, source: source)
        #expect(throws: (any Error).self) { try coordinator.commit(request, source: source) }
        try FileManager.default.removeItem(at: coordinator.generationDirectory(request.operationID).appendingPathComponent("wardrobe.store"))
        #expect(throws: (any Error).self) { try coordinator.currentDirectory() }
        let restarted = LocalDataCoordinator(legacyRoot: source.localDirectory)
        try restarted.recover()
        #expect(try restarted.currentDirectory().standardizedFileURL.path == source.localDirectory.standardizedFileURL.path)
        #expect(try PieceStore(directory: restarted.currentDirectory()).agentConversations().first?.draft == "Original remains")
        #expect(try restarted.pendingReview()?.phase == .failed)
        try restarted.cancel(request.operationID)
    }
}
