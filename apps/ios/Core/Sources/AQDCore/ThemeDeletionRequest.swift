import Foundation

public struct ThemeDeletionRequest: Codable, Equatable, Sendable {
    public let operationID: UUID
    public let themeID: UUID
    public let expectedRevision: Int
    public init(theme: OutfitTheme, operationID: UUID = UUID()) {
        self.operationID = operationID; themeID = theme.id; expectedRevision = theme.revision
    }
}
