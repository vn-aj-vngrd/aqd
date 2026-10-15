import Foundation

public enum OutfitValidationError: Error, Equatable {
    case nameRequired, nameTooLong, piecesRequired, unavailablePiece, stalePieces, invalidRecord
}

/// An owned private combination. Saving never schedules or records wear.
public struct Outfit: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let ownerID: UUID
    public var name: String
    public var pieceIDs: [UUID]
    public var mood: String?
    public var occasion: String?
    public var isFavorite: Bool
    public var revision: Int
    public let createdAt: Date
    public var updatedAt: Date

    public init(id: UUID, ownerID: UUID, name: String, pieceIDs: [UUID], mood: String? = nil, occasion: String? = nil, isFavorite: Bool = false,
                revision: Int = 1, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.ownerID = ownerID; self.name = name; self.pieceIDs = pieceIDs
        self.mood = mood; self.occasion = occasion; self.isFavorite = isFavorite; self.revision = revision
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }

    public func validated() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw OutfitValidationError.nameRequired }
        guard name.count <= 80 else { throw OutfitValidationError.nameTooLong }
        guard !pieceIDs.isEmpty else { throw OutfitValidationError.piecesRequired }
        guard (mood?.count ?? 0) <= 80, (occasion?.count ?? 0) <= 80,
              revision > 0, revision < Int.max, Set(pieceIDs).count == pieceIDs.count else { throw OutfitValidationError.invalidRecord }
    }
}

/// Durable draft identity and operation identity survive cancellation/restart.
public enum OutfitProposalSource: String, Codable, Sendable { case rules, appleIntelligence }

public enum OutfitDraftStage: String, Codable, Sendable { case builder, readiness, suggest, review }

public struct OutfitDraft: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let outfitID: UUID
    public let ownerID: UUID
    public let baseRevision: Int
    public var operationID: UUID
    public var name: String
    public private(set) var pieceIDs: [UUID]
    public var themeIDs: [UUID]?
    public var pinnedPieceIDs: [UUID]?
    public var reviewedPieceRevisions: [UUID: Int]?
    public var starterPieceID: UUID?
    public var stage: OutfitDraftStage?
    public var proposalSource: OutfitProposalSource?
    public var occasion: String?
    public var mood: String?

    public var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    public init(ownerID: UUID) {
        id = UUID(); outfitID = UUID(); self.ownerID = ownerID; baseRevision = 0
        operationID = UUID(); name = ""; pieceIDs = []
    }

    public init(editing outfit: Outfit) {
        id = UUID(); outfitID = outfit.id; ownerID = outfit.ownerID; baseRevision = outfit.revision
        operationID = UUID(); name = outfit.name; pieceIDs = outfit.pieceIDs
        mood = outfit.mood; occasion = outfit.occasion
    }

    public mutating func select(_ id: UUID) {
        if !pieceIDs.contains(id) { pieceIDs.append(id) }
    }

    public mutating func remove(_ id: UUID) { pieceIDs.removeAll { $0 == id } }

    public mutating func applyManualSelection(_ ids: [UUID], pieces: [WardrobePiece]) throws {
        guard Set(ids).count == ids.count,
              Set(pinnedPieceIDs ?? []).isSubset(of: Set(ids)),
              Set(ids).isSubset(of: Set(pieces.filter { !$0.isArchived }.map(\.id))) else {
            throw OutfitSuggestionError.invalidProposal
        }
        pieceIDs = ids
        try reviewCurrentPieces(pieces)
    }

    public mutating func reviewCurrentPieces(_ pieces: [WardrobePiece]) throws {
        let active = pieces.filter { !$0.isArchived }
        guard Set(pieceIDs).isSubset(of: Set(active.map(\.id))) else { throw OutfitValidationError.unavailablePiece }
        reviewedPieceRevisions = Dictionary(uniqueKeysWithValues: active.filter { pieceIDs.contains($0.id) }.map { ($0.id, $0.revision) })
    }

    public func validated() throws {
        guard baseRevision >= 0, baseRevision < Int.max, Set(pieceIDs).count == pieceIDs.count,
              Set(themeIDs ?? []).count == (themeIDs ?? []).count,
              Set(pinnedPieceIDs ?? []).count == (pinnedPieceIDs ?? []).count else { throw OutfitValidationError.invalidRecord }
    }

    public func validatedForSave(pieces: [WardrobePiece]) throws {
        try validated()
        guard (mood?.count ?? 0) <= 80, (occasion?.count ?? 0) <= 80 else { throw OutfitValidationError.invalidRecord }
        guard !trimmedName.isEmpty else { throw OutfitValidationError.nameRequired }
        guard trimmedName.count <= 80 else { throw OutfitValidationError.nameTooLong }
        guard !pieceIDs.isEmpty else { throw OutfitValidationError.piecesRequired }
        guard Set(pinnedPieceIDs ?? []).isSubset(of: Set(pieceIDs)) else { throw OutfitValidationError.invalidRecord }
        if let revisions = reviewedPieceRevisions {
            guard pieceIDs.allSatisfy({ id in pieces.contains { $0.id == id && revisions[id] == $0.revision } }) else {
                throw OutfitValidationError.stalePieces
            }
        }
        let activeIDs = Set(pieces.filter { !$0.isArchived }.map(\.id))
        guard Set(pieceIDs).isSubset(of: activeIDs) else { throw OutfitValidationError.unavailablePiece }
    }
}
