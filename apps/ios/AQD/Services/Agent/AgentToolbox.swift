import Foundation
import AQDCore

enum AgentWearWindow: String, Sendable { case thisMonth, lastMonth }

/// Feature-owned implementations the model-facing tools call. Each runs on the main actor against the store.
/// What the owner asked to see. Empty strings mean "any".
struct AgentShowRequest: Sendable {
    enum Kind: String, Sendable { case pieces, outfits, themes, plans }
    var kind: Kind
    var color = "", category = "", brand = "", availability = "", query = ""
}

struct AgentToolHandlers: Sendable {
    var show: @MainActor @Sendable (_ request: AgentShowRequest) throws -> String
    var find: @MainActor @Sendable (_ query: String, _ kinds: [AgentDataSource]) throws -> String
    var wearStats: @MainActor @Sendable (_ window: AgentWearWindow, _ pieceIDs: [UUID]) throws -> String
    var weather: @MainActor @Sendable (_ day: String) throws -> String
    var prepare: @MainActor @Sendable (_ request: AgentMutationRequest, _ tool: AgentToolID) throws -> String
    var ask: @MainActor @Sendable (_ question: AgentQuestion) throws -> String
    var suggestOutfit: @MainActor @Sendable (_ occasion: String?, _ mood: String?, _ pinnedIDs: [UUID]) async throws -> String
    /// Turns what the model wrote (a handle such as p3, or a name) into a record. Ambiguity asks the owner; a miss is a quiet step.
    var resolve: @MainActor @Sendable (_ reference: String, _ kinds: [AgentRecordKind]) throws -> AgentRecordIndex.Entry
    /// Maps an attached image handle (a1) to its attachment.
    var attachment: @MainActor @Sendable (_ handle: String) -> UUID?
}

extension AgentToolHandlers {
    /// Handlers that do nothing, for measuring tool definitions without a conversation.
    static let inert = AgentToolHandlers(
        show: { _ in "" }, find: { _, _ in "" }, wearStats: { _, _ in "" }, weather: { _ in "" }, prepare: { _, _ in "" }, ask: { _ in "" },
        suggestOutfit: { _, _, _ in "" }, resolve: { _, _ in throw AgentToolRejection.invalidArguments }, attachment: { _ in nil })
}

enum AgentToolID: String, CaseIterable, Sendable {
    case findRecords, wearStats, weatherFor, editCloset, tidyCloset, editOutfit, editTheme, editPlan, proposePlan, recordWear, editProfile, addPieceFromPhoto
    case suggestOutfit, proposeOutfit, proposeTheme, relabel, showRecords, proposeTrip, askUser

    var isProposal: Bool { ![.findRecords, .showRecords, .wearStats, .weatherFor, .askUser].contains(self) }
}

/// Tool registry helpers. Which tools a turn offers is decided by `AgentIntent`, at most three, so their definitions fit the on-device window.
enum AgentToolbox {
    static let maximumTools = 3
    /// Drops the least relevant tools until their measured definitions fit. Returns an empty list when none fit.
    @MainActor static func fit(_ tools: [AgentToolID], measure: ([AgentToolID]) async throws -> Int, fits: (Int) -> Bool) async rethrows -> [AgentToolID] {
        var kept = tools
        while !kept.isEmpty {
            if fits(try await measure(kept)) { return kept }
            kept.removeLast()
        }
        return kept
    }

    /// Cancellation propagates; a rejection explains itself to the model; anything else is a generic refusal.
    static func result(_ body: @MainActor () async throws -> String) async throws -> String {
        do { return try await body() }
        catch is CancellationError { throw CancellationError() }
        catch let rejection as AgentToolRejection { return "No proposal prepared. " + rejection.reason }
        catch { return "No change prepared or applied. Arguments, source access, dates, conflicts or records could not be validated. If a detail is missing, call askUser with one short question and tappable answers. Never ask the owner for a code; look records up by name with findRecords. Do not claim success." }
    }
}

struct AgentToolSelection: Sendable {
    let ids: [AgentToolID]
    let handlers: AgentToolHandlers
}
