import AQDCore
import Foundation
import SwiftData

/// The baseline stores only presentation identity and the authoritative stock order.
/// Full kind-specific configuration/personal content belongs to the linked Today slice.
@Model
final class StoredTodayConfiguration {
    @Attribute(.unique) var id: Int
    var ownerID: UUID
    var schemaVersion: Int
    var revision: Int
    var instanceIDs: [UUID]
    var kindIDs: [String]

    init(_ configuration: TodayConfiguration) {
        id = 1
        ownerID = configuration.ownerID
        schemaVersion = configuration.schemaVersion
        revision = configuration.revision
        instanceIDs = configuration.instances.map(\.id)
        kindIDs = configuration.instances.map { $0.kind.rawValue }
    }

    func value() throws -> TodayConfiguration {
        guard id == 1, instanceIDs.count == kindIDs.count else { throw PieceStore.StoreError.invalidRecord }
        var result = TodayConfiguration(ownerID: ownerID)
        result.schemaVersion = schemaVersion
        result.revision = revision
        result.instances = try zip(instanceIDs, kindIDs).map { id, rawKind in
            guard let kind = TodayWidgetKind(rawValue: rawKind) else { throw PieceStore.StoreError.invalidRecord }
            return TodayWidgetInstance(id: id, kind: kind)
        }
        try result.validated()
        return result
    }
}
