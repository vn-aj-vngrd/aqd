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
    @Generable struct Option {
        @Guide(description: "The answer, under 6 words") var label: String
        @Guide(description: "Optional short reason or trade-off, under 10 words") var detail: String?
    }
    @Generable struct Arguments {
        @Guide(description: "Topic chip such as Trip length or Occasion, under 3 words") var header: String
        @Guide(description: "The question, under 15 words") var question: String
        @Guide(description: "Answers the owner can tap", .minimumCount(2), .maximumCount(4)) var options: [Option]
        @Guide(description: "Label of the answer you suggest, if one is clearly best") var recommended: String?
        @Guide(description: "True only when several answers can apply together") var multiSelect: Bool
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            guard let question = AgentQuestion(prompt: arguments.question, options: arguments.options.map(\.label), header: arguments.header,
                                               details: arguments.options.map { $0.detail ?? "" }, recommended: arguments.recommended,
                                               multiSelect: arguments.multiSelect) else { throw AgentToolRejection.invalidArguments }
            return try handlers.ask(question)
        }
    }
}
#endif
