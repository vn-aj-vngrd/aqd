import AQDCore
import Foundation
import SwiftData

@Model final class StoredOutfitPlanEntry {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: OutfitPlanEntry) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> OutfitPlanEntry {
        let value = try JSONDecoder().decode(OutfitPlanEntry.self, from: payload)
        guard id == value.id else { throw PieceStore.StoreError.invalidRecord }
        try value.validated(); return value
    }
}
@Model final class StoredOutfitPlanDraft {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: OutfitPlanDraft) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> OutfitPlanDraft {
        let value = try JSONDecoder().decode(OutfitPlanDraft.self, from: payload)
        guard id == value.id else { throw PieceStore.StoreError.invalidRecord }
        _ = try value.day.date(); return value
    }
}
@Model final class StoredOutfitPlanSave {
    @Attribute(.unique) var id: UUID
    var draft: Data
    var snapshot: Data
    init(draft: OutfitPlanDraft, saved: OutfitPlanEntry) throws {
        id = draft.operationID; self.draft = try JSONEncoder().encode(draft); snapshot = try JSONEncoder().encode(saved)
    }
}
