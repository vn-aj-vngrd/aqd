import AQDCore
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Asks the on-device model to choose an intent when no rule is sure. The answer is constrained to the intent names,
/// so it can only be a real intent; any failure or delay leaves the rule's answer in place.
@MainActor enum AgentIntentClassifier {
    static let instructions = """
    Classify the owner's request to a wardrobe assistant. Answer with exactly one intent.
    chat: greeting, thanks or small talk
    show: show pieces, outfits, themes or plans as cards
    find: ask whether they own something, or look something up
    stats: how often or how many, wear history
    whatToWear: what to wear today, tomorrow or tonight, or the weather
    suggestOutfit: recommend or build an outfit for an occasion or mood
    planTrip: pack or plan outfits for a trip
    planDays: plan outfits for the next days or the week
    theme: make a theme or collection
    relabel: rename an outfit or theme, change its occasion or mood
    editPiece: rename a piece, change its color or brand, mark it laundry or unavailable
    recordWear: record what was worn
    profile: change the profile name or bio
    addPiece: add a piece from a photo
    outOfScope: not about the closet, clothes or style
    """

    static func classify(_ request: String, previous: AgentIntent?) async -> AgentIntent? {
        #if canImport(FoundationModels)
        guard #available(iOS 26, *), SystemLanguageModel.default.availability == .available, SystemLanguageModel.default.supportsLocale() else { return nil }
        let choices = DynamicGenerationSchema(name: "Intent", description: "One intent name", anyOf: AgentIntent.allCases.map(\.rawValue))
        guard let schema = try? GenerationSchema(root: choices, dependencies: []) else { return nil }
        let prompt = (previous.map { "The previous request was \($0.rawValue).\n" } ?? "") + "Request: " + String(request.prefix(300))
        let session = LanguageModelSession(instructions: instructions)
        let name = try? await withThrowingTaskGroup(of: String.self) { group in
            group.addTask { try await session.respond(to: prompt, schema: schema, options: GenerationOptions(maximumResponseTokens: 12)).content.value(String.self) }
            group.addTask { try await Task.sleep(for: .seconds(6)); throw CancellationError() }
            defer { group.cancelAll() }
            return try await group.next() ?? ""
        }
        return name.flatMap(AgentIntent.init(rawValue:))
        #else
        return nil
        #endif
    }
}
