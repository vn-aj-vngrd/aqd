import Foundation

/// What the owner is asking for. Decided once per turn by rules, so similar prompts always get the same tools and the same instructions.
public enum AgentIntent: String, Codable, CaseIterable, Sendable {
    case chat, show, find, stats, whatToWear, suggestOutfit, planTrip, planDays, theme, relabel, editPiece, recordWear, profile, addPiece, outOfScope

    /// The tools this intent may call, most relevant first and never more than three so their definitions always fit the window.
    /// `weatherAvailable` adds the weather tool where a forecast changes the answer.
    public func tools(weatherAvailable: Bool) -> [AgentToolName] {
        switch self {
        case .chat, .outOfScope: return []
        case .show: return [.showRecords]
        case .find: return [.findRecords, .showRecords]
        case .stats: return [.wearStats, .findRecords]
        case .whatToWear: return weatherAvailable ? [.suggestOutfit, .weatherFor, .findRecords] : [.suggestOutfit, .findRecords]
        case .suggestOutfit: return weatherAvailable ? [.suggestOutfit, .weatherFor, .findRecords] : [.suggestOutfit, .findRecords, .askUser]
        case .planTrip: return [.proposeTrip, .askUser, .findRecords]
        case .planDays: return weatherAvailable ? [.proposePlan, .weatherFor, .askUser] : [.proposePlan, .askUser, .findRecords]
        case .theme: return [.proposeTheme, .findRecords, .askUser]
        case .relabel: return [.relabel, .askUser]
        case .editPiece: return [.editCloset, .askUser]
        case .recordWear: return [.recordWear, .askUser]
        case .profile: return [.editProfile]
        case .addPiece: return [.addPieceFromPhoto]
        }
    }

    /// Reply length ceiling in tokens: short answers stay short, plans get room.
    public var responseTokens: Int {
        switch self {
        case .planTrip, .planDays: 500
        case .suggestOutfit, .whatToWear, .theme: 400
        default: 300
        }
    }

    /// How much of the closet this intent needs in the prompt.
    public enum ContextNeed: Sendable { case none, light, standard }
    public var contextNeed: ContextNeed {
        switch self {
        case .outOfScope: .none
        case .chat: .light
        default: .standard
        }
    }

    /// Whether the app can answer from records without the model choosing a tool; the model then writes only a one-line framing.
    public var hasFastPath: Bool { [.show, .stats, .whatToWear].contains(self) }
}

/// The model-facing tool names. Mirrors the app's tool list without depending on it.
public enum AgentToolName: String, CaseIterable, Sendable {
    case findRecords, showRecords, wearStats, weatherFor, editCloset, editOutfit, editTheme, editPlan, proposePlan, recordWear, editProfile, addPieceFromPhoto
    case suggestOutfit, proposeOutfit, proposeTheme, relabel, proposeTrip, askUser
}

public extension AgentIntent {
    /// Reads the owner's request. `previous` is the intent of the last reply; `answeringQuestion` is true when the last reply ended in a question card.
    static func classify(_ prompt: String, previous: AgentIntent? = nil, answeringQuestion: Bool = false, hasImage: Bool = false) -> AgentIntent {
        decide(prompt, previous: previous, answeringQuestion: answeringQuestion, hasImage: hasImage).intent
    }

    /// The intent plus whether a specific rule fired. When it did not (a fall-through or a lone keyword), the caller may ask the model to choose.
    static func decide(_ prompt: String, previous: AgentIntent? = nil, answeringQuestion: Bool = false, hasImage: Bool = false) -> (intent: AgentIntent, confident: Bool) {
        let (fresh, sure) = Rules(prompt, hasImage: hasImage).decision
        let words = Rules.normalize(prompt).split(separator: " ").count
        if let previous, previous != .chat, previous != .outOfScope {
            // "Make it dressier" or "Show me a different option" steers the look just suggested.
            if [.suggestOutfit, .whatToWear].contains(previous), Rules.isRefinement(prompt) { return (.suggestOutfit, true) }
            // An answer to the Agent's own question, or a few words with no signal of their own, continues the earlier request.
            if answeringQuestion, fresh == .chat || (fresh == .outOfScope && words < 5) { return (previous, true) }
            if !answeringQuestion, words <= 4, fresh == .chat || fresh == .outOfScope, Rules.isContinuation(prompt) { return (previous, true) }
        }
        return (fresh, sure)
    }

    /// The previous intent and open question of a conversation, for follow-ups.
    static func context(of conversation: AgentConversation) -> (previous: AgentIntent?, answering: Bool) {
        let lastReply = conversation.messages.last { $0.role == .assistant && $0.status == .complete }
        return (lastReply?.diagnostics?.intent.flatMap(AgentIntent.init(rawValue:)), (lastReply?.toolSteps ?? []).contains { $0.question != nil })
    }

