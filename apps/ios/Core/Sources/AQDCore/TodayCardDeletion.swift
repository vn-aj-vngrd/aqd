import Foundation

public struct TodayCardDeletion: Codable, Equatable, Sendable {
    public let operationID: UUID
    public let card: TodayPersonalCard
    public let undo: TodayLayoutUndo?
    public init(card: TodayPersonalCard, undo: TodayLayoutUndo?) { operationID = UUID(); self.card = card; self.undo = undo }
}
public struct TodayCardUsage: Equatable, Sendable {
    public let active: Bool
    public let draft: Bool
    public let undo: Bool
    public init(active: Bool, draft: Bool, undo: Bool) { self.active = active; self.draft = draft; self.undo = undo }
}
