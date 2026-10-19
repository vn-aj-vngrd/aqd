import Foundation
import Testing
@testable import AQDCore

struct AgentTripTests {
    private let owner = UUID()
    private func piece(_ name: String, _ category: PieceCategory, color: String = "") -> WardrobePiece {
        WardrobePiece(id: UUID(), name: name, category: category, photoID: UUID(), details: PieceDetails(color: color))
    }
    private var closet: [WardrobePiece] {
        [piece("Linen top", .tops), piece("Silk cami", .tops), piece("Cotton tee", .tops),
         piece("Linen shorts", .bottoms), piece("Denim skirt", .bottoms), piece("Wide trousers", .bottoms),
         piece("Beach dress", .dresses), piece("Satin dress", .dresses),
         piece("Sandals", .shoes), piece("Sneakers", .shoes), piece("Straw hat", .accessories), piece("Light cardigan", .layers)]
    }

    @Test func parsesDaysAndDestination() {
        let intent = TripIntent.parse("Plan my 3 day trip to Boracay")
        #expect(intent?.days == 3)
        #expect(intent?.destination == "Boracay")
        #expect(TripIntent.parse("what should I wear tomorrow") == nil)
        #expect(TripIntent.parse("a weekend getaway in Tagaytay")?.days == 3)
    }

    @Test func composesDistinctLooksAcrossDays() throws {
        let briefs = TripIntent.parse("3 day trip to Boracay")!.briefs
        let looks = try TripOutfitComposer.compose(briefs: briefs, pieces: closet)
        #expect(looks.count == 3)
        #expect(Set(looks.map(Set.init)).count == 3)
        #expect(looks.allSatisfy { !$0.isEmpty })
    }

    @Test func refusesAClosetThatCannotMakeAnOutfit() {
        #expect(throws: (any Error).self) { try TripOutfitComposer.compose(briefs: [TripDayBrief(label: "Day 1")], pieces: [piece("Hat", .accessories)]) }
    }

    @Test func requestBecomesATripDraftWithThemeAndPlan() throws {
        let spec = AgentTripSpec(destination: "Boracay", startDate: "2027-03-10", days: TripIntent.parse("3 day trip to Boracay")!.briefs)
        let action = try AgentMutationRequest(kind: .createTrip, name: "Boracay trip", trip: spec)
            .prepare(ownerID: owner, pieces: closet, timeZone: TimeZone(identifier: "Asia/Manila") ?? .current)
        guard case .trip(let draft) = action else { Issue.record("expected a trip"); return }
        #expect(draft.days.count == 3)
        #expect(draft.theme.outfitIDs.count == 3)
        #expect(draft.canPlan && draft.includePlan)
        #expect(draft.plan?.plan.trip?.destination == "Boracay")
        #expect(draft.days.map { $0.day?.key } == ["2027-03-10", "2027-03-11", "2027-03-12"])
    }

    @Test func undatedTripSavesLooksWithoutAPlan() throws {
        let spec = AgentTripSpec(destination: "Boracay", days: [TripDayBrief(label: "Day 1"), TripDayBrief(label: "Day 2")])
        let action = try AgentMutationRequest(kind: .createTrip, name: "Boracay trip", trip: spec).prepare(ownerID: owner, pieces: closet)
        guard case .trip(let draft) = action else { Issue.record("expected a trip"); return }
        #expect(!draft.canPlan && !draft.includePlan)
        #expect(try draft.resolvedPlan(saved: []) == nil)
    }

    @Test func themeNameAvoidsAnExistingTheme() throws {
        let existing = OutfitTheme(id: UUID(), ownerID: owner, name: "Boracay trip", description: "", outfitIDs: [], revision: 1)
        let spec = AgentTripSpec(destination: "Boracay", days: [TripDayBrief(label: "Day 1")])
        let action = try AgentMutationRequest(kind: .createTrip, name: "Boracay trip", trip: spec).prepare(ownerID: owner, pieces: closet, themes: [existing])
        guard case .trip(let draft) = action else { Issue.record("expected a trip"); return }
        #expect(draft.theme.name == "Boracay trip 2")
    }
}

