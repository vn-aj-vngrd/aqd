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

/// One question the Agent needs answered, shown as a choice card: a short header, the question, answers with an optional
/// one-line detail, an optional recommended answer and single or multiple choice. The owner can always type something else.
public struct AgentQuestion: Codable, Equatable, Sendable {
    public let prompt: String
    public let options: [String]
    /// A chip above the question, such as "Trip length". At most 24 characters.
    public var header: String?
    /// One line under each answer, aligned with `options`; empty strings mean no detail.
    public var details: [String]?
    /// The answer the Agent suggests, drawn first and marked.
    public var recommended: String?
    public var multiSelect: Bool?

    public init?(prompt: String, options: [String], header: String? = nil, details: [String]? = nil, recommended: String? = nil, multiSelect: Bool = false) {
        let trim: (String) -> String = { $0.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "?.!"))) }
        var seen = Set<String>(), unique: [(String, String)] = []
        for (index, option) in options.enumerated() {
            let label = trim(option)
            guard !label.isEmpty, label.count <= 40, seen.insert(label.lowercased()).inserted else { continue }
            let detail = details.flatMap { index < $0.count ? $0[index].trimmingCharacters(in: .whitespacesAndNewlines) : nil } ?? ""
            unique.append((label, String(detail.prefix(80))))
        }
        let text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= 200, (2...4).contains(unique.count) else { return nil }
        // The recommended answer leads, as in a default choice.
        let pick = recommended.map(trim).flatMap { value in unique.firstIndex { $0.0.lowercased() == value.lowercased() } }
        if let pick, pick > 0 { unique.insert(unique.remove(at: pick), at: 0) }
        self.prompt = text; self.options = unique.map(\.0)
        let lines = unique.map(\.1)
        self.details = lines.contains { !$0.isEmpty } ? lines : nil
        self.recommended = pick.map { _ in unique[0].0 }
        let chip = header?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.header = chip.isEmpty ? nil : String(chip.prefix(24))
        self.multiSelect = multiSelect ? true : nil
    }

    public func detail(at index: Int) -> String? {
        guard let details, index < details.count, !details[index].isEmpty else { return nil }
        return details[index]
    }

    /// The text sent back for the chosen answers and any typed note.
    public func answer(choices: [String], note: String) -> String {
        let typed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let picked = options.filter(choices.contains)
        let list = picked.count > 1 ? picked.dropLast().joined(separator: ", ") + " and " + (picked.last ?? "") : picked.first ?? ""
        if list.isEmpty { return typed }
        return typed.isEmpty ? list : "\(list). \(typed)"
    }

    /// Reads "…, 3 days, 5 days or a full week?" from the end of a reply. Nil unless the reply ends in one short question that lists answers.
    public static func fromReply(_ reply: String) -> AgentQuestion? {
        let text = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.hasSuffix("?"), text.filter({ $0 == "?" }).count == 1 else { return nil }
        let body = String(text.dropLast())
        let start = body.lastIndex(where: { ".!\n".contains($0) }).map { body.index(after: $0) } ?? body.startIndex
        let sentence = String(body[start...]).trimmingCharacters(in: .whitespaces)
        guard sentence.count <= 200, sentence.range(of: " or ", options: .caseInsensitive) != nil || sentence.contains(",") else { return nil }
        let tail = sentence.components(separatedBy: CharacterSet(charactersIn: ":—–")).last ?? sentence
        var parts = tail.replacingOccurrences(of: " or ", with: ",", options: .caseInsensitive).split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard parts.count >= 2 else { return nil }
        // The first answer is glued to the question: keep as many trailing words as the next answer has.
        let width = max(1, parts[1].split(separator: " ").count)
        parts[0] = parts[0].split(separator: " ").suffix(width).joined(separator: " ")
        return AgentQuestion(prompt: sentence + "?", options: parts)
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
    /// Set by the askUser tool or read from a reply that ends in a question with answers.
    public var question: AgentQuestion?
    public init(tool: String, summary: String, count: Int = 0, rejection: String? = nil, results: [AgentResultItem]? = nil, question: AgentQuestion? = nil) {
        id = UUID(); self.tool = tool; self.summary = summary; self.count = count; self.rejection = rejection; self.results = results; self.question = question
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
        case .malformedID(let value): "“\(value)” is not a record ID. Call findRecords with its name and use the ID it returns. Never ask the owner for an ID; they never see IDs."
        case .unknownRecord(let id): "No record has ID \(id.uuidString). Call findRecords for exact IDs; never guess and never ask the owner for one."
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
