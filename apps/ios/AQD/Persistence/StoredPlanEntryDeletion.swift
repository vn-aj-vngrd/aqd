import AQDCore
import Foundation
import SwiftData

@Model final class StoredPlanEntryDeletion {
    @Attribute(.unique) var id: UUID
    var request: Data
    init(_ request: PlanEntryDeletionRequest) throws {
        id = request.operationID; self.request = try JSONEncoder().encode(request)
    }
}
