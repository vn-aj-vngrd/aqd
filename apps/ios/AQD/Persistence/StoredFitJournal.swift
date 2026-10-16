import AQDCore
import Foundation
import SwiftData

@Model final class StoredFitMemory {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: FitMemory) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> FitMemory {
        let result = try JSONDecoder().decode(FitMemory.self, from: payload)
        guard result.id == id else { throw PieceStore.StoreError.invalidRecord }; try result.validated(); return result
    }
}
@Model final class StoredFitDraft {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: FitDraft) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> FitDraft {
        let result = try JSONDecoder().decode(FitDraft.self, from: payload)
        guard result.id == id else { throw PieceStore.StoreError.invalidRecord }; try result.validated(requireContent: false); return result
    }
}
@Model final class StoredFitSave {
    @Attribute(.unique) var id: UUID
    var request: Data
    var result: Data
    init(_ draft: FitDraft, result: FitMemory) throws { id = draft.operationID; request = try JSONEncoder().encode(draft); self.result = try JSONEncoder().encode(result) }
}
@Model final class StoredFitDeletion {
    @Attribute(.unique) var id: UUID
    var request: Data
    init(_ value: FitDeletionRequest) throws { id = value.operationID; request = try JSONEncoder().encode(value) }
}