struct AgentQuestionTests {
    @Test func readsAnswersFromAReplyThatAsksOneQuestion() {
        let question = AgentQuestion.fromReply("Boracay sounds lovely. How long is the trip: 3 days, 5 days or a full week?")
        #expect(question?.options == ["3 days", "5 days", "a full week"])
    }
    @Test func ignoresRepliesWithoutAnswersOrWithSeveralQuestions() {
        #expect(AgentQuestion.fromReply("Here is a look for you.") == nil)
        #expect(AgentQuestion.fromReply("What is the occasion? Where are you going?") == nil)
        #expect(AgentQuestion.fromReply("Do you want a look?") == nil)
    }
    @Test func rejectsTooFewOrTooManyAnswers() {
        #expect(AgentQuestion(prompt: "Pick?", options: ["One"]) == nil)
        #expect(AgentQuestion(prompt: "Pick?", options: ["A", "B", "C", "D", "E"]) == nil)
        #expect(AgentQuestion(prompt: "Pick?", options: ["A", "a", "B"])?.options == ["A", "B"])
    }
}

struct AgentQuestionChoiceTests {
    @Test func recommendedAnswerLeadsAndKeepsItsDetail() throws {
        let question = try #require(AgentQuestion(prompt: "How long is the trip?", options: ["3 days", "5 days", "A week"], header: "Trip length",
                                                  details: ["Weekend", "", "Most variety"], recommended: "5 days"))
        #expect(question.options == ["5 days", "3 days", "A week"])
        #expect(question.recommended == "5 days")
        #expect(question.detail(at: 1) == "Weekend")
        #expect(question.detail(at: 0) == nil)
        #expect(question.header == "Trip length")
    }
    @Test func answerJoinsChoicesInOrderWithANote() throws {
        let question = try #require(AgentQuestion(prompt: "Which days?", options: ["Beach", "Dinner", "Hiking"], multiSelect: true))
        #expect(question.answer(choices: ["Hiking", "Beach"], note: "") == "Beach and Hiking")
        #expect(question.answer(choices: ["Dinner"], note: "somewhere dressy") == "Dinner. somewhere dressy")
        #expect(question.answer(choices: [], note: "Surprise me") == "Surprise me")
    }
}

struct TripIntentDayTests {
    @Test func daysAreReadWithOrWithoutATripWord() {
        #expect(TripIntent.dayCount(in: "Plan outfits for 3 days in Boracay") == 3 && TripIntent.dayCount(in: "four-night stay") == 4)
        #expect(TripIntent.dayCount(in: "Pack for a weekend in Baguio") == 3 && TripIntent.dayCount(in: "a week away") == 7)
        #expect(TripIntent.dayCount(in: "Plan a trip for me") == nil && TripIntent.dayCount(in: "30 days in Japan") == TripOutfitComposer.maximumDays)
        #expect(TripIntent.parse("Plan outfits for 3 days in Boracay") == nil)
        #expect(TripIntent.parse("Plan outfits for 3 days in Boracay", requireTrigger: false) == TripIntent(days: 3, destination: "Boracay"))
        #expect(TripIntent.parse("Plan outfits for my trip to Cebu. 3 days")?.destination == "Cebu")
    }
    @Test func datesAreRecognisedSoTheModelCanPlaceTheTrip() {
        #expect(TripIntent.mentionsDates("A 4 day trip to Tokyo starting March 3") && TripIntent.mentionsDates("trip 10/12 to 10/15"))
        #expect(!TripIntent.mentionsDates("3 days in Boracay") && !TripIntent.mentionsDates("What may I wear on the trip"))
    }
}

struct AgentWearAnswerTests {
    @Test func readsTheFocusOfAWearQuestion() {
        #expect(AgentWearAnswer.focus("Rediscover unworn pieces", namesPiece: false) == .unworn)
        #expect(AgentWearAnswer.focus("What do I wear most?", namesPiece: false) == .mostWorn)
        #expect(AgentWearAnswer.focus("How often did I wear my ivory sneakers", namesPiece: true) == .named)
        #expect(AgentWearAnswer.focus("Wear stats", namesPiece: false) == .overview)
    }
    @Test func writesNaturalSentences() {
        #expect(AgentWearAnswer.unworn(count: 22, active: 51, period: "this month").hasPrefix("You haven’t worn 22 of your 51 pieces this month."))
        #expect(AgentWearAnswer.mostWorn([("Ivory sneakers", 5), ("Black tee", 3), ("Jeans", 2)], period: "this month")
                == "Your most worn piece this month is Ivory sneakers, 5 times. Close behind: Black tee and Jeans.")
        #expect(AgentWearAnswer.named("Ivory sneakers", count: 1, period: "this month") == "You’ve worn Ivory sneakers once this month.")
        #expect(AgentWearAnswer.overview(looks: 10, used: 29, active: 51, period: "this month") == "This month you’ve recorded 10 looks and worn 29 of your 51 pieces.")
    }
}
