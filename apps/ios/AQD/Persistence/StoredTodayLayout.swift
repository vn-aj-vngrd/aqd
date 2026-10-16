import AQDCore
import Foundation
import SwiftData

@Model final class StoredTodayLayout {
    @Attribute(.unique) var id: Int
    var payload: Data
    init(_ value: TodayConfiguration) throws { id = 1; payload = try JSONEncoder().encode(value) }
    func value() throws -> TodayConfiguration {
        let value = try JSONDecoder().decode(TodayConfiguration.self, from: payload)
        guard id == 1 else { throw PieceStore.StoreError.invalidRecord }; try value.validated(); return value
    }
}
@Model final class StoredTodayDraft {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: TodayLayoutDraft) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> TodayLayoutDraft {
        let value = try JSONDecoder().decode(TodayLayoutDraft.self, from: payload)
        guard id == value.id else { throw PieceStore.StoreError.invalidRecord }; try value.validated(); return value
    }
}
@Model final class StoredTodaySave {
    @Attribute(.unique) var id: UUID
    var request: Data
    var result: Data
    init(_ draft: TodayLayoutDraft, result: TodayConfiguration) throws { id = draft.operationID; request = try JSONEncoder().encode(draft); self.result = try JSONEncoder().encode(result) }
}
@Model final class StoredTodayUndo {
    @Attribute(.unique) var id: Int
    var payload: Data
    init(_ value: TodayLayoutUndo) throws { id = 1; payload = try JSONEncoder().encode(value) }
    func value() throws -> TodayLayoutUndo {
        let value = try JSONDecoder().decode(TodayLayoutUndo.self, from: payload)
        try value.previous.validated(); try value.current.validated()
        guard id == 1, value.previous.ownerID == value.current.ownerID else { throw PieceStore.StoreError.invalidRecord }; return value
    }
}
@Model final class StoredTodayPersonalCard {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: TodayPersonalCard) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> TodayPersonalCard {
        let value = try JSONDecoder().decode(TodayPersonalCard.self, from: payload)
        guard id == value.id else { throw PieceStore.StoreError.invalidRecord }; try value.validated(); return value
    }
}
