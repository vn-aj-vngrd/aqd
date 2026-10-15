import Foundation

/// Revision-bound review, with no retained photo, metadata or historical media ownership.
public struct PieceDeletionImpact: Codable, Equatable, Sendable {
    public let pieceID: UUID
    public let pieceRevision: Int
    public let outfitRevisions: [UUID: Int]
    public let themeRevisions: [UUID: Int]
    public let futurePlanRevisions: [UUID: Int]

    public init(pieceID: UUID, pieceRevision: Int, outfitRevisions: [UUID: Int], themeRevisions: [UUID: Int], futurePlanRevisions: [UUID: Int]) {
        self.pieceID = pieceID; self.pieceRevision = pieceRevision; self.outfitRevisions = outfitRevisions
        self.themeRevisions = themeRevisions; self.futurePlanRevisions = futurePlanRevisions
    }
    public var hasDependencies: Bool { !outfitRevisions.isEmpty || !themeRevisions.isEmpty || !futurePlanRevisions.isEmpty }
}
