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
public enum AgentReviewedAction: Codable, Equatable, Sendable {
    case outfit(OutfitDraft), theme(ThemeDraft), plan(PlanAuthoringDraft), wear(OutfitWearDraft), availability(AgentAvailabilityChange), profile(LocalIdentityDraft), piece(AgentPieceChange), trip(AgentTripDraft)
    public var title: String {
        switch self { case .outfit: "Review outfit"; case .theme: "Review theme"; case .plan: "Review plan"; case .wear: "Review recorded wear"; case .availability: "Review piece availability"; case .profile: "Review profile"; case .piece: "Review piece"; case .trip: "Review trip looks" }
    }
}
public enum AgentActionStatus: String, Codable, Sendable { case proposed, executing, succeeded, cancelled }
public struct AgentActionReceipt: Codable, Equatable, Sendable {
    public let recordID: UUID
    public let kind: String
    public let acknowledgedAt: Date
    public init(recordID: UUID, kind: String) { self.recordID = recordID; self.kind = kind; acknowledgedAt = Date() }
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
