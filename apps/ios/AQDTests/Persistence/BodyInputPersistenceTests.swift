import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor
struct BodyInputPersistenceTests {
    private func complete() -> StylePreferences {
        var value = StylePreferences()
        for step in 0..<4 { value.choose("No preference", at: step) }
        value.body.decline(); value.colors.declined = true
        return value
    }
    @Test func rawInvalidHeightAndNestedCustomPickerSurviveRestartWithoutChangingSavedAnswers() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        let original = StylePreferenceDraft(source: .profile, answers: complete())
        try #require(store).saveStyleDraft(original)
        let saved = try #require(store).saveStylePreferences(original)
        try #require(store).acknowledgeStyleReceipt(operationID: original.operationID)
        var draft = StylePreferenceDraft(source: .settings, baseRevision: 1, answers: saved.answers)
        draft.page = 4
        draft.editHeight(.centimeters, text: "173..5")
        draft.openBodyShapePicker()
        draft.bodyShapePicker?.selection = "Straight"
        draft.bodyShapePicker?.isEditingCustom = true
        draft.bodyShapePicker?.customText = String(repeating: "👩🏽‍💻", count: 161)
        try #require(store).saveStyleDraft(draft)
        store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).localExperience().styleDraft == draft)
        #expect(try #require(store).localExperience().style == saved)
        #expect(throws: (any Error).self) { try #require(store).saveStylePreferences(draft) }
        draft.bodyShapePicker?.cancelDescription()
        draft.finishBodyShapePicker()
        #expect(draft.answers.body.shape == "Straight")
        #expect(!draft.isComplete)
        draft.editHeight(.centimeters, text: "173.125")
        draft.switchHeightUnits(to: .feetInches)
        #expect(!draft.answers.body.useForSuggestions)
        try #require(store).saveStyleDraft(draft)
        let updated = try #require(store).saveStylePreferences(draft)
        store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).localExperience().style == updated)
        #expect(updated.answers.body.heightCM == 173.125)
        #expect(updated.answers.body.units == .feetInches)
        #expect(updated.revision == 2)
        store = nil
    }
    @Test func deniedBodySaveKeepsPriorHeightUnitsConsentAndCustomDraftForTheSameRetry() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var denied = false
        var store: PieceStore? = try PieceStore(directory: directory, beforeStyleSave: {
            if denied { throw CocoaError(.fileWriteNoPermission) }
        })
        var original = StylePreferenceDraft(source: .profile, answers: complete())
        original.editHeight(.centimeters, text: "168.4")
        original.answers.body.useForSuggestions = true
        try #require(store).saveStyleDraft(original)
        let saved = try #require(store).saveStylePreferences(original)
        try #require(store).acknowledgeStyleReceipt(operationID: original.operationID)
        var draft = StylePreferenceDraft(source: .profile, baseRevision: 1, answers: saved.answers)
        draft.editHeight(.centimeters, text: "171")
        draft.openBodyShapePicker()
        draft.bodyShapePicker?.customText = "My shoulders are broader than my hips."
        try draft.bodyShapePicker?.useDescription()
        draft.finishBodyShapePicker()
        draft.answers.body.useForSuggestions = false
        try #require(store).saveStyleDraft(draft)
        denied = true
        #expect(throws: (any Error).self) { try #require(store).saveStylePreferences(draft) }
        #expect(try #require(store).localExperience().style == saved)
        store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).localExperience().styleDraft == draft)
        let result = try #require(store).saveStylePreferences(draft)
        #expect(result.operationID == draft.operationID && result.revision == 2)
        #expect(result.answers.body.shape == "My shoulders are broader than my hips.")
        #expect(!result.answers.body.useForSuggestions)
        store = nil
    }
}
