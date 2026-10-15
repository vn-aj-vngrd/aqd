import Foundation
import Testing
@testable import AQDCore

struct OutfitTests {
    private func piece(_ id: UUID = UUID(), archived: Bool = false) -> WardrobePiece {
        WardrobePiece(id: id, name: "Shirt", category: .tops, photoID: UUID(), isArchived: archived)
    }

    @Test func manualPartialOutfitIsValidAndKeepsOrderedSelection() throws {
        let first = piece(), second = piece()
        var draft = OutfitDraft(ownerID: UUID())
        draft.name = "  Weekend  "
        draft.select(first.id); draft.select(second.id); draft.select(first.id)
        try draft.validatedForSave(pieces: [first, second])
        #expect(draft.pieceIDs == [first.id, second.id])
        #expect(draft.trimmedName == "Weekend")
        #expect(draft.name == "  Weekend  ")
    }

    @Test func staleOrArchivedSelectionCannotBeSavedAndDraftIsRetained() throws {
        let item = piece()
        var draft = OutfitDraft(ownerID: UUID())
        draft.name = "Weekend"; draft.select(item.id)
        #expect(throws: OutfitValidationError.unavailablePiece) { try draft.validatedForSave(pieces: []) }
        #expect(throws: OutfitValidationError.unavailablePiece) {
            try draft.validatedForSave(pieces: [piece(item.id, archived: true)])
        }
        #expect(draft.pieceIDs == [item.id])
    }

    @Test func draftCanBeIncompleteButSaveNeedsNameAndAnOwnedPiece() throws {
        var draft = OutfitDraft(ownerID: UUID())
        try draft.validated()
        #expect(throws: OutfitValidationError.nameRequired) { try draft.validatedForSave(pieces: []) }
        draft.name = "Look"
        #expect(throws: OutfitValidationError.piecesRequired) { try draft.validatedForSave(pieces: []) }
        draft.name = String(repeating: "x", count: 81)
        #expect(throws: OutfitValidationError.nameTooLong) { try draft.validatedForSave(pieces: []) }
    }

    @Test func editRetainsIdentityAndRevisionWhileFilteringDoesNotMutateSelection() throws {
        let item = piece()
        let saved = Outfit(id: UUID(), ownerID: UUID(), name: "Weekend", pieceIDs: [item.id])
        var edit = OutfitDraft(editing: saved)
        edit.name = "Evening"
        #expect(edit.outfitID == saved.id)
        #expect(edit.baseRevision == 1)
        #expect(edit.pieceIDs == [item.id])
        let encoded = try JSONEncoder().encode(edit)
        #expect(try JSONDecoder().decode(OutfitDraft.self, from: encoded) == edit)
        #expect(saved.name == "Weekend")
    }
}
