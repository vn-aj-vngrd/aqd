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
    /// The names of the records this step read, so the owner can see exactly what the answer was based on.
    public var read: [String]?
    public init(tool: String, summary: String, count: Int = 0, rejection: String? = nil, results: [AgentResultItem]? = nil, question: AgentQuestion? = nil, read: [String]? = nil) {
        id = UUID(); self.tool = tool; self.summary = summary; self.count = count; self.rejection = rejection; self.results = results; self.question = question
        self.read = read.flatMap { Self.readList($0) }
    }

    /// At most twelve names, each kept short, with the rest counted. Empty when nothing was read.
    public static func readList(_ names: [String]) -> [String]? {
        let clean = names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.map { String($0.prefix(48)) }
        guard !clean.isEmpty else { return nil }
        return clean.count <= 12 ? clean : Array(clean.prefix(12)) + ["and \(clean.count - 12) more"]
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

/// Why a tool call produced no proposal. The reason is returned to the model so it can correct itself; the summary is the quiet step the owner sees.
public enum AgentToolRejection: Error, Equatable, Sendable {
    case malformedID(String)
    case unknownRecord(UUID)
    case missingTarget
    case revisionRequired
    case staleRevision(expected: Int, current: Int)
    case invalidArguments
    /// No record matches what the model named.
    case notFound(String)
    /// Several records match; the app asked the owner which one.
    case ambiguous(String, [String])

    public var reason: String {
        switch self {
        case .malformedID(let value): "“\(value)” is not a piece, outfit, theme or plan. Use a handle such as p3 or the exact name from findRecords. Never ask the owner for a code."
        case .unknownRecord: "That record is no longer in the closet. Call findRecords to look it up by name."
        case .missingTarget: "Name the piece, outfit, theme or plan to change. Use findRecords if unsure."
        case .revisionRequired: "That record could not be read. Call findRecords again."
        case .staleRevision: "That record changed since you looked it up. Call findRecords again."
        case .invalidArguments: "The arguments could not be validated. Ask the user to clarify or use the manual editor."
        case .notFound(let value): "Nothing in the closet matches “\(value)”. Call findRecords with its words, or tell the owner it isn't in their closet. Never ask for a code."
        case .ambiguous(let value, let names): "“\(value)” could mean " + names.joined(separator: " or ") + ". The app is asking the owner which one. Reply with one short sentence and wait; do not ask again."
        }
    }

    /// One quiet line for the activity list.
    public var stepSummary: String {
        switch self {
        case .notFound(let value): "Couldn’t find “\(value)” in your closet"
        case .ambiguous(let value, let names): "“\(value)” matched \(names.count) records, asked you instead"
        case .malformedID: "Couldn’t match that to your closet"
        case .unknownRecord, .staleRevision, .revisionRequired: "That record changed, so nothing was prepared"
        case .missingTarget: "Needed to know which record to change"
        case .invalidArguments: "Couldn’t prepare a change"
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
