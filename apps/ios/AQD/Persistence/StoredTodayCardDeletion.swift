import AQDCore
import Foundation
import SwiftData

@Model final class StoredTodayCardDeletion {
    @Attribute(.unique) var id: UUID
    var payload: Data
    var applied: Bool
    var acknowledged: Bool
    init(_ request: TodayCardDeletion) throws { id = request.operationID; payload = try JSONEncoder().encode(request); applied = false; acknowledged = false }
    func value() throws -> TodayCardDeletion {
        let value = try JSONDecoder().decode(TodayCardDeletion.self, from: payload)
        guard value.operationID == id else { throw PieceStore.StoreError.invalidRecord }; try value.card.validated(); return value
    }
}
