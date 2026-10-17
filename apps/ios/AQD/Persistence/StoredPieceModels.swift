import AQDCore
import Foundation
import SwiftData

@Model
final class StoredPiece {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String
    var photoID: UUID
    var photoQuarterTurns: Int = 0
    var photoCropX: Double?
    var photoCropY: Double?
    var photoCropWidth: Double?
    var photoCropHeight: Double?
    var color: String
    var brand: String
    var size: String
    var fit: String
    var material: String
    var season: String
    var condition: String
    var ownershipAge: String
    var tags: [String]
    var notes: String
    var priorWearCount: Int?
    var availability: String
    var revision: Int
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    init(_ piece: WardrobePiece) {
        id = piece.id
        name = piece.name
        category = piece.category.rawValue
        photoID = piece.photoID
        photoQuarterTurns = piece.photoRecipe.quarterTurns
        photoCropX = piece.photoRecipe.crop?.x
        photoCropY = piece.photoRecipe.crop?.y
        photoCropWidth = piece.photoRecipe.crop?.width
        photoCropHeight = piece.photoRecipe.crop?.height
        color = piece.details.color
        brand = piece.details.brand
        size = piece.details.size
        fit = piece.details.fit
        material = piece.details.material
        season = piece.details.season
        condition = piece.details.condition
        ownershipAge = piece.details.ownershipAge
        tags = Self.storedTags(for: piece.details)
        notes = piece.details.notes
        priorWearCount = piece.details.priorWearCount
        availability = piece.availability.rawValue
        revision = piece.revision
        isArchived = piece.isArchived
        createdAt = piece.createdAt
        updatedAt = piece.updatedAt
    }

    /// A piece's category assignment has no column of its own: adding one would change every versioned schema hash.
    /// It rides in `tags` as one reserved entry that never reaches `PieceDetails.tags`.
    private static let categoryTagPrefix = "aqd.category:"

    private static func storedTags(for details: PieceDetails) -> [String] {
        details.tags + (details.organizationCategoryID.map { [categoryTagPrefix + $0] } ?? [])
    }

    private static func visibleTags(_ tags: [String]) -> [String] { tags.filter { !$0.hasPrefix(categoryTagPrefix) } }

    private static func organizationCategoryID(in tags: [String]) -> String? {
        tags.first { $0.hasPrefix(categoryTagPrefix) }.map { String($0.dropFirst(categoryTagPrefix.count)) }
    }

    func recipe() throws -> PhotoEditRecipe {
        let components = [photoCropX, photoCropY, photoCropWidth, photoCropHeight]
        guard components.allSatisfy({ $0 == nil }) || components.allSatisfy({ $0 != nil }) else {
            throw PieceStore.StoreError.invalidRecord
        }
        let crop: NormalizedPhotoCrop?
        if let x = photoCropX, let y = photoCropY, let w = photoCropWidth, let h = photoCropHeight {
            crop = .init(x: x, y: y, width: w, height: h)
        } else { crop = nil }
        let result = PhotoEditRecipe(quarterTurns: photoQuarterTurns, crop: crop)
        try result.validated()
        return result
    }

    func value() throws -> WardrobePiece {
        guard let category = PieceCategory(rawValue: category),
              let availability = PieceAvailability(rawValue: availability), revision > 0 else {
            throw PieceStore.StoreError.invalidRecord
        }
        return WardrobePiece(id: id, name: name, category: category, photoID: photoID,
                             details: PieceDetails(color: color, brand: brand, size: size, fit: fit, material: material,
                                                   season: season, condition: condition, ownershipAge: ownershipAge,
                                                   tags: Self.visibleTags(tags), notes: notes, priorWearCount: priorWearCount,
                                                   organizationCategoryID: Self.organizationCategoryID(in: tags)),
                             availability: availability, revision: revision, isArchived: isArchived,
                             createdAt: createdAt, updatedAt: updatedAt, photoRecipe: try recipe())
    }

