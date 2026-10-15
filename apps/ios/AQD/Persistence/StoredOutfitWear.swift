import AQDCore
import Foundation
import SwiftData

@Model final class StoredOutfitWear {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: OutfitWearRecord) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> OutfitWearRecord {
        let value = try JSONDecoder().decode(OutfitWearRecord.self, from: payload)
        guard value.id == id else { throw PieceStore.StoreError.invalidRecord }
        try value.validated(); return value
    }
}
@Model final class StoredOutfitWearDraft {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: OutfitWearDraft) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> OutfitWearDraft {
        let value = try JSONDecoder().decode(OutfitWearDraft.self, from: payload)
        guard value.id == id, Set(value.pieceIDs).count == value.pieceIDs.count else { throw PieceStore.StoreError.invalidRecord }
        _ = try value.day.date(); return value
    }
}
@Model final class StoredOutfitWearSave {
    @Attribute(.unique) var id: UUID
    var draft: Data
    var snapshot: Data
    init(draft: OutfitWearDraft, saved: OutfitWearRecord) throws {
        id = draft.operationID; self.draft = try JSONEncoder().encode(draft); snapshot = try JSONEncoder().encode(saved)
    }
}
