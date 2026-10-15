import AQDCore
import Foundation
import SwiftData

@Model final class StoredThemeDeletion {
    @Attribute(.unique) var id: UUID
    var request: Data
    init(_ request: ThemeDeletionRequest) throws {
        id = request.operationID; self.request = try JSONEncoder().encode(request)
    }
}
