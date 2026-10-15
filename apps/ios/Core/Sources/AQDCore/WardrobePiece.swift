import Foundation

public enum PieceSort: String, CaseIterable, Sendable {
    case name
    case recentlyAdded
    case mostWorn, leastWorn, lastWorn

    public var title: String {
        switch self {
        case .name: "Name A–Z"
        case .recentlyAdded: "Recently added"
        case .mostWorn: "Most worn"
        case .leastWorn: "Least worn"
        case .lastWorn: "Last worn"
        }
    }
}

public struct PieceWearSummary: Equatable, Sendable {
    public let recorded: Int
    public let priorEstimate: Int?
    public let lastWorn: LocalPlanDay?
    public var total: Int { recorded + (priorEstimate ?? 0) }

    public init(piece: WardrobePiece, records: [OutfitWearRecord]) {
        let matches = records.filter { $0.pieces.contains { $0.id == piece.id } }
        recorded = matches.count
        priorEstimate = piece.details.priorWearCount.flatMap { (0...10000).contains($0) ? $0 : nil }
        lastWorn = matches.map(\.day).max { $0.key < $1.key }
    }
}

public struct WardrobePiece: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let category: PieceCategory
    public let photoID: UUID
    public let photoRecipe: PhotoEditRecipe
    public let details: PieceDetails
    public let availability: PieceAvailability
    public let revision: Int
    public let isArchived: Bool
    public let createdAt: Date
    public let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, name, category, photoID, details, availability, revision, isArchived, createdAt, updatedAt, photoRecipe
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(id: try values.decode(UUID.self, forKey: .id),
                  name: try values.decode(String.self, forKey: .name),
                  category: try values.decode(PieceCategory.self, forKey: .category),
                  photoID: try values.decode(UUID.self, forKey: .photoID),
                  details: try values.decode(PieceDetails.self, forKey: .details),
                  availability: try values.decode(PieceAvailability.self, forKey: .availability),
                  revision: try values.decode(Int.self, forKey: .revision),
                  isArchived: try values.decode(Bool.self, forKey: .isArchived),
                  createdAt: try values.decode(Date.self, forKey: .createdAt),
                  updatedAt: try values.decode(Date.self, forKey: .updatedAt),
                  photoRecipe: try values.decodeIfPresent(PhotoEditRecipe.self, forKey: .photoRecipe) ?? .fit)
        try photoRecipe.validated()
    }

    public init(id: UUID, name: String, category: PieceCategory, photoID: UUID,
                details: PieceDetails = PieceDetails(), availability: PieceAvailability = .available,
                revision: Int = 1, isArchived: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date(), photoRecipe: PhotoEditRecipe = .fitOriginal) {
        self.id = id
        self.name = name
        self.category = category
        self.photoID = photoID
        self.photoRecipe = photoRecipe
        self.details = details
        self.availability = availability
        self.revision = revision
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
