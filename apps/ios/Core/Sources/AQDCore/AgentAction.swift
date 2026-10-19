import Foundation

public struct AgentAvailabilityChange: Codable, Equatable, Sendable {
    public let pieceID: UUID
    public let pieceName: String
    public let expectedRevision: Int
    public let value: PieceAvailability
    public let operationID: UUID
    public init(piece: WardrobePiece, value: PieceAvailability) { pieceID = piece.id; pieceName = piece.name; expectedRevision = piece.revision; self.value = value; operationID = UUID() }
}
public struct AgentPieceChange: Codable, Equatable, Sendable {
    public let draft: PieceDraft
    public let operationID: UUID
    /// Set when the draft is a new piece guessed from a chat photo; the photo itself is added in the Closet editor.
    public let attachmentID: UUID?
    public init(draft: PieceDraft, attachmentID: UUID? = nil) { self.draft = draft; operationID = UUID(); self.attachmentID = attachmentID }
    public var isNewPiece: Bool { attachmentID != nil }
}
/// What a closet tidy does to the pieces it names. Archive keeps a piece and can be undone; delete removes it for good.
public enum AgentTidyOp: String, Codable, CaseIterable, Sendable {
    case archive, unarchive, delete
    public var isDestructive: Bool { self == .delete }
    public var verb: String { switch self { case .archive: "Archive"; case .unarchive: "Restore"; case .delete: "Delete" } }
}
/// One piece in a tidy review. The owner can untick it before approving; the revision binds it to the piece as it was reviewed.
public struct AgentTidyItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let expectedRevision: Int
    public let operationID: UUID
    public var selected = true
    /// Filled by the app for a delete, from the piece's current dependencies, so the confirmation can name what is affected.
    public var impact: PieceDeletionImpact?
    public init(piece: WardrobePiece) { id = piece.id; name = piece.name; expectedRevision = piece.revision; operationID = UUID() }
}
public struct AgentTidyChange: Codable, Equatable, Sendable {
    public let op: AgentTidyOp
    public var items: [AgentTidyItem]
    public init(op: AgentTidyOp, pieces: [WardrobePiece]) { self.op = op; items = pieces.map(AgentTidyItem.init(piece:)) }
    public var selectedItems: [AgentTidyItem] { items.filter(\.selected) }
    public mutating func setSelected(_ id: UUID, _ value: Bool) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].selected = value
    }
    /// Pieces a delete would leave out of outfits, themes or future plans.
    public var dependentCount: Int { selectedItems.reduce(0) { $0 + ($1.impact.map { $0.outfitRevisions.count + $0.themeRevisions.count + $0.futurePlanRevisions.count } ?? 0) } }
    public var summary: String {
        let count = selectedItems.count
        return "\(op.verb) \(count) piece" + (count == 1 ? "" : "s")
    }
}

public enum AgentReviewedAction: Codable, Equatable, Sendable {
    case outfit(OutfitDraft), theme(ThemeDraft), plan(PlanAuthoringDraft), wear(OutfitWearDraft), availability(AgentAvailabilityChange), profile(LocalIdentityDraft), piece(AgentPieceChange), trip(AgentTripDraft), tidy(AgentTidyChange)
    public var title: String {
        switch self {
        case .outfit: "Review outfit"; case .theme: "Review theme"; case .plan: "Review plan"; case .wear: "Review recorded wear"; case .availability: "Review piece availability"
        case .profile: "Review profile"; case .piece: "Review piece"; case .trip: "Review trip looks"; case .tidy(let change): "Review \(change.op.verb.lowercased())"
        }
    }
}
public enum AgentActionStatus: String, Codable, Sendable { case proposed, executing, succeeded, cancelled }

/// What it takes to put a record back after an approved change. Only changes that keep a full copy of the earlier state can be undone.
public enum AgentUndo: Codable, Equatable, Sendable {
    public struct Item: Codable, Equatable, Sendable {
        public let pieceID: UUID
        public let wasArchived: Bool
        public let appliedRevision: Int
        public init(pieceID: UUID, wasArchived: Bool, appliedRevision: Int) { self.pieceID = pieceID; self.wasArchived = wasArchived; self.appliedRevision = appliedRevision }
    }
    case availability(pieceID: UUID, previous: PieceAvailability, appliedRevision: Int)
    case archive([Item])
    case piece(previous: PieceDraft, appliedRevision: Int)

    /// The pieces this undo touches with the revision each must still be at. A piece edited since the change is left alone.
    public var requiredRevisions: [UUID: Int] {
        switch self {
        case .availability(let id, _, let revision): [id: revision]
        case .archive(let items): Dictionary(uniqueKeysWithValues: items.map { ($0.pieceID, $0.appliedRevision) })
        case .piece(let previous, let revision): [previous.itemID: revision]
        }
    }
    public func isEligible(currentRevisions: [UUID: Int]) -> Bool {
        let required = requiredRevisions
        return !required.isEmpty && required.allSatisfy { currentRevisions[$0.key] == $0.value }
    }
}
public struct AgentActionReceipt: Codable, Equatable, Sendable {
    public let recordID: UUID
    public let kind: String
    public let acknowledgedAt: Date
    /// How many records the change touched, when it touched several.
    public var count: Int?
    public var undo: AgentUndo?
    public var undoneAt: Date?
    public init(recordID: UUID, kind: String, count: Int? = nil, undo: AgentUndo? = nil) { self.recordID = recordID; self.kind = kind; acknowledgedAt = Date(); self.count = count; self.undo = undo }
    public var canOfferUndo: Bool { undo != nil && undoneAt == nil }
}
public struct AgentActionProposal: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let version: Int
    public var action: AgentReviewedAction
    public var status: AgentActionStatus
    public var receipt: AgentActionReceipt?
    public var toolRequest: AgentMutationRequest?
    public var sources: [AgentSelectedRecord]?
    /// The assistant attempt that produced this proposal; nil for proposals made before messages were linked.
    public var attemptID: UUID?
    public init(action: AgentReviewedAction) { id = UUID(); version = 1; self.action = action; status = .proposed }
    public mutating func approve(version: Int) throws {
        guard version == self.version, status == .proposed || status == .executing else { throw PlanValidationError.invalidRecord }
        status = .executing
    }
    public mutating func cancel() throws {
        guard status == .proposed else { throw PlanValidationError.invalidRecord }; status = .cancelled
    }
}
