import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct LocalEraseTests {
    @Test func exactConfirmationClearsAllDomainsButCleanupWaitsForReleasedOwnersAndPreservesOutsideCopies() async throws {
        var fixture: LocalDataFixture? = try await LocalDataFixture()
        var source: PieceStore? = try #require(fixture).store
        let root = try #require(source).localDirectory
        let previousOwner = try #require(source).todayConfiguration().ownerID
        let outside = root.deletingLastPathComponent().appendingPathComponent("Outside-original-\(UUID().uuidString).jpg")
        try Data("outside original and exported copy".utf8).write(to: outside)
        defer { try? FileManager.default.removeItem(at: outside) }
        var denyCleanup = true
        let coordinator = LocalDataCoordinator(legacyRoot: root, removeDirectory: { url in
            if denyCleanup { throw CocoaError(.fileWriteNoPermission) }; try FileManager.default.removeItem(at: url)
        })
        let request = try await coordinator.prepareErase(source: source)
        #expect(throws: (any Error).self) { try coordinator.commit(request, source: source, confirmation: "erase") }
        #expect(try #require(source).pieces().count == 1)
        let result = try coordinator.commit(request, source: source, confirmation: "ERASE")
        #expect(try result.store.todayConfiguration().ownerID != previousOwner)
        #expect(try result.store.validateArchiveContents().pieces == 0)
        #expect(try result.store.agentConversations().isEmpty && result.store.todayPersonalCards().isEmpty)
        #expect(try result.store.fitMemories().isEmpty && result.store.planEntries().isEmpty && result.store.wearRecords().isEmpty)
        #expect(try result.store.localExperience().style == nil && result.store.localIdentity() == nil && result.store.todayUndo() == nil)
        try coordinator.acknowledge(request.operationID)
        #expect(try !coordinator.cleanupRetired())
        fixture = nil; source = nil
        #expect(throws: (any Error).self) { try coordinator.cleanupRetired() }
        #expect(try coordinator.pendingReview() != nil)
        denyCleanup = false
        #expect(try coordinator.cleanupRetired())
        #expect(!FileManager.default.fileExists(atPath: root.path))
        #expect(try Data(contentsOf: outside) == Data("outside original and exported copy".utf8))
    }
}
