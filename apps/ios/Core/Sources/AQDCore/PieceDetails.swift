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
    public var organizationCategoryID: String?

    public init(color: String = "", brand: String = "", size: String = "", fit: String = "",
                material: String = "", season: String = "", condition: String = "",
                ownershipAge: String = "", tags: [String] = [], notes: String = "",
                priorWearCount: Int? = nil, organizationCategoryID: String? = nil) {
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
        self.organizationCategoryID = organizationCategoryID
    }

    public func validated() throws {
        if let organizationCategoryID, organizationCategoryID.isEmpty || organizationCategoryID.count > 80 { throw PieceValidationError.metadataTooLong }
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

public enum WardrobeCategoryError: Error, Equatable { case invalidName, invalidID, duplicateName, invalidCount }

/// Personal organization stays separate from the garment type used by saved outfits.
public struct WardrobeCategory: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var name: String
    public let type: PieceCategory
    public init(id: String = UUID().uuidString, name: String, type: PieceCategory) {
        self.id = id; self.name = name; self.type = type
    }
    public static let defaults: [Self] = [
        Self(id: "tops", name: "Shirts", type: .tops), Self(id: "bottoms", name: "Bottoms", type: .bottoms),
        Self(id: "dresses", name: "Dresses", type: .dresses), Self(id: "layers", name: "Layers", type: .layers),
        Self(id: "shoes", name: "Shoes", type: .shoes), Self(id: "accessories", name: "Accessories", type: .accessories)
    ]
    public static func validate(_ categories: [Self]) throws {
        guard (1...64).contains(categories.count) else { throw WardrobeCategoryError.invalidCount }
        guard categories.allSatisfy({ !$0.id.isEmpty && $0.id.count <= 80 }), Set(categories.map(\.id)).count == categories.count else { throw WardrobeCategoryError.invalidID }
        let names = categories.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard names.allSatisfy({ !$0.isEmpty && $0.count <= 40 }), zip(names, categories).allSatisfy({ $0.0 == $0.1.name }) else { throw WardrobeCategoryError.invalidName }
        guard Set(names.map { $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX")) }).count == names.count else { throw WardrobeCategoryError.duplicateName }
    }
}
