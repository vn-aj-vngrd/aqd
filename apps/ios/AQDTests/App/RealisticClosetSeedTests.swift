import AQDCore
import Foundation
import Testing
@testable import AQD

@MainActor @Suite(.serialized) struct RealisticClosetSeedTests {
    private var specCount: Int { 51 }
    @Test func replacesTheOldSamplesWithAWeekOfUseAndRunsAgainWithoutDuplicates() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: root.appendingPathComponent("store"))
        let output = root.appendingPathComponent("receipts")
        _ = try await PreviewSampleContent.populate(store: store, outputDirectory: output)

        let first = try await RealisticClosetSeed.run(store: store, outputDirectory: output)
        func counts() throws -> [Int] {
            [try store.pieces().count, try store.outfits().count, try store.themes().count, try store.planEntries().count, try store.wearRecords().count, try store.fitMemories().count]
        }
        #expect(try counts() == [specCount, 26, 12, 13, 10, 5])
        let sampleIDs = Set(PreviewSampleContent.sampleIDs.values.flatMap { $0 })
        #expect(try Set(store.pieces().map(\.id)).isDisjoint(with: sampleIDs))
        #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent(first.backup).path))

        _ = try await RealisticClosetSeed.run(store: store, outputDirectory: output)
        #expect(try counts() == [specCount, 26, 12, 13, 10, 5])
    }

    @Test func agentContextNamesEveryPieceOutfitAndThemeWithinTheRequestBudget() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: root.appendingPathComponent("store"))
        _ = try await RealisticClosetSeed.run(store: store, outputDirectory: root.appendingPathComponent("receipts"))
        let result = try AgentKnowledgeSource.build(store: store, preferences: AgentPreferences(), query: "What should I wear today?", currentConversationID: UUID(),
                                                    weather: nil, selection: nil, maximumCharacters: 5200, maximumRecords: 6)
        #expect(result.retrieval.text.count <= 5200)
        #expect(result.catalog.contains("51 pieces") && result.catalog.contains("26 outfits") && result.catalog.contains("12 themes"))
        for name in ["Classic white tee", "Straw tote bag", "Coral bikini set", "Boracay trip", "Wedding guest"] { #expect(result.retrieval.text.contains(name)) }
    }
}
