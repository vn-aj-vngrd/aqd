import Foundation

public enum AgentMessageStatus: String, Codable, Sendable { case waiting, streaming, complete, stopping, stopped, interrupted, failed }
public enum AgentMessageRole: String, Codable, Sendable { case user, assistant }
public struct AgentResponseVersion: Codable, Equatable, Sendable {
    public let source: String
    public let status: AgentMessageStatus
    public var attemptID: UUID?
}
public struct AgentMessage: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let role: AgentMessageRole
    public var source: String
    public var status: AgentMessageStatus
    public var attemptID: UUID?
    public let createdAt: Date
    public var firstTextSeconds: Double?
    public var elapsedSeconds: Double?
    public var contextSummary: String?
    public var failureReason: String?
    public var diagnostics: AgentResponseDiagnostics?
    public var feedback: [AgentFeedback]?
    public var attachments: [AgentAttachment]?
    public var versions: [AgentResponseVersion] = []
    public init(role: AgentMessageRole, source: String, status: AgentMessageStatus, attemptID: UUID? = nil) {
        id = UUID(); self.role = role; self.source = source; self.status = status; self.attemptID = attemptID; createdAt = Date()
    }
    public var promptText: String { ([source] + (attachments ?? []).map(\.promptText)).filter { !$0.isEmpty }.joined(separator: "\n") }
    public var isActive: Bool { [.waiting, .streaming, .stopping].contains(status) }
}
public enum AgentContextScope: String, Codable, CaseIterable, Sendable { case closet, selected, general }
public struct AgentSelectedRecord: Identifiable, Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable { case piece, outfit, theme }
    public let id: UUID
    public let kind: Kind
    public let revision: Int
    public let resolvedPieces: [UUID: Int]?
    public let resolvedOutfits: [UUID: Int]?
    public init(id: UUID, kind: Kind, revision: Int, resolvedPieces: [UUID: Int]? = nil, resolvedOutfits: [UUID: Int]? = nil) {
        self.id = id; self.kind = kind; self.revision = revision
        self.resolvedPieces = resolvedPieces; self.resolvedOutfits = resolvedOutfits
    }
}
public struct AgentContext: Codable, Equatable, Sendable {
    public var automatic: Bool? = true
    public var scope: AgentContextScope = .closet
    public var includesWear = false
    public var includesStyle = false
    public var selected: [AgentSelectedRecord] = []
    public var weather: WeatherSelection?
    public init() {}
}
public struct AgentConversation: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let ownerID: UUID
    public var revision: Int = 0
    public var draft = ""
    public var draftAttachments: [AgentAttachment]?
    public var context = AgentContext()
    public var messages: [AgentMessage] = []
    public var proposals: [AgentActionProposal]?
    public var pinnedAt: Date?
    public var archivedAt: Date?
    public var isPinned: Bool { pinnedAt != nil }
    public var isArchived: Bool { archivedAt != nil }
    public var updatedAt = Date()
    public init(ownerID: UUID) { id = UUID(); self.ownerID = ownerID }
    public var title: String {
        guard let first = messages.first(where: { $0.role == .user }) else { return "New conversation" }
        return first.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? first.attachments?.first?.name ?? "Attachment" : String(first.source.prefix(80))
    }
    public var draftPrompt: String { ([draft] + (draftAttachments ?? []).map(\.promptText)).filter { !$0.isEmpty }.joined(separator: "\n") }
    /// Proposals made by this message's current or earlier attempts, so a retry never orphans a review card.
    public func proposals(for message: AgentMessage) -> [AgentActionProposal] {
        guard message.role == .assistant else { return [] }
        let attempts = Set(([message.attemptID] + message.versions.map(\.attemptID)).compactMap { $0 })
        return (proposals ?? []).filter { $0.attemptID.map(attempts.contains) ?? false }
    }
    /// Proposals not linked to any message, shown after the last message.
    public var unlinkedProposals: [AgentActionProposal] {
        let linked = Set(messages.flatMap { proposals(for: $0).map(\.id) })
        return (proposals ?? []).filter { !linked.contains($0.id) }
    }
    public mutating func beginAttempt() throws -> UUID {
        try AgentAttachment.validate(draftAttachments ?? [])
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !(draftAttachments ?? []).isEmpty else { throw PlanValidationError.invalidRecord }
        guard !messages.contains(where: \.isActive) else { throw PlanValidationError.invalidRecord }
        let attempt = UUID()
        var user = AgentMessage(role: .user, source: draft, status: .complete)
        user.attachments = draftAttachments
        messages.append(user)
        messages.append(AgentMessage(role: .assistant, source: "", status: .waiting, attemptID: attempt))
        draft = ""; draftAttachments = nil; updatedAt = Date(); return attempt
    }
    public mutating func append(_ text: String, attemptID: UUID) throws {
        guard let i = messages.firstIndex(where: { $0.attemptID == attemptID && $0.isActive && $0.status != .stopping }) else { throw PlanValidationError.invalidRecord }
        messages[i].source += text; messages[i].status = .streaming
    }
    public mutating func complete(attemptID: UUID) throws {
        guard let i = messages.firstIndex(where: { $0.attemptID == attemptID && $0.isActive && $0.status != .stopping }),
              !messages[i].source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw PlanValidationError.invalidRecord }
        messages[i].status = .complete
    }
    public mutating func interruptActiveAttempt() {
        for i in messages.indices where messages[i].isActive { messages[i].status = .interrupted }
    }
    public mutating func retry(messageID: UUID) throws -> UUID {
        guard !messages.contains(where: \.isActive), let i = messages.firstIndex(where: { $0.id == messageID && $0.role == .assistant && !$0.isActive }), i == messages.count - 1 else { throw PlanValidationError.invalidRecord }
        let attempt = UUID()
        messages[i].versions.append(AgentResponseVersion(source: messages[i].source, status: messages[i].status, attemptID: messages[i].attemptID))
        messages[i].source = ""; messages[i].status = .waiting; messages[i].attemptID = attempt
        messages[i].firstTextSeconds = nil; messages[i].elapsedSeconds = nil
        messages[i].failureReason = nil; messages[i].diagnostics = nil
        return attempt
    }
    public func validated() throws {
        try context.weather?.validated()
        try AgentAttachment.validate(draftAttachments ?? [])
        guard revision >= 0, revision < Int.max, Set(messages.map(\.id)).count == messages.count,
              messages.filter(\.isActive).count <= 1,
              Set(context.selected.map { "\($0.kind):\($0.id)" }).count == context.selected.count,
              context.selected.allSatisfy({ $0.revision > 0 }) else { throw PlanValidationError.invalidRecord }
        let actions = proposals ?? []
        guard Set(actions.map(\.id)).count == actions.count,
              actions.allSatisfy({ $0.version == 1 && ($0.status == .succeeded) == ($0.receipt != nil) }) else { throw PlanValidationError.invalidRecord }
        for (i, message) in messages.enumerated() {
            try AgentAttachment.validate(message.attachments ?? [])
            guard message.role == .user || (message.attachments ?? []).isEmpty else { throw PlanValidationError.invalidRecord }
            try message.diagnostics?.validated()
            let feedback = message.feedback ?? []
            guard Set(feedback.map(\.id)).count == feedback.count,
                  Set(feedback.compactMap(\.attemptID)).count == feedback.count,
                  feedback.allSatisfy({ message.role == .assistant && $0.conversationID == id && $0.messageID == message.id }) else { throw PlanValidationError.invalidRecord }
            for value in feedback { try value.validated() }
            guard message.role == (i.isMultiple(of: 2) ? .user : .assistant),
                  message.role == .assistant || message.status == .complete,
                  message.role == .user || message.attemptID != nil,
                  message.firstTextSeconds.map({ $0.isFinite && $0 >= 0 }) ?? true,
                  message.elapsedSeconds.map({ $0.isFinite && $0 >= 0 }) ?? true else { throw PlanValidationError.invalidRecord }
        }
        guard messages.count.isMultiple(of: 2) else { throw PlanValidationError.invalidRecord }
    }
}

