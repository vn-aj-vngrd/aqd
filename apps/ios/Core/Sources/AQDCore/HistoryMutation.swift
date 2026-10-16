import Foundation

public struct HistoryMutation: Codable, Equatable, Sendable {
    public enum Action: Codable, Equatable, Sendable {
        case skip(OutfitPlanEntry)
        case deletePlan(PlanDefinition, [OutfitPlanEntry])
    }
    public let operationID: UUID
    public let action: Action
    public init(operationID: UUID = UUID(), action: Action) { self.operationID = operationID; self.action = action }
}
