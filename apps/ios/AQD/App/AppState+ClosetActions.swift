import AQDCore
import Foundation

/// One-tap Closet changes made straight from a card, each acknowledged by the store before the lists refresh.
extension AppState {
    /// Moves a piece to the laundry, or back to available when it is already there.
    @discardableResult
    func toggleLaundry(_ piece: WardrobePiece) -> WardrobePiece? {
        guard let store, !piece.isArchived else { return nil }
        do {
            let saved = try store.setAvailability(id: piece.id, value: PieceStatus.laundryToggle(from: piece.availability),
                                                  expectedRevision: piece.revision, operationID: UUID())
            reloadPieces()
            return saved
        } catch {
            reloadPieces()
            collectionError = "\(piece.displayName) wasn’t changed. Reopen the latest record and retry."
            return nil
        }
    }

    /// Flips an outfit's favorite flag.
    @discardableResult
    func toggleFavorite(_ outfit: Outfit) -> Bool {
        guard let store else { return false }
        do {
            _ = try store.applyOutfitMutation(OutfitMutationRequest(outfit: outfit, action: .favorite(!outfit.isFavorite)))
            reloadOutfits()
            return true
        } catch {
            reloadOutfits()
            outfitError = "\(outfit.displayName) wasn’t changed. Reopen the latest record and retry."
            return false
        }
    }
}

extension AppState {
    /// Result of a multi-piece change: each piece is its own acknowledged write, so some can succeed while others fail.
    struct BulkResult: Equatable {
        var changed = 0
        var failed = 0
    }

    /// Sets availability on several pieces, skipping archived ones and never undoing a write that was acknowledged.
    func setAvailability(_ value: PieceAvailability, for pieces: [WardrobePiece]) -> BulkResult {
        var result = BulkResult()
        guard let store else { return BulkResult(failed: pieces.count) }
        for piece in pieces where !piece.isArchived && piece.availability != value {
            do {
                try store.setAvailability(id: piece.id, value: value, expectedRevision: piece.revision, operationID: UUID())
                result.changed += 1
            } catch { result.failed += 1 }
        }
        reloadPieces()
        if result.failed > 0 { collectionError = "\(result.failed) of \(pieces.count) pieces weren’t changed. Reselect them and retry." }
        return result
    }

    /// Archives several pieces; each stays restorable.
    func archive(_ pieces: [WardrobePiece]) -> BulkResult {
        var result = BulkResult()
        guard let store else { return BulkResult(failed: pieces.count) }
        for piece in pieces where !piece.isArchived {
            do {
                try store.setArchived(id: piece.id, archived: true, expectedRevision: piece.revision, operationID: UUID())
                result.changed += 1
            } catch { result.failed += 1 }
        }
        reloadPieces()
        if result.failed > 0 { collectionError = "\(result.failed) of \(pieces.count) pieces weren’t archived. Reselect them and retry." }
        return result
    }

    /// Opens Build outfit with this outfit's pieces and themes as a new, unsaved draft.
    func duplicateOutfit(_ outfit: Outfit) {
        guard !hasActiveEditor else { return }
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            if let existing = try store.outfitDraft() {
                if try store.savedOutfit(for: existing) != nil { try store.acknowledgeOutfitReceipt(existing) }
                else { buildOutfit(); return }
            }
            var draft = OutfitDraft(ownerID: try store.todayConfiguration().ownerID)
            draft.name = String("\(outfit.displayName) copy".prefix(80))
            draft.themeIDs = try store.themes().filter { $0.outfitIDs.contains(outfit.id) }.map(\.id)
            try draft.applyManualSelection(outfit.pieceIDs, pieces: pieces)
            try store.saveOutfitDraft(draft)
            outfitEditor = OutfitEditorModel(state: self, draft: draft)
        } catch {
            outfitError = "This outfit can’t be copied while some of its pieces are unavailable. The original is unchanged."
        }
    }

    /// Takes an outfit out of one theme without touching the outfit itself.
    @discardableResult
    func remove(_ outfit: Outfit, from theme: OutfitTheme) -> Bool {
        guard !hasActiveEditor else { return false }
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            guard try store.themeDraft() == nil else {
                themeError = "Finish or discard your unfinished theme before changing this one."
                return false
            }
            var draft = ThemeDraft(editing: theme)
            draft.outfitIDs.removeAll { $0 == outfit.id }
            try store.saveThemeDraft(draft)
            _ = try store.saveTheme(draft)
            try store.finishThemeDraft(draft)
            reloadThemes()
            return true
        } catch {
            reloadThemes()
            themeError = "\(theme.displayName) wasn’t changed. Your outfits are unchanged; retry."
            return false
        }
    }
}
