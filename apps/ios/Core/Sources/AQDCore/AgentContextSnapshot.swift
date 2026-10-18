import Foundation

public enum AgentContextError: Error { case selectionRequired, budgetExceeded }

public struct AgentContextSnapshot: Codable, Equatable, Sendable {
    public struct Piece: Codable, Equatable, Sendable {
        public let id: UUID
        public let revision: Int
        public let name: String
        public let category: PieceCategory
        public let color: String
    }
    public let pieces: [Piece]
    public let totalEligible: Int
    public let scope: AgentContextScope
    /// Capture the exact descendants reviewed when an outfit or theme is selected.
    /// Legacy selections lack these revisions and must be selected again before sending.
    public static func selection(id: UUID, kind: AgentSelectedRecord.Kind, pieces: [WardrobePiece], outfits: [Outfit], themes: [OutfitTheme]) throws -> AgentSelectedRecord {
        let eligible = pieces.filter { !$0.isArchived && $0.availability == .available }
        if kind == .piece {
            guard let piece = eligible.first(where: { $0.id == id }) else { throw PlanValidationError.invalidRecord }
            return AgentSelectedRecord(id: id, kind: kind, revision: piece.revision)
        }
        let revision: Int, members: [Outfit]
        if kind == .outfit {
            guard let outfit = outfits.first(where: { $0.id == id }) else { throw PlanValidationError.invalidRecord }
            revision = outfit.revision; members = [outfit]
        } else {
            guard let theme = themes.first(where: { $0.id == id }) else { throw PlanValidationError.invalidRecord }
            revision = theme.revision
            members = try theme.outfitIDs.map { id in
                guard let outfit = outfits.first(where: { $0.id == id }) else { throw PlanValidationError.invalidRecord }
                return outfit
            }
        }
        var pieceRevisions: [UUID: Int] = [:], outfitRevisions: [UUID: Int] = [:]
        for outfit in members {
            outfitRevisions[outfit.id] = outfit.revision
            for id in outfit.pieceIDs {
                guard let piece = eligible.first(where: { $0.id == id }) else { throw PlanValidationError.invalidRecord }
                pieceRevisions[id] = piece.revision
            }
        }
        return AgentSelectedRecord(id: id, kind: kind, revision: revision, resolvedPieces: pieceRevisions, resolvedOutfits: outfitRevisions)
    }
    public static func build(_ context: AgentContext, pieces: [WardrobePiece], outfits: [Outfit], themes: [OutfitTheme], maximumPieces: Int) throws -> Self {
        guard maximumPieces > 0 else { throw PlanValidationError.invalidRecord }
        if context.scope == .general { return Self(pieces: [], totalEligible: 0, scope: .general) }
        let eligible = pieces.filter { !$0.isArchived && $0.availability == .available }
        var selected = Set<UUID>()
        if context.scope == .selected {
            for record in context.selected {
                guard record == (try selection(id: record.id, kind: record.kind, pieces: pieces, outfits: outfits, themes: themes)) else { throw PlanValidationError.invalidRecord }
                switch record.kind {
                case .piece:
                    guard let value = eligible.first(where: { $0.id == record.id }), value.revision == record.revision else { throw PlanValidationError.invalidRecord }; selected.insert(value.id)
                case .outfit:
                    guard let value = outfits.first(where: { $0.id == record.id }), value.revision == record.revision else { throw PlanValidationError.invalidRecord }; selected.formUnion(value.pieceIDs)
                case .theme:
                    guard let value = themes.first(where: { $0.id == record.id }), value.revision == record.revision else { throw PlanValidationError.invalidRecord }
                    for id in value.outfitIDs {
                        guard let outfit = outfits.first(where: { $0.id == id }) else { throw PlanValidationError.invalidRecord }; selected.formUnion(outfit.pieceIDs)
                    }
                }
            }
            guard selected.isSubset(of: Set(eligible.map(\.id))) else { throw PlanValidationError.invalidRecord }
        }
        let allowed = eligible.filter { context.scope == .closet || selected.contains($0.id) }.sorted { $0.id.uuidString < $1.id.uuidString }
        guard allowed.count <= maximumPieces else { throw AgentContextError.selectionRequired }
        return Self(pieces: allowed.map { Piece(id: $0.id, revision: $0.revision, name: $0.name, category: $0.category, color: $0.details.color) }, totalEligible: eligible.count, scope: context.scope)
    }
    public var summary: String { scope == .general ? "General styling, no closet or wear access" : "\(pieces.count) of \(totalEligible) eligible pieces, with names, categories and colors, without photos or private notes" }
}

public enum AgentMarkdownPolicy {
    /// Code-bearing replies keep their literal source; generation instructions govern their punctuation.
    public static func conversationalText(_ source: String) -> String {
        let source = hidingIdentifiers(source)
        guard source.contains("—"), !source.contains("`"), !source.contains("~~~"),
              !source.components(separatedBy: "\n").contains(where: { $0.hasPrefix("    ") || $0.hasPrefix("\t") }),
              let tokens = try? NSRegularExpression(pattern: #"(?i:https?)://[^\s)]+|[ \t]*—[ \t]*"#) else { return source }
        var value = source
        for match in tokens.matches(in: source, range: NSRange(source.startIndex..., in: source)).reversed() {
            guard let range = Range(match.range, in: value), !value[range].lowercased().hasPrefix("http") else { continue }
            value.replaceSubrange(range, with: ", ")
        }
        return value
    }

    /// Record IDs are for tools, never for the owner: drop "ID <uuid> –" labels and bare UUIDs from displayed text.
    public static func hidingIdentifiers(_ source: String) -> String {
        let uuid = "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
        guard source.range(of: uuid, options: [.regularExpression, .caseInsensitive]) != nil,
              let pattern = try? NSRegularExpression(pattern: #"(?i)\(?\s*(?:\b(?:record\s+)?ID\b\s*[:=#]?\s*)?"# + uuid + #"\s*\)?\s*(?:[–—:-]\s*)?"#) else { return source }
        return pattern.stringByReplacingMatches(in: source, range: NSRange(source.startIndex..., in: source), withTemplate: "")
    }

    public static func spokenText(_ source: String) -> String {
        let withoutTargets = source.replacingOccurrences(of: #"!?\[([^\]]*)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
        let prose = String(((try? AttributedString(markdown: withoutTargets, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(withoutTargets)).characters)
        return prose
            .replacingOccurrences(of: #"(?m)^\s{0,3}(#{1,6}|>|[-*+]|\d+[.)])\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?m)^\s*(```|~~~)[^\n]*$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func allowsLink(_ value: String) -> Bool {
        guard let url = URL(string: value), let scheme = url.scheme?.lowercased(), ["https", "http"].contains(scheme), url.host?.isEmpty == false else { return false }; return true
    }
    public static func plainText(_ source: String, incomplete: Bool) -> String {
        var value = source.replacingOccurrences(of: #"!?\[([^\]]*)\]\(([^)]+)\)"#, with: "$1 ($2)", options: .regularExpression)
        value = value.replacingOccurrences(of: #"(?m)^\s{0,3}#{1,6}\s+"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "__", with: "")
        value = value.replacingOccurrences(of: #"(?m)^```[^\n]*\n?"#, with: "", options: .regularExpression)
        return (incomplete ? "Incomplete response\n\n" : "") + value
    }
}
