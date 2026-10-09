import Foundation

public enum PieceAvailability: String, Codable, CaseIterable, Sendable {
    case available, unavailable, laundry
}

public struct PieceDetails: Equatable, Codable, Sendable {
    public var color: String
    public var brand: String
    public var size: String
    public var fit: String
    public var material: String
    public var season: String
    public var condition: String
    public var ownershipAge: String
    public var tags: [String]
    public var notes: String
    public var priorWearCount: Int?

    public init(color: String = "", brand: String = "", size: String = "", fit: String = "",
                material: String = "", season: String = "", condition: String = "",
                ownershipAge: String = "", tags: [String] = [], notes: String = "",
                priorWearCount: Int? = nil) {
        self.color = color
        self.brand = brand
        self.size = size
        self.fit = fit
        self.material = material
        self.season = season
        self.condition = condition
        self.ownershipAge = ownershipAge
        self.tags = tags
        self.notes = notes
        self.priorWearCount = priorWearCount
    }

    public func validated() throws {
        guard [color, brand, size, fit, material, season, condition, ownershipAge].allSatisfy({ $0.count <= 80 }) else {
            throw PieceValidationError.metadataTooLong
        }
        guard tags.count <= 20, tags.allSatisfy({ $0.count <= 40 }) else { throw PieceValidationError.invalidTags }
        guard notes.count <= 2000 else { throw PieceValidationError.notesTooLong }
        if let priorWearCount, !(0...10000).contains(priorWearCount) { throw PieceValidationError.invalidPriorWearCount }
    }
}

public struct RecoverablePieceDraft: Equatable, Codable, Sendable {
    public let draft: PieceDraft
    public let operationID: UUID

    public init(draft: PieceDraft, operationID: UUID) {
        self.draft = draft
        self.operationID = operationID
    }
}
