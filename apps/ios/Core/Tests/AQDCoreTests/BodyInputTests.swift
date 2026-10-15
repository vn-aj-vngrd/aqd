import Foundation
import Testing
@testable import AQDCore

struct BodyInputTests {
    @Test func unitSwitchesKeepCanonicalMeasurementAndInvalidRawTextSurvivesRestart() throws {
        var input = HeightInput(body: BodyPreferences())
        input.edit(.centimeters, text: "173.125")
        let exact = input.centimeters
        for _ in 0..<20 {
            input.switchUnits(to: .feetInches)
            #expect(input.centimeters == exact)
            input.switchUnits(to: .cm)
            #expect(input.centimeters == exact)
        }
        input.edit(.centimeters, text: "173..125")
        #expect(!input.isValid)
        input.switchUnits(to: .feetInches)
        #expect(input.units == .cm)
        let restored = try JSONDecoder().decode(HeightInput.self, from: JSONEncoder().encode(input))
        #expect(restored.cmText == "173..125")
        #expect(!restored.isValid)
    }

    @Test func roundedWholeFootBoundaryRemainsValidAndSwitchableAfterRestart() throws {
        var input = HeightInput(body: BodyPreferences())
        input.edit(.centimeters, text: "182.87999999999")
        let exact = input.centimeters
        input.switchUnits(to: .feetInches)
        #expect(input.feetText == "6")
        #expect(input.inchesText == "0")
        #expect(input.isValid)
        #expect(input.centimeters == exact)
        input = try JSONDecoder().decode(HeightInput.self, from: JSONEncoder().encode(input))
        input.switchUnits(to: .cm)
        #expect(input.units == .cm)
        #expect(input.isValid)
        #expect(input.centimeters == exact)
    }

    @Test func tinyPositiveMeasurementsRemainNonzeroAndSwitchable() throws {
        for value in [0.00000000001, 1e-200, Double.leastNormalMagnitude, Double.leastNonzeroMagnitude] {
            var body = BodyPreferences()
            body.heightCM = value
            var input = HeightInput(body: body)
            #expect(input.isValid)
            input.switchUnits(to: .feetInches)
            #expect(input.units == .feetInches)
            #expect(input.isValid)
            #expect(input.inchesText != "0")
            #expect(input.centimeters == value)
            input = try JSONDecoder().decode(HeightInput.self, from: JSONEncoder().encode(input))
            input.switchUnits(to: .cm)
            #expect(input.units == .cm)
            #expect(input.isValid)
            #expect(input.centimeters == value)
        }
    }

    @Test func optionalHeightValidatesFinitePositiveUnitsWithoutNormativeBounds() {
        var input = HeightInput(body: BodyPreferences())
        #expect(input.isValid && input.centimeters == nil)
        for invalid in ["0", "-2", "nan", "inf", "1e309", "abc"] {
            input.edit(.centimeters, text: invalid)
            #expect(!input.isValid)
        }
        input.edit(.centimeters, text: "400")
        #expect(input.isValid && input.centimeters == 400)
        input.edit(.centimeters, text: "")
        input.switchUnits(to: .feetInches)
        input.edit(.feet, text: "5"); input.edit(.inches, text: "8.5")
        #expect(input.isValid)
        #expect(abs((input.centimeters ?? 0) - 173.99) < 0.000001)
        input.edit(.inches, text: "12")
        #expect(!input.isValid)
        input.edit(.inches, text: "8"); input.edit(.feet, text: "5.5")
        #expect(!input.isValid)
    }

    @Test func customPickerIsTransactionalAndCountsGraphemesWithoutTruncation() throws {
        var draft = StylePreferenceDraft(source: .settings)
        draft.answers.body.shape = "Straight"; draft.answers.body.response = .provided
        draft.openBodyShapePicker()
        draft.bodyShapePicker?.selection = "Rounded"
        draft.bodyShapePicker?.isEditingCustom = true
        draft.bodyShapePicker?.customText = "My shoulders feel broad"
        draft.bodyShapePicker?.cancelDescription()
        #expect(draft.bodyShapePicker?.selection == "Rounded")
        #expect(draft.answers.body.shape == "Straight")
        draft.bodyShapePicker?.isEditingCustom = true
        let extended = String(repeating: "👩🏽‍💻", count: 161)
        draft.bodyShapePicker?.customText = extended
        #expect(draft.bodyShapePicker?.customText.count == 161)
        #expect(draft.bodyShapePicker?.canUseDescription == false)
        #expect(throws: (any Error).self) { try draft.bodyShapePicker?.useDescription() }
        #expect(draft.bodyShapePicker?.customText == extended)
        draft.bodyShapePicker?.customText = String(extended.dropLast())
        try draft.bodyShapePicker?.useDescription()
        #expect(draft.answers.body.shape == "Straight")
        draft.finishBodyShapePicker()
        #expect(draft.answers.body.shape?.count == 160)
        #expect(!draft.answers.body.useForSuggestions)
        draft.openBodyShapePicker(); draft.bodyShapePicker?.selection = nil
        draft.cancelBodyShapePicker()
        #expect(draft.answers.body.shape?.count == 160)
    }

    @Test func invalidHeightCannotHideBehindShapeAndRefusalClearsDetailsAndConsent() throws {
        var draft = StylePreferenceDraft(source: .profile)
        for step in 0..<4 { draft.answers.choose("No preference", at: step) }
        draft.answers.colors.declined = true
        draft.answers.body.shape = "Not sure"; draft.answers.body.response = .provided
        draft.answers.body.useForSuggestions = true
        draft.editHeight(.centimeters, text: "-1")
        #expect(!draft.isAnswered(4)); #expect(!draft.isComplete)
        #expect(throws: (any Error).self) { try draft.validatedForSave() }
        draft.declineBody()
        #expect(draft.isComplete)
        #expect(draft.heightInput == nil && draft.bodyShapePicker == nil)
        #expect(!draft.answers.body.useForSuggestions)
        try draft.validatedForSave()
    }

    @Test func unknownShapeIsNeverPassedAsBodyContextAndBothPermissionsAreRequired() {
        var body = BodyPreferences(); body.response = .provided; body.shape = "Not sure"
        body.useForSuggestions = true
        #expect(body.suggestionContext(styleContextEnabled: true) == nil)
        body.heightCM = 173
        #expect(body.suggestionContext(styleContextEnabled: true)?.shape == nil)
        #expect(body.suggestionContext(styleContextEnabled: false) == nil)
        body.useForSuggestions = false
        #expect(body.suggestionContext(styleContextEnabled: true) == nil)
    }
}
