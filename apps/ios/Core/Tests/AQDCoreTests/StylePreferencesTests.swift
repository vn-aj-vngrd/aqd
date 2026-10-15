import Foundation
import Testing
@testable import AQDCore

struct StylePreferencesTests {
    @Test func freshAnswersAreIncompleteAndEveryExplicitRefusalCompletesReview() throws {
        var answers = StylePreferences()
        #expect(answers.answeredCount == 0)
        #expect(!answers.isComplete)
        #expect(!answers.body.useForSuggestions)
        for step in 0..<4 { answers.choose("No preference", at: step) }
        answers.body.response = .declined
        answers.colors.declined = true
        #expect(answers.answeredCount == 6)
        try answers.validated()
        #expect(!answers.body.useForSuggestions)
    }

    @Test func choicesAreExclusiveAndGoalsHaveAnActualTwoChoiceLimit() {
        var answers = StylePreferences()
        answers.choose("No preference", at: 0)
        answers.choose("Wear more of my closet", at: 0)
        #expect(answers.goals == ["Wear more of my closet"])
        answers.choose("Plan outfits faster", at: 0)
        answers.choose("Try new combinations", at: 0)
        #expect(answers.goals.count == 2)
        answers.choose("No preference", at: 0)
        #expect(answers.goals == ["No preference"])
        answers.choose("No preference", at: 0)
        #expect(answers.goals.isEmpty)
    }

    @Test func corruptedOrIncompleteAnswersCannotBeSaved() throws {
        var answers = StylePreferences()
        #expect(throws: StylePreferences.ValidationError.incomplete) { try answers.validated() }
        for step in 0..<4 { answers.choose("No preference", at: step) }
        answers.body.response = .declined
        answers.colors.declined = true
        answers.goals = ["No preference", "Wear more of my closet"]
        #expect(throws: StylePreferences.ValidationError.invalidChoice) { try answers.validated() }
        answers.goals = ["Unknown"]
        #expect(throws: StylePreferences.ValidationError.invalidChoice) { try answers.validated() }
    }

    @Test func durableDraftKeepsCallerReviewPositionAndOperationWithoutCompletingPreferences() throws {
        var draft = StylePreferenceDraft(source: .settings, baseRevision: 4)
        draft.page = 6
        draft.answers.choose("Classic", at: 2)
        let restored = try JSONDecoder().decode(StylePreferenceDraft.self, from: JSONEncoder().encode(draft))
        #expect(restored == draft)
        #expect(!restored.answers.isComplete)
        #expect(restored.source == .settings)
    }
    @Test func reviewIncludesComfortAndDistinguishesPreferredFromAvoidedValues() {
        var answers = StylePreferences()
        for step in 0..<4 { answers.choose("No preference", at: step) }
        answers.body.decline(); answers.colors.declined = true
        answers.comfort = "Avoid wool"
        #expect(!answers.allDeclined)
        #expect(answers.summary(at: 3).contains("Avoid wool"))
        answers.colors.declined = false
        answers.colors.preferredColors = "Blue"; answers.colors.avoidedColors = "Red"
        answers.colors.preferredPatterns = "Stripes"; answers.colors.avoidedPatterns = "Checks"
        let summary = answers.summary(at: 5)
        #expect(summary.contains("Preferred colors: Blue"))
        #expect(summary.contains("Colors to avoid: Red"))
        #expect(summary.contains("Preferred patterns: Stripes"))
        #expect(summary.contains("Patterns to avoid: Checks"))
    }

}
