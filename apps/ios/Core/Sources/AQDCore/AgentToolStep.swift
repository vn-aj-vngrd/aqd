import Foundation

/// A record the Agent showed in the chat: enough to draw a card, never record text beyond a title and a subtitle.
public struct AgentResultItem: Identifiable, Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable { case piece, outfit, theme, plan }
    public let id: UUID
    public let kind: Kind
    public let title: String
    public let subtitle: String
    /// Photos to draw: one for a piece, up to four for an outfit or theme.
    public let photoIDs: [UUID]
    /// The pieces of an outfit, so the chat can draw it with the same composition the Closet uses.
    public let pieceIDs: [UUID]
    public init(id: UUID, kind: Kind, title: String, subtitle: String, photoIDs: [UUID] = [], pieceIDs: [UUID] = []) {
        self.id = id; self.kind = kind; self.title = title; self.subtitle = subtitle; self.photoIDs = photoIDs; self.pieceIDs = pieceIDs
    }

    private enum CodingKeys: String, CodingKey { case id, kind, title, subtitle, photoIDs, pieceIDs }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id); kind = try c.decode(Kind.self, forKey: .kind)
        title = try c.decode(String.self, forKey: .title); subtitle = try c.decode(String.self, forKey: .subtitle)
        photoIDs = try c.decodeIfPresent([UUID].self, forKey: .photoIDs) ?? []
        pieceIDs = try c.decodeIfPresent([UUID].self, forKey: .pieceIDs) ?? []
    }
}

/// One collapsed tool call in an assistant message, such as "Looked up 6 pieces". It never carries record text.
public struct AgentToolStep: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let tool: String
    public var summary: String
    public var count: Int
    /// Set when the tool refused its arguments; no proposal exists for a rejected step.
    public var rejection: String?
    /// Records the tool displayed in the chat, newest tool call last.
    public var results: [AgentResultItem]?
    public init(tool: String, summary: String, count: Int = 0, rejection: String? = nil, results: [AgentResultItem]? = nil) {
        id = UUID(); self.tool = tool; self.summary = summary; self.count = count; self.rejection = rejection; self.results = results
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

public enum AgentActivityFormat {
    /// "12s", "1m 49s".
    public static func duration(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        return total < 60 ? "\(total)s" : "\(total / 60)m \(total % 60)s"
    }
}
