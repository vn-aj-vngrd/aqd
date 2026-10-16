import Foundation

public struct TripConfiguration: Codable, Equatable, Sendable {
    public var destination: String
    public var activities: [String]
    public init(destination: String = "", activities: [String] = []) { self.destination = destination; self.activities = activities }
    public func validated() throws {
        guard destination.count <= 160, activities.count <= 20,
              activities.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.count <= 80 }) else { throw PlanAuthoringError.invalidSlots }
    }
}
public struct PackingItem: Identifiable, Equatable, Sendable {
    public var id: UUID { piece.id }
    public let piece: WardrobePiece
    public let uses: Int
    public let checked: Bool
}
public struct PackingGap: Identifiable, Equatable, Sendable {
    public let id: String
    public let day: LocalPlanDay
    public let entryID: UUID?
    public let reason: String
}
public struct TripPackingSummary: Equatable, Sendable {
    public let items: [PackingItem]
    public let gaps: [PackingGap]
    public init(plan: PlanDefinition, entries: [OutfitPlanEntry], outfits: [Outfit], pieces: [WardrobePiece], checkedIDs: Set<UUID>) throws {
        try plan.validated()
        guard plan.trip != nil, Set(entries.map(\.id)).count == entries.count,
              Set(outfits.map(\.id)).count == outfits.count, Set(pieces.map(\.id)).count == pieces.count else { throw PlanAuthoringError.invalidSlots }
        let outfitsByID = Dictionary(uniqueKeysWithValues: outfits.map { ($0.id, $0) })
        let piecesByID = Dictionary(uniqueKeysWithValues: pieces.map { ($0.id, $0) })
        var uses: [UUID: Int] = [:], missing: [PackingGap] = []
        let entries = entries.filter { $0.planID == plan.id }
        for entry in entries {
            try entry.validated()
            guard entry.ownerID == plan.ownerID else { throw PlanAuthoringError.invalidSlots }
            guard let outfit = entry.outfitID.flatMap({ outfitsByID[$0] }) else {
                missing.append(PackingGap(id: entry.id.uuidString, day: entry.day, entryID: entry.id, reason: "Outfit unassigned")); continue
            }
            try outfit.validated()
            guard outfit.ownerID == plan.ownerID else { throw PlanAuthoringError.invalidSlots }
            let unavailable = outfit.pieceIDs.contains { id in piecesByID[id].map { $0.isArchived || $0.availability != .available } ?? true }
            if unavailable || entry.requiresReview || entry.outfitRevision != outfit.revision {
                missing.append(PackingGap(id: entry.id.uuidString, day: entry.day, entryID: entry.id,
                    reason: unavailable ? "Assigned pieces need attention" : "Outfit changed; review assignment"))
            }
            for id in outfit.pieceIDs where piecesByID[id] != nil { uses[id, default: 0] += 1 }
        }
        let covered = Set(entries.map { $0.day.key })
        for day in try plan.days() where !covered.contains(day.key) {
            missing.append(PackingGap(id: "date:" + day.key, day: day, entryID: nil, reason: "No plan entry"))
        }
        items = uses.compactMap { id, count in piecesByID[id].map { PackingItem(piece: $0, uses: count, checked: checkedIDs.contains(id)) } }
            .sorted { $0.piece.name == $1.piece.name ? $0.id.uuidString < $1.id.uuidString : $0.piece.name.localizedStandardCompare($1.piece.name) == .orderedAscending }
        gaps = missing.sorted { $0.day.key == $1.day.key ? $0.id < $1.id : $0.day.key < $1.day.key }
    }
}
public struct PackingState: Codable, Equatable, Sendable {
    public let planID: UUID
    public var checkedIDs: Set<UUID>
    public var revision: Int
    public init(planID: UUID, checkedIDs: Set<UUID> = [], revision: Int = 0) { self.planID = planID; self.checkedIDs = checkedIDs; self.revision = revision }
}
public struct PackingCheckRequest: Codable, Equatable, Sendable {
    public let operationID: UUID
    public let planID: UUID
    public let pieceID: UUID
    public let checked: Bool
    public let expectedRevision: Int
    public init(planID: UUID, pieceID: UUID, checked: Bool, expectedRevision: Int, operationID: UUID = UUID()) {
        self.operationID = operationID; self.planID = planID; self.pieceID = pieceID; self.checked = checked; self.expectedRevision = expectedRevision
    }
}
