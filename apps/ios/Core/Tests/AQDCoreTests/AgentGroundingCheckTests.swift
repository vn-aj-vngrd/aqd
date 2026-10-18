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
