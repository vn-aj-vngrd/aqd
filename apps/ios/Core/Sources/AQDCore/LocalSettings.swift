import Foundation
public enum LocalAppearance: String, Codable, CaseIterable, Sendable { case system, light, dark }
public struct LocalSettings: Codable, Equatable, Sendable {
    public let ownerID: UUID
    public var revision = 0
    public var appearance: LocalAppearance = .system
    public init(ownerID: UUID) { self.ownerID = ownerID }
    public func validated() throws { guard revision >= 0, revision < Int.max else { throw PlanValidationError.invalidRecord } }
}
public struct LocalSettingsRequest: Codable, Equatable, Sendable {
    public let operationID: UUID
    public let base: LocalSettings
    public let appearance: LocalAppearance
    public init(base: LocalSettings, appearance: LocalAppearance) { operationID = UUID(); self.base = base; self.appearance = appearance }
    public func result() throws -> LocalSettings { try base.validated(); var value = base; value.revision += 1; value.appearance = appearance; try value.validated(); return value }
}
