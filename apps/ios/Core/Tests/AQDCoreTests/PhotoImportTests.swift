import Foundation
import Testing
@testable import AQDCore

struct PhotoImportTests {
    @Test func foreignDraftCannotAcceptCompletion() {
        let original = UUID()
        let source = PieceDraft(name: "Walking shoes", category: .shoes, photoID: original)
        var foreign = PieceDraft(name: "Coat", category: .layers, photoID: original)
        let unchanged = foreign
        var gate = PhotoImportGate()
        let request = gate.begin(for: source)

        #expect(!gate.canAccept(request, for: foreign))
        #expect(!gate.apply(photoID: UUID(), request: request, to: &foreign))
        #expect(foreign == unchanged)
    }

    @Test(arguments: [false, true])
    func replacedSourceCannotAcceptCompletion(initiallyHasPhoto: Bool) {
        var draft = PieceDraft(name: "Walking shoes", category: .shoes,
                               photoID: initiallyHasPhoto ? UUID() : nil)
        var gate = PhotoImportGate()
        let request = gate.begin(for: draft)
        draft.photoID = UUID()
        let unchanged = draft

        #expect(!gate.canAccept(request, for: draft))
        #expect(!gate.apply(photoID: UUID(), request: request, to: &draft))
        #expect(draft == unchanged)
    }

    @Test func latestImportSupersedesOlderCompletion() {
        var draft = PieceDraft(name: "Walking shoes", category: .shoes, photoID: UUID())
        let unchanged = draft
        var gate = PhotoImportGate()
        let older = gate.begin(for: draft)
        let latest = gate.begin(for: draft)
        let acceptedPhoto = UUID()

        #expect(!gate.canAccept(older, for: draft))
        #expect(!gate.apply(photoID: UUID(), request: older, to: &draft))
        #expect(draft == unchanged)
        #expect(gate.canAccept(latest, for: draft))
        #expect(gate.apply(photoID: acceptedPhoto, request: latest, to: &draft))
        #expect(draft.photoID == acceptedPhoto)
    }

    @Test func duplicatedCompletionCannotApplyAgain() {
        let original = UUID()
        var draft = PieceDraft(name: "Walking shoes", category: .shoes, photoID: original)
        var gate = PhotoImportGate()
        let request = gate.begin(for: draft)
        // Keeping the same source ID makes request consumption, not source mismatch,
        // the reason the duplicate is rejected.
        let accepted = gate.apply(photoID: original, request: request, to: &draft)
        #expect(accepted)
        let unchanged = draft

        #expect(!gate.canAccept(request, for: draft))
        #expect(!gate.apply(photoID: UUID(), request: request, to: &draft))
        #expect(draft == unchanged)
    }

    @Test(arguments: [false, true])
    func matchingCompletionUpdatesOnlyPhoto(initiallyHasPhoto: Bool) {
        var draft = PieceDraft(name: "Walking shoes", category: .shoes,
                               photoID: initiallyHasPhoto ? UUID() : nil)
        var gate = PhotoImportGate()
        let request = gate.begin(for: draft)
        #expect(request.draftID == draft.id)
        #expect(request.previousPhotoID == draft.photoID)
        draft.name = "Evening shoes"
        draft.category = .accessories
        let acceptedPhoto = UUID()
        var expected = draft
        expected.photoID = acceptedPhoto

        #expect(gate.canAccept(request, for: draft))
        #expect(gate.canAccept(request, for: draft))
        #expect(gate.apply(photoID: acceptedPhoto, request: request, to: &draft))
        #expect(draft == expected)
        #expect(gate.pending == nil)
    }

    @Test func cancelledImportCannotReplaceAcceptedPhotoOrMetadata() {
        let original = UUID()
        var draft = PieceDraft(name: "Walking shoes", category: .shoes, photoID: original)
        var gate = PhotoImportGate()
        let request = gate.begin(for: draft)
        gate.cancel()
        #expect(!gate.canAccept(request, for: draft))
        #expect(!gate.apply(photoID: UUID(), request: request, to: &draft))
        #expect(draft.photoID == original)
        #expect(draft.name == "Walking shoes")
        #expect(draft.category == .shoes)
    }
}