    static func decide(_ prompt: String, conversation: AgentConversation, hasImage: Bool = false) -> (intent: AgentIntent, confident: Bool) {
        let context = context(of: conversation)
        return decide(prompt, previous: context.previous, answeringQuestion: context.answering, hasImage: hasImage)
    }

    static func classify(_ prompt: String, conversation: AgentConversation, hasImage: Bool = false) -> AgentIntent {
        decide(prompt, conversation: conversation, hasImage: hasImage).intent
    }
}

/// Phrase tables and the ordered rules behind `AgentIntent.classify`.
struct Rules {
    let text: String
    let padded: String
    let hasImage: Bool

    init(_ prompt: String, hasImage: Bool) {
        text = Self.normalize(Self.withoutPoliteness(prompt)); padded = " " + text + " "; self.hasImage = hasImage
    }

    /// "Can you show my skirts" asks for the same thing as "Show my skirts".
    static func withoutPoliteness(_ prompt: String) -> String {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: #"(?i)^(?:(?:hey|hi|hello|ok|okay)[,!]?\s+)?(?:please\s+)?(?:(?:can|could|would|will)\s+you\s+(?:please\s+)?|i(?:'|’)?d\s+like\s+you\s+to\s+|i\s+(?:need|want)\s+you\s+to\s+)"#, with: "", options: .regularExpression)
    }

