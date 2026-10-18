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
