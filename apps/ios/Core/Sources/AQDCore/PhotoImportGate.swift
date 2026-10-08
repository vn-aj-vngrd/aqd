import Foundation

public struct PhotoImportRequest: Equatable, Sendable {
    public let id: UUID
    public let draftID: UUID
    public let previousPhotoID: UUID?
}

public struct PhotoImportGate: Sendable {
    public private(set) var pending: PhotoImportRequest?
    public init() {}

    public mutating func begin(for draft: PieceDraft) -> PhotoImportRequest {
        let request = PhotoImportRequest(id: UUID(), draftID: draft.id, previousPhotoID: draft.photoID)
        pending = request
        return request
    }

    public mutating func cancel() { pending = nil }

    public func canAccept(_ request: PhotoImportRequest, for draft: PieceDraft) -> Bool {
        pending == request && draft.id == request.draftID && draft.photoID == request.previousPhotoID
    }

    public mutating func apply(photoID: UUID, request: PhotoImportRequest, to draft: inout PieceDraft) -> Bool {
        guard canAccept(request, for: draft) else { return false }
        draft.photoID = photoID
        pending = nil
        return true
    }
}
