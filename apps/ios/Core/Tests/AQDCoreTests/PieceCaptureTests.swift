import Foundation
import Testing
@testable import AQDCore

struct PieceCaptureTests {
    @Test func optionalMetadataIsBoundedWithoutChangingTheDraft() throws {
        var details = PieceDetails(color: String(repeating: "b", count: 81))
        var draft = PieceDraft(name: "Shirt", category: .tops, photoID: UUID(), details: details)
        #expect(throws: PieceValidationError.metadataTooLong) { try draft.validated() }
        details.color = "Blue"
        details.tags = Array(repeating: "tag", count: 21)
        draft.details = details
        #expect(throws: PieceValidationError.invalidTags) { try draft.validated() }
        draft.details.tags = [String(repeating: "a", count: 41)]
        #expect(throws: PieceValidationError.invalidTags) { try draft.validated() }
        draft.details.tags = ["casual"]
        draft.details.notes = String(repeating: "n", count: 2001)
        #expect(throws: PieceValidationError.notesTooLong) { try draft.validated() }
        draft.details.notes = "Private note"
        draft.details.priorWearCount = -1
        #expect(throws: PieceValidationError.invalidPriorWearCount) { try draft.validated() }
        draft.details.priorWearCount = 10001
        #expect(throws: PieceValidationError.invalidPriorWearCount) { try draft.validated() }
        draft.details.priorWearCount = 10000
        try draft.validated()
        #expect(draft.details.color == "Blue")
    }

    @Test func savingRejectsNamesLongerThanEightyCharacters() throws {
        let draft = PieceDraft(name: String(repeating: "a", count: 81), category: .tops, photoID: UUID())
        #expect(throws: PieceValidationError.nameTooLong) { try draft.validated() }
    }

    @Test func savingRequiresAChosenCategory() throws {
        let draft = PieceDraft(name: "Walking shoes", photoID: UUID())
        #expect(throws: PieceValidationError.categoryRequired) { try draft.validated() }
    }

    @Test func savingRejectsWhitespaceOnlyNameWithoutLosingPhoto() throws {
        let photo = UUID()
        let draft = PieceDraft(name: "  \n ", category: .shoes, photoID: photo)
        #expect(throws: PieceValidationError.nameRequired) { try draft.validated() }
        #expect(draft.photoID == photo)
    }

    @Test func newPieceCannotSaveWithoutAcceptedPhoto() throws {
        let draft = PieceDraft(name: "Walking shoes", category: .shoes)
        #expect(throws: PieceValidationError.photoRequired) {
            try draft.validated()
        }
        #expect(draft.name == "Walking shoes")
        #expect(draft.category == .shoes)
    }
}
