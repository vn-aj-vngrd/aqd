import AQDCore
import Foundation
import SwiftData

@Model final class StoredLocalSettings {
    @Attribute(.unique) var id: Int
    var payload: Data
    init(_ value: LocalSettings) throws { id = 1; payload = try JSONEncoder().encode(value) }
    func value() throws -> LocalSettings { let value = try JSONDecoder().decode(LocalSettings.self, from: payload); try value.validated(); guard id == 1 else { throw PieceStore.StoreError.invalidRecord }; return value }
}
@Model final class StoredSettingsSave {
    @Attribute(.unique) var id: UUID
    var request: Data
    var result: Data
    init(_ request: LocalSettingsRequest, result: LocalSettings, fingerprint: String? = nil) throws {
        id = request.operationID
        self.request = try fingerprint.map { Data(("sha256:" + $0).utf8) } ?? JSONEncoder().encode(request)
        self.result = try JSONEncoder().encode(result)
    }
}
/// Changes only inside the same acknowledged transaction, for stale replacement review checks.
@Model final class StoredLocalMutation {
    @Attribute(.unique) var id: Int
    var stamp: UUID
    init() { id = 1; stamp = UUID() }
}
