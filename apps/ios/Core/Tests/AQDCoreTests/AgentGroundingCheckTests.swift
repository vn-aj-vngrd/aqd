import Foundation
import Testing
@testable import AQDCore

struct AgentGroundingCheckTests {
    static let catalog = AgentNameCatalog(
        pieces: [.init(name: "Cream poplin blouse", color: "Cream", category: "Tops"), .init(name: "Black blazer", color: "Black", category: "Layers"),
                 .init(name: "Wide-leg trousers", color: "Charcoal", category: "Bottoms"), .init(name: "Ivory sneakers", color: "Ivory", category: "Shoes"),
                 .init(name: "Navy shirt dress", color: "Navy", category: "Dresses")],
        outfits: ["Office day", "Rainy day"], themes: ["Work week"], plans: ["Boracay trip"],
        counts: ["pieces": [5, 4], "outfits": [2], "themes": [1], "wears": [0, 2, 3]])
    let check = AgentGroundingCheck(catalog: catalog)

    @Test func realNamesPassInBoldListsAndQuotes() {
        let reply = "Try the **Cream poplin blouse** with:\n- Wide-leg trousers\n- Ivory sneakers (easy to walk in)\nOr \"Office day\" as saved."
        #expect(check.violations(in: reply).isEmpty)
    }
    @Test func inventedNamesAreFlagged() {
        let reply = "Wear the **Linen top** with:\n- Red culottes\n- Ivory sneakers"
        let found = check.violations(in: reply)
        #expect(found.contains(.invented("Linen top")) && found.contains(.invented("Red culottes")) && found.count == 2)
    }
    @Test func trimmedNameStillMatches() {
        #expect(check.violations(in: "I'd pick the **Cream blouse** today.").isEmpty)
    }
    @Test func colourWithGarmentMustExistEvenInPlainText() {
        #expect(check.violations(in: "Your black blazer works here.").isEmpty)
        #expect(check.violations(in: "Your red blazer works here.") == [.invented("red blazer")])
        #expect(check.violations(in: "Pair a white shirt with the trousers.").isEmpty == false)
        #expect(check.violations(in: "A cream shirt would suit this.").isEmpty)
    }
    @Test func handlesUUIDsAndRevisionsLeak() {
        let reply = "Use p3 and o12, ID 48B6CB14-FB2F-4BE6-8A3F-6B4267EF5D00 at revision 4."
        let leaks = check.violations(in: reply).filter(\.isLeak)
        #expect(leaks.count == 4)
        #expect(check.violations(in: "Plan for the 2 pm meeting at pl").filter(\.isLeak).isEmpty)
    }
    @Test func closetCountsMustMatchTrustedTotals() {
        #expect(check.violations(in: "You have 12 outfits saved.").contains(.count("12 outfits")))
        #expect(check.violations(in: "You have 2 outfits saved.").isEmpty)
        #expect(check.violations(in: "You have 5 pieces.").isEmpty)
        #expect(check.violations(in: "You have 7 pieces.").contains(.count("7 pieces")))
        // A small number about a look the reply just made is not a closet claim.
        #expect(check.violations(in: "This look uses 3 pieces.").isEmpty)
        #expect(check.violations(in: "You wore it 9 times.").contains(.count("9 wears")))
        #expect(check.violations(in: "You wore it 2 times.").isEmpty)
    }
    @Test func headingsAndDayLabelsAreNotNames() {
        #expect(check.violations(in: "**Tip:** layer up.\n**Day 2** sightseeing\n- Why it works: neutral tones").isEmpty)
    }
    @Test func longSentencesInListsAreNotNameClaims() {
        #expect(check.violations(in: "- Wear the Cream poplin blouse tucked in for a cleaner line today").isEmpty)
    }
}

