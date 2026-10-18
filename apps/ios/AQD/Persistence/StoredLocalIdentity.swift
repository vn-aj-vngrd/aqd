import AQDCore
import Foundation
import SwiftData

@Model final class StoredLocalIdentity {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: LocalProfileIdentity) throws { id = value.ownerID; payload = try JSONEncoder().encode(value) }
    func value() throws -> LocalProfileIdentity {
        let value = try JSONDecoder().decode(LocalProfileIdentity.self, from: payload)
        guard value.ownerID == id else { throw PieceStore.StoreError.invalidRecord }
        try value.validated(); return value
    }
}
@Model final class StoredIdentityDraft {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: LocalIdentityDraft) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> LocalIdentityDraft {
        let value = try JSONDecoder().decode(LocalIdentityDraft.self, from: payload)
        guard value.id == id else { throw PieceStore.StoreError.invalidRecord }
        try value.validatedForRetention(); return value
    }
}
@Model final class StoredIdentitySave {
    @Attribute(.unique) var id: UUID
    var request: Data
    var result: Data
    init(_ draft: LocalIdentityDraft, result: LocalProfileIdentity) throws {
        id = draft.operationID; request = try JSONEncoder().encode(draft); self.result = try JSONEncoder().encode(result)
    }
}
