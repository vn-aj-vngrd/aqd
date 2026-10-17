import AQDCore
import Foundation
import Observation

/// Where a new fit starts: straight into the camera or Photos, or from an existing outfit.
enum FitCaptureSource { case camera, photos, outfit }

@MainActor @Observable
final class FitEditorModel: Identifiable {
    let id: UUID
    let state: AppState
    var draft: FitDraft
    var saved: FitMemory?
    var pending = false
    var unknown = false
    var error: String?
    var importing = false
    var completedPhotoImportID: UUID?
    var importID = UUID()
    /// A source chosen before the editor opened (Take photo / Photos); consumed once by the hero.
    var launch: PhotoSourceLaunch?
    /// Opens Record wear for this fit after saving. Wear is still only recorded when the person confirms there.
    var recordWearNext = false
    private var importTask: Task<Void, Never>?
    init(state: AppState, draft: FitDraft) throws {
        self.state = state; self.draft = draft; id = draft.id; saved = try state.store?.savedFit(for: draft)
    }
    var hasUnsavedChanges: Bool {
        saved == nil && (pending || unknown || importing || error != nil || draft.hasChanges)
    }
    var locked: Bool { pending || unknown || saved != nil }
    /// The outfit already planned for this fit's day, when it is still owned and not yet linked.
    var plannedOutfit: Outfit? {
        guard draft.value.outfit == nil,
              let id = FitJournalPresentation.plannedOutfitID(on: draft.value.day, entries: state.planEntries) else { return nil }
        return state.outfits.first { $0.id == id }
    }
    var guidance: FitJournalPresentation.SaveGuidance { FitJournalPresentation.guidance(for: draft.value) }
    var canSave: Bool { !locked && !importing && (draft.base == nil || draft.hasChanges) && (try? draft.result()) != nil }
    func update(_ change: (inout FitMemory) -> Void) {
        guard !locked else { return }; var value = draft; change(&value.value); draft = value
        do { guard let store = state.store else { throw PieceStore.StoreError.corruptStore }; try store.saveFitDraft(draft); error = nil }
        catch { self.error = "These fit edits could not be retained. Keep the editor open and retry." }
    }
    func link(_ outfit: Outfit?) -> Bool {
        guard !locked else { return false }
        do {
            let snapshot: FitOutfitSnapshot?
            if let outfit {
                guard let store = state.store, let current = try store.outfit(id: outfit.id) else { throw FitValidationError.outfitUnavailable }
                snapshot = try FitOutfitSnapshot(outfit: current, pieces: store.ownedPiecesForWear())
            } else { snapshot = nil }
            update { $0.outfit = snapshot }; return error == nil
        } catch { self.error = "This outfit changed or is unavailable. Choose a current saved outfit; your previous link is retained."; return false }
    }
    func cancelImport() { importID = UUID(); importTask?.cancel(); importTask = nil; importing = false }
    func removePhoto() { guard !locked else { return }; cancelImport(); update { $0.photoID = nil; $0.photoRecipe = .fitOriginal } }
    func importPhoto(_ data: Data) {
        guard !locked else { return }; cancelImport(); let token = importID; importing = true
        importTask = Task { [weak self] in
            do {
                let photo = try await PhotoPreparer().prepare(data: data)
                guard let self, self.importID == token, !Task.isCancelled, !self.locked else { return }
                guard let store = self.state.store else { throw PieceStore.StoreError.corruptStore }
                _ = try store.acceptPhoto(photo)
                self.update { $0.photoID = photo.id; $0.photoRecipe = .fitOriginal }; self.importing = false
                if self.error == nil { self.completedPhotoImportID = photo.id }
            } catch {
                guard let self, self.importID == token else { return }
                self.importing = false; self.error = "The photo could not be prepared. Your previous photo, link and note are retained. Choose another or retry."
            }
        }
    }
    func save() async {
        guard !importing else { return }
        await runSave()
        if saved != nil { finish() }
    }
    func finish(discarding: Bool = false) {
        guard !pending, !unknown else { return }; cancelImport()
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            let retained = try store.fitDraft()
            guard let retained, retained.id == draft.id, retained.operationID == draft.operationID,
                  retained.base == draft.base else { throw PieceStore.StoreError.staleDraft }
            try store.finishFitDraft(discarding ? retained : draft, discarding: discarding)
            if let saved {
                state.fitAnchor = saved.id
                if recordWearNext, !discarding { state.pendingFitWear = (saved.outfit?.id, saved.day) }
            }
            state.fitEditor = nil; state.reloadFits(); state.retryPhotoCleanup()
        } catch { self.error = "This task could not close. The fit and draft are retained; retry." }
    }
}

extension AppState {
    func reloadFits() {
        do { fitMemories = try store?.fitMemories() ?? []; fitError = nil }
        catch { fitError = "Your fit journal could not be read. Keep your local data and retry." }
    }
    func openFit(_ memory: FitMemory? = nil, source: FitCaptureSource? = nil) {
        guard !hasActiveEditor else { return }
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            let draft: FitDraft
            if let retained = try store.fitDraft() { draft = retained }
            else {
                if let memory { guard try store.fitMemories().contains(memory) else { throw PieceStore.StoreError.staleRevision } }
                draft = FitDraft(ownerID: try store.todayConfiguration().ownerID, base: memory); try store.saveFitDraft(draft)
            }
            reloadOutfits(); reloadPieces(); reloadPlanEntries()
            let editor = try FitEditorModel(state: self, draft: draft)
            if draft.value.photoID == nil, draft.base == nil {
                switch source { case .camera: editor.launch = .camera; case .photos: editor.launch = .photos; default: break }
            }
            fitEditor = editor
        } catch { fitError = "This fit task could not open. Your saved journal is unchanged." }
    }
    /// Called once the fit sheet has closed, so Record wear never competes with the dismissing sheet.
    func openPendingFitWear() {
        guard let request = pendingFitWear else { return }
        pendingFitWear = nil
        let outfitID = request.outfitID.flatMap { id in (try? store?.outfit(id: id)).flatMap { $0 } }?.id
        openWear(outfitID: outfitID, day: request.day)
    }
    func resumeFit() {
        guard entry.page == .main else { return }
        do { if try store?.fitDraft() != nil { openFit() } }
        catch { fitError = "Your fit draft could not be recovered. Keep the app data." }
    }
}

extension AppState {
    func recordWear(from memory: FitMemory) {
        do {
            guard let store, try store.fitMemories().contains(memory) else { throw PieceStore.StoreError.staleRevision }
            let current = try memory.outfit.flatMap { try store.outfit(id: $0.id) }
            openWear(outfitID: current?.id, day: memory.day)
            if current == nil { wearEditor?.error = "Choose the pieces you actually wore. This memory does not imply a wear or reconstruct deleted garments." }
        } catch { fitError = "This memory changed or could not be read. Reload it before recording wear." }
    }
}

extension FitEditorModel: DraftSaving {
    func persistDraft() throws { try state.requireStore().saveFitDraft(draft) }
    func commit() throws -> FitMemory { try state.requireStore().saveFit(draft) }
    func receipt() throws -> FitMemory? { try state.requireStore().savedFit(for: draft) }
    func didFinishSave(recovered: Bool) { state.reloadFits() }
    func notSavedMessage() -> String { "Fit was not saved. Review the date, current outfit and photo, and keep notes within 500 characters. Your draft is retained." }
    var unknownMessage: String { "The result is unknown. Check the same save before editing." }
}