    static func normalize(_ value: String) -> String {
        var flat = value.lowercased().replacingOccurrences(of: "’", with: "'")
        // "Where's my cardigan" reads as "where is my cardigan".
        for word in ["where", "what", "who", "how", "that", "there", "here"] { flat = flat.replacingOccurrences(of: word + "'s ", with: word + " is ") }
        flat = flat.replacingOccurrences(of: "'", with: "")
        return flat.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: " ")
    }
    static func isContinuation(_ prompt: String) -> Bool {
        let text = normalize(prompt)
        return text.range(of: #"^(\d+|one|two|three|four|five|six|seven)( days?| nights?)?$"#, options: .regularExpression) != nil
            || ["yes", "no", "yeah", "sure", "ok", "okay", "please", "go ahead", "you choose", "you choose for me", "any", "either", "surprise me", "the first one", "the second one", "first", "second", "both", "none"].contains(text)
    }

    static func isRefinement(_ prompt: String) -> Bool {
        normalize(prompt).range(of: #"^(make it|make this|swap|add a|use a different|try another|another|show me a different|something (more|less)|a different|change the)\b"#, options: .regularExpression) != nil
    }

    /// A phrase matches as whole words, with or without a plural s ("plan" finds "plans").
    func has(_ phrases: [String]) -> Bool { phrases.contains { padded.contains(" " + $0 + " ") || padded.contains(" " + $0 + "s ") } }
    func starts(_ phrases: [String]) -> Bool { phrases.contains { text == $0 || text.hasPrefix($0 + " ") } }
    func matches(_ pattern: String) -> Bool { text.range(of: pattern, options: .regularExpression) != nil }

    static let closetWords = ["wear", "wearing", "worn", "wore", "outfit", "outfits", "clothes", "clothing", "closet", "wardrobe", "piece", "pieces", "dress", "dresses", "shirt", "shirts", "top", "tops",
        "blouse", "tee", "pants", "trousers", "jeans", "skirt", "skirts", "shorts", "shoes", "sneakers", "sandals", "heels", "boots", "flats", "jacket", "coat", "blazer", "cardigan", "bag", "bags",
        "accessories", "accessory", "jewelry", "style", "look", "looks", "theme", "themes", "laundry", "color", "colour", "swimsuit", "bikini", "hat", "scarf", "belt", "sweater", "layer", "layers",
        "fashion", "unworn", "trip", "pack", "packing", "plan", "planner", "wedding", "brunch", "date", "dinner", "party", "rain", "rainy", "umbrella", "weather", "cold", "warm", "hot", "profile", "bio", "caption", "photo",
        "cozy", "comfy", "comfortable", "elegant", "chic", "fancy", "dressy", "sporty", "minimal", "classic", "black", "white", "blue", "navy", "red", "green", "olive", "yellow", "orange", "pink", "purple", "brown", "tan", "beige", "cream", "ivory", "grey", "gray", "sage", "coral", "burgundy",
        "tomorrow", "tonight", "things", "stuff", "interview", "errands", "weekend", "evening", "morning", "afternoon", "office", "meeting", "boss", "lunch", "chilly", "picnic", "gallery", "opening", "outing", "holiday", "party", "occasion", "mood", "favorite", "denim", "linen", "cotton", "silk", "wool", "leather", "brand", "size", "season", "tote", "clutch", "necklace", "earrings", "watch", "sunglasses", "hoodie", "trench", "gold", "jewellery", "formal", "casual", "work"]
    static let stats = ["how many", "how often", "how much", "most worn", "least worn", "never worn", "unworn", "rediscover", "worn most", "wear most", "wear least", "wear the most", "wear the least", "wear stats", "wear history", "statistics", "stats", "haven t worn", "havent worn", "not worn"]

    /// The intent and whether a specific rule fired. A fall-through or a lone keyword is not confident, and the app may ask the model to decide.
    var decision: (intent: AgentIntent, confident: Bool) {
        if text.isEmpty { return (.chat, false) }
        let size = text.split(separator: " ").count
        let asksQuestion = starts(["how", "what", "when", "which", "why", "did", "do", "does", "have", "has", "tell", "can", "could"])
        // 1. Greetings and questions about the Agent itself.
        if starts(["hi", "hello", "hey", "yo", "hiya", "good morning", "good afternoon", "good evening", "thanks", "thank you", "thx", "ok", "okay", "cool", "great", "nice", "bye", "goodbye"]) && size <= 4 { return (.chat, true) }
        if matches(#"^(what can you (do|help)|who are you|how do you work|what are you|help( me)?$|what do you do|what can i ask|what (kinds|sorts|types) of things can (i|you))"#) || has(["what can you help me with", "what can you do"]) { return (.chat, true) }
        // 2. Photos the owner attached to add to the closet.
        if hasImage && (has(["add", "save", "new piece", "closet"]) || size <= 3) { return (.addPiece, true) }
        if matches(#"\badd (this|that|these|a|an)\b.*\b(piece|item|photo|picture|closet)\b"#) || has(["add to my closet", "add it to my closet", "add this to my closet"]) { return (.addPiece, true) }
        // 3. Profile.
        if has(["profile", "bio", "caption"]) && has(["change", "set", "update", "edit", "make", "my"]) && !has(["theme", "outfit"]) { return (.profile, true) }
        if matches(#"\b(change|update|set) my name\b"#) { return (.profile, true) }
        // 4. Recording what was worn (a statement or a log request, not a question about history).
        if matches(#"\b(log|record|mark|note|save|add)\b.*\b(wore|worn|wearing|wear)\b"#) || matches(#"^(i|we) (just )?(wore|wear|am wearing|put on|have on|threw on)\b"#) || matches(#"^im (just )?wearing\b"#) || (has(["i wore"]) && !asksQuestion) || has(["log my outfit", "log what i wore", "record what i wore", "record my outfit"]) { return (.recordWear, true) }
        // 5. Changes to existing records.
        let editVerb = has(["rename", "relabel", "retitle", "call it", "call this", "change", "edit", "update", "set", "mark", "swap", "replace", "switch", "turn", "put", "move", "flag"])
        if editVerb {
            if has(["rename", "relabel", "retitle"]) || has(["occasion", "mood"]) || matches(#"\b(change|set|update|edit) the (name|title|occasion|mood|description)\b"#) {
                if has(["outfit", "look", "theme", "plan", "collection", "occasion", "mood"]) { return (.relabel, true) }
                if has(["piece", "tee", "shirt", "dress", "top", "blazer", "jeans", "trousers", "sneakers", "coat", "jacket", "skirt", "shoes", "sandals", "blouse", "cardigan", "bag"]) || has(["rename"]) { return (.editPiece, true) }
            }
            if has(["laundry", "unavailable", "available", "color", "colour", "brand"]) && !has(["trip", "plan my", "show", "list"]) { return (.editPiece, true) }
            if matches(#"\b(change|set|update|edit) the (name|title) (of|for)\b"#) { return (.relabel, true) }
        }
        // 6. Themes.
        if has(["theme", "themes", "collection", "collections"]) {
            if has(["show", "list", "see", "display", "view", "browse", "what", "which", "how many", "rundown", "overview", "give me", "pull up", "bring up"]) && !has(["make", "create", "build", "new"]) { return (has(["how many"]) ? .stats : .show, true) }
            return (.theme, true)
        }
        // 7. Trips.
        if has(["trip", "vacation", "holiday", "getaway", "itinerary", "honeymoon", "staycation", "travelling", "traveling", "travel", "pack", "packing", "flying", "weekend away", "going away", "road trip", "going to", "heading to", "flying to", "visiting", "off to"]) || matches(#"\b(\d+|one|two|three|four|five|six|seven) ?-?(day|days|night|nights)\b.*\b(in|to|at)\b"#) || matches(#"\b(a|one|1) ?-?(week|weekend|fortnight)\b.*\b(in|to|at)\b"#)
            || (matches(#"\b(\d+|one|two|three|four|five|six|seven) ?-?(day|days|night|nights)\b"#) && matches(#"\b(outfits?|pack|packing|bring|take)\b"#) && !has(["plan my", "next", "coming"])) { return (.planTrip, true) }
        // 8. Planning several days.
        if has(["plan", "schedule", "prepare"]) && (has(["week", "days", "month", "weekend", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday", "next few days", "rest of the week", "outfits"]) || matches(#"\b\d+ days?\b"#)) { return (.planDays, true) }
        if matches(#"\boutfits? for (the )?(next|coming|upcoming) \d* ?days?\b"#) || has(["outfits for the week", "week of outfits"]) { return (.planDays, true) }
        // 9. Counts and history.
        if has(Self.stats) || matches(#"\bwhat did i wear\b"#) || matches(#"\b(worn|wearing|wear|wore)\b.*\b(most|least|often|rarely)\b"#) || matches(#"\b(most|least)\b.*\b(worn|wearing)\b"#) || matches(#"\b(wear|worn|wearing|wore)\b.*\b(never|seldom)\b|\b(never|seldom)\b.*\b(wear|worn|wearing|wore)\b"#) || matches(#"\b(havent|have not|hasnt|didnt|did not)\b.*\b(worn|wear)\b"#) || matches(#"\bhow many (times|outfits|pieces|themes|plans|items|clothes|tops|dresses|shoes)\b"#) { return (.stats, true) }
        // 10. Today's look.
        if matches(#"\b(what|which)( should i| to| do i| can i)? (wear|put on|throw on) (today|tomorrow|tonight|this evening|this morning|now)\b"#) || matches(#"\bwhat (am i|are we) wearing (today|tomorrow|tonight)\b"#) || matches(#"\b(outfit|look|ideas?)\b.*\b(for|this) (today|tonight|tomorrow|this evening|this morning|evening|morning)\b"#) || has(["tonights look", "todays look", "outfit for today", "outfit for tonight", "outfit for tomorrow", "look for today", "look for tonight", "look tonight", "look today", "look tomorrow"]) { return (.whatToWear, true) }
        // 11. Not about clothes at all.
        if !has(Self.closetWords) && (size >= 3 || matches(#"^(write|code|translate|solve|calculate|compute|book|order|buy|email)\b"#)) { return (.outOfScope, false) }
        if has(["rain", "umbrella", "forecast", "weather"]) { return (.whatToWear, false) }
        // 12. Suggesting an outfit.
        if has(["suggest", "recommend", "put together", "pair", "style", "goes with", "go with", "match", "dress me", "help me dress", "help me choose", "help me pick", "surprise me"]) || matches(#"^(something|anything)\b.*\b(to wear|for)\b"#) || matches(#"\bdress for\b"#) || matches(#"\b(what|which)( should| can| do) i (wear|put on|throw on)\b"#) || matches(#"\b(pick|choose|select|find me)( me)?( an?| the)? (look|outfit)\b"#) || matches(#"\b(what|which)( should i| to| can i)? wear (to|for|with|on|at)\b"#)
            || matches(#"\b(need|want|make|create|build|give) (me )?(an? )?(\w+ ){0,2}(outfit|look)\b"#) || matches(#"\boutfit (for|with|to)\b"#) || has(["what should i wear", "what to wear", "something to wear", "dress me", "inspire me", "ideas for"]) { return (.suggestOutfit, true) }
        // 13. Seeing and finding records. "Do I own a coat?" is a question to answer; "What do I own in blue?" is a list to show.
        if starts(["find", "search", "look for", "locate"]) || matches(#"^(do|does) (i|my closet) (own|have|got)\b"#) || matches(#"^(where|which of my)\b"#) || matches(#"^(is|are) there (any|anything)\b"#) || matches(#"^(is|are) (my|the)\b.*\b(closet|wardrobe)\b"#) || matches(#"^(any chance|by any chance|am i missing|did i (buy|get))\b"#)
            || has(["tell me about", "details of", "details on", "describe"]) { return (.find, true) }
        if has(["show", "list", "display", "see", "view", "browse", "preview", "give me", "bring up", "pull up", "open", "look at", "rundown", "overview", "pull out"]) || matches(#"^(which|what)\b.*\b(do i have|i have|do i own|i own|are available|available)\b"#)
            || matches(#"^(which|what)\b.*\b(are|is) in\b"#) || matches(#"^(all|every) (my|of my)\b"#) { return (.show, true) }
        if has(["do i own", "do i have", "do i got", "i own"]) { return (.find, true) }
        return (.chat, false)
    }

    var intent: AgentIntent { decision.intent }
}
