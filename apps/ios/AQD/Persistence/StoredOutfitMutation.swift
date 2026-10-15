import AQDCore
import Foundation
import SwiftData

@Model final class StoredOutfitMutation {
    @Attribute(.unique) var id: UUID
    var request: Data
    var result: Data
    init(request: OutfitMutationRequest, result: OutfitMutationReceipt) throws {
        id = request.operationID; self.request = try JSONEncoder().encode(request); self.result = try JSONEncoder().encode(result)
    }
}
