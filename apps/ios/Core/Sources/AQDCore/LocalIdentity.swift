import Foundation

public struct LocalProfileIdentity: Codable, Equatable, Sendable {
    public static let defaultCaption = "A little of what I wear."
    public let ownerID: UUID
    public let name: String?
    public let caption: String?
    public let photoID: UUID?
    public let photoRecipe: PhotoEditRecipe?
    public let revision: Int
    public init(ownerID: UUID, name: String?, photoID: UUID?, revision: Int, photoRecipe: PhotoEditRecipe? = nil, caption: String? = nil) {
        self.ownerID = ownerID; self.name = name; self.photoID = photoID; self.revision = revision; self.photoRecipe = photoRecipe; self.caption = caption
    }
    public func validated() throws {
        try photoRecipe?.validated()
        guard caption.map({ $0.count <= 160 && $0 == $0.trimmingCharacters(in: .whitespacesAndNewlines) }) ?? true else { throw PlanValidationError.invalidRecord }
        guard revision > 0, revision < Int.max, name.map({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? true else { throw PlanValidationError.invalidRecord }
    }
}

public struct LocalIdentityDraft: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let operationID: UUID
    public let ownerID: UUID
    public let base: LocalProfileIdentity?
    public var name: String
    public var caption: String?
    public var photoID: UUID?
    public var photoRecipe: PhotoEditRecipe?
    public init(ownerID: UUID, base: LocalProfileIdentity? = nil) {
        id = UUID(); operationID = UUID(); self.ownerID = ownerID; self.base = base
        name = base?.name ?? ""; caption = base?.caption; photoID = base?.photoID; photoRecipe = base?.photoRecipe
    }
    public func validatedForRetention() throws {
        var structuralDraft = self
        structuralDraft.caption = nil
        _ = try structuralDraft.result()
    }
    public func result() throws -> LocalProfileIdentity {
        if let base { try base.validated(); guard base.ownerID == ownerID else { throw PlanValidationError.invalidRecord } }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = LocalProfileIdentity(ownerID: ownerID, name: trimmed.isEmpty ? nil : trimmed, photoID: photoID, revision: (base?.revision ?? 0) + 1, photoRecipe: photoID == nil ? nil : photoRecipe, caption: caption?.trimmingCharacters(in: .whitespacesAndNewlines))
        try value.validated(); return value
    }
    public var hasChanges: Bool { name != (base?.name ?? "") || caption != base?.caption || photoID != base?.photoID || photoRecipe != base?.photoRecipe }
}
