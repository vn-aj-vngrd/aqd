import Foundation

/// Light clean-up of a finished reply: filler openers and closers, lists the cards already show, and the middle-dot separator.
/// It only removes text, never rewrites it, and gives back the original if nothing readable would remain.
public enum AgentReplyPolish {
    private static let openers = ["sure", "sure thing", "certainly", "of course", "absolutely", "great question", "good question", "happy to help", "no problem", "okay", "ok", "got it", "definitely", "great", "awesome", "perfect"]
    private static let closers = ["let me know", "feel free to ask", "feel free to reach", "feel free to let", "hope this helps", "i hope this", "don t hesitate", "do not hesitate", "happy to help", "is there anything else", "anything else i can", "just ask"]

    /// Removes handles (p3, o12), UUIDs and revision numbers the model repeated from its context. Names stay.
    public static func scrubIdentifiers(_ text: String) -> String {
        var value = AgentMarkdownPolicy.hidingIdentifiers(text)
        for pattern in [#"(?<![A-Za-z0-9])(?:pl|p|o|t)\d{1,3}(?![A-Za-z0-9])\s?"#, #"(?i)\brevision\s*[:=]?\s*\d+\s?"#] {
            value = value.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        value = value.replacingOccurrences(of: #"\(\s*\)"#, with: "", options: .regularExpression).replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
        value = value.replacingOccurrences(of: #" +([,.;:!?])"#, with: "$1", options: .regularExpression)
        return value.trimmingCharacters(in: .whitespaces)
    }

    public static func polish(_ text: String, cardTitles: [String] = []) -> String {
        var value = text.replacingOccurrences(of: " · ", with: ", ").replacingOccurrences(of: "·", with: ",")
        value = removingCardLists(value, cardTitles: cardTitles)
        var lines = value.components(separatedBy: "\n")
        func isItem(_ line: String) -> Bool { line.trimmingCharacters(in: .whitespaces).range(of: #"^([-*•]|\d+[.)])\s"#, options: .regularExpression) != nil }
        let content = lines.indices.filter { !lines[$0].trimmingCharacters(in: .whitespaces).isEmpty }
        if let first = content.first, !isItem(lines[first]) {
            var sentences = sentences(of: lines[first])
            if sentences.count > 1 || content.count > 1, let lead = sentences.first, isOpener(lead) { sentences.removeFirst(); lines[first] = sentences.joined(separator: " ") }
        }
        if let last = content.last, !isItem(lines[last]) {
            var sentences = sentences(of: lines[last])
            if sentences.count > 1 || content.count > 1, let tail = sentences.last, isCloser(tail) { sentences.removeLast(); lines[last] = sentences.joined(separator: " ") }
        }
        let result = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? text : result
    }

    private static func isOpener(_ sentence: String) -> Bool {
        let key = AgentText.normalize(sentence)
        return key.split(separator: " ").count <= 4 && openers.contains(key) && (sentence.hasSuffix("!") || sentence.hasSuffix(".") || sentence.hasSuffix(","))
    }
    /// A closer is an invitation with nothing else in it ("Let me know if you want another option!").
    private static func isCloser(_ sentence: String) -> Bool {
        let key = AgentText.normalize(sentence)
        return key.split(separator: " ").count <= 14 && closers.contains { key.hasPrefix(AgentText.normalize($0)) }
    }

    private static func sentences(of line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var iterator = line.makeIterator()
        var previous: Character?
        while let character = iterator.next() {
            if character == " ", let previous, ".!?".contains(previous), !current.trimmingCharacters(in: .whitespaces).isEmpty {
                result.append(current.trimmingCharacters(in: .whitespaces)); current = ""
            } else { current.append(character) }
            previous = character
        }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty { result.append(current.trimmingCharacters(in: .whitespaces)) }
        return result
    }

    /// A bulleted or numbered list whose entries are the very pieces the cards show is dropped; the cards say it better.
    static func removingCardLists(_ text: String, cardTitles: [String]) -> String {
        let titles = cardTitles.map { AgentText.normalize($0) }.filter { !$0.isEmpty }
        guard titles.count >= 2 else { return text }
        let lines = text.components(separatedBy: "\n")
        var kept: [String] = []
        var run: [String] = []
        func isItem(_ line: String) -> Bool { line.trimmingCharacters(in: .whitespaces).range(of: #"^([-*•]|\d+[.)])\s"#, options: .regularExpression) != nil }
        func flush() {
            guard !run.isEmpty else { return }
            let matching = run.filter { line in let key = " " + AgentText.normalize(line) + " "; return titles.contains { key.contains(" " + $0 + " ") } }.count
            if run.count < 2 || Double(matching) / Double(run.count) < 0.6 { kept += run }
            run = []
        }
        for line in lines { if isItem(line) { run.append(line) } else { flush(); kept.append(line) } }
        flush()
        return kept.joined(separator: "\n").replacingOccurrences(of: "\n\n\n", with: "\n\n")
    }
}
