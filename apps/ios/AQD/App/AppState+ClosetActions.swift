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
