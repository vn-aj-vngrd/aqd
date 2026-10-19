import AQDCore
import Foundation
import Observation

/// Existing framing controls operate on an explicit owner’s photo draft.
@MainActor protocol PhotoEditingOwner: AnyObject, Observable {
    var editingPhotoID: UUID? { get }
    var completedPhotoImportID: UUID? { get }
    var editingPhotoRecipe: PhotoEditRecipe { get }
    var errorText: String? { get }
    var hasProcessedPhoto: Bool { get }
    func resetThumbnailData() -> Data?
    func applyPhotoReset(_ recipe: PhotoEditRecipe, sourceID: UUID, previousRecipe: PhotoEditRecipe) async -> Bool
    func originalPhotoData() -> Data?
    func originalThumbnailData() -> Data?
    func applyPhotoEdit(_ recipe: PhotoEditRecipe, sourceID: UUID, previousRecipe: PhotoEditRecipe) async -> Bool
    func cancelImport()
}

extension PhotoEditingOwner {
    var hasProcessedPhoto: Bool { false }
    func resetThumbnailData() -> Data? { originalThumbnailData() }
    func applyPhotoReset(_ recipe: PhotoEditRecipe, sourceID: UUID, previousRecipe: PhotoEditRecipe) async -> Bool {
        await applyPhotoEdit(recipe, sourceID: sourceID, previousRecipe: previousRecipe)
    }
}

extension CaptureModel: PhotoEditingOwner {
    var editingPhotoID: UUID? { draft.photoID }
    var editingPhotoRecipe: PhotoEditRecipe { draft.photoRecipe }
}

extension FitEditorModel: PhotoEditingOwner {
    var editingPhotoID: UUID? { draft.value.photoID }
    var editingPhotoRecipe: PhotoEditRecipe { draft.value.photoRecipe }
    var errorText: String? { error }
    func originalPhotoData() -> Data? { editingPhotoID.flatMap { try? state.store?.originalPhoto(id: $0) } }
    func originalThumbnailData() -> Data? { editingPhotoID.flatMap { try? state.store?.thumbnailPhoto(id: $0) } }
    func applyPhotoEdit(_ recipe: PhotoEditRecipe, sourceID: UUID, previousRecipe: PhotoEditRecipe) async -> Bool {
        guard !locked, editingPhotoID == sourceID, editingPhotoRecipe == previousRecipe, let data = originalPhotoData() else { return false }
        cancelImport(); let token = importID; importing = true
        do {
            let prepared = try await PhotoPreparer().render(data: data, sourcePhotoID: sourceID, recipe: recipe)
            guard !Task.isCancelled, token == importID, !locked, editingPhotoID == sourceID, editingPhotoRecipe == previousRecipe else { return false }
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.acceptPhotoEdit(prepared); importing = false
            update { $0.photoRecipe = recipe }; return error == nil
        } catch {
            if token == importID { importing = false; self.error = "Photo edits could not be applied. The original and previous framing are retained; retry or cancel." }
            return false
        }
    }
}

extension LocalIdentityEditorModel: PhotoEditingOwner {
    var editingPhotoID: UUID? { draft.photoID }
    var editingPhotoRecipe: PhotoEditRecipe { draft.photoRecipe ?? .fitOriginal }
    var errorText: String? { error }
    func originalPhotoData() -> Data? { editingPhotoID.flatMap { try? state.store?.originalPhoto(id: $0) } }
    func originalThumbnailData() -> Data? { editingPhotoID.flatMap { try? state.store?.thumbnailPhoto(id: $0) } }
    func applyPhotoEdit(_ recipe: PhotoEditRecipe, sourceID: UUID, previousRecipe: PhotoEditRecipe) async -> Bool {
        guard !locked, editingPhotoID == sourceID, editingPhotoRecipe == previousRecipe, let data = originalPhotoData() else { return false }
        cancelImport(); let token = importID; importing = true
        do {
            let prepared = try await PhotoPreparer().render(data: data, sourcePhotoID: sourceID, recipe: recipe)
            guard !Task.isCancelled, token == importID, !locked, editingPhotoID == sourceID, editingPhotoRecipe == previousRecipe else { return false }
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.acceptPhotoEdit(prepared); importing = false
            update { $0.photoRecipe = recipe }; return error == nil
        } catch {
            if token == importID { importing = false; self.error = "Photo edits could not be applied. The original and previous framing are retained; retry or cancel." }
            return false
        }
    }
}

/// Lets one editor live inside a container with other editors (crop and rotate beside cut out). The container owns the sheet,
/// its close button and the switch between tabs; the editor reports unapplied edits and says when it applied them, and does not dismiss.
struct EmbeddedEditing {
    let dirty: (Bool) -> Void
    let applied: () -> Void
}
