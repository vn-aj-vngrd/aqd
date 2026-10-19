import Foundation
import Testing
@testable import AQDCore

struct AgentBudgetTests {
    @Test func fixedPartsComeOffTheWindowFirst() {
        let budget = AgentBudget(contextSize: 4096, instructions: 400, tools: 600, response: 300, toolResults: 300, margin: 96)
        #expect(budget.promptTokens == 4096 - 400 - 600 - 300 - 300 - 96)
        #expect(AgentBudget(contextSize: 1000, instructions: 900, tools: 900, response: 300).promptTokens == 0)
    }
    @Test func tiersAreServedInPriorityOrderAndNeverExceedTheRoom() {
        let budget = AgentBudget(contextSize: 4096, instructions: 400, tools: 600, response: 300, toolResults: 300, margin: 96)
        let room = budget.promptTokens
        let plenty = budget.allocate(required: 100, facts: 300, records: 400, history: 200)
        #expect(plenty == AgentBudget.Allocation(facts: 300, records: 400, history: 200, fits: true))
        // Facts first, then records, then history: a tight window starves history before records, and records before facts.
        let tight = budget.allocate(required: room - 500, facts: 300, records: 400, history: 200)
        #expect(tight.facts == 300 && tight.records == 200 && tight.history == 0)
        let tighter = budget.allocate(required: room - 100, facts: 300, records: 400, history: 200)
        #expect(tighter.facts == 100 && tighter.records == 0 && tighter.history == 0)
        #expect(plenty.facts + plenty.records + plenty.history + 100 <= room)
    }
    @Test func aRequestThatCannotFitIsReportedNotTruncated() {
        let budget = AgentBudget(contextSize: 2000, instructions: 800, tools: 700, response: 300)
        #expect(budget.allocate(required: 500, facts: 10, records: 10, history: 10).fits == false)
    }
    @Test func tokenConversionUsesTheMeasuredRatioAndFallsBackToTheEstimate() {
        #expect(AgentBudget(contextSize: 4096, instructions: 0, tools: 0, response: 0).tokens(forCharacters: 300) == 100)
        let measured = AgentBudget(contextSize: 4096, instructions: 0, tools: 0, response: 0, charactersPerToken: 4.0)
        #expect(measured.tokens(forCharacters: 400) == 100 && measured.characters(forTokens: 100) == 400)
        #expect(AgentBudget(contextSize: 4096, instructions: 0, tools: 0, response: 0, charactersPerToken: .nan).charactersPerToken == AgentBudget.estimatedCharactersPerToken)
        let window = AgentBudget(contextSize: 4096, instructions: 1000, tools: 1000, response: 500, margin: 96)
        #expect(window.fits(promptTokens: window.promptTokens) && !window.fits(promptTokens: window.promptTokens + 1))
    }
}

struct AgentConversationMemoryTests {
    private func chat(_ turns: Int) -> [AgentMessage] {
        (1...turns).flatMap { n -> [AgentMessage] in
            [AgentMessage(role: .user, source: "Question number \(n) about outfits", status: .complete),
             AgentMessage(role: .assistant, source: "**Answer \(n)** with the Black blazer and some long text to be trimmed " + String(repeating: "x", count: 600), status: .complete, attemptID: UUID())]
        }
    }
    @Test func lastFourTurnsStayVerbatimAndOlderOnesBecomeASummary() throws {
        let messages = chat(7)
        let memory = AgentConversationMemory.history(messages, characters: 6000)
        #expect(memory.lines.count == 8 && memory.lines.first?.hasPrefix("user: Question number 4") == true)
        let summary = try #require(memory.summary)
        #expect(summary.contains("Question number 1") && summary.contains("Question number 3") && !summary.contains("Question number 4"))
        #expect(AgentConversationMemory.rollingSummary(messages)?.contains("Question number 3") == true)
        #expect(AgentConversationMemory.rollingSummary(chat(4)) == nil)
    }
    @Test func aTightBudgetDropsWholeOldTurnsIntoTheSummaryNeverMidSentence() {
        let memory = AgentConversationMemory.history(chat(4), characters: 1100)
        #expect(memory.lines.count < 8 && memory.lines.count.isMultiple(of: 2))
        #expect(memory.lines.joined(separator: "\n").count + (memory.summary?.count ?? 0) <= 1100)
        #expect(memory.lines.last?.hasPrefix("assistant: Answer 4") == true)
    }
    @Test func unansweredTurnsAndTheRetriedMessageAreLeftOut() {
        var messages = chat(3)
        messages[3].status = .failed
        let retried = messages[1].id
        #expect(AgentConversationMemory.turns(messages).count == 2)
        #expect(AgentConversationMemory.turns(messages, excluding: retried).count == 1)
    }
    @Test func promptPartsRenderInOrderAndShrinkOldestFirst() {
        let parts = AgentPromptParts(context: "Facts", summary: "Earlier", history: ["user: a", "assistant: b", "user: c", "assistant: d"], userTurn: "now", reviews: "Reviews")
        #expect(parts.render() == "Facts\nEarlier\nConversation:\nuser: a\nassistant: b\nuser: c\nassistant: d\nReviews\nuser: now")
        let once = parts.shrunk()
        #expect(once?.history == ["user: c", "assistant: d"])
        #expect(once?.shrunk()?.shrunk()?.summary == nil)
        var last = parts.shrunk(); while let next = last?.shrunk() { last = next }
        #expect(last?.render() == "Facts\nuser: now" && last?.shrunk() == nil)
    }
    @Test func oldConversationsWithoutASummaryStillDecode() throws {
        var conversation = AgentConversation(ownerID: UUID()); conversation.summary = "x"
        var json = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(conversation)) as? [String: Any])
        json["summary"] = nil
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(try JSONDecoder().decode(AgentConversation.self, from: data).summary == nil)
    }
}
