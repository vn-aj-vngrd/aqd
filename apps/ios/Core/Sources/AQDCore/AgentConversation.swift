import Foundation

public enum AgentMessageStatus: String, Codable, Sendable { case waiting, streaming, complete, stopping, stopped, interrupted, failed }
public enum AgentMessageRole: String, Codable, Sendable { case user, assistant }
public struct AgentResponseVersion: Codable, Equatable, Sendable {
    public let source: String
    public let status: AgentMessageStatus
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
    public var versions: [AgentResponseVersion] = []
    public init(role: AgentMessageRole, source: String, status: AgentMessageStatus, attemptID: UUID? = nil) {
        id = UUID(); self.role = role; self.source = source; self.status = status; self.attemptID = attemptID; createdAt = Date()
    }
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
    public var context = AgentContext()
    public var messages: [AgentMessage] = []
    public var proposals: [AgentActionProposal]?
    public var pinnedAt: Date?
    public var archivedAt: Date?
    public var isPinned: Bool { pinnedAt != nil }
    public var isArchived: Bool { archivedAt != nil }
    public var updatedAt = Date()
    public init(ownerID: UUID) { id = UUID(); self.ownerID = ownerID }
    public var title: String { messages.first(where: { $0.role == .user }).map { String($0.source.prefix(80)) } ?? "New conversation" }
    public mutating func beginAttempt() throws -> UUID {
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !messages.contains(where: \.isActive) else { throw PlanValidationError.invalidRecord }
        let attempt = UUID()
        messages.append(AgentMessage(role: .user, source: draft, status: .complete))
        messages.append(AgentMessage(role: .assistant, source: "", status: .waiting, attemptID: attempt))
        draft = ""; updatedAt = Date(); return attempt
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
        messages[i].versions.append(AgentResponseVersion(source: messages[i].source, status: messages[i].status))
        messages[i].source = ""; messages[i].status = .waiting; messages[i].attemptID = attempt
        messages[i].firstTextSeconds = nil; messages[i].elapsedSeconds = nil
        messages[i].failureReason = nil
        return attempt
    }
    public func validated() throws {
        try context.weather?.validated()
        guard revision >= 0, revision < Int.max, Set(messages.map(\.id)).count == messages.count,
              messages.filter(\.isActive).count <= 1,
              Set(context.selected.map { "\($0.kind):\($0.id)" }).count == context.selected.count,
              context.selected.allSatisfy({ $0.revision > 0 }) else { throw PlanValidationError.invalidRecord }
        let actions = proposals ?? []
        guard Set(actions.map(\.id)).count == actions.count,
              actions.allSatisfy({ $0.version == 1 && ($0.status == .succeeded) == ($0.receipt != nil) }) else { throw PlanValidationError.invalidRecord }
        for (i, message) in messages.enumerated() {
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
