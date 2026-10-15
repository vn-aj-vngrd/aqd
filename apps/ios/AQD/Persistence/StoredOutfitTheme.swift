import AQDCore
import Foundation
import SwiftData

@Model final class StoredOutfitTheme {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: OutfitTheme) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> OutfitTheme {
        let value = try JSONDecoder().decode(OutfitTheme.self, from: payload)
        guard id == value.id else { throw PieceStore.StoreError.invalidRecord }
        try value.validated()
        return value
    }
}

@Model final class StoredThemeDraft {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: ThemeDraft) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> ThemeDraft {
        let value = try JSONDecoder().decode(ThemeDraft.self, from: payload)
        guard id == value.id, value.baseRevision >= 0, Set(value.outfitIDs).count == value.outfitIDs.count else {
            throw PieceStore.StoreError.invalidRecord
        }
        return value
    }
}

@Model final class StoredThemeSave {
    @Attribute(.unique) var id: UUID
    var draft: Data
    var snapshot: Data
    init(draft: ThemeDraft, saved: OutfitTheme) throws {
        id = draft.operationID; self.draft = try JSONEncoder().encode(draft); snapshot = try JSONEncoder().encode(saved)
    }
}
