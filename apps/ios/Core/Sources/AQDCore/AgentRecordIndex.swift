import Foundation

public enum AgentRecordKind: String, Codable, CaseIterable, Sendable { case piece, outfit, theme, plan }

/// What a reference to a record turned out to be.
public enum AgentResolution: Equatable, Sendable {
    case found(AgentRecordIndex.Entry)
    /// Two to four records the reference could mean. The owner picks; nothing is guessed.
    case ambiguous([AgentRecordIndex.Entry])
    case notFound
}

/// The records one turn can talk about, each with a short handle (`p1`, `o3`, `t2`, `pl1`). The model only ever sees handles and names;
/// the app maps them back to UUIDs and current revisions. Handles are assigned by name order, so they stay the same while the closet does.
public struct AgentRecordIndex: Equatable, Sendable {
    public struct Entry: Equatable, Sendable, Identifiable {
        public let handle: String
        public let kind: AgentRecordKind
        public let id: UUID
        public let name: String
        public let revision: Int
        /// Words that help a loose reference find this record: color, category, tags, occasion.
        public let attributes: [String]
        public let nameKey: String
        let nameStems: Set<String>
        let attributeStems: Set<String>
    }

    /// A record before it has a handle.
    public struct Draft: Sendable {
        public let kind: AgentRecordKind
        public let id: UUID
        public let name: String
        public let revision: Int
        public let attributes: [String]
        public init(kind: AgentRecordKind, id: UUID, name: String, revision: Int, attributes: [String] = []) {
            self.kind = kind; self.id = id; self.name = name; self.revision = revision; self.attributes = attributes
        }
    }

    public private(set) var entries: [Entry] = []
    private var byHandle: [String: Int] = [:]
    private var byID: [UUID: Int] = [:]
    public static let prefixes: [AgentRecordKind: String] = [.piece: "p", .outfit: "o", .theme: "t", .plan: "pl"]

    public init(_ drafts: [Draft] = []) {
        var counters: [AgentRecordKind: Int] = [:]
        let ordered = drafts.sorted {
            if $0.kind != $1.kind { return Self.rank($0.kind) < Self.rank($1.kind) }
            let left = AgentText.normalize($0.name), right = AgentText.normalize($1.name)
            return left != right ? left < right : $0.id.uuidString < $1.id.uuidString
        }
        for draft in ordered {
            counters[draft.kind, default: 0] += 1
            let handle = (Self.prefixes[draft.kind] ?? "r") + String(counters[draft.kind] ?? 0)
            // Group words ("blouse" is a top) let "the cream top" find a blouse.
            let group = AgentText.stems(draft.name).compactMap { AgentGroundingCheck.groups[$0] }
            let attributes = draft.attributes + group
            let entry = Entry(handle: handle, kind: draft.kind, id: draft.id, name: draft.name, revision: draft.revision, attributes: attributes,
                              nameKey: AgentText.normalize(draft.name), nameStems: Set(AgentText.stems(draft.name)), attributeStems: Set(attributes.flatMap(AgentText.stems)))
            byHandle[handle] = entries.count; byID[draft.id] = entries.count; entries.append(entry)
        }
    }
    private static func rank(_ kind: AgentRecordKind) -> Int { AgentRecordKind.allCases.firstIndex(of: kind) ?? 0 }

    public func entries(of kind: AgentRecordKind) -> [Entry] { entries.filter { $0.kind == kind } }
    public func entry(handle: String) -> Entry? { byHandle[handle.lowercased()].map { entries[$0] } }
    public func entry(id: UUID) -> Entry? { byID[id].map { entries[$0] } }
    public func handle(for id: UUID) -> String? { entry(id: id)?.handle }

    private static let handlePattern = try? NSRegularExpression(pattern: #"^(?:pl|p|o|t)\d{1,4}$"#)

    /// Exact handle first, then exact name (case, accents and punctuation ignored), then a loose match on the words of the name plus its
    /// color, category and tags. A loose match must cover every word the owner used and be the only one that does.
    public func resolve(_ reference: String, kinds: [AgentRecordKind] = AgentRecordKind.allCases) -> AgentResolution {
        let allowed = Set(kinds)
        var text = reference.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"'“”‘’[]()`*")))
        if text.isEmpty { return .notFound }
        let lowered = text.lowercased()
        if let pattern = Self.handlePattern, pattern.firstMatch(in: lowered, range: NSRange(lowered.startIndex..., in: lowered)) != nil {
            if let entry = entry(handle: lowered), allowed.contains(entry.kind) { return .found(entry) }
            return .notFound
        }
        text = lowered
        let key = AgentText.normalize(text)
        guard !key.isEmpty else { return .notFound }
        let pool = entries.filter { allowed.contains($0.kind) }
        let exact = pool.filter { $0.nameKey == key }
        if exact.count == 1, let only = exact.first { return .found(only) }
        if exact.count > 1 { return .ambiguous(Array(exact.prefix(4))) }
        let words = Set(AgentText.stems(text).filter { !AgentText.fillers.contains($0) && !Self.ownership.contains($0) })
        guard !words.isEmpty else { return .notFound }
        // A name that fully contains the words, or words that fully contain a name, are the strongest loose matches.
        var scored: [(Entry, Int)] = []
        for entry in pool {
            let known = entry.nameStems.union(entry.attributeStems)
            guard words.isSubset(of: known) else { continue }
            let nameHits = words.intersection(entry.nameStems).count
            guard nameHits > 0 else { continue }
            scored.append((entry, nameHits * 4 + words.intersection(entry.attributeStems).count - (entry.nameStems.count - nameHits)))
        }
        if scored.isEmpty {
            // The owner may have added a word the name lacks ("my long black coat"): accept a name fully inside the words when it is the only one.
            let inside = pool.filter { $0.nameStems.count >= 2 && $0.nameStems.isSubset(of: words) }
            if inside.count == 1, let only = inside.first { return .found(only) }
            return .notFound
        }
        scored.sort { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.nameKey < $1.0.nameKey }
        if scored.count == 1, let only = scored.first { return .found(only.0) }
        return .ambiguous(Array(scored.prefix(4).map(\.0)))
    }

    private static let ownership: Set<String> = ["piece", "item", "outfit", "look", "theme", "plan", "one"]
}
