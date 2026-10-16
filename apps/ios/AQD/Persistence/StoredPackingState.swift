import AQDCore
import Foundation
import SwiftData

@Model final class StoredPackingState {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: PackingState) throws { id = value.planID; payload = try JSONEncoder().encode(value) }
    func value() throws -> PackingState {
        let value = try JSONDecoder().decode(PackingState.self, from: payload)
        guard value.planID == id, value.revision > 0, value.revision < Int.max else { throw PieceStore.StoreError.invalidRecord }
        return value
    }
}
@Model final class StoredPackingCheck {
    @Attribute(.unique) var id: UUID
    var request: Data
    var result: Data
    init(request: PackingCheckRequest, result: PackingState) throws {
        id = request.operationID; self.request = try JSONEncoder().encode(request); self.result = try JSONEncoder().encode(result)
    }
}
