import Foundation
import AQDCore
#if canImport(FoundationModels)
import FoundationModels

/// Asks the owner one question as tappable answers, like a multiple-choice prompt. The owner can still type anything else.
@available(iOS 26, *)
struct AgentAskUserTool: Tool {
    let name = "askUser"
    let description = "Ask the owner ONE short question when something essential is missing, such as how many days, the dates, the occasion or which style. Give 2 to 4 short answers the owner can tap. The app shows them as buttons, so after calling this reply with at most one short sentence and wait. Ask only one question per turn and never ask for IDs or codes."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        @Guide(description: "The question, under 15 words") var question: String
        @Guide(description: "Short tappable answers, each under 6 words", .minimumCount(2), .maximumCount(4)) var options: [String]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result { try handlers.ask(arguments.question, arguments.options) }
    }
}
#endif
