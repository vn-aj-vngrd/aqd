import Foundation

/// What the owner wants one trip day to feel like. `pinnedIDs` are pieces that must appear.
public struct TripDayBrief: Codable, Equatable, Sendable {
    public var label: String
    public var occasion: String
    public var pinnedIDs: [UUID]
    public init(label: String, occasion: String = "", pinnedIDs: [UUID] = []) { self.label = label; self.occasion = occasion; self.pinnedIDs = pinnedIDs }
}

/// Builds one varied outfit per trip day from available pieces. Pure and deterministic: the same closet and briefs give the same looks.
/// Pieces are spread across days (least used first), dresses and separates alternate, and no two days repeat the same set.
public enum TripOutfitComposer {
    public static let maximumDays = 7

    private static let themes: [(triggers: [String], liked: [String], disliked: [String])] = [
        (["beach", "island", "swim", "pool", "resort", "sun", "summer", "boracay", "bali", "hawaii", "snorkel"],
         ["linen", "cotton", "light", "sandal", "straw", "sun", "swim", "cover", "resort", "short", "skirt", "dress", "white", "flowy", "tote"],
         ["wool", "coat", "puffer", "boot", "heavy", "fleece", "scarf", "knit"]),
        (["dinner", "evening", "night", "cocktail", "date", "party", "celebration"],
         ["satin", "silk", "heel", "dress", "evening", "clutch", "gold", "black", "dressy", "earring"],
         ["sneaker", "gym", "sport", "swim"]),
        (["airport", "flight", "travel", "transit", "commute", "arrival"],
         ["comfort", "sneaker", "knit", "cardigan", "jean", "jogger", "soft", "stretch", "layer", "tote"],
         ["heel", "formal", "stiff"]),
        (["hike", "active", "trail", "walk", "sightsee", "explore", "tour", "city", "market"],
         ["sneaker", "comfort", "legging", "short", "sport", "cotton", "light", "denim", "cap", "crossbody"],
         ["heel", "formal", "silk", "satin"]),
        (["work", "office", "meeting", "business", "conference", "interview"],
         ["blazer", "trouser", "shirt", "loafer", "tailor", "classic", "neutral", "pump", "flat"],
         ["sport", "swim", "gym"]),
        (["cold", "snow", "winter", "ski", "rain"],
         ["coat", "wool", "knit", "boot", "layer", "scarf", "sweater", "jacket"],
         ["swim", "sandal", "linen", "short"])
    ]

    private static func text(_ piece: WardrobePiece) -> String {
        ([piece.name, piece.details.color, piece.details.material, piece.details.season, piece.details.notes] + piece.details.tags).joined(separator: " ").lowercased()
    }

    private static func fit(_ piece: WardrobePiece, brief: TripDayBrief) -> Int {
        let wanted = (brief.occasion + " " + brief.label).lowercased()
        let haystack = text(piece)
        var score = 0
        for theme in themes where theme.triggers.contains(where: { wanted.contains($0) }) {
            score += theme.liked.filter { haystack.contains($0) }.count * 3
            score -= theme.disliked.filter { haystack.contains($0) }.count * 4
        }
        for word in wanted.split(whereSeparator: { !$0.isLetter }) where word.count > 3 && haystack.contains(word) { score += 2 }
        return score
    }

    /// Piece IDs for each brief, in order. Throws when the closet cannot make a complete outfit.
    public static func compose(briefs: [TripDayBrief], pieces: [WardrobePiece]) throws -> [[UUID]] {
        guard !briefs.isEmpty, briefs.count <= maximumDays else { throw PlanValidationError.invalidRecord }
        let available = pieces.filter { !$0.isArchived && $0.availability == .available }.sorted {
            let order = $0.name.localizedStandardCompare($1.name)
            return order == .orderedSame ? $0.id.uuidString < $1.id.uuidString : order == .orderedAscending
        }
        func has(_ category: PieceCategory) -> Bool { available.contains { $0.category == category } }
        let canDress = has(.dresses) && has(.shoes)
        let canSeparate = has(.tops) && has(.bottoms) && has(.shoes)
        guard canDress || canSeparate else { throw OutfitValidationError.piecesRequired }

        var uses: [UUID: Int] = [:]
        var made: [Set<UUID>] = []
        var result: [[UUID]] = []
        for (index, brief) in briefs.enumerated() {
            let pins = available.filter { brief.pinnedIDs.contains($0.id) }
            let wantsDress: Bool
            if pins.contains(where: { $0.category == .dresses }) { wantsDress = true }
            else if pins.contains(where: { $0.category == .tops || $0.category == .bottoms }) { wantsDress = false }
            else if !canSeparate { wantsDress = true }
            else if !canDress { wantsDress = false }
            else {
                let dressy = available.filter { $0.category == .dresses }.map { fit($0, brief: brief) }.max() ?? 0
                let topFit = available.filter { $0.category == .tops }.map { fit($0, brief: brief) }.max() ?? 0
                // Alternate by default; a clearly better-fitting side wins.
                wantsDress = dressy > topFit + 2 ? true : topFit > dressy + 2 ? false : index % 2 == 1
            }
            var categories: [PieceCategory] = wantsDress ? [.dresses, .shoes] : [.tops, .bottoms, .shoes]
            let wanted = (brief.occasion + " " + brief.label).lowercased()
            let cool = ["evening", "dinner", "night", "airport", "flight", "cold", "rain", "winter"].contains { wanted.contains($0) }
            if cool, has(.layers) { categories.append(.layers) }
            if has(.accessories), index % 2 == 0 || wanted.contains("beach") || wanted.contains("dinner") { categories.append(.accessories) }

            var attempt = 0
            var picked: [UUID] = []
            repeat {
                picked = pins.map(\.id)
                for category in categories where !pins.contains(where: { $0.category == category }) {
                    let ranked = available.filter { $0.category == category }.sorted { lhs, rhs in
                        // Shoes may repeat; everything else is spread across the trip first.
                        let weight = category == .shoes ? 3 : 12
                        let left = fit(lhs, brief: brief) * 4 - uses[lhs.id, default: 0] * weight
                        let right = fit(rhs, brief: brief) * 4 - uses[rhs.id, default: 0] * weight
                        return left == right ? lhs.id.uuidString < rhs.id.uuidString : left > right
                    }
                    guard !ranked.isEmpty else { continue }
                    // A repeated set shifts the lead garment to its next-best choice.
                    let lead = category == categories[0] ? min(attempt, ranked.count - 1) : 0
                    picked.append(ranked[lead].id)
                }
                attempt += 1
            } while made.contains(Set(picked)) && attempt < 6
            guard !picked.isEmpty else { throw OutfitValidationError.piecesRequired }
            for id in picked { uses[id, default: 0] += 1 }
            made.append(Set(picked)); result.append(picked)
        }
        return result
    }
}
