import Foundation

/// A one-line index of a collection that shrinks to the room it is given. Names drop from the end and the line says how many more exist,
/// so the model knows to look them up instead of guessing.
public enum AgentCatalogText {
    public static func fit(label: String, items: [String], limit: Int) -> String? {
        guard !items.isEmpty else { return nil }
        let header = label + ": "
        func more(_ hidden: Int) -> String { hidden == 0 ? "" : "; and \(hidden) more (use findRecords)" }
        guard limit > header.count + 8 else { return nil }
        if (header + items.joined(separator: "; ")).count <= limit { return header + items.joined(separator: "; ") }
        var shown: [String] = []
        for item in items {
            let candidate = header + (shown + [item]).joined(separator: "; ") + more(items.count - shown.count - 1)
            if candidate.count > limit { break }
            shown.append(item)
        }
        return shown.isEmpty ? nil : header + shown.joined(separator: "; ") + more(items.count - shown.count)
    }
}
