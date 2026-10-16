import Foundation
import SwiftData

/// A derived full-extent source keeps its metadata-minimized original reachable.
@Model final class StoredPhotoSource {
    @Attribute(.unique) var id: UUID
    var originalID: UUID
    init(id: UUID, originalID: UUID) { self.id = id; self.originalID = originalID }
}
