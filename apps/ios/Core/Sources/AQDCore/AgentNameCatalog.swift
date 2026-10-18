import Foundation

/// Text rules shared by name resolution and the grounding check: case, accents and punctuation never decide whether two names match.
public enum AgentText {
    /// Lowercase, accents folded, every run of punctuation or spaces becomes one space.
    public static func normalize(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// Words of a normalized text with a trailing plural "s" removed ("trousers" and "trouser" compare equal; "dress" stays).
    public static func stems(_ value: String) -> [String] {
        normalize(value).split(separator: " ").map { word in
            let word = String(word)
            return word.count > 3 && word.hasSuffix("s") && !word.hasSuffix("ss") ? String(word.dropLast()) : word
        }
    }

    /// Words that carry no identity in a piece name.
    static let fillers: Set<String> = ["the", "a", "an", "your", "my", "this", "that", "these", "those", "some", "with", "and", "of", "in", "for", "to", "on", "or", "it", "its"]
}

/// The names and trusted totals a reply may refer to. The Agent builds one per turn from the owner's records.
public struct AgentNameCatalog: Equatable, Sendable {
    public struct Piece: Equatable, Sendable {
        public let name: String
        public let color: String
        public let category: String
        public init(name: String, color: String = "", category: String = "") { self.name = name; self.color = color; self.category = category }
    }
    public var pieces: [Piece]
    public var outfits: [String]
    public var themes: [String]
    public var plans: [String]
    /// Counts the owner's closet really has, by noun ("pieces", "outfits", "themes", "plans", "wears", and category plurals such as "tops").
    public var counts: [String: Set<Int>]
    public init(pieces: [Piece] = [], outfits: [String] = [], themes: [String] = [], plans: [String] = [], counts: [String: Set<Int>] = [:]) {
        self.pieces = pieces; self.outfits = outfits; self.themes = themes; self.plans = plans; self.counts = counts
    }
    public var allNames: [String] { pieces.map(\.name) + outfits + themes + plans }
}

/// A problem found in a finished reply.
public enum AgentGroundingViolation: Equatable, Hashable, Sendable {
    /// A name the reply presents as the owner's that matches no record.
    case invented(String)
    /// A handle, UUID or revision the owner should never see.
    case leak(String)
    /// A number about the closet that disagrees with the trusted totals.
    case count(String)

    public var label: String {
        switch self { case .invented(let v): "invented: " + v; case .leak(let v): "leak: " + v; case .count(let v): "count: " + v }
    }
    public var isInvention: Bool { if case .invented = self { true } else { false } }
    public var isLeak: Bool { if case .leak = self { true } else { false } }
    public var isCount: Bool { if case .count = self { true } else { false } }
}

/// Checks a finished reply against the owner's records: names in bold, lists or quotes must exist, a colour and garment must exist together,
/// counts must match the trusted totals, and no handle, UUID or revision may show.
public struct AgentGroundingCheck: Sendable {
    public let catalog: AgentNameCatalog
    private let known: [(key: String, stems: [String])]

    public init(catalog: AgentNameCatalog) {
        self.catalog = catalog
        known = catalog.allNames.map { (AgentText.normalize($0), AgentText.stems($0)) }.filter { !$0.0.isEmpty }
    }