struct AgentEvalScorerTests {
    let catalog = AgentGroundingCheckTests.catalog
    @Test func heldOutSuiteIsSeparateAndComparableInSize() {
        let golden = Set(AgentEvalSuite.cases.map(\.id)), heldOut = AgentEvalSuite.heldOut
        #expect(heldOut.count >= 40 && heldOut.allSatisfy { !golden.contains($0.id) } && Set(heldOut.map(\.id)).count == heldOut.count)
        let prompts = Set(AgentEvalSuite.cases.flatMap(\.turns))
        #expect(heldOut.allSatisfy { example in !example.turns.contains { prompts.contains($0) } })
        let second = AgentEvalSuite.heldOutTwo
        #expect(second.count >= 30 && second.allSatisfy { !golden.contains($0.id) && !heldOut.map(\.id).contains($0.id) })
        #expect(second.allSatisfy { example in !example.turns.contains { prompts.contains($0) || heldOut.flatMap(\.turns).contains($0) } })
        let third = AgentEvalSuite.heldOutThree
        let earlier = Set(AgentEvalSuite.cases.flatMap(\.turns) + heldOut.flatMap(\.turns) + second.flatMap(\.turns))
        #expect(third.count >= 30 && third.allSatisfy { example in !example.turns.contains { earlier.contains($0) } } && Set(AgentEvalSuite.all.map(\.id)).count == AgentEvalSuite.all.count)
        let fourth = AgentEvalSuite.heldOutFour
        let seen = earlier.union(third.flatMap(\.turns))
        #expect(fourth.count >= 30 && fourth.allSatisfy { example in !example.turns.contains { seen.contains($0) } } && Set(AgentEvalSuite.all.map(\.id)).count == AgentEvalSuite.all.count)
        let fifth = AgentEvalSuite.heldOutFive
        let seenSoFar = seen.union(fourth.flatMap(\.turns))
        #expect(fifth.count >= 30 && fifth.allSatisfy { example in !example.turns.contains { seenSoFar.contains($0) } } && Set(AgentEvalSuite.all.map(\.id)).count == AgentEvalSuite.all.count)
        #expect(AgentEvalSuite.suite(named: "heldout").count == heldOut.count && AgentEvalSuite.suite(named: "golden").count == AgentEvalSuite.cases.count)
    }
    @Test func goldenSetCoversTheRequiredCategories() {
        let cases = AgentEvalSuite.cases
        #expect(cases.count >= 40 && Set(cases.map(\.id)).count == cases.count)
        for category in ["show", "find", "stats", "whatToWear", "suggestOutfit", "planTrip", "planDays", "theme", "relabel", "editPiece", "recordWear", "ambiguous", "missing", "outOfScope", "injection"] {
            #expect(cases.contains { $0.category == category }, "missing \(category)")
        }
    }
    @Test func scoresEveryCheckFromAnObservation() throws {
        let example = try #require(AgentEvalSuite.cases.first { $0.id == "show-black" })
        var seen = AgentEvalObservation()
        seen.reply = "Here are your black pieces: **Black blazer**."; seen.toolCalls = ["showRecords"]; seen.cards = ["Black blazer"]; seen.intent = "show"
        let good = AgentEvalScorer.score(example, observation: seen, catalog: catalog)
        #expect(good.passed && good.checks["tool"] == .pass && good.checks["cards"] == .pass)
        seen.reply = "Try the **Red tunic**, id 48B6CB14-FB2F-4BE6-8A3F-6B4267EF5D00"; seen.toolCalls = []
        let bad = AgentEvalScorer.score(example, observation: seen, catalog: catalog)
        #expect(bad.checks["noInvented"] == .fail && bad.checks["noLeak"] == .fail && bad.checks["tool"] == .fail && !bad.passed)
    }
    @Test func cardsContradictedByTheReplyFailConsistency() throws {
        let example = try #require(AgentEvalSuite.cases.first { $0.id == "show-black" })
        var seen = AgentEvalObservation(); seen.cards = ["Black blazer"]; seen.toolCalls = ["showRecords"]
        seen.reply = "I couldn’t find any black pieces."
        #expect(AgentEvalScorer.score(example, observation: seen, catalog: catalog).checks["consistent"] == .fail)
        seen.reply = "Here are 1 black piece."
        #expect(AgentEvalScorer.score(example, observation: seen, catalog: catalog).checks["consistent"] == .pass)
    }
    @Test func appAssistedCallsCountAndNoToolCasesFailOnAnyCall() throws {
        let scope = try #require(AgentEvalSuite.cases.first { $0.id == "scope-capital" })
        var seen = AgentEvalObservation(); seen.reply = "That is outside what I do."
        #expect(AgentEvalScorer.score(scope, observation: seen, catalog: catalog).checks["tool"] == .pass)
        seen.toolCalls = ["findRecords"]
        #expect(AgentEvalScorer.score(scope, observation: seen, catalog: catalog).checks["tool"] == .fail)
        let trip = try #require(AgentEvalSuite.cases.first { $0.id == "trip-boracay" })
        seen.toolCalls = ["proposeTrip (app)"]; seen.proposals = ["trip"]; seen.reply = "Here are your days."
        #expect(AgentEvalScorer.score(trip, observation: seen, catalog: catalog).checks["tool"] == .pass)
    }
    @Test func observationsSavedByEarlierBuildsStillDecode() throws {
        let old = #"{"reply":"Hi","toolCalls":["findRecords"],"proposals":[],"question":false,"cards":[],"rejections":[],"elapsedSeconds":2.5}"#
        let value = try JSONDecoder().decode(AgentEvalObservation.self, from: Data(old.utf8))
        #expect(value.reply == "Hi" && value.toolCalls == ["findRecords"] && value.proposalNames.isEmpty && value.intentSource == nil)
    }
    @Test func reportSummarizesPerCheckRatesAndSkipsNotApplicable() throws {
        let example = try #require(AgentEvalSuite.cases.first { $0.id == "chat-hi" })
        var seen = AgentEvalObservation(); seen.reply = "Hello!"
        let report = AgentEvalReport(label: "t", cases: [AgentEvalScorer.score(example, observation: seen, catalog: catalog)])
        #expect(report.summary["noInvented"] == AgentEvalRate(passed: 1, total: 1))
        #expect(report.summary["cards"]?.total == 0)
        #expect(report.markdown.contains("not measured"))
        let data = try JSONEncoder().encode(report)
        #expect(try JSONDecoder().decode(AgentEvalReport.self, from: data).cases.count == 1)
    }
}

