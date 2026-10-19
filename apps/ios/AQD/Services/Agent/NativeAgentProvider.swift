import Foundation
import ImageIO
import AQDCore
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Bounded text-chat defaults. Quality and latency qualification remain issue30.
struct AgentQualification: Sendable {
    let maximumPieces: Int
    let maximumPromptCharacters: Int
    let responseTokens: Int
    let slowSeconds: Double
    let timeoutSeconds: Double
    static let current: AgentQualification? = AgentQualification(maximumPieces: 24, maximumPromptCharacters: 8000, responseTokens: 768, slowSeconds: 8, timeoutSeconds: 60)
    var isValid: Bool { maximumPieces > 0 && maximumPromptCharacters > 0 && responseTokens > 0 && slowSeconds.isFinite && slowSeconds > 0 && timeoutSeconds.isFinite && timeoutSeconds > slowSeconds }
}

enum AgentProviderError: Error {
    case contextLimit, unavailable, guardrail, unsupportedLanguage, preparing, intelligenceOff
    var category: AgentFailureCategory {
        switch self { case .contextLimit: .contextLimit; case .guardrail: .generation; case .unavailable, .unsupportedLanguage, .preparing, .intelligenceOff: .unsupported }
    }
    /// The reason the model cannot answer right now, as the typed error the failed message explains.
    static func forAvailability(_ value: OutfitSuggestionAvailability) -> AgentProviderError {
        switch value {
        case .preparing: .preparing
        case .intelligenceOff: .intelligenceOff
        case .localeUnavailable: .unsupportedLanguage
        case .available, .unsupported, .awaitingQualification: .unavailable
        }
    }
    var message: String {
        switch self {
        case .contextLimit: "This request exceeds the on-device context limit. Start a new conversation with a shorter message or fewer attachments. Your messages, draft and attachments are retained."
        case .guardrail: "The on-device model declined this request. Rephrase it and try again. Your messages and draft are retained."
        case .unsupportedLanguage: "The on-device model doesn’t support this language yet. Try again in a supported language. Your messages and draft are retained."
        case .unavailable: "The on-device model isn’t available. Your messages and draft are retained."
        case .preparing: "Apple Intelligence is still preparing the on-device model. Try again in a few minutes. Your messages and draft are retained."
        case .intelligenceOff: "Apple Intelligence is turned off. Turn it on in Settings to use the Agent. Your messages and draft are retained."
        }
    }
    /// Translates framework generation errors into typed provider errors; anything else passes through.
    static func map(_ error: any Error) -> any Error {
        #if canImport(FoundationModels)
        if #available(iOS 27, *), let value = error as? LanguageModelError {
            switch value {
            case .contextSizeExceeded: return AgentProviderError.contextLimit
            case .guardrailViolation, .refusal: return AgentProviderError.guardrail
            case .unsupportedLanguageOrLocale: return AgentProviderError.unsupportedLanguage
            default: return error
            }
        }
        if #available(iOS 26, *), let value = error as? LanguageModelSession.GenerationError {
            switch value {
            case .exceededContextWindowSize: return AgentProviderError.contextLimit
            case .guardrailViolation, .refusal: return AgentProviderError.guardrail
            case .unsupportedLanguageOrLocale: return AgentProviderError.unsupportedLanguage
            default: break
            }
        }
        #endif
        return error
    }
}

/// Names the provider step that threw so an unclassified model failure can be traced.
struct AgentStageError: Error, CustomStringConvertible {
    let stage: String
    let underlying: any Error
    var description: String { "\(stage): \(underlying)" }
}

@MainActor enum NativeAgentProvider {
    /// Token costs measured from the model in the background. Until a measurement lands, estimates stand in so a turn never waits on counting.
    struct Costs {
        var contextSize = 4096
        var charactersPerToken = AgentBudget.estimatedCharactersPerToken
        var instructions: [String: Int] = [:]
        var tools: [AgentToolID: Int] = [:]
    }
    private(set) static var costs = Costs()
    static let toolEstimate = 240
    /// Reserved for what tool results add to the transcript before the reply.
    static let toolResultTokens = 320

    /// The window for one turn: instructions, the tools offered, the reply and tool results come off the top; the rest is for the prompt.
    static func budget(instructions: String, tools: [AgentToolID], response: Int) -> AgentBudget {
        AgentBudget(contextSize: costs.contextSize, instructions: costs.instructions[instructions] ?? AgentBudget.estimate(instructions.count),
                    tools: tools.reduce(0) { $0 + (costs.tools[$1] ?? toolEstimate) }, response: response, toolResults: tools.isEmpty ? 0 : toolResultTokens,
                    charactersPerToken: costs.charactersPerToken)
    }

    /// Measures the window, every instruction text and every tool once. A failed count leaves the estimate in place.
    static func prime(instructions: [String]) async {
        #if canImport(FoundationModels)
        guard #available(iOS 26.4, *), SystemLanguageModel.default.availability == .available else { return }
        let model = SystemLanguageModel.default
        costs.contextSize = model.contextSize
        for text in instructions where costs.instructions[text] == nil {
            guard let count = try? await model.tokenCount(for: Instructions(text)), count > 0 else { continue }
            costs.instructions[text] = count
            costs.charactersPerToken = min(6, max(1.5, Double(text.count) / Double(count)))
        }
        for id in AgentToolID.allCases where costs.tools[id] == nil {
            if let count = try? await model.tokenCount(for: AgentToolbox.makeTools([id], handlers: .inert)), count > 0 { costs.tools[id] = count }
        }
        #endif
    }

