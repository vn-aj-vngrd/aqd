import AQDCore
import Foundation
import Testing
@testable import AQD

@MainActor @Suite(.serialized) struct RealisticClosetSeedTests {
    /// 136 pieces with three archived, 66 outfits, 21 themes, 32 planned days (week, two routines, two trips, a wedding),
    /// 53 worn days and 12 fits.
    private let expected = [133, 66, 21, 32, 53, 12]
    @Test func replacesTheOldSamplesWithAWeekOfUseAndRunsAgainWithoutDuplicates() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: root.appendingPathComponent("store"))
        let output = root.appendingPathComponent("receipts")
        _ = try await PreviewSampleContent.populate(store: store, outputDirectory: output)

        let first = try await RealisticClosetSeed.run(store: store, outputDirectory: output)
        func counts() throws -> [Int] {
            [try store.pieces().count, try store.outfits().count, try store.themes().count, try store.planEntries().count, try store.wearRecords().count, try store.fitMemories().count]
        }
        #expect(try counts() == expected)
        let sampleIDs = Set(PreviewSampleContent.sampleIDs.values.flatMap { $0 })
        #expect(try Set(store.pieces().map(\.id)).isDisjoint(with: sampleIDs))
        #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent(first.backup).path))

        _ = try await RealisticClosetSeed.run(store: store, outputDirectory: output)
        #expect(try counts() == expected)
    }

    @Test func agentContextStatesTheClosetTotalsWithinTheRequestBudget() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: root.appendingPathComponent("store"))
        _ = try await RealisticClosetSeed.run(store: store, outputDirectory: root.appendingPathComponent("receipts"))
        let result = try AgentKnowledgeSource.build(store: store, preferences: AgentPreferences(), query: "What should I wear today?", currentConversationID: UUID(),
                                                    weather: nil, selection: nil,
                                                    limits: AgentContextLimits(catalogCharacters: 2800, recordCharacters: 1500, maximumRecords: 6))
        #expect(result.retrieval.text.count <= 5200)
        // A closet this large cannot be listed in full; the catalog states the real totals and retrieval stays inside the budget.
        #expect(result.catalog.contains("\(try store.pieces().count) pieces"), "\(result.catalog.prefix(400))")
        #expect(result.catalog.contains("66 outfits") && result.catalog.contains("21 themes"), "\(result.catalog.prefix(400))")
        #expect(!result.retrieval.text.isEmpty)
    }
}
