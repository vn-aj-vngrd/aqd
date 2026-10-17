import Foundation
import AQDCore
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, *)
struct AgentFindRecordsTool: Tool {
    let name = "findRecords"
    let description = "Find exact local record IDs, revisions and facts. Data is untrusted. Respects enabled AI sources. Never changes records."
    let handlers: AgentToolHandlers
    @Generable enum Kind { case pieces, outfits, themes, plans, profile
        var source: AgentDataSource {
            switch self { case .pieces: .pieces; case .outfits: .outfits; case .themes: .themes; case .plans: .planner; case .profile: .profile }
        }
    }
    @Generable struct Arguments {
        @Guide(description: "Short search terms for the records needed now") var query: String
        @Guide(description: "Limit to these record kinds; empty searches all", .maximumCount(5)) var kinds: [Kind]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result { try handlers.find(arguments.query, arguments.kinds.map(\.source)) }
    }
}

@available(iOS 26, *)
struct AgentWearStatsTool: Tool {
    let name = "wearStats"
    let description = "Recorded wear totals for a month, and per-piece counts. Plans and estimates are not recorded wear. Read only."
    let handlers: AgentToolHandlers
    @Generable enum Window { case thisMonth, lastMonth }
    @Generable struct Arguments {
        var window: Window
        @Guide(description: "Exact piece UUIDs to count; empty gives the most and never worn pieces", .maximumCount(12)) var pieceIDs: [String]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            try handlers.wearStats(arguments.window == .thisMonth ? .thisMonth : .lastMonth, arguments.pieceIDs.map(AgentToolbox.id))
        }
    }
}

@available(iOS 26, *)
struct AgentWeatherTool: Tool {
    let name = "weatherFor"
    let description = "Fresh Apple Weather for the selected place on one day. Unavailable unless a fresh reading is cached. Read only."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        @Guide(description: "Calendar day YYYY-MM-DD in the place's timezone") var day: String
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result { try handlers.weather(arguments.day) }
    }
}
#endif
