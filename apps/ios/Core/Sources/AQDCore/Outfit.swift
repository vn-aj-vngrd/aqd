import Foundation

public enum OutfitValidationError: Error, Equatable {
    case nameRequired, nameTooLong, piecesRequired, unavailablePiece, invalidRecord
}

/// An owned private combination. Saving never schedules or records wear.
public struct Outfit: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let ownerID: UUID
    public var name: String
    public var pieceIDs: [UUID]
    public var isFavorite: Bool
    public var revision: Int
    public let createdAt: Date
    public var updatedAt: Date

    public init(id: UUID, ownerID: UUID, name: String, pieceIDs: [UUID], isFavorite: Bool = false,
                revision: Int = 1, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.ownerID = ownerID; self.name = name; self.pieceIDs = pieceIDs
        self.isFavorite = isFavorite; self.revision = revision
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }

    public func validated() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw OutfitValidationError.nameRequired }
        guard name.count <= 80 else { throw OutfitValidationError.nameTooLong }
        guard !pieceIDs.isEmpty else { throw OutfitValidationError.piecesRequired }
        guard revision > 0, revision < Int.max, Set(pieceIDs).count == pieceIDs.count else { throw OutfitValidationError.invalidRecord }
    }
}

/// Durable draft identity and operation identity survive cancellation/restart.
public struct OutfitDraft: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let outfitID: UUID
    public let ownerID: UUID
    public let baseRevision: Int
    public var operationID: UUID
    public var name: String
    public private(set) var pieceIDs: [UUID]
    public var themeIDs: [UUID]?

    public var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    public init(ownerID: UUID) {
        id = UUID(); outfitID = UUID(); self.ownerID = ownerID; baseRevision = 0
        operationID = UUID(); name = ""; pieceIDs = []
    }

    public init(editing outfit: Outfit) {
        id = UUID(); outfitID = outfit.id; ownerID = outfit.ownerID; baseRevision = outfit.revision
        operationID = UUID(); name = outfit.name; pieceIDs = outfit.pieceIDs
    }

    public mutating func select(_ id: UUID) {
        if !pieceIDs.contains(id) { pieceIDs.append(id) }
    }

    public mutating func remove(_ id: UUID) { pieceIDs.removeAll { $0 == id } }

    public func validated() throws {
        guard baseRevision >= 0, baseRevision < Int.max, Set(pieceIDs).count == pieceIDs.count,
              Set(themeIDs ?? []).count == (themeIDs ?? []).count else { throw OutfitValidationError.invalidRecord }
    }

    public func validatedForSave(pieces: [WardrobePiece]) throws {
        try validated()
        guard !trimmedName.isEmpty else { throw OutfitValidationError.nameRequired }
        guard trimmedName.count <= 80 else { throw OutfitValidationError.nameTooLong }
        guard !pieceIDs.isEmpty else { throw OutfitValidationError.piecesRequired }
        let activeIDs = Set(pieces.filter { !$0.isArchived }.map(\.id))
        guard Set(pieceIDs).isSubset(of: activeIDs) else { throw OutfitValidationError.unavailablePiece }
    }
}
