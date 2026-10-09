import Foundation

public enum PieceCategory: String, Codable, CaseIterable, Sendable {
    case tops = "Tops"
    case bottoms = "Bottoms"
    case dresses = "Dresses"
    case layers = "Layers"
    case shoes = "Shoes"
    case accessories = "Accessories"
}

public enum PieceValidationError: Error, Equatable, Sendable {
    case photoRequired
    case nameRequired
    case categoryRequired
    case nameTooLong
    case metadataTooLong, invalidTags, notesTooLong, invalidPriorWearCount
}

public struct PieceDraft: Equatable, Codable, Sendable {
    public let id: UUID
    public let itemID: UUID
    public var name: String
    public var category: PieceCategory?
    public var photoID: UUID? {
        didSet { if photoID != oldValue { photoRecipe = .fitOriginal } }
    }
    public var photoRecipe: PhotoEditRecipe
    public var baseRevision: Int?
    public var details: PieceDetails
    public var availability: PieceAvailability

    public init(id: UUID = UUID(), itemID: UUID = UUID(), name: String = "",
                category: PieceCategory? = nil, photoID: UUID? = nil, baseRevision: Int? = nil,
                details: PieceDetails = PieceDetails(), availability: PieceAvailability = .available,
                photoRecipe: PhotoEditRecipe = .fitOriginal) {
        self.id = id
        self.itemID = itemID
        self.name = name
        self.category = category
        self.photoID = photoID
        self.photoRecipe = photoRecipe
        self.baseRevision = baseRevision
        self.details = details
        self.availability = availability
    }

    private enum CodingKeys: String, CodingKey {
        case id, itemID, name, category, photoID, baseRevision, details, availability, photoRecipe
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(id: try values.decode(UUID.self, forKey: .id),
                  itemID: try values.decode(UUID.self, forKey: .itemID),
                  name: try values.decode(String.self, forKey: .name),
                  category: try values.decodeIfPresent(PieceCategory.self, forKey: .category),
                  photoID: try values.decodeIfPresent(UUID.self, forKey: .photoID),
                  baseRevision: try values.decodeIfPresent(Int.self, forKey: .baseRevision),
                  details: try values.decode(PieceDetails.self, forKey: .details),
                  availability: try values.decode(PieceAvailability.self, forKey: .availability),
                  photoRecipe: try values.decodeIfPresent(PhotoEditRecipe.self, forKey: .photoRecipe) ?? .fit)
        try photoRecipe.validated()
    }

    public func validated() throws {
        guard photoID != nil else { throw PieceValidationError.photoRequired }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PieceValidationError.nameRequired
        }
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).count <= 80 else {
            throw PieceValidationError.nameTooLong
        }
        guard category != nil else { throw PieceValidationError.categoryRequired }
        try photoRecipe.validated()
        try details.validated()
    }
}
