import AQDCore
import Foundation
import SwiftData

@Model final class StoredOutfit {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: Outfit) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> Outfit {
        let value = try JSONDecoder().decode(Outfit.self, from: payload)
        guard id == value.id else { throw PieceStore.StoreError.invalidRecord }
        try value.validated()
        return value
    }
}

@Model final class StoredOutfitDraft {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: OutfitDraft) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> OutfitDraft {
        let value = try JSONDecoder().decode(OutfitDraft.self, from: payload)
        guard id == value.id else { throw PieceStore.StoreError.invalidRecord }
        try value.validated()
        return value
    }
}

@Model final class StoredOutfitSave {
    @Attribute(.unique) var id: UUID
    var draft: Data
    var snapshot: Data
    init(draft: OutfitDraft, saved: Outfit) throws {
        id = draft.operationID
        self.draft = try JSONEncoder().encode(draft)
        snapshot = try JSONEncoder().encode(saved)
    }
}
