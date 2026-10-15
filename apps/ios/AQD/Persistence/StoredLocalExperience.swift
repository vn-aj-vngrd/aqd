import AQDCore
import Foundation
import SwiftData

@Model
final class StoredLocalExperience {
    @Attribute(.unique) var id: Int
    var payload: Data
    init(_ value: LocalExperience) throws {
        id = 1
        payload = try JSONEncoder().encode(value)
    }
}

/// One private entry state and one active preference task, shared by all callers.
struct LocalExperience: Codable, Equatable {
    var schemaVersion = 1
    var enteredPrivateSpace: Bool
    var style: SavedStylePreferences?
    var styleDraft: StylePreferenceDraft?
    var pendingStyleReceipt: StylePreferenceDraft?
    var entry: PrivateEntryState?
    var entryState: PrivateEntryState { entry ?? PrivateEntryState(alreadyEntered: enteredPrivateSpace) }

    func validated() throws {
        guard schemaVersion == 1 else { throw PieceStore.StoreError.unsupportedStore }
        try entryState.validated()
        if entry != nil, enteredPrivateSpace != (entryState.page == .main) { throw PieceStore.StoreError.invalidRecord }
        if let style {
            guard style.revision > 0 else { throw PieceStore.StoreError.invalidRecord }
            try style.answers.validated()
        }
        try styleDraft?.validated()
        if let pendingStyleReceipt {
            try pendingStyleReceipt.validated()
            guard styleDraft == nil, style?.operationID == pendingStyleReceipt.operationID,
                  style?.answers == pendingStyleReceipt.answers else { throw PieceStore.StoreError.invalidRecord }
        }
    }
}
