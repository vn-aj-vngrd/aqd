import Foundation
public enum LocalAppearance: String, Codable, CaseIterable, Sendable { case system, light, dark }
public struct LocalSettings: Codable, Equatable, Sendable {
    public let ownerID: UUID
    public var revision = 0
    public var agentPreferences: AgentPreferences?
    public var feedback: [AgentFeedback]?
    public var appearance: LocalAppearance = .system
    public init(ownerID: UUID) { self.ownerID = ownerID }
    public func validated() throws {
        guard revision >= 0, revision < Int.max, Set((feedback ?? []).map(\.id)).count == (feedback ?? []).count,
              (feedback ?? []).allSatisfy({ $0.conversationID == nil }) else { throw PlanValidationError.invalidRecord }
        try agentPreferences?.validated()
        for value in feedback ?? [] { try value.validated() }
    }
}
public struct LocalSettingsRequest: Codable, Equatable, Sendable {
    public let operationID: UUID
    public let base: LocalSettings
    public let appearance: LocalAppearance
    public let agentPreferences: AgentPreferences?
    public let feedback: [AgentFeedback]?
    public init(base: LocalSettings, appearance: LocalAppearance) { operationID = UUID(); self.base = base; self.appearance = appearance; agentPreferences = nil; feedback = nil }
    public init(base: LocalSettings, agentPreferences: AgentPreferences? = nil, feedback: [AgentFeedback]? = nil) {
        operationID = UUID(); self.base = base; appearance = base.appearance; self.agentPreferences = agentPreferences; self.feedback = feedback
    }
    public func result() throws -> LocalSettings { try base.validated(); var value = base; value.revision += 1; value.appearance = appearance; if let agentPreferences { value.agentPreferences = agentPreferences }; if let feedback { value.feedback = feedback }; try value.validated(); return value }
}
