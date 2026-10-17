import Foundation

/// One collapsed tool call in an assistant message, such as "Looked up 6 pieces". It never carries record text.
public struct AgentToolStep: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let tool: String
    public var summary: String
    public var count: Int
    /// Set when the tool refused its arguments; no proposal exists for a rejected step.
    public var rejection: String?
    public init(tool: String, summary: String, count: Int = 0, rejection: String? = nil) {
        id = UUID(); self.tool = tool; self.summary = summary; self.count = count; self.rejection = rejection
    }

    public static func lookup(_ counts: [AgentDataSource: Int]) -> AgentToolStep {
        func noun(_ source: AgentDataSource, _ count: Int) -> String {
            switch source {
            case .pieces: count == 1 ? "piece" : "pieces"
            case .outfits: count == 1 ? "outfit" : "outfits"
            case .themes: count == 1 ? "theme" : "themes"
            case .planner: count == 1 ? "plan" : "plans"
            case .profile: "profile"
            default: source.rawValue
            }
        }
        let parts = AgentDataSource.allCases.compactMap { source in counts[source].flatMap { $0 > 0 ? "\($0) \(noun(source, $0))" : nil } }
        return AgentToolStep(tool: "findRecords", summary: parts.isEmpty ? "Looked up records, found none" : "Looked up " + parts.joined(separator: ", "), count: counts.values.reduce(0, +))
    }
}

/// Why a tool call produced no proposal. The reason is returned to the model so it can correct itself.
public enum AgentToolRejection: Error, Equatable, Sendable {
    case malformedID(String)
    case unknownRecord(UUID)
    case missingTarget
    case revisionRequired
    case staleRevision(expected: Int, current: Int)
    case invalidArguments

    public var reason: String {
        switch self {
        case .malformedID(let value): "“\(value)” is not a record ID. Call findRecords and copy the exact ID."
        case .unknownRecord(let id): "No record has ID \(id.uuidString). Call findRecords for exact IDs; never guess."
        case .missingTarget: "This change needs the ID of the record to edit. Call findRecords first."
        case .revisionRequired: "Pass the revision shown by findRecords with the ID."
        case .staleRevision(let expected, let current): "The record is at revision \(current), not \(expected). It changed since the lookup. Call findRecords again."
        case .invalidArguments: "The arguments could not be validated. Ask the user to clarify or use the manual editor."
        }
    }
}
