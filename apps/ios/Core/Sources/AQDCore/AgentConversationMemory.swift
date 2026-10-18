import Foundation

/// What the model remembers of a conversation: the last few turns word for word and a short summary of anything older.
/// Nothing here calls a model; the summary is built from the stored messages so it can never invent a fact.
public enum AgentConversationMemory {
    public static let verbatimTurns = 4
    static let summaryCharacters = 480

    private static func clean(_ text: String, limit: Int) -> String {
        var value = AgentMarkdownPolicy.conversationalText(text).replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "\n", with: " ")
        while value.contains("  ") { value = value.replacingOccurrences(of: "  ", with: " ") }
        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.count <= limit ? value : String(value.prefix(max(0, limit - 1))).trimmingCharacters(in: .whitespaces) + "…"
    }

    /// Finished turns as (user, assistant) pairs, oldest first. A turn the model never answered is left out; the pending user message is not a turn.
    public static func turns(_ messages: [AgentMessage], excluding id: UUID? = nil) -> [(user: AgentMessage, assistant: AgentMessage)] {
        var result: [(AgentMessage, AgentMessage)] = []
        var index = 0
        while index + 1 < messages.count {
            let user = messages[index], assistant = messages[index + 1]
            if user.role == .user, assistant.role == .assistant, assistant.id != id, assistant.status == .complete, !assistant.source.isEmpty { result.append((user, assistant)) }
            index += 2
        }
        return result
    }

    /// One line per older turn, newest kept when the summary outgrows its room.
    public static func summary(of older: [(user: AgentMessage, assistant: AgentMessage)]) -> String? {
        guard !older.isEmpty else { return nil }
        var lines = older.map { "Asked \(clean($0.user.source.isEmpty ? $0.user.promptText : $0.user.source, limit: 70)); you replied \(clean($0.assistant.source, limit: 90))" }
        while lines.count > 1, lines.joined(separator: " ").count > summaryCharacters { lines.removeFirst() }
        return clean("Earlier in this chat: " + lines.joined(separator: ". "), limit: summaryCharacters + 40)
    }

    /// The summary of every turn older than the verbatim window, to store on the conversation.
    public static func rollingSummary(_ messages: [AgentMessage]) -> String? {
        let all = turns(messages)
        return summary(of: Array(all.dropLast(verbatimTurns)))
    }

    /// History lines for the prompt: the older summary (if any), then up to the last four turns, newest kept first when room is short.
    /// `characters` is the history budget; a turn is dropped whole rather than cut mid-sentence.
    public static func history(_ messages: [AgentMessage], excluding id: UUID? = nil, characters: Int) -> (summary: String?, lines: [String]) {
        let all = turns(messages, excluding: id)
        let recent = Array(all.suffix(verbatimTurns))
        var older = Array(all.dropLast(recent.count))
        var kept: [(String, String)] = []
        var used = 0
        for turn in recent.reversed() {
            let user = clean(turn.user.promptText, limit: 400), assistant = clean(turn.assistant.source, limit: 360)
            let size = user.count + assistant.count + 24
            if used + size > characters { older.insert(turn, at: 0); continue }
            used += size; kept.insert((user, assistant), at: 0)
        }
        // Turns that did not fit move into the summary rather than vanishing.
        older.sort { $0.user.createdAt < $1.user.createdAt }
        var text = summary(of: older)
        // A summary that no longer fits whole is cut to what remains; below a readable size it is left out.
        if let value = text, used + value.count > characters {
            let room = characters - used
            text = room < 120 ? nil : String(value.prefix(room - 1)) + "…"
        }
        return (text, kept.flatMap { ["user: \($0.0)", "assistant: \($0.1)"] })
    }
}

/// The prompt as parts, so the provider can drop the least important one when a measured count says the request is too long.
public struct AgentPromptParts: Equatable, Sendable {
    public var context: String
    public var summary: String?
    public var history: [String]
    public var userTurn: String
    public var reviews: String
    public init(context: String, summary: String? = nil, history: [String] = [], userTurn: String, reviews: String = "") {
        self.context = context; self.summary = summary; self.history = history; self.userTurn = userTurn; self.reviews = reviews
    }

    public func render() -> String {
        var parts = [context]
        if let summary, !summary.isEmpty { parts.append(summary) }
        if !history.isEmpty { parts.append("Conversation:\n" + history.joined(separator: "\n")) }
        if !reviews.isEmpty { parts.append(reviews) }
        parts.append("user: " + userTurn)
        return parts.joined(separator: "\n")
    }

    /// The same request with its least important text removed: oldest turn first, then the summary. Nil when only the request is left.
    public func shrunk() -> AgentPromptParts? {
        var value = self
        if value.history.count >= 2 { value.history.removeFirst(2); return value }
        if value.summary != nil { value.summary = nil; return value }
        if !value.history.isEmpty { value.history = []; return value }
        if !value.reviews.isEmpty { value.reviews = ""; return value }
        return nil
    }
}
