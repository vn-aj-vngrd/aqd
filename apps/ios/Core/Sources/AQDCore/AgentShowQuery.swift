import Foundation

/// What a "show me" request asks to see, read from the words alone so the app can answer without the model choosing arguments.
public struct AgentShowQuery: Equatable, Sendable {
    public var kind: AgentRecordKind = .piece
    public var color = ""
    /// A `PieceCategory` name (Tops, Bottoms, Dresses, Layers, Shoes, Accessories) or empty.
    public var category = ""
    /// "available", "laundry" or "unavailable", or empty.
    public var availability = ""
    /// A garment or material word to match in names and tags, such as "sneaker" or "linen".
    public var query = ""

    private static let colors = ["black", "white", "blue", "navy", "red", "green", "olive", "yellow", "orange", "pink", "purple", "brown", "tan", "beige", "cream", "ivory", "grey", "gray", "sage",
                                 "coral", "burgundy", "maroon", "khaki", "gold", "silver", "charcoal", "lilac", "blush", "camel", "indigo", "wine", "sand", "oatmeal"]
    private static let materials = ["linen", "denim", "cotton", "silk", "satin", "wool", "leather", "knit", "suede", "straw", "crepe", "viscose", "velvet"]
    private static let categories: [(String, [String])] = [
        ("Dresses", ["dress", "dresses", "gown", "swimsuit"]), ("Layers", ["layer", "layers", "jacket", "jackets", "coat", "coats", "blazer", "blazers", "cardigan", "cardigans", "trench"]),
        ("Shoes", ["shoe", "shoes", "sneaker", "sneakers", "sandal", "sandals", "heels", "boots", "flats", "slides", "footwear"]),
        ("Bottoms", ["bottom", "bottoms", "pants", "trousers", "jeans", "skirt", "skirts", "shorts"]),
        ("Accessories", ["accessory", "accessories", "jewelry", "jewellery", "bag", "bags", "hat", "hats", "scarf", "scarves", "belt", "belts", "sunglasses", "watch", "earrings", "necklace"]),
        ("Tops", ["top", "tops", "shirt", "shirts", "blouse", "blouses", "tee", "tees", "tank", "tanks", "cami", "camis", "knit", "knits", "sweater", "sweaters"])]
    /// Words that name a whole category and so need no further name filter.
    private static let generic: Set<String> = ["layer", "layers", "shoe", "shoes", "bottom", "bottoms", "accessory", "accessories", "top", "tops", "dress", "dresses", "footwear"]

    public static func parse(_ prompt: String) -> AgentShowQuery {
        var query = AgentShowQuery()
        let words = Set(Rules.normalize(prompt).split(separator: " ").map(String.init))
        if !words.isDisjoint(with: ["theme", "themes", "collection", "collections"]) { query.kind = .theme }
        else if !words.isDisjoint(with: ["plan", "plans", "schedule", "trips"]) { query.kind = .plan }
        else if !words.isDisjoint(with: ["outfit", "outfits", "looks"]) { query.kind = .outfit }
        guard query.kind == .piece else {
            if let material = materials.first(where: words.contains) { query.query = material }
            return query
        }
        query.color = colors.first(where: words.contains) ?? ""
        for (name, list) in categories {
            if let noun = list.first(where: words.contains) {
                query.category = name
                if !generic.contains(noun) { query.query = noun.hasSuffix("s") && noun != "jeans" && noun != "heels" && noun != "sunglasses" ? String(noun.dropLast()) : noun }
                break
            }
        }
        if query.query.isEmpty, let material = materials.first(where: words.contains) { query.query = material }
        if words.contains("unavailable") { query.availability = "unavailable" } else if words.contains("laundry") { query.availability = "laundry" } else if words.contains("available") { query.availability = "available" }
        return query
    }

    /// The occasion a request names: "brunch" in "Suggest an outfit for brunch", "date night" in "something for a date night". Nil when none is named.
    public static func occasion(in prompt: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"\b(?:for|to|at)\s+(?:a\s+|an\s+|the\s+|my\s+)?([A-Za-z][A-Za-z' -]{2,40}?)\s*[.?!]?\s*$"#, options: .caseInsensitive),
              let match = regex.firstMatch(in: prompt, range: NSRange(prompt.startIndex..., in: prompt)), let range = Range(match.range(at: 1), in: prompt) else { return nil }
        let value = String(prompt[range]).trimmingCharacters(in: .whitespaces)
        let ignored: Set<String> = ["me", "today", "tonight", "tomorrow", "it", "this", "that", "wear", "now", "go"]
        return value.isEmpty || ignored.contains(value.lowercased()) ? nil : value
    }

    /// How a prompt refers to a day: 0 for today or tonight, 1 for tomorrow.
    public static func dayOffset(_ prompt: String) -> Int { Rules.normalize(prompt).contains("tomorrow") ? 1 : 0 }
    /// "last month" selects the earlier month; anything else is this month.
    public static func wantsLastMonth(_ prompt: String) -> Bool { Rules.normalize(prompt).contains("last month") }
}

public extension AgentRecordIndex {
    /// Records whose full name appears in the text, longest names first ("Black blazer" before "Black").
    func mentions(in text: String, kinds: [AgentRecordKind] = AgentRecordKind.allCases) -> [Entry] {
        let padded = " " + AgentText.normalize(text) + " "
        return entries.filter { kinds.contains($0.kind) && $0.nameKey.count >= 3 && padded.contains(" " + $0.nameKey + " ") }.sorted { $0.nameKey.count > $1.nameKey.count }
    }
}

public extension AgentRecordIndex {
    private static let searchStops: Set<String> = AgentText.fillers.union(["do", "does", "i", "you", "own", "have", "has", "got", "find", "search", "look", "locate", "show", "list", "tell", "about", "me", "which", "what", "where",
        "is", "are", "any", "piece", "item", "made", "closet", "wardrobe", "there", "describe", "detail", "all", "can", "see", "please", "much", "many"])

    /// Records that match the words of a question about the closet. Records matching every word come first; a partial match is returned only
    /// when nothing matches them all, so "Do I own a trench coat?" never answers with unrelated coats of arms.
    func search(_ text: String, kinds: [AgentRecordKind] = AgentRecordKind.allCases, limit: Int = 8) -> [Entry] {
        let terms = Set(AgentText.stems(text).filter { !Self.searchStops.contains($0) })
        guard !terms.isEmpty else { return [] }
        var scored: [(Entry, Int, Int)] = []
        for entry in entries where kinds.contains(entry.kind) {
            let known = entry.nameStems.union(entry.attributeStems)
            let matched = terms.intersection(known).count
            if matched > 0 { scored.append((entry, matched, terms.intersection(entry.nameStems).count)) }
        }
        let complete = scored.filter { $0.1 == terms.count }
        let pool = complete.isEmpty ? scored.filter { $0.1 * 2 >= terms.count } : complete
        return pool.sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.2 != $1.2 ? $0.2 > $1.2 : $0.0.nameKey < $1.0.nameKey }.prefix(limit).map(\.0)
    }
}