    static let colors: Set<String> = ["black", "white", "blue", "navy", "red", "green", "olive", "yellow", "orange", "pink", "purple", "brown", "tan", "beige", "cream", "ivory", "grey", "gray",
                                      "maroon", "burgundy", "khaki", "gold", "silver", "charcoal", "sage", "blush", "lilac", "coral", "camel", "indigo", "wine", "champagne", "sand", "oatmeal", "lavender", "teal", "mint"]
    /// Garment words grouped by what they are, so "white shirt" can stand for a white tee but not a white skirt.
    static let groups: [String: String] = {
        let table: [String: [String]] = [
            "top": ["top", "tee", "shirt", "t", "blouse", "tank", "cami", "crop", "knit", "sweater", "jumper", "bikini", "tshirt", "polo"],
            "bottom": ["pant", "trouser", "jean", "short", "skirt", "legging", "denim"],
            "dress": ["dress", "gown", "swimsuit", "onepiece", "jumpsuit", "romper"],
            "layer": ["blazer", "jacket", "coat", "cardigan", "trench", "hoodie", "vest"],
            "shoe": ["sneaker", "shoe", "heel", "boot", "sandal", "flat", "slide", "loafer", "pump"],
            "bag": ["bag", "clutch", "tote", "crossbody", "backpack", "purse"],
            "jewelry": ["earring", "hoop", "necklace", "watch", "bracelet", "ring"],
            "hat": ["hat", "cap"], "glasses": ["sunglass", "glass"], "belt": ["belt"], "scarf": ["scarf"]
        ]
        return Dictionary(uniqueKeysWithValues: table.flatMap { group, words in words.map { ($0, group) } })
    }()
    static let generic: Set<String> = ["casual", "formal", "light", "dark", "bright", "neutral", "comfortable", "cozy", "warm", "cool", "extra", "simple", "classic", "little", "pair", "layer", "outfit", "look", "piece",
                                       "item", "option", "idea", "tip", "note", "why", "work", "weekend", "evening", "morning", "night", "day", "beach", "trip", "travel", "dinner", "brunch", "event", "party",
                                       "swap", "alternative", "bonus", "top", "bottom", "shoe", "accessory", "accessories", "pattern", "stripe", "floral", "gingham", "denim"]
    static let headings: Set<String> = ["tip", "tips", "note", "notes", "why", "why it work", "the look", "look", "outfit", "option", "options", "idea", "ideas", "summary", "plan", "today", "tomorrow", "morning",
                                        "afternoon", "evening", "night", "bonus", "alternative", "swap", "pro tip", "quick tip", "next step", "next steps", "for you", "your look", "suggestion", "suggestions", "recommendation"]