public enum AgentHistoryFilter: String, CaseIterable, Sendable {
    case active = "Active", pinned = "Pinned", archived = "Archived", all = "All conversations"

    public func conversations(in history: [AgentConversation]) -> [AgentConversation] {
        history.filter { value in
            switch self {
            case .active: !value.isArchived
            case .pinned: value.isPinned && !value.isArchived
            case .archived: value.isArchived
            case .all: true
            }
        }.sorted { left, right in
            if left.isPinned != right.isPinned { return left.isPinned }
            if left.updatedAt != right.updatedAt { return left.updatedAt > right.updatedAt }
            return left.id.uuidString < right.id.uuidString
        }
    }
}

public enum AgentChatTimestamp {
    public static func startsGroup(_ date: Date, after previous: Date?, calendar: Calendar = .current) -> Bool {
        guard let previous else { return true }
        return !calendar.isDate(date, inSameDayAs: previous) || date.timeIntervalSince(previous) >= 15 * 60
    }
    public static func label(for date: Date, relativeTo now: Date = Date(), calendar: Calendar = .current, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar; formatter.timeZone = calendar.timeZone; formatter.locale = locale
        let day: String
        if calendar.isDate(date, inSameDayAs: now) { day = String(localized: "Today", locale: locale) }
        else if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) { day = String(localized: "Yesterday", locale: locale) }
        else {
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
            let template = (2...6).contains(days) ? "EEEE" : calendar.component(.year, from: date) == calendar.component(.year, from: now) ? "MMM d" : "MMM d yyyy"
            formatter.setLocalizedDateFormatFromTemplate(template); day = formatter.string(from: date)
        }
        formatter.dateStyle = .none; formatter.timeStyle = .short
        return day + " " + formatter.string(from: date)
    }
}
