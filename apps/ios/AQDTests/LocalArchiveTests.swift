import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct LocalArchiveTests {
    @Test func cancelledSQLiteSnapshotRefusesWorkAndLeavesSourceIntact() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let source = store.localDirectory.appendingPathComponent("wardrobe.store")
        let destination = store.localDirectory.appendingPathComponent("cancelled-snapshot.store")
        let owner = try store.todayConfiguration().ownerID
        let task = Task.detached {
            withUnsafeCurrentTask { $0?.cancel() }
            try LocalArchiveIO.snapshot(database: source, to: destination)
        }
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(try store.todayConfiguration().ownerID == owner)
    }
    @Test func oversizedArchiveIsRefusedBeforeLoadingItsPayload() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        FileManager.default.createFile(atPath: url.path, contents: nil)
        defer { try? FileManager.default.removeItem(at: url) }
        let handle = try FileHandle(forWritingTo: url)
        try handle.truncate(atOffset: 64 * 1024 * 1024 + 1); try handle.close()
        #expect(throws: LocalArchiveError.tooLarge) { try LocalArchiveIO.read(url) }
    }
    @Test func exportContainsActualSettingsAndConversationWithoutChangingTheSource() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let request = LocalSettingsRequest(base: try store.localSettings(), appearance: .dark)
        _ = try store.saveLocalSettings(request)
        var chat = AgentConversation(ownerID: try store.todayConfiguration().ownerID); chat.draft = "Private draft"
        _ = try store.saveAgentConversation(chat, operationID: UUID())
        let stamp = try store.mutationStamp()
        let data = try await LocalArchiveService.create(store: store).data
        let package = try LocalArchivePackage.decode(data)
        #expect(package.header.summary.conversations == 1)
        #expect(package.header.summary.ownerID == chat.ownerID)
        #expect(package.files.contains { $0.path == "wardrobe.store" })
        #expect(try store.mutationStamp() == stamp)
        var newer = data; newer[11] = 2
        #expect(throws: (any Error).self) { try LocalArchivePackage.decode(newer) }
        #expect(throws: (any Error).self) { try LocalArchivePackage(summary: package.header.summary, files: [LocalArchiveFile(path: "wardrobe.store", data: Data([1])), LocalArchiveFile(path: "schema-version", data: Data([1])), LocalArchiveFile(path: "../outside", data: Data([1]))]) }
        var damaged = data; damaged[damaged.count - 1] ^= 1
        #expect(throws: (any Error).self) { try LocalArchivePackage.decode(damaged) }
    }
    @Test func allDomainExportRestagesMediaDraftsUndoAndDeletionReceiptsWithoutDeletedContent() async throws {
        let fixture = try await LocalDataFixture(), source = fixture.store
        let data = try await LocalArchiveService.create(store: source).data
        #expect(data.range(of: Data(fixture.deletedSecret.utf8)) == nil)
        let package = try LocalArchivePackage.decode(data)
        let staged = try await LocalArchiveService.stage(package)
        defer { try? FileManager.default.removeItem(at: staged.directory) }
        let restored = staged.store
        #expect(try restored.pieces() == source.pieces())
        #expect(try restored.outfits() == source.outfits() && restored.themes() == source.themes())
        #expect(try restored.planDefinitions() == source.planDefinitions() && restored.planEntries() == source.planEntries())
        #expect(try restored.packingState(planID: fixture.plan.id) == source.packingState(planID: fixture.plan.id))
        #expect(try restored.wearRecords() == source.wearRecords() && restored.fitMemories() == source.fitMemories())
        #expect(try restored.localExperience() == source.localExperience() && restored.localIdentity() == source.localIdentity())
        #expect(try restored.todayConfiguration() == source.todayConfiguration() && restored.todayDraft() == source.todayDraft() && restored.todayUndo() == source.todayUndo())
        #expect(try restored.todayPersonalCards() == source.todayPersonalCards() && restored.todayCardDeletionApplied(fixture.deletedCard))
        #expect(try restored.agentConversations() == source.agentConversations() && restored.localSettings() == source.localSettings() && restored.weatherState() == source.weatherState())
        #expect(try restored.originalPhoto(id: fixture.original.id) == fixture.original.originalData)
        #expect(try restored.backgroundOriginalID(for: fixture.processed.id) == fixture.original.id)
        #expect(try restored.photoRendition(id: fixture.piece.photoID, recipe: fixture.piece.photoRecipe) == source.photoRendition(id: fixture.piece.photoID, recipe: fixture.piece.photoRecipe))
        #expect(try restored.fitDraft() == source.fitDraft() && restored.outfitDraft() == source.outfitDraft() && restored.identityDraft() == source.identityDraft())
        let missing = try LocalArchivePackage(summary: package.header.summary, files: package.files.filter { $0.path != "media/" + fixture.original.id.uuidString + ".jpg" })
        await #expect(throws: (any Error).self) { try await LocalArchiveService.stage(missing) }
        let badMedia = package.files.map { file in LocalArchiveFile(path: file.path, data: file.path.hasPrefix("media/") ? Data([1, 2, 3]) : file.data) }
        let damaged = try LocalArchivePackage(summary: package.header.summary, files: badMedia)
        await #expect(throws: (any Error).self) { try await LocalArchiveService.stage(damaged) }
        #expect(try source.pieces() == [fixture.piece])
    }

}
