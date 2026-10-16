import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct LocalReplacementTests {
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
