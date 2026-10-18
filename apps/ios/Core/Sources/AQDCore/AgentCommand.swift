import Foundation

/// A plain, complete instruction the app can carry out without the model choosing a tool: "Mark my Black flats as laundry".
/// Anything that does not match one of these shapes goes to the model as before. The words are only parsed here; the app resolves the
/// names against the owner's records, so a name that matches several pieces becomes a question and a miss becomes a quiet step.
public enum AgentCommand: Equatable, Sendable {
    case rename(target: String, to: String)
    /// `value` is "available", "unavailable" or "laundry".
    case setAvailability(target: String, value: String)
    /// `field` is "color" or "brand".
    case setPieceField(target: String, field: String, value: String)
    /// `field` is "occasion" or "mood".
    case setOutfitField(target: String, field: String, value: String)
    /// `dayOffset` is 0 for today and -1 for yesterday.
    case recordWear(subjects: [String], dayOffset: Int)
    /// `field` is "caption" or "name".
    case setProfile(field: String, value: String)
    case createTheme(name: String?, about: String?)
    /// Outfits for the next `count` days from today (at most 14).
    case planDays(count: Int)

    private static func expression(_ pattern: String) -> NSRegularExpression? { try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) }
    private static let rename = expression(#"^\s*(?:please\s+)?(?:rename|relabel|retitle)\s+(?:my\s+|the\s+)?(.+?)\s+(?:to|as)\s+(.+?)\s*[.!]?\s*$"#)
    private static let renameName = expression(#"^\s*(?:please\s+)?(?:change|set|update|edit)\s+the\s+(?:name|title)\s+(?:of|for)\s+(?:my\s+|the\s+)?(.+?)\s+to\s+(.+?)\s*[.!]?\s*$"#)
    private static let availability = expression(#"^\s*(?:please\s+)?(?:mark|set|put|move|flag)\s+(?:my\s+|the\s+)?(.+?)\s+(?:as|to|into|in)\s+(?:in\s+)?(?:the\s+)?(laundry(?:\s+(?:pile|basket|bin))?|unavailable|available)\s*[.!]?\s*$"#)
    private static let pieceField = expression(#"^\s*(?:please\s+)?(?:change|set|update|edit)\s+(?:the\s+)?(colou?r|brand)\s+(?:of|for|on)\s+(?:my\s+|the\s+)?(.+?)\s+to\s+(.+?)\s*[.!]?\s*$"#)
    private static let outfitField = expression(#"^\s*(?:please\s+)?(?:change|set|update|edit)\s+(?:the\s+)?(occasion|mood)\s+(?:of|for|on)\s+(?:my\s+|the\s+)?(.+?)\s+to\s+(.+?)\s*[.!]?\s*$"#)
    private static let wear = expression(#"^\s*(?:please\s+)?(?:(?:log|record|note|mark)(?:\s+that)?\s+)?i\s+(?:just\s+)?(?:wore|put\s+on|threw\s+on)\s+(?:my\s+|the\s+)?(.+?)(?:\s+(today|yesterday|this morning|last night))?\s*[.!]?\s*$"#)
    private static let profile = expression(#"^\s*(?:please\s+)?(?:change|set|update)\s+my\s+(?:profile\s+)?(caption|bio|name)\s+to\s+(.+?)\s*[.!]?\s*$"#)
    private static let planNext = expression(#"^\s*(?:please\s+)?(?:(?:plan|schedule)\s+)?(?:my\s+|the\s+)?(?:outfits?\s+|looks?\s+)?(?:for\s+)?(?:the\s+)?(?:next|coming|upcoming)\s+(\d+|one|two|three|four|five|six|seven)\s+days?(?:\s+please)?\s*[.!]?\s*$"#)
    private static let planWeek = expression(#"^\s*(?:please\s+)?(?:plan|schedule)\s+(?:my\s+|the\s+)?(?:outfits?\s+(?:for\s+)?)?(?:the\s+|this\s+|my\s+|next\s+|coming\s+|upcoming\s+)?week(?:\s+(?:for\s+me|please))?\s*[.!]?\s*$"#)
    private static let theme = expression(#"^\s*(?:please\s+)?(?:make|create|build)\s+(?:me\s+)?(?:a\s+|an\s+)?(?:new\s+)?theme\b(.*)$"#)

    private static func groups(_ pattern: NSRegularExpression?, _ text: String) -> [String]? {
        guard let pattern, let match = pattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        return (1..<match.numberOfRanges).map { Range(match.range(at: $0), in: text).map { String(text[$0]) } ?? "" }
    }
    private static func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"“”'‘’.!"))).trimmingCharacters(in: .whitespaces)
    }

    public static func parse(_ prompt: String) -> AgentCommand? {
        let text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if let g = groups(pieceField, text) { return .setPieceField(target: clean(g[1]), field: g[0].lowercased().hasPrefix("colo") ? "color" : "brand", value: clean(g[2])) }
        if let g = groups(outfitField, text) { return .setOutfitField(target: clean(g[1]), field: g[0].lowercased(), value: clean(g[2])) }
        if let g = groups(profile, text) { return .setProfile(field: g[0].lowercased() == "name" ? "name" : "caption", value: clean(g[1])) }
        if let g = groups(availability, text) { return .setAvailability(target: clean(g[0]), value: g[1].lowercased().hasPrefix("laundry") ? "laundry" : g[1].lowercased()) }
        if let g = groups(wear, text) {
            let subjects = g[0].replacingOccurrences(of: " and ", with: ",", options: .caseInsensitive).split(separator: ",").map { clean(String($0)).replacingOccurrences(of: #"^(?i:the|my)\s+"#, with: "", options: .regularExpression) }.filter { !$0.isEmpty }
            let day = g[1].lowercased()
            return subjects.isEmpty ? nil : .recordWear(subjects: subjects, dayOffset: day == "yesterday" || day == "last night" ? -1 : 0)
        }
        if let g = groups(rename, text) ?? groups(renameName, text) { return .rename(target: clean(g[0]), to: clean(g[1])) }
        if let g = groups(planNext, text) {
            let words = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7]
            let count = Int(g[0]) ?? words[g[0].lowercased()] ?? 0
            return (1...14).contains(count) ? .planDays(count: count) : nil
        }
        if groups(planWeek, text) != nil { return .planDays(count: 7) }
        if let g = groups(theme, text) {
            let rest = g[0]
            var name: String?, about: String?
            if let named = groups(expression(#"\b(?:called|named)\s+"?([^"]+?)"?(?:\s+(?:from|using|with|of)\b|\s*$)"#), rest) { name = clean(named[0]) }
            if let from = groups(expression(#"\b(?:from|using|with|of)\s+(?:all\s+)?(?:my\s+|the\s+)?(.+?)\s+(?:outfits?|looks?)\b"#), rest) { about = clean(from[0]) }
            return .createTheme(name: name?.isEmpty == true ? nil : name, about: about?.isEmpty == true ? nil : about)
        }
        return nil
    }
}