struct AgentGroundingRepairTests {
    let catalog = AgentGroundingCheckTests.catalog
    @Test func repairPromptNamesTheProblemsAndOnlyRealNames() {
        let parts = AgentGroundingRepair.prompt(request: "What goes with my blazer?", previousReply: "Try the **Linen top** (p3).", violations: [.invented("Linen top"), .leak("p3")], catalog: catalog, cardsShown: 0)
        let text = parts.render()
        #expect(text.contains("Linen top") && text.contains("internal codes") && text.contains("Black blazer") && text.contains("user: What goes with my blazer?"))
    }
    @Test func contradictionsAndCountsAreExplained() {
        let text = AgentGroundingRepair.prompt(request: "Show black", previousReply: "none", violations: [.contradiction("couldn’t find"), .count("12 outfits")], catalog: AgentNameCatalog(), cardsShown: 9).render()
        #expect(text.contains("showing 9 matching cards") && text.contains("12 outfits") && text.contains("Name no specific pieces"))
    }
    @Test func denyingResultsWhileCardsShowIsAViolationOnlyWhenCardsShow() {
        let check = AgentGroundingCheck(catalog: catalog)
        #expect(check.violations(in: "I couldn’t find any black pieces.", hasCards: true) == [.contradiction("couldn’t find")])
        #expect(check.violations(in: "I couldn’t find any black pieces.").isEmpty)
    }
}

struct AgentCompletionClaimTests {
    let check = AgentGroundingCheck(catalog: AgentGroundingCheckTests.catalog)
    @Test func sayingAChangeWasMadeIsFlaggedOnlyWhenChangesAreForbidden() {
        for claim in ["I’ve renamed the Office day outfit.", "I renamed it for you.", "The outfit has been saved.", "Done, I have updated your profile.", "All set!", "We've marked it as laundry.", "The Slow Sunday outfit is now labeled Lazy morning."] {
            #expect(check.violations(in: claim, forbidCompletionClaims: true).contains { $0.isFalseClaim }, "\(claim)")
            #expect(check.violations(in: claim).isEmpty, "\(claim)")
        }
    }
    @Test func preparingAReviewIsNotAClaimOfCompletion() {
        for fine in ["I prepared a review. Nothing is saved until you save it.", "Review is ready: tap Review and save.", "I can rename it once you confirm.", "It will be saved when you tap Save.", "An outfit named Beach walk is ready to review."] {
            #expect(check.violations(in: fine, forbidCompletionClaims: true).isEmpty, "\(fine)")
        }
    }
}

struct AgentGroundingScopeTests {
    let check = AgentGroundingCheck(catalog: AgentGroundingCheckTests.catalog)
    @Test func headingsDaysDatesAndOptionsAreNotNameClaims() {
        #expect(check.violations(in: "**Arrival** is easy.\n**Saturday – Relaxed vibe**\n**Daily highlights**\n- Extend to 31 October").isEmpty)
        #expect(check.violations(in: "How long is the trip?\n1. One week\n2. Three days\n3. A Red Tunic").isEmpty)
    }
    @Test func titleCaseNamesAndGarmentNamesAreHeldToTheCloset() {
        #expect(check.violations(in: "Try **Beach Vibes** today.") == [.invented("Beach Vibes")])
        #expect(check.violations(in: "Try the **Linen top** today.") == [.invented("Linen top")])
        #expect(check.violations(in: "Try **Beach** today.").isEmpty)
    }
    @Test func aProposedNameIsTheAgentsOwnSuggestion() {
        var catalog = AgentGroundingCheckTests.catalog
        catalog.proposed = ["Beach Vibes"]
        #expect(AgentGroundingCheck(catalog: catalog).violations(in: "Here is a theme: **Beach Vibes**.").isEmpty)
    }
}
