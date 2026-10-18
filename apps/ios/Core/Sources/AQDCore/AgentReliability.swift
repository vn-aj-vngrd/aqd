import Foundation

public enum AgentDataSource: String, Codable, CaseIterable, Sendable {
    case pieces, outfits, themes, planner, wear, journal, today, style, profile, pastChats, feedback, notes, weather
    public var title: String {
        switch self {
        case .pieces: "Pieces"; case .outfits: "Outfits"; case .themes: "Themes"; case .planner: "Plans"
        case .today: "Today cards"; case .wear: "Wear history & insights"; case .journal: "Fit journal"; case .style: "Style preferences"
        case .profile: "Profile"; case .pastChats: "Past chat topics"; case .feedback: "Saved feedback"
        case .notes: "Private notes"; case .weather: "Weather"
        }
    }
}
public struct AgentPreferences: Codable, Equatable, Sendable {
    public var sources: [AgentDataSource] = AgentDataSource.allCases
    public init() {}
    public func allows(_ source: AgentDataSource) -> Bool { sources.contains(source) }
    public mutating func set(_ source: AgentDataSource, enabled: Bool) {
        sources = AgentDataSource.allCases.filter { $0 == source ? enabled : sources.contains($0) }
    }
    public func validated() throws { guard Set(sources).count == sources.count else { throw PlanValidationError.invalidRecord } }
}
public enum AgentFailureCategory: String, Codable, CaseIterable, Sendable {
    case contextLimit, sourceUnavailable, generation, interrupted, timeout, storage, unsupported
    public var title: String {
        switch self {
        case .contextLimit: "Context limit"; case .sourceUnavailable: "Data unavailable"; case .generation: "Response error"
        case .interrupted: "Interrupted"; case .timeout: "Timed out"; case .storage: "Save unconfirmed"; case .unsupported: "Model unavailable"
        }
    }
}
public struct AgentResponseDiagnostics: Codable, Equatable, Sendable {
    public static let currentPromptVersion = "aqd-grounding-4"
    public var promptVersion = Self.currentPromptVersion
    public var retrievalVersion = AgentRetrieval.version
    public var included: Int
    public var omitted: Int
    public var inputCharacters: Int
    public var sources: [AgentDataSource]
    public var unavailable: [AgentDataSource]
    public var failure: AgentFailureCategory?
    /// The classified intent (`AgentIntent` raw value) and the tools the turn called, in order. A " (app)" suffix marks work the app did itself.
    public var intent: String?
    public var toolCalls: [String]?
    /// Problems the grounding check found in the first reply, and in the reply that was kept.
    public var firstViolations: [String]?
    public var groundingViolations: [String]?
    public init(included: Int, omitted: Int, inputCharacters: Int, sources: [AgentDataSource], unavailable: [AgentDataSource] = []) {
        self.included = included; self.omitted = omitted; self.inputCharacters = inputCharacters; self.sources = sources; self.unavailable = unavailable
    }
    public func validated() throws {
        guard included >= 0, omitted >= 0, inputCharacters >= 0, promptVersion.count <= 80, retrievalVersion.count <= 80,
              Set(sources).count == sources.count, Set(unavailable).count == unavailable.count,
              (toolCalls?.count ?? 0) <= 64, (firstViolations?.count ?? 0) <= 32, (groundingViolations?.count ?? 0) <= 32 else { throw PlanValidationError.invalidRecord }
    }
}
public enum AgentFeedbackRating: String, Codable, Sendable { case helpful, notHelpful }
public enum AgentFeedbackReason: String, Codable, CaseIterable, Sendable {
    case incorrectFacts, irrelevant, unavailableItems, ignoredPreferences, tone, safety, privacy, bug, idea, other
    public var title: String {
        switch self {
        case .incorrectFacts: "Incorrect information"; case .irrelevant: "Not relevant"; case .unavailableItems: "Unavailable pieces"
        case .ignoredPreferences: "Missed my preferences"; case .tone: "Tone or formatting"; case .safety: "Unsafe advice"
        case .privacy: "Privacy concern"; case .bug: "Something isn’t working"; case .idea: "An idea for AQD"; case .other: "Something else"
        }
    }
}
public struct AgentFeedback: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var rating: AgentFeedbackRating?
    public var isReport = false
    public var reasons: [AgentFeedbackReason] = []
    public var comment = ""
    public let conversationID: UUID?
    public let messageID: UUID?
    public let attemptID: UUID?
    public var diagnostics: AgentResponseDiagnostics?
    public var includesConversation = false
    public var userText: String?
    public var responseText: String?
    public let createdAt: Date
    public var updatedAt: Date
    public init(rating: AgentFeedbackRating? = nil, isReport: Bool = false, conversationID: UUID? = nil, messageID: UUID? = nil, attemptID: UUID? = nil, diagnostics: AgentResponseDiagnostics? = nil) {
        id = UUID(); self.rating = rating; self.isReport = isReport; self.conversationID = conversationID
        self.messageID = messageID; self.attemptID = attemptID; self.diagnostics = diagnostics; createdAt = Date(); updatedAt = createdAt
    }
    public var title: String { isReport ? "Report" : rating == .helpful ? "Helpful response" : rating == .notHelpful ? "Not helpful" : "Feedback" }
    public func validated() throws {
        guard comment.count <= 1000, (userText?.count ?? 0) <= 1000, (responseText?.count ?? 0) <= 2000,
              includesConversation || (userText == nil && responseText == nil),
              (conversationID == nil) == (messageID == nil), (messageID == nil) == (attemptID == nil),
              Set(reasons).count == reasons.count, rating != nil || isReport || !comment.isEmpty || !reasons.isEmpty,
              createdAt.timeIntervalSince1970.isFinite, updatedAt >= createdAt else { throw PlanValidationError.invalidRecord }
        try diagnostics?.validated()
    }
    public func report(includingConversation: Bool) -> AgentFeedbackReport {
        AgentFeedbackReport(feedbackID: id, createdAt: createdAt, updatedAt: updatedAt, rating: rating, isReport: isReport, reasons: reasons, comment: comment,
            attemptID: attemptID, diagnostics: diagnostics,
            userText: includingConversation && includesConversation ? userText : nil,
            responseText: includingConversation && includesConversation ? responseText : nil)
    }
}
/// A reviewed local export contract. No network destination or automatic delivery exists.
public struct AgentFeedbackReport: Encodable, Equatable, Sendable {
    public let schemaVersion = 1
    public let feedbackID: UUID
    public let createdAt: Date
    public let updatedAt: Date
    public let rating: AgentFeedbackRating?
    public let isReport: Bool
    public let reasons: [AgentFeedbackReason]
    public let comment: String
    public let attemptID: UUID?
    public let diagnostics: AgentResponseDiagnostics?
    public let userText: String?
    public let responseText: String?
}
public struct AgentKnowledgeRecord: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let source: AgentDataSource
    public let text: String
    public let eligibleForSuggestions: Bool
    public let priority: Double
    public let containsPrivateNotes: Bool
    public init(id: UUID = UUID(), source: AgentDataSource, text: String, eligibleForSuggestions: Bool = true, priority: Double = 0, containsPrivateNotes: Bool = false) {
        self.id = id; self.source = source; self.text = text; self.eligibleForSuggestions = eligibleForSuggestions; self.priority = priority; self.containsPrivateNotes = containsPrivateNotes
    }
}
public struct AgentRetrievalResult: Equatable, Sendable {
    public let text: String
    public let recordIDs: [UUID]
    public let sources: [AgentDataSource]
    public let included: Int
    public let omitted: Int
}
public enum AgentRetrieval {
    public static let version = "bm25-diverse-1"
    private static func terms(_ text: String) -> [String] {
        let stops: Set<String> = ["the", "a", "an", "my", "i", "to", "for", "and", "of", "in", "what", "can", "is", "it", "me", "with", "please"]
        return text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty && !stops.contains($0) }
    }
    public static func select(query: String, records: [AgentKnowledgeRecord], facts: [String], maximumCharacters: Int, maximumRecords: Int) throws -> AgentRetrievalResult {
        guard maximumCharacters >= 256, maximumRecords > 0, records.allSatisfy({ $0.priority.isFinite }), Set(records.map { $0.source.rawValue + ":" + $0.id.uuidString }).count == records.count else { throw PlanValidationError.invalidRecord }
        let queryTerms = Array(Set(terms(query).prefix(48))).sorted(), lower = query.lowercased()
        let historical = ["archiv", "laundry", "unavailable", "history", "wore", "count", "how many", "show", "list", "own", "have"].contains { lower.contains($0) }
        let candidates = records.filter { historical || $0.eligibleForSuggestions }
        let documents = candidates.map { terms($0.text) }
        let average = max(1, Double(documents.reduce(0) { $0 + $1.count }) / Double(max(1, documents.count)))
        let documentFrequencies = Dictionary(uniqueKeysWithValues: queryTerms.map { term in
            (term, Double(documents.filter { $0.contains(term) }.count))
        })
        func boost(_ source: AgentDataSource) -> Double {
            let words: [String]
            switch source {
            case .pieces, .outfits: words = ["wear", "outfit", "look", "piece", "shirt", "shoe", "dress"]
            case .themes: words = ["theme", "collection"]
            case .planner, .today: words = ["today", "plan", "week", "trip", "travel", "tomorrow", "schedule"]
            case .wear: words = ["wore", "worn", "unworn", "history", "insight", "often", "least", "most"]
            case .journal: words = ["fit", "journal", "photo", "memory"]
            case .style: words = ["prefer", "style", "color", "comfort"]
            case .pastChats: words = ["said", "previous", "remember", "chat"]
            default: words = []
            }
            return words.contains(where: { lower.contains($0) }) ? 3 : 0
        }
        var ranked: [(AgentKnowledgeRecord, Double)] = []
        for (index, record) in candidates.enumerated() {
            let document = documents[index]
            var score = boost(record.source) + max(-5, min(5, record.priority))
            for term in queryTerms {
                let frequency = Double(document.filter { $0 == term }.count)
                let containing = documentFrequencies[term, default: 0]
                let idf = log(1 + (Double(documents.count) - containing + 0.5) / (containing + 0.5))
                score += idf * frequency * 2.2 / (frequency + 1.2 * (0.25 + 0.75 * Double(document.count) / average))
            }
            ranked.append((record, score))
        }
        ranked.sort { left, right in
            if left.1 != right.1 { return left.1 > right.1 }
            if left.0.id != right.0.id { return left.0.id.uuidString < right.0.id.uuidString }
            return left.0.source.rawValue < right.0.source.rawValue
        }
        struct Item: Encodable { let source: String; let data: String; let availableForSuggestions: Bool; let containsPrivateNotes: Bool }
        struct Payload: Encodable { let facts: [String]; let included: Int; let omitted: Int; let records: [Item] }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        func excerpt(_ text: String) -> String {
            guard text.count > 600 else { return text }
            let relevantTerms = queryTerms.sorted {
                let left = documentFrequencies[$0, default: 0], right = documentFrequencies[$1, default: 0]
                return left == right ? $0 < $1 : left < right
            }
            for term in relevantTerms {
                if let match = text.range(of: term, options: [.caseInsensitive, .diacriticInsensitive]), text.distance(from: text.startIndex, to: match.lowerBound) > 250 {
                    let start = text.index(match.lowerBound, offsetBy: -60, limitedBy: text.startIndex) ?? text.startIndex
                    let end = text.index(start, offsetBy: 340, limitedBy: text.endIndex) ?? text.endIndex
                    return String(text.prefix(160)) + " … " + String(text[start..<end]) + " [partial record]"
                }
            }
            return String(text.prefix(580)) + " [partial record]"
        }
        func render(_ selected: [AgentKnowledgeRecord]) throws -> String {
            let items = selected.map { record in Item(source: record.source.rawValue, data: excerpt(record.text), availableForSuggestions: record.eligibleForSuggestions, containsPrivateNotes: record.containsPrivateNotes) }
            return String(decoding: try encoder.encode(Payload(facts: facts, included: selected.count, omitted: records.count - selected.count, records: items)), as: UTF8.self)
        }
        var selected: [AgentKnowledgeRecord] = []
        guard try render(selected).count <= maximumCharacters else { throw AgentContextError.budgetExceeded }
        // First represent the most relevant record in each enabled collection, then fill by relevance.
        var representatives: [(AgentKnowledgeRecord, Double)] = []
        for source in AgentDataSource.allCases {
            if let match = ranked.first(where: { $0.0.source == source }) { representatives.append(match) }
        }
        representatives.sort { left, right in
            if left.1 != right.1 { return left.1 > right.1 }
            if left.0.id != right.0.id { return left.0.id.uuidString < right.0.id.uuidString }
            return left.0.source.rawValue < right.0.source.rawValue
        }
        let representativeRecords = representatives.map { $0.0 }
        for record in representativeRecords + ranked.map({ $0.0 }) where !selected.contains(where: { $0.id == record.id && $0.source == record.source }) {
            guard selected.count < maximumRecords else { break }
            if try render(selected + [record]).count <= maximumCharacters { selected.append(record) }
        }
        return AgentRetrievalResult(text: try render(selected), recordIDs: selected.map(\.id), sources: AgentDataSource.allCases.filter { source in selected.contains { $0.source == source || (source == .notes && $0.containsPrivateNotes) } }, included: selected.count, omitted: records.count - selected.count)
    }
}
