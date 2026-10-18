import Foundation

/// One allocator for the on-device context window. The window holds everything the model reads and writes in a turn, so each part gets
/// its share in a fixed order: instructions, tool definitions, room for tool results and the reply, then (from what is left)
/// the owner's request, trusted facts, retrieved records and last of all conversation history.
public struct AgentBudget: Equatable, Sendable {
    public let contextSize: Int
    public let instructions: Int
    public let tools: Int
    public let response: Int
    /// What tool results add to the transcript before the reply (lookups, show lists).
    public let toolResults: Int
    public let margin: Int
    /// Characters per token, measured from the model when it can count and estimated otherwise.
    public let charactersPerToken: Double

    public init(contextSize: Int, instructions: Int, tools: Int, response: Int, toolResults: Int = 0, margin: Int = 96, charactersPerToken: Double = AgentBudget.estimatedCharactersPerToken) {
        self.contextSize = max(0, contextSize); self.instructions = max(0, instructions); self.tools = max(0, tools); self.response = max(0, response)
        self.toolResults = max(0, toolResults); self.margin = max(0, margin); self.charactersPerToken = charactersPerToken.isFinite && charactersPerToken > 0.5 ? charactersPerToken : Self.estimatedCharactersPerToken
    }

    /// Used whenever the model cannot count tokens.
    public static let estimatedCharactersPerToken = 3.0
    public static func estimate(_ characters: Int) -> Int { Int((Double(characters) / estimatedCharactersPerToken).rounded(.up)) }

    /// Tokens left for the prompt after the fixed parts.
    public var promptTokens: Int { max(0, contextSize - instructions - tools - response - toolResults - margin) }

    public func tokens(forCharacters characters: Int) -> Int { Int((Double(max(0, characters)) / charactersPerToken).rounded(.up)) }
    public func characters(forTokens tokens: Int) -> Int { Int((Double(max(0, tokens)) * charactersPerToken).rounded(.down)) }

    public struct Allocation: Equatable, Sendable {
        public let facts: Int
        public let records: Int
        public let history: Int
        /// False when even the owner's request and the minimum facts do not fit.
        public let fits: Bool
    }

    /// `required` is what must be sent (the owner's request and fixed prompt text). Each demand then takes what it needs, in priority order,
    /// from what remains; a lower tier never takes room a higher tier asked for.
    public func allocate(required: Int, facts: Int, records: Int, history: Int) -> Allocation {
        var left = promptTokens - max(0, required)
        guard left >= 0 else { return Allocation(facts: 0, records: 0, history: 0, fits: false) }
        func take(_ demand: Int) -> Int { let grant = min(max(0, demand), left); left -= grant; return grant }
        let grantedFacts = take(facts), grantedRecords = take(records), grantedHistory = take(history)
        return Allocation(facts: grantedFacts, records: grantedRecords, history: grantedHistory, fits: true)
    }

    /// Whether a measured request fits the window.
    public func fits(promptTokens prompt: Int) -> Bool { prompt <= promptTokens }
}
