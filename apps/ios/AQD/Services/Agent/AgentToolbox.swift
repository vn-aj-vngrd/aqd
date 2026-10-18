import Foundation
import AQDCore

enum AgentWearWindow: String, Sendable { case thisMonth, lastMonth }

/// Feature-owned implementations the model-facing tools call. Each runs on the main actor against the store.
/// What the owner asked to see. Empty strings mean "any".
struct AgentShowRequest: Sendable {
    enum Kind: String, Sendable { case pieces, outfits, themes, plans }
    var kind: Kind
    var color = "", category = "", brand = "", availability = "", query = ""
}

struct AgentToolHandlers: Sendable {
    var show: @MainActor @Sendable (_ request: AgentShowRequest) throws -> String
    var find: @MainActor @Sendable (_ query: String, _ kinds: [AgentDataSource]) throws -> String
    var wearStats: @MainActor @Sendable (_ window: AgentWearWindow, _ pieceIDs: [UUID]) throws -> String
    var weather: @MainActor @Sendable (_ day: String) throws -> String
    var prepare: @MainActor @Sendable (_ request: AgentMutationRequest, _ revision: Int?) throws -> String
    var suggestOutfit: @MainActor @Sendable (_ occasion: String?, _ mood: String?, _ pinnedIDs: [UUID]) async throws -> String
}

enum AgentToolID: String, CaseIterable, Sendable {
    case findRecords, wearStats, weatherFor, editCloset, editOutfit, editTheme, editPlan, proposePlan, recordWear, editProfile, addPieceFromPhoto
    case suggestOutfit, proposeOutfit, proposeTheme, relabel, showRecords

    var isProposal: Bool { ![.findRecords, .showRecords, .wearStats, .weatherFor].contains(self) }
    fileprivate var keywords: [String] {
        switch self {
        case .findRecords: ["find", "show", "list", "which", "what do i have", "my ", "own", "have"]
        case .showRecords: ["show", "preview", "image", "photo", "picture", "see", "display", "look at", "list", "all my", "all the", "which", "see my", "display", "pieces", "outfits", "themes", "plans", "color", "colour", "green", "black", "white", "blue", "red", "brand", "available"]
        case .wearStats: ["wear", "worn", "wore", "unworn", "how many", "how often", "most", "least", "stats", "rediscover"]
        case .weatherFor: ["weather", "rain", "temperature", "cold", "hot", "warm", "forecast", "tomorrow", "umbrella"]
        case .editCloset: ["rename", "laundry", "unavailable", "available", "color", "colour", "brand", "piece", "shirt", "shoe"]
        case .editOutfit: ["outfit", "look", "combine"]
        case .editTheme: ["theme", "collection"]
        case .editPlan: ["edit plan", "change plan", "update plan", "swap", "trip", "pack", "routine"]
        case .proposePlan: ["plan", "week", "schedule", "days", "next", "outfits for"]
        case .recordWear: ["wore", "wearing", "log", "record"]
        case .editProfile: ["profile", "bio", "my name"]
        case .suggestOutfit: ["suggest", "recommend", "should i wear", "what to wear", "idea", "occasion", "mood", "pair", "go with", "outfit"]
        case .proposeOutfit: ["new outfit", "an outfit", "outfit from", "put together", "combine", "save this outfit", "create outfit", "make outfit"]
        case .proposeTheme: ["theme", "collection", "group", "gather", "set of outfits"]
        case .relabel: ["name", "label", "rename", "call", "title", "occasion", "mood", "unnamed"]
        case .addPieceFromPhoto: ["photo", "picture", "image", "attach", "new piece", "add this", "to my closet"]
        }
    }
}

/// Registry and intent routing: each turn offers only the two or three tools the request needs,
/// which keeps the tool definitions small enough for the on-device context window.
enum AgentToolbox {
    static let maximumTools = 3
    private static let writeVerbs = ["save", "create", "make", "add", "rename", "change", "edit", "update", "set", "mark", "plan", "record", "log", "put", "remove", "move", "suggest", "recommend", "should i wear", "label", "name", "group"]

    /// Most relevant first. A change request always carries `findRecords`, because edits need exact IDs and revisions.
    static func route(_ prompt: String, weatherAvailable: Bool) -> [AgentToolID] {
        let text = prompt.lowercased()
        let wantsChange = writeVerbs.contains { text.contains($0) }
        var scored: [(tool: AgentToolID, score: Int)] = AgentToolID.allCases.compactMap { tool in
            if tool == .weatherFor && !weatherAvailable { return nil }
            if tool.isProposal && !wantsChange { return nil }
            let hits = tool.keywords.filter { text.contains($0) }.count
            return tool == .findRecords ? (tool, hits + 1) : hits > 0 ? (tool, hits + 1) : nil
        }
        scored.sort { $0.score > $1.score }
        var chosen = scored.map(\.tool)
        let proposals = chosen.filter(\.isProposal)
        if let lead = proposals.first {
            let rest = chosen.filter { $0 != lead && $0 != .findRecords }
            chosen = [lead, .findRecords] + rest
        }
        return Array(chosen.prefix(maximumTools))
    }

    /// Drops the least relevant tools until their measured definitions fit. Returns an empty list when none fit.
    @MainActor static func fit(_ tools: [AgentToolID], measure: ([AgentToolID]) async throws -> Int, fits: (Int) -> Bool) async rethrows -> [AgentToolID] {
        var kept = tools
        while !kept.isEmpty {
            if fits(try await measure(kept)) { return kept }
            kept.removeLast()
        }
        return kept
    }

    static func id(_ value: String) throws -> UUID {
        guard let id = UUID(uuidString: value.trimmingCharacters(in: .whitespacesAndNewlines)) else { throw AgentToolRejection.malformedID(value) }
        return id
    }

    /// Cancellation propagates; a rejection explains itself to the model; anything else is a generic refusal.
    static func result(_ body: @MainActor () async throws -> String) async throws -> String {
        do { return try await body() }
        catch is CancellationError { throw CancellationError() }
        catch let rejection as AgentToolRejection { return "No proposal prepared. " + rejection.reason }
        catch { return "No change prepared or applied. Arguments, source access, dates, conflicts or records could not be validated. Ask the user to clarify or use the manual editor. Do not claim success." }
    }
}

struct AgentToolSelection: Sendable {
    let ids: [AgentToolID]
    let handlers: AgentToolHandlers
}
