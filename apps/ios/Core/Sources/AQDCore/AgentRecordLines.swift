import Foundation

/// The short lines the model reads about the owner's records. Every line starts with a handle and a name; empty fields are left out and no
/// UUID or revision ever appears. The same format serves the prompt, the lookup tool and the eval.
public enum AgentRecordLines {
    private static func parenthetical(_ parts: [String?]) -> String {
        let kept = parts.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return kept.isEmpty ? "" : " (" + kept.joined(separator: ", ") + ")"
    }

    public static func piece(handle: String, name: String, category: String, color: String, status: String, wears: Int?, extras: [String] = []) -> String {
        handle + " " + name + parenthetical([category, color.lowercased(), status, wears.map { $0 == 0 ? "no recorded wear" : "worn \($0)" }] + extras)
    }
    public static func outfit(handle: String, name: String, occasion: String?, mood: String?, members: [String], note: String? = nil) -> String {
        handle + " " + name + parenthetical([occasion, mood, members.isEmpty ? nil : "\(members.count) pieces: " + members.joined(separator: ", "), note])
    }
    public static func theme(handle: String, name: String, outfits: [String]) -> String {
        handle + " " + name + parenthetical([outfits.isEmpty ? "no outfits yet" : "\(outfits.count) outfits: " + outfits.joined(separator: ", ")])
    }
    public static func plan(handle: String, name: String, start: String, end: String, kind: String, destination: String?) -> String {
        handle + " " + name + parenthetical([start == end ? start : start + " to " + end, kind, destination])
    }
    /// "Black blazer (p1), Black trousers (p4)" for answers that must point at records.
    public static func names(_ entries: [AgentRecordIndex.Entry]) -> String { entries.map(\.name).joined(separator: ", ") }
}
