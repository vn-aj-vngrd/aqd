import Foundation

/// Reads a trip request from plain text: how many days and where. The Agent uses it as a safety net when the model answers a clear
/// trip request without preparing the review, so the owner always gets looks they can save.
public struct TripIntent: Equatable, Sendable {
    public let days: Int
    public let destination: String
    public var name: String { destination.isEmpty ? "Trip looks" : "\(destination) trip" }

    private static let triggers = ["trip", "vacation", "holiday", "getaway", "travel", "itinerary", "pack", "weekend away", "flying", "honeymoon", "staycation"]
    private static let words = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7]
    private static let beach = ["beach", "island", "boracay", "bali", "hawaii", "cebu", "palawan", "phuket", "maldives", "resort", "snorkel", "siargao", "coron", "el nido", "tulum", "cancun"]

    /// The number of days a request names ("3 days", "four-night", "a weekend", "a week"), or nil.
    public static func dayCount(in prompt: String) -> Int? {
        let text = prompt.lowercased()
        var count: Int?
        if let match = text.range(of: #"(\d+)\s*[- ]?\s*(?:day|days|night|nights)"#, options: .regularExpression) {
            count = Int(text[match].prefix { $0.isNumber })
        }
        if count == nil {
            for (word, value) in words where text.range(of: "\\b\(word)[- ](?:day|days|night|nights)\\b", options: .regularExpression) != nil { count = value }
        }
        if count == nil, text.contains("weekend") { count = 3 }
        if count == nil, text.range(of: #"\b(a|one|1)[- ]week\b"#, options: .regularExpression) != nil { count = 7 }
        guard let count, count >= 1 else { return nil }
        return min(count, TripOutfitComposer.maximumDays)
    }

    /// Whether a request names dates (a month or a numeric date), which the model path can place on the Planner.
    public static func mentionsDates(_ prompt: String) -> Bool {
        let text = prompt.lowercased()
        let months = ["january", "february", "march", "april", "june", "july", "august", "september", "october", "november", "december", "jan ", "feb ", "apr ", "jun ", "jul ", "aug ", "sep ", "oct ", "nov ", "dec "]
        return months.contains { text.contains($0) } || text.range(of: #"\b\d{1,2}[/-]\d{1,2}\b"#, options: .regularExpression) != nil
    }

    /// `requireTrigger` is false once the request is already known to be about a trip; then only the days and place matter.
    public static func parse(_ prompt: String, requireTrigger: Bool = true) -> TripIntent? {
        let text = prompt.lowercased()
        guard !requireTrigger || triggers.contains(where: { text.contains($0) }) else { return nil }
        guard let count = dayCount(in: prompt) else { return nil }
        var place = ""
        let stop: Set<String> = ["My", "The", "A", "An", "Plan", "Please", "Can", "Could", "What", "Make", "Build", "Help", "I"]
        if let regex = try? NSRegularExpression(pattern: #"\b(?:to|in|at|for)\s+([A-Z][\p{L}]+(?:\s+[A-Z][\p{L}]+)*)"#) {
            for match in regex.matches(in: prompt, range: NSRange(prompt.startIndex..., in: prompt)) {
                guard let range = Range(match.range(at: 1), in: prompt) else { continue }
                let candidate = String(prompt[range])
                if !stop.contains(candidate.components(separatedBy: " ").first ?? candidate) { place = candidate; break }
            }
        }
        return TripIntent(days: count, destination: String(place.prefix(60)))
    }

    /// A sensible spread of days. Labels are shown to the owner; occasions steer the outfit composer.
    public var briefs: [TripDayBrief] {
        let coastal = Self.beach.contains { destination.lowercased().contains($0) }
        let plan: [(String, String)] = coastal
            ? [("Arrival day", "airport travel"), ("Beach day", "beach"), ("Island hopping", "beach island"), ("Sunset dinner", "dinner evening"),
               ("Easy morning", "beach"), ("Night out", "dinner evening"), ("Travel home", "airport travel")]
            : [("Arrival day", "airport travel"), ("Sightseeing", "walk explore city"), ("Dinner out", "dinner evening"), ("Day trip", "walk explore"),
               ("Relaxed day", "city"), ("Night out", "dinner evening"), ("Travel home", "airport travel")]
        // A short trip keeps its first and last day, then fills the middle.
        let order: [Int] = days >= 7 ? Array(0..<7) : days == 1 ? [1] : (0..<days).map { $0 == days - 1 ? 6 : $0 }
        return order.enumerated().map { offset, index in
            TripDayBrief(label: "Day \(offset + 1) \(plan[index].0.lowercased())", occasion: plan[index].1)
        }
    }
}
