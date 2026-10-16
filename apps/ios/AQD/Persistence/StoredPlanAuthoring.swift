import AQDCore
import Foundation
import SwiftData

@Model final class StoredPlanDefinition {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: PlanDefinition) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> PlanDefinition {
        let value = try JSONDecoder().decode(PlanDefinition.self, from: payload)
        guard id == value.id else { throw PieceStore.StoreError.invalidRecord }
        try value.validated(); return value
    }
}
@Model final class StoredPlanAuthoringDraft {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: PlanAuthoringDraft) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> PlanAuthoringDraft {
        let value = try JSONDecoder().decode(PlanAuthoringDraft.self, from: payload)
        guard id == value.id else { throw PieceStore.StoreError.invalidRecord }
        _ = try value.plan.start.date(); _ = try value.plan.end.date()
        return value
    }
}
@Model final class StoredPlanAuthoringSave {
    @Attribute(.unique) var id: UUID
    var request: Data
    var result: Data
    init(draft: PlanAuthoringDraft, saved: PlanAuthoringReceipt) throws {
        id = draft.operationID; request = try JSONEncoder().encode(draft); result = try JSONEncoder().encode(saved)
    }
}
