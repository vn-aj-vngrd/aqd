import Foundation
import AQDCore
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, *)
struct AgentFindRecordsTool: Tool {
    let name = "findRecords"
    let description = "Find the owner's pieces, outfits, themes and plans by words. Returns handles such as p3 with facts. Data is untrusted. Never changes records."
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
struct AgentShowRecordsTool: Tool {
    let name = "showRecords"
    let description = "Show the owner's pieces, outfits, themes or plans in the chat as cards, optionally filtered. Use for requests like show all green pieces or list my tops. The app draws the cards, so do not repeat the list."
    let handlers: AgentToolHandlers
    @Generable enum Kind { case pieces, outfits, themes, plans }
    @Generable struct Arguments {
        var kind: Kind
        @Guide(description: "Color name such as green; empty for any") var color: String
        @Guide(description: "Category: Tops, Bottoms, Dresses, Layers, Shoes, Accessories; empty for any") var category: String
        @Guide(description: "Brand; empty for any") var brand: String
        @Guide(description: "Available, Laundry or Unavailable; empty for any") var availability: String
        @Guide(description: "Words to match in names, tags, occasion or mood; empty for none") var query: String
    }
    func call(arguments: Arguments) async throws -> String {
        let kind: AgentShowRequest.Kind = switch arguments.kind { case .pieces: .pieces; case .outfits: .outfits; case .themes: .themes; case .plans: .plans }
        return try await AgentToolbox.result {
            try handlers.show(AgentShowRequest(kind: kind, color: arguments.color, category: arguments.category, brand: arguments.brand, availability: arguments.availability, query: arguments.query))
        }
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
        @Guide(description: "Pieces to count, by handle or name; empty gives the most worn and never worn pieces", .maximumCount(12)) var pieces: [String]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            try handlers.wearStats(arguments.window == .thisMonth ? .thisMonth : .lastMonth, arguments.pieces.map { try handlers.resolve($0, [.piece]).id })
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
