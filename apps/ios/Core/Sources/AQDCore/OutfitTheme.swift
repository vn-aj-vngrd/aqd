import Foundation

public enum ThemeValidationError: Error, Equatable {
    case nameRequired, nameTooLong, duplicateName, invalidMembership, invalidRecord
}

public struct OutfitTheme: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let ownerID: UUID
    public var name: String
    public var description: String
    public var outfitIDs: [UUID]
    public var revision: Int

    public init(id: UUID = UUID(), ownerID: UUID, name: String, description: String = "", outfitIDs: [UUID] = [], revision: Int = 1) {
        self.id = id; self.ownerID = ownerID; self.name = name; self.description = description
        self.outfitIDs = outfitIDs; self.revision = revision
    }

    public func validated() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ThemeValidationError.nameRequired }
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).count <= 40 else { throw ThemeValidationError.nameTooLong }
        guard revision > 0, revision < Int.max, Set(outfitIDs).count == outfitIDs.count else { throw ThemeValidationError.invalidRecord }
    }

    public static func nameKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}

public struct ThemeDraft: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let themeID: UUID
    public let ownerID: UUID
    public let baseRevision: Int
    public let operationID: UUID
    public var name: String
    public var description: String
    public var outfitIDs: [UUID]

    public init(ownerID: UUID) {
        id = UUID(); themeID = UUID(); self.ownerID = ownerID; baseRevision = 0; operationID = UUID()
        name = ""; description = ""; outfitIDs = []
    }

    public init(editing theme: OutfitTheme) {
        id = UUID(); themeID = theme.id; ownerID = theme.ownerID; baseRevision = theme.revision; operationID = UUID()
        name = theme.name; description = theme.description; outfitIDs = theme.outfitIDs
    }

    public func validatedForSave(themes: [OutfitTheme], outfits: [Outfit]) throws {
        guard baseRevision >= 0, baseRevision < Int.max else { throw ThemeValidationError.invalidRecord }
        let value = OutfitTheme(id: themeID, ownerID: ownerID, name: name, description: description,
                                outfitIDs: outfitIDs, revision: baseRevision + 1)
        try value.validated()
        guard baseRevision >= 0 else { throw ThemeValidationError.invalidRecord }
        guard !themes.contains(where: { $0.id != themeID && OutfitTheme.nameKey($0.name) == OutfitTheme.nameKey(name) }) else {
            throw ThemeValidationError.duplicateName
        }
        let owned = Set(outfits.filter { $0.ownerID == ownerID }.map(\.id))
        guard Set(outfitIDs).isSubset(of: owned) else { throw ThemeValidationError.invalidMembership }
    }
}