    private static func regex(_ pattern: String) -> NSRegularExpression? { try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) }
    private static let uuidPattern = regex("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")
    private static let handlePattern = regex(#"(?<![A-Za-z0-9])(?:pl|p|o|t)\d{1,3}(?![A-Za-z0-9])"#)
    private static let revisionPattern = regex(#"\brevision\s*[:=]?\s*\d+"#)
    private static let boldPattern = regex(#"\*\*(.+?)\*\*"#)
    private static let quotePattern = regex(#"[“"]([^”"\n]{2,60})[”"]"#)
    private static let listPattern = try? NSRegularExpression(pattern: #"(?m)^\s*(?:[-*•]|\d+[.)])\s+(.+)$"#)
    private static let countPattern = regex(#"(\d+)\s+(?:(?:active|saved|available|total|recorded|different|unworn|worn|new|favorite|planned)\s+)*(pieces?|items?|garments?|outfits?|looks?|themes?|plans?|tops?|bottoms?|dresses|layers?|shoes?|accessor(?:y|ies))\b"#)
    private static let wearPattern = regex(#"(?:worn|wore|wear(?:s|ing)?)\s+(?:it\s+|them\s+)?(\d+)\s+times?|(\d+)\s+(?:recorded\s+)?(?:wears|times)\b"#)

    private func matches(_ pattern: NSRegularExpression?, in text: String, group: Int = 0) -> [String] {
        guard let pattern else { return [] }
        return pattern.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { Range($0.range(at: group), in: text).map { String(text[$0]) } }
    }

    public func violations(in reply: String) -> [AgentGroundingViolation] {
        var found: [AgentGroundingViolation] = []
        func add(_ value: AgentGroundingViolation) { if !found.contains(value) { found.append(value) } }
        for value in matches(Self.uuidPattern, in: reply) + matches(Self.handlePattern, in: reply) + matches(Self.revisionPattern, in: reply) { add(.leak(value)) }
        for span in claims(in: reply) where !isGrounded(span) { add(.invented(span)) }
        for pair in uncoveredColorGarments(in: reply) { add(.invented(pair)) }
        for value in unmatchedCounts(in: reply) { add(.count(value)) }
        return found
    }

    /// Spans the reply presents as names: bold, list entries and quotes of at most six words.
    func claims(in reply: String) -> [String] {
        var spans: [String] = []
        spans += matches(Self.boldPattern, in: reply, group: 1)
        spans += matches(Self.quotePattern, in: reply, group: 1)
        for item in matches(Self.listPattern, in: reply, group: 1) {
            var text = item.replacingOccurrences(of: "**", with: "")
            for separator in [" - ", " – ", " — ", ":", " (", ","] { if let range = text.range(of: separator) { text = String(text[..<range.lowerBound]) } }
            spans.append(text)
        }
        var seen = Set<String>()
        return spans.map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)) }.filter { span in
            let words = span.split(separator: " ").count
            return !span.isEmpty && words <= 6 && seen.insert(AgentText.normalize(span)).inserted
        }
    }

    func isGrounded(_ span: String) -> Bool {
        let key = AgentText.normalize(span)
        guard !key.isEmpty else { return true }
        if Self.headings.contains(key) || key.range(of: #"^(day|option|step|look|outfit)\s+\d+"#, options: .regularExpression) != nil { return true }
        if span.hasSuffix(":") { return true }
        let stems = AgentText.stems(span).filter { !AgentText.fillers.contains($0) }
        guard !stems.isEmpty else { return true }
        let padded = " " + stems.joined(separator: " ") + " "
        for name in known {
            let nameKey = name.stems.joined(separator: " ")
            if nameKey == stems.joined(separator: " ") { return true }
            if nameKey.count >= 3, padded.contains(" " + nameKey + " ") { return true }
            // A trimmed name such as "Cream blouse" for "Cream poplin blouse".
            if stems.count >= 2, Set(stems).isSubset(of: Set(name.stems)) { return true }
        }
        // Wholly generic words ("a white top", "extra layer") are not names; only a colour with a garment is checked.
        if stems.allSatisfy({ Self.colors.contains($0) || Self.groups[$0] != nil || Self.generic.contains($0) }) {
            return uncoveredColorGarments(in: span).isEmpty
        }
        return false
    }

    /// "red blazer" is invented when no red layer exists, even outside bold or lists.
    func uncoveredColorGarments(in text: String) -> [String] {
        let words = AgentText.stems(text)
        var missing: [String] = []
        for (index, word) in words.enumerated() where Self.colors.contains(word) {
            for next in (index + 1)..<min(words.count, index + 4) {
                if Self.colors.contains(words[next]) { break }
                guard let group = Self.groups[words[next]] else { continue }
                let exists = catalog.pieces.contains { piece in
                    let stems = Set(AgentText.stems(piece.name + " " + piece.color))
                    return stems.contains(word) && stems.contains { Self.groups[$0] == group || (group == "top" && piece.category.lowercased().hasPrefix("top")) }
                }
                if !exists {
                    let phrase = words[index...next].joined(separator: " ")
                    if !missing.contains(phrase) { missing.append(phrase) }
                }
                break
            }
        }
        return missing
    }

    private func nounKey(_ noun: String) -> String {
        let value = AgentText.stems(noun).first ?? noun.lowercased()
        switch value {
        case "piece", "item", "garment": return "pieces"
        case "outfit", "look": return "outfits"
        case "theme": return "themes"
        case "plan": return "plans"
        case "top": return "tops"
        case "bottom": return "bottoms"
        case "dress", "dresse": return "dresses"
        case "layer": return "layers"
        case "shoe": return "shoes"
        default: return "accessories"
        }
    }

    func unmatchedCounts(in text: String) -> [String] {
        var bad: [String] = []
        if let pattern = Self.countPattern {
            for match in pattern.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                guard let whole = Range(match.range, in: text), let numberRange = Range(match.range(at: 1), in: text), let nounRange = Range(match.range(at: 2), in: text),
                      let number = Int(text[numberRange]) else { continue }
                let key = nounKey(String(text[nounRange]))
                guard let allowed = catalog.counts[key], !allowed.isEmpty, !allowed.contains(number) else { continue }
                // Small numbers usually describe an outfit or a plan the reply just made; only claims about the whole closet are strict.
                let lead = String(text[..<whole.lowerBound].suffix(28)).lowercased()
                let aboutCloset = ["you have", "you own", "closet has", "there are", "total", "in your closet", "you've got", "you got"].contains { lead.contains($0) }
                if aboutCloset || number > 8 { bad.append("\(number) \(key)") }
            }
        }
        if let pattern = Self.wearPattern, let allowed = catalog.counts["wears"], !allowed.isEmpty {
            for match in pattern.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                for group in 1...2 {
                    if let range = Range(match.range(at: group), in: text), let number = Int(text[range]), !allowed.contains(number) { bad.append("\(number) wears") }
                }
            }
        }
        return bad
    }
}
