import Foundation

public struct OutfitDeletionDependencies: Codable, Equatable, Sendable {
    public let themeRevisions: [UUID: Int]
    public let planRevisions: [UUID: Int]
    public init(themeRevisions: [UUID: Int], planRevisions: [UUID: Int]) {
        self.themeRevisions = themeRevisions; self.planRevisions = planRevisions
    }
}
public enum OutfitMutationAction: Codable, Equatable, Sendable {
    case favorite(Bool)
    case delete(OutfitDeletionDependencies)
}
public struct OutfitMutationRequest: Codable, Equatable, Sendable {
    public let operationID: UUID
    public let outfit: Outfit
    public let action: OutfitMutationAction
    public init(outfit: Outfit, action: OutfitMutationAction) {
        operationID = UUID(); self.outfit = outfit; self.action = action
    }
}
public enum OutfitMutationReceipt: Codable, Equatable, Sendable {
    case saved(Outfit)
    case deleted(UUID)
}