    func apply(_ piece: WardrobePiece) {
        name = piece.name
        category = piece.category.rawValue
        photoID = piece.photoID
        photoQuarterTurns = piece.photoRecipe.quarterTurns
        photoCropX = piece.photoRecipe.crop?.x
        photoCropY = piece.photoRecipe.crop?.y
        photoCropWidth = piece.photoRecipe.crop?.width
        photoCropHeight = piece.photoRecipe.crop?.height
        color = piece.details.color
        brand = piece.details.brand
        size = piece.details.size
        fit = piece.details.fit
        material = piece.details.material
        season = piece.details.season
        condition = piece.details.condition
        ownershipAge = piece.details.ownershipAge
        tags = Self.storedTags(for: piece.details)
        notes = piece.details.notes
        priorWearCount = piece.details.priorWearCount
        availability = piece.availability.rawValue
        revision = piece.revision
        isArchived = piece.isArchived
        updatedAt = piece.updatedAt
    }
}

@Model
final class StoredPhoto {
    @Attribute(.unique) var id: UUID
    var pixelWidth: Int
    var pixelHeight: Int

    init(id: UUID, pixelWidth: Int, pixelHeight: Int) {
        self.id = id
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}

/// Exact operation acknowledgment proof, not a historical media owner.
/// A retry returns this immutable result even if superseded media has been released.
@Model
final class StoredPieceSave {
    @Attribute(.unique) var id: UUID
    var itemID: UUID
    var draftDigest: String
    var snapshot: Data

    init(id: UUID, itemID: UUID, draftDigest: String, snapshot: Data) {
        self.id = id
        self.itemID = itemID
        self.draftDigest = draftDigest
        self.snapshot = snapshot
    }
}

@Model
final class StoredPieceDraft {
    @Attribute(.unique) var id: UUID
    var itemID: UUID
    var operationID: UUID
    var payload: Data
    var updatedAt: Date

    init(draft: PieceDraft, operationID: UUID, payload: Data) {
        self.id = draft.id
        self.itemID = draft.itemID
        self.operationID = operationID
        self.payload = payload
        self.updatedAt = Date()
    }
}

/// Minimal local deletion acknowledgment prevents retry resurrecting a removed identity.
/// Cleanup candidates are committed with record removal, then reconciled separately.
/// This is not a remote-sync tombstone.
@Model
final class StoredPieceDeletion {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var itemID: UUID
    var expectedRevision: Int
    var pendingPhotoIDs: [UUID] = []

    init(operationID: UUID, itemID: UUID, expectedRevision: Int, pendingPhotoIDs: [UUID]) {
        id = operationID
        self.itemID = itemID
        self.expectedRevision = expectedRevision
        self.pendingPhotoIDs = pendingPhotoIDs
    }
}

/// A local cleanup intent, not a deletion receipt or a claim that media is unowned.
/// Stage it before file writes, and with every relinquished draft reference.
@Model
final class StoredPhotoCleanup {
    @Attribute(.unique) var id: UUID
    var recipeDigests: [String] = []

    init(photoID: UUID) { id = photoID }
}

extension WardrobePiece {
    /// The piece without its category assignment. Receipts written before assignments were persisted lack it on the
    /// stored side, so receipt checks compare both sides in this form.
    var withoutCategoryAssignment: WardrobePiece {
        let stored = PieceDetails(color: details.color, brand: details.brand, size: details.size, fit: details.fit, material: details.material,
                                  season: details.season, condition: details.condition, ownershipAge: details.ownershipAge,
                                  tags: details.tags, notes: details.notes, priorWearCount: details.priorWearCount)
        return WardrobePiece(id: id, name: name, category: category, photoID: photoID, details: stored, availability: availability,
                             revision: revision, isArchived: isArchived, createdAt: createdAt, updatedAt: updatedAt, photoRecipe: photoRecipe)
    }
}
