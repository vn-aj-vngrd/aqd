import Foundation

public enum WearValidationError: Error, Equatable { case piecesRequired, stalePieces, futureDay, alreadyRecorded, invalidRecord }

public struct WearPieceSnapshot: Codable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let category: PieceCategory
    public init(_ piece: WardrobePiece) { id = piece.id; name = piece.name; category = piece.category }
}

public struct OutfitWearRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let ownerID: UUID
    public let day: LocalPlanDay
    public let outfitID: UUID?
    public let pieces: [WearPieceSnapshot]
    public var revision: Int
    public var planEntryID: UUID?

    public init(id: UUID, ownerID: UUID, day: LocalPlanDay, outfitID: UUID?, pieces: [WearPieceSnapshot], revision: Int = 1, planEntryID: UUID? = nil) {
        self.id = id; self.ownerID = ownerID; self.day = day; self.outfitID = outfitID; self.pieces = pieces; self.revision = revision; self.planEntryID = planEntryID
    }
    public func validated() throws {
        _ = try day.date()
        guard !pieces.isEmpty, Set(pieces.map(\.id)).count == pieces.count, revision > 0, revision < Int.max else {
            throw WearValidationError.invalidRecord
        }
    }
    public var duplicateKey: String { day.key + ":" + pieces.map { $0.id.uuidString }.sorted().joined(separator: ",") }
}

public struct OutfitWearDraft: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let wearID: UUID
    public let ownerID: UUID
    public let operationID: UUID
    public var day: LocalPlanDay
    public var outfitID: UUID?
    public var pieceIDs: [UUID]
    public var reviewedRevisions: [UUID: Int]
    public var baseRecord: OutfitWearRecord?
    public var planEntry: OutfitPlanEntry?
    public var acceptedDuplicateID: UUID?
    public var initialDay: LocalPlanDay?
    public var initialOutfitID: UUID?
    public var initialPieceIDs: [UUID]?

    public var hasChanges: Bool {
        if let baseRecord {
            return day != baseRecord.day || outfitID != baseRecord.outfitID || Set(pieceIDs) != Set(baseRecord.pieces.map(\.id))
        }
        guard let initialDay, let initialPieceIDs else { return true }
        return day != initialDay || outfitID != initialOutfitID || Set(pieceIDs) != Set(initialPieceIDs)
    }

    public init(ownerID: UUID, outfitID: UUID? = nil, pieces: [WardrobePiece], day: LocalPlanDay = LocalPlanDay()) {
        id = UUID(); wearID = UUID(); operationID = UUID(); self.ownerID = ownerID; self.day = day; self.outfitID = outfitID
        initialDay = day; initialOutfitID = outfitID; initialPieceIDs = pieces.map(\.id)
        pieceIDs = pieces.map(\.id); reviewedRevisions = Dictionary(uniqueKeysWithValues: pieces.map { ($0.id, $0.revision) })
    }
    public init(editing record: OutfitWearRecord, currentPieces: [WardrobePiece]) {
        id = UUID(); operationID = UUID(); wearID = record.id; ownerID = record.ownerID
        day = record.day; outfitID = record.outfitID; pieceIDs = record.pieces.map(\.id)
        reviewedRevisions = Dictionary(uniqueKeysWithValues: currentPieces.map { ($0.id, $0.revision) })
        baseRecord = record
    }
    public func validatedForSave(pieces: [WardrobePiece], now: Date = Date()) throws {
        _ = try day.date()
        if let baseRecord {
            try baseRecord.validated()
            guard baseRecord.id == wearID, baseRecord.ownerID == ownerID, planEntry == nil else { throw WearValidationError.invalidRecord }
        }
        if let planEntry {
            try planEntry.validated()
            guard planEntry.ownerID == ownerID, planEntry.state == .planned || planEntry.state == .unassigned,
                  planEntry.day == day else { throw WearValidationError.invalidRecord }
        }
        guard !pieceIDs.isEmpty else { throw WearValidationError.piecesRequired }
        guard Set(pieceIDs).count == pieceIDs.count else { throw WearValidationError.invalidRecord }
        let zone = TimeZone(identifier: day.timeZoneID) ?? .current
        guard day.key <= LocalPlanDay(date: now, timeZone: zone).key else { throw WearValidationError.futureDay }
        guard pieceIDs.allSatisfy({ id in baseRecord?.pieces.contains { $0.id == id } == true || pieces.contains { $0.id == id && reviewedRevisions[id] == $0.revision } }) else {
            throw WearValidationError.stalePieces
        }
    }
    public var duplicateKey: String { day.key + ":" + pieceIDs.map(\.uuidString).sorted().joined(separator: ",") }
}
