import Foundation

public enum OutfitSuggestionError: Error, Equatable {
    case invalidProposal, pinnedPiece, unavailablePin, missingCategories
}

public enum OutfitForm: String, Codable, Sendable {
    case separates, dress
    public var categories: [PieceCategory] { self == .separates ? [.tops, .bottoms, .shoes] : [.dresses, .shoes] }
}

public struct OutfitReadiness: Sendable {
    public let form: OutfitForm
    public let missingCategories: [PieceCategory]
    public let unavailablePins: [UUID]
    public let candidateIDs: [UUID]
    public var isReady: Bool { missingCategories.isEmpty && unavailablePins.isEmpty }

    public init(pieces: [WardrobePiece], pinnedIDs: [UUID] = [], form: OutfitForm? = nil) {
        let available = pieces.filter { !$0.isArchived && $0.availability == .available }.sorted {
            let order = $0.name.localizedStandardCompare($1.name)
            return order == .orderedSame ? $0.id.uuidString < $1.id.uuidString : order == .orderedAscending
        }
        let pins = available.filter { pinnedIDs.contains($0.id) }
        unavailablePins = pinnedIDs.filter { id in !available.contains { $0.id == id } }
        let chosen: OutfitForm
        if let form { chosen = form }
        else if pins.contains(where: { $0.category == .dresses }) { chosen = .dress }
        else if pins.contains(where: { $0.category == .tops || $0.category == .bottoms }) { chosen = .separates }
        else {
            let separatesGaps = OutfitForm.separates.categories.filter { category in !available.contains { $0.category == category } }.count
            let dressGaps = OutfitForm.dress.categories.filter { category in !available.contains { $0.category == category } }.count
            chosen = dressGaps < separatesGaps ? .dress : .separates
        }
        self.form = chosen
        missingCategories = chosen.categories.filter { category in !available.contains { $0.category == category } }
        var selected = pins.map(\.id)
        for category in chosen.categories {
            if pins.contains(where: { $0.category == category }) { continue }
            if let candidate = available.first(where: { $0.category == category }) { selected.append(candidate.id) }
        }
        candidateIDs = selected
    }
}

extension OutfitDraft {
    public mutating func pin(_ id: UUID) {
        guard pieceIDs.contains(id) else { return }
        if !(pinnedPieceIDs ?? []).contains(id) { pinnedPieceIDs = (pinnedPieceIDs ?? []) + [id] }
    }

    public mutating func unpin(_ id: UUID) { pinnedPieceIDs = (pinnedPieceIDs ?? []).filter { $0 != id } }

    public mutating func applyProposal(_ ids: [UUID], pieces: [WardrobePiece]) throws {
        let active = pieces.filter { !$0.isArchived && $0.availability == .available }
        guard !ids.isEmpty, Set(ids).count == ids.count,
              Set(pinnedPieceIDs ?? []).isSubset(of: Set(ids)),
              Set(ids).isSubset(of: Set(active.map(\.id))) else { throw OutfitSuggestionError.invalidProposal }
        let selected = active.filter { ids.contains($0.id) }
        let hasDress = selected.contains { $0.category == .dresses }
        let hasSeparates = selected.contains { $0.category == .tops } && selected.contains { $0.category == .bottoms }
        guard (hasDress || hasSeparates), selected.contains(where: { $0.category == .shoes }) else {
            throw OutfitSuggestionError.invalidProposal
        }
        for id in pieceIDs { remove(id) }
        for id in ids { select(id) }
        reviewedPieceRevisions = Dictionary(uniqueKeysWithValues: selected.map { ($0.id, $0.revision) })
    }

    public mutating func replace(_ id: UUID, with replacement: UUID, pieces: [WardrobePiece]) throws {
        guard !(pinnedPieceIDs ?? []).contains(id) else { throw OutfitSuggestionError.pinnedPiece }
        guard let index = pieceIDs.firstIndex(of: id), !pieceIDs.contains(replacement),
              let previous = pieces.first(where: { $0.id == id }),
              let next = pieces.first(where: { $0.id == replacement }), next.category == previous.category,
              !next.isArchived, next.availability == .available else {
            throw OutfitSuggestionError.invalidProposal
        }
        var ids = pieceIDs; ids[index] = replacement
        try applyManualSelection(ids, pieces: pieces)
    }
}
