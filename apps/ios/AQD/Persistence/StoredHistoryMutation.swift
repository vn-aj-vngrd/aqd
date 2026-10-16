import AQDCore
import Foundation
import SwiftData

@Model final class StoredHistoryMutation {
    @Attribute(.unique) var id: UUID
    var request: Data
    init(_ value: HistoryMutation) throws { id = value.operationID; request = try JSONEncoder().encode(value) }
}
