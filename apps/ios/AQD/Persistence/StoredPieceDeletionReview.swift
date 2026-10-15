import AQDCore
import Foundation
import SwiftData

@Model final class StoredPieceDeletionReview {
    @Attribute(.unique) var id: UUID
    var impact: Data
    init(operationID: UUID, impact: PieceDeletionImpact) throws {
        id = operationID; self.impact = try JSONEncoder().encode(impact)
    }
}
