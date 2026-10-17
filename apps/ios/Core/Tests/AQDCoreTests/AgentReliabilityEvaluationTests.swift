import Foundation
import Testing
@testable import AQDCore

struct AgentReliabilityEvaluationTests {
    @Test func versionedSyntheticContextSuiteProducesAnHonestScorecard() throws {
        struct Result: Codable { let id: String; let issues: [String]; let included: Int; let omitted: Int; let inputCharacters: Int }
        struct Report: Codable { let suiteVersion: String; let promptVersion: String; let scope: String; let liveModelEvaluated: Bool; let passed: Int; let total: Int; let results: [Result] }
        var results: [Result] = []
        for example in AgentEvaluationSuite.cases {
            let context = try AgentRetrieval.select(query: example.query, records: example.records, facts: example.facts, maximumCharacters: 1600, maximumRecords: 8)
            var issues = AgentEvaluationSuite.contextIssues(example, result: context)
            if context.text.count > 1600 { issues.append("Context budget exceeded") }
            results.append(Result(id: example.id, issues: issues, included: context.included, omitted: context.omitted, inputCharacters: context.text.count))
            #expect(issues.isEmpty, "\(example.id): \(issues)")
        }
        let report = Report(suiteVersion: AgentEvaluationSuite.version, promptVersion: AgentResponseDiagnostics.currentPromptVersion, scope: "Deterministic synthetic context pipeline only", liveModelEvaluated: false, passed: results.filter { $0.issues.isEmpty }.count, total: results.count, results: results)
        if let path = ProcessInfo.processInfo.environment["AQD_AGENT_EVAL_REPORT"] {
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(report).write(to: URL(fileURLWithPath: path), options: .atomic)
        }
        let fabricated = "I saved your outfit with the red blazer."
        let issues = AgentEvaluationSuite.responseIssues(AgentEvaluationSuite.cases[0], response: fabricated)
        #expect(issues.contains { $0.contains("I saved") } && issues.contains { $0.contains("red blazer") })
    }
}
