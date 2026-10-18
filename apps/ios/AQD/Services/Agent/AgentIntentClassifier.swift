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
    outOfScope: not about the closet, clothes or style, such as questions about people, places, facts, math, code, recipes, news or money
    """

    static let domainInstructions = """
    Decide whether a request belongs to a personal wardrobe assistant. Answer yes if it is about clothes, outfits, the closet, style, laundry, \
    wearing or packing clothes, trips or plans for clothes, the assistant itself, or is a greeting or thanks. Answer no for anything else, such as \
    questions about people, places, facts, news, money, math, code, recipes or health.
    """

    /// First asks whether the request is about the wardrobe at all, which a small model answers reliably, then which intent it is.
    /// `rule` is what the rules guessed. Only a guess of outOfScope (no clothing word at all) may be confirmed as outside the Agent;
    /// otherwise the request has a clothing word and the model only picks which wardrobe intent it is.
    static func classify(_ request: String, rule: AgentIntent, previous: AgentIntent?) async -> AgentIntent? {
        #if canImport(FoundationModels)
        guard #available(iOS 26, *), SystemLanguageModel.default.availability == .available, SystemLanguageModel.default.supportsLocale() else { return nil }
        let text = String(request.prefix(300))
        if rule == .outOfScope {
            guard let domain = await choose(domainInstructions, "Request: " + text, from: ["yes", "no"]) else { return nil }
            if domain == "no" { return .outOfScope }
        }
        let prompt = (previous.map { "The previous request was \($0.rawValue).\n" } ?? "") + "Request: " + text
        let name = await choose(instructions, prompt, from: AgentIntent.allCases.filter { $0 != .outOfScope }.map(\.rawValue))
        return name.flatMap(AgentIntent.init(rawValue:))
        #else
        return nil
        #endif
    }

    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private static func choose(_ instructions: String, _ prompt: String, from choices: [String]) async -> String? {
        let options = DynamicGenerationSchema(name: "Choice", description: "One of the allowed answers", anyOf: choices)
        guard let schema = try? GenerationSchema(root: options, dependencies: []) else { return nil }
        let session = LanguageModelSession(instructions: instructions)
        return try? await withThrowingTaskGroup(of: String.self) { group in
            group.addTask { try await session.respond(to: prompt, schema: schema, options: GenerationOptions(maximumResponseTokens: 12)).content.value(String.self) }
            group.addTask { try await Task.sleep(for: .seconds(6)); throw CancellationError() }
            defer { group.cancelAll() }
            return try await group.next() ?? ""
        }
    }
    #endif
}
