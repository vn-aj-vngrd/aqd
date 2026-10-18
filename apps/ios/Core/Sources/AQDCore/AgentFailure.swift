import Foundation

/// Why a reply failed, in words the owner can act on: a title, a one-line cause and the ways forward. Stored on the failed message.
public struct AgentFailure: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Sendable {
        case modelUnavailable, modelPreparing, intelligenceOff, unsupportedLanguage, contextTooLong, timedOut, guardrail, interrupted, toolRejected, storage, generation
    }
    public enum Action: String, Codable, CaseIterable, Sendable {
        case retry, shorten, edit, newChat, openSettings, continueWithoutCloset
        public var title: String {
            switch self {
            case .retry: "Retry"; case .shorten: "Try a shorter request"; case .edit: "Edit request"; case .newChat: "New chat"
            case .openSettings: "Open Settings"; case .continueWithoutCloset: "Continue without closet"
            }
        }
        public var symbol: String {
            switch self {
            case .retry: "arrow.clockwise"; case .shorten, .edit: "pencil"; case .newChat: "square.and.pencil"; case .openSettings: "gearshape"; case .continueWithoutCloset: "tshirt"
            }
        }
    }
    public var kind: Kind
    public var title: String
    public var cause: String
    public var actions: [Action]
    /// True when text arrived before the failure and is kept above the failure notice.
    public var keptPartialReply: Bool

    /// `closetIncluded` offers Continue without closet where the closet may be what made the request too big.
    public static func make(_ kind: Kind, keptPartialReply: Bool = false, closetIncluded: Bool = true) -> AgentFailure {
        let title: String, cause: String
        var actions: [Action]
        switch kind {
        case .modelUnavailable: (title, cause, actions) = ("Agent isn’t available", "The on-device model can’t run on this iPhone right now.", [.retry])
        case .modelPreparing: (title, cause, actions) = ("Agent is getting ready", "Apple Intelligence is still preparing the on-device model.", [.retry])
        case .intelligenceOff: (title, cause, actions) = ("Apple Intelligence is off", "Turn it on in Settings to use the Agent.", [.openSettings, .retry])
        case .unsupportedLanguage: (title, cause, actions) = ("Language not supported", "The on-device model doesn’t support this language yet.", [.edit, .newChat])
        case .contextTooLong: (title, cause, actions) = ("That request is too long", "This chat and your closet don’t fit the on-device model at once.", [.shorten, .continueWithoutCloset, .newChat])
        case .timedOut: (title, cause, actions) = ("The reply took too long", "The on-device model didn’t finish in time.", [.retry, .shorten])
        case .guardrail: (title, cause, actions) = ("Couldn’t answer that", "The on-device model declined this request.", [.edit, .newChat])
        case .interrupted: (title, cause, actions) = ("The reply was cut off", "It was interrupted before it finished.", [.retry])
        case .toolRejected: (title, cause, actions) = ("Couldn’t prepare that change", "Something in the request didn’t match your closet.", [.edit, .retry])
        case .storage: (title, cause, actions) = ("Save wasn’t confirmed", "Your message is kept; retrying checks the same save first.", [.retry])
        case .generation: (title, cause, actions) = ("Couldn’t get a reply", "The on-device model hit a problem.", [.retry, .shorten, .newChat])
        }
        if !closetIncluded { actions.removeAll { $0 == .continueWithoutCloset } }
        return AgentFailure(kind: kind, title: title, cause: cause, actions: actions, keptPartialReply: keptPartialReply)
    }
}

public extension AgentConversation {
    /// Takes the last request back into the composer and drops the failed turn so a shorter or edited request can replace it.
    /// Returns the request text, or nil when the last turn did not fail.
    mutating func reviseFailedRequest() -> String? {
        guard messages.count >= 2, let last = messages.last, last.role == .assistant, last.failure != nil, !last.isActive,
              messages[messages.count - 2].role == .user else { return nil }
        let user = messages[messages.count - 2]
        let text = user.source
        let attempts = Set(([last.attemptID] + last.versions.map(\.attemptID)).compactMap { $0 })
        messages.removeLast(2)
        proposals = proposals?.filter { !($0.attemptID.map(attempts.contains) ?? false) }
        if proposals?.isEmpty == true { proposals = nil }
        draft = text; draftAttachments = user.attachments; updatedAt = Date()
        return text
    }
}
