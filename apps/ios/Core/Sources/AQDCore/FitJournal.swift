import Foundation

public enum FitValidationError: Error, Equatable { case contentRequired, noteTooLong, invalidRecord, outfitUnavailable }

public struct FitOutfitSnapshot: Codable, Equatable, Sendable {
    public let id: UUID
    public let ownerID: UUID
    public let name: String
    public let revision: Int
    public let pieces: [WearPieceSnapshot]
    public init(outfit: Outfit, pieces: [WardrobePiece]) throws {
        try outfit.validated()
        id = outfit.id; ownerID = outfit.ownerID; name = outfit.name; revision = outfit.revision
        self.pieces = try outfit.pieceIDs.map { id in
            guard let piece = pieces.first(where: { $0.id == id }) else { throw FitValidationError.outfitUnavailable }
            return WearPieceSnapshot(piece)
        }
    }
    public func validated() throws {
        guard !name.isEmpty, revision > 0, !pieces.isEmpty, Set(pieces.map(\.id)).count == pieces.count else { throw FitValidationError.invalidRecord }
    }
}

public struct FitMemory: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let ownerID: UUID
    public var day: LocalPlanDay
    public var photoID: UUID?
    public var photoRecipe: PhotoEditRecipe
    public var outfit: FitOutfitSnapshot?
    public var note: String
    public var revision: Int
    public init(id: UUID = UUID(), ownerID: UUID) {
        self.id = id; self.ownerID = ownerID; day = LocalPlanDay(); photoRecipe = .fitOriginal; note = ""; revision = 1
    }
    public func validated(requireContent: Bool = true) throws {
        _ = try day.date(); try photoRecipe.validated()
        guard revision > 0, revision < Int.max else { throw FitValidationError.invalidRecord }
        if let outfit { try outfit.validated(); guard outfit.ownerID == ownerID else { throw FitValidationError.invalidRecord } }
        if requireContent {
            guard photoID != nil || outfit != nil else { throw FitValidationError.contentRequired }
            guard note.count <= 500 else { throw FitValidationError.noteTooLong }
        }
    }
}

public struct FitDraft: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let operationID: UUID
    public let base: FitMemory?
    public var value: FitMemory
    public init(ownerID: UUID, base: FitMemory? = nil) {
        id = UUID(); operationID = UUID(); self.base = base; value = base ?? FitMemory(ownerID: ownerID)
    }
    public func validated(requireContent: Bool = true) throws {
        try value.validated(requireContent: requireContent)
        if let base {
            try base.validated()
            guard base.id == value.id, base.ownerID == value.ownerID, base.revision == value.revision else { throw FitValidationError.invalidRecord }
        } else if value.revision != 1 { throw FitValidationError.invalidRecord }
    }
    public func result() throws -> FitMemory {
        try validated()
        var result = value; result.revision = (base?.revision ?? 0) + 1; try result.validated(); return result
    }
    public var hasChanges: Bool {
        if let base { return base != value }
        return value.photoID != nil || value.outfit != nil || !value.note.isEmpty || value.day != LocalPlanDay()
    }
}

public struct FitDeletionRequest: Codable, Equatable, Sendable {
    public let operationID: UUID
    public let memory: FitMemory
    public init(memory: FitMemory, operationID: UUID = UUID()) { self.operationID = operationID; self.memory = memory }
}