    /// Whether a request fits the context window. `tools` is the measured size of the tool definitions.
    nonisolated static func fits(input: Int, system: Int, tools: Int, response: Int, contextSize: Int, toolResults: Int = 0) -> Bool {
        input + system + tools + response + toolResults + 64 <= contextSize
    }

    static func stream(prompt: String, responseTokens: Int) -> AsyncThrowingStream<String, any Error> {
        streamAttached(parts: AgentPromptParts(context: prompt, userTurn: ""), instructions: AgentInstructions.compose(.chat), responseTokens: responseTokens, attachments: [])
    }

    static func streamAttached(prompt: String, responseTokens: Int, attachments: [AgentAttachment], tools selection: AgentToolSelection? = nil) -> AsyncThrowingStream<String, any Error> {
        streamAttached(parts: AgentPromptParts(context: prompt, userTurn: ""), instructions: AgentInstructions.compose(.chat), responseTokens: responseTokens, attachments: attachments, tools: selection)
    }

    /// Streams a reply. `parts` can shrink: when the measured request does not fit, the oldest history goes first, then the summary.
    static func streamAttached(parts initial: AgentPromptParts, instructions: String, responseTokens: Int, attachments: [AgentAttachment], tools selection: AgentToolSelection? = nil,
                               onShrink: (@MainActor @Sendable (AgentPromptParts) -> Void)? = nil) -> AsyncThrowingStream<String, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                var stage = "check availability"
                do {
                    #if canImport(FoundationModels)
                    if #available(iOS 26, *) {
                        guard SystemLanguageModel.default.availability == .available, SystemLanguageModel.default.supportsLocale() else { throw AgentProviderError.forAvailability(OutfitSuggestions.modelAvailability()) }
                        func prepared(_ text: String) throws -> Prompt {
                            var value = Prompt(text + (attachments.isEmpty ? "" : "\nOnly these images are provided as visible image input in this request: " + attachments.indices.map { "a\($0 + 1)" }.joined(separator: ", ") + ". Other image references supply text only."))
                            if #available(iOS 27, *) {
                                for (offset, attachment) in attachments.enumerated() {
                                    guard let data = attachment.preview, let source = CGImageSourceCreateWithData(data as CFData, nil), let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: attachments.count > 2 ? 384 : 768, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else { throw CocoaError(.fileReadCorruptFile) }
                                    let previous = value
                                    value = Prompt { previous; Attachment(image).label("a\(offset + 1)") }
                                }
                            } else if !attachments.isEmpty {
                                value = Prompt(text + "\nThis runtime cannot inspect image pixels. Only recognized text is available; disclose that limitation when relevant.")
                            }
                            return value
                        }
                        var parts = initial
                        var tools: [any Tool] = selection.map { AgentToolbox.makeTools($0.ids, handlers: $0.handlers) } ?? []
                        if #available(iOS 26.4, *) {
                            let model = SystemLanguageModel.default
                            stage = "count instruction tokens"
                            // Token counting can fail while the model service is unavailable; estimate then and let generation report real limits.
                            let system = (try? await model.tokenCount(for: Instructions(instructions))) ?? instructions.count / 3 + 1
                            var fitted = false
                            while !fitted {
                                stage = "count prompt tokens"
                                let text = parts.render()
                                let input = (try? await model.tokenCount(for: try prepared(text))) ?? text.count / 3 + 1
                                stage = "fit tools"
                                var reserve = 0
                                if let selection {
                                    // Offer as many of the routed tools as fit, most relevant first.
                                    let kept = try await AgentToolbox.fit(selection.ids, measure: { ids in
                                        ids.isEmpty ? 0 : ((try? await model.tokenCount(for: AgentToolbox.makeTools(ids, handlers: selection.handlers))) ?? ids.count * toolEstimate)
                                    }, fits: { fits(input: input, system: system, tools: $0, response: responseTokens, contextSize: model.contextSize, toolResults: toolResultTokens) })
                                    tools = AgentToolbox.makeTools(kept, handlers: selection.handlers)
                                    reserve = kept.isEmpty ? 0 : toolResultTokens
                                }
                                let toolTokens = tools.isEmpty ? 0 : ((try? await model.tokenCount(for: tools)) ?? tools.count * toolEstimate)
                                if fits(input: input, system: system, tools: toolTokens, response: responseTokens, contextSize: model.contextSize, toolResults: reserve) { fitted = true; break }
                                guard let smaller = parts.shrunk() else { throw AgentProviderError.contextLimit }
                                parts = smaller; onShrink?(smaller)
                            }
                        }
                        stage = "generate"
                        let session = LanguageModelSession(tools: tools, instructions: instructions)
                        for try await response in session.streamResponse(to: try prepared(parts.render()), options: GenerationOptions(maximumResponseTokens: responseTokens)) {
                            try Task.checkCancellation(); continuation.yield(response.content)
                        }
                        continuation.finish(); return
                    }
                    #endif
                    throw CocoaError(.featureUnsupported)
                } catch {
                    let mapped = AgentProviderError.map(error)
                    continuation.finish(throwing: mapped is AgentProviderError || mapped is CancellationError ? mapped : AgentStageError(stage: stage, underlying: mapped))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
