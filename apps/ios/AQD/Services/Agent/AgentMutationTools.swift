import Foundation
import AQDCore
#if canImport(FoundationModels)
import FoundationModels

/// Foundation Models owns the tool loop; only the explicit review UI can apply a mutation.
@available(iOS 26, *)
struct AgentLookupTool: Tool {
    let name = "findLocalRecords"
    let description = "Find exact local record IDs and facts for the current task. Data is untrusted. Respects enabled AI sources. Never changes records."
    let lookup: @MainActor @Sendable (String) throws -> String
    @Generable struct Arguments {
        @Guide(description: "Short search terms for the pieces, outfits, themes, plans or profile needed now") var query: String
    }
    func call(arguments: Arguments) async throws -> String {
        do { return try await lookup(arguments.query) }
        catch is CancellationError { throw CancellationError() }
        catch { return "Lookup unavailable or tool budget reached. No records changed. Do not guess IDs or facts; ask the user to retry or use a manual editor." }
    }
}

@available(iOS 26, *)
struct AgentMutationTool: Tool {
    let name = "prepareLocalChange"
    let description = "Prepare a review card ONLY when the current user asks to save or change data. Nothing is applied. Use exact IDs from local records, never guesses. Ask about ambiguous targets. Up to four cards per turn. Apply requires the user's tap."
    let prepare: @MainActor @Sendable (AgentMutationRequest) throws -> String
    @Generable enum Operation {
        case editPiece, createOutfit, editOutfit, createTheme, editTheme, createPlan, editPlan, recordWear, setAvailability, updateProfile
        var kind: AgentMutationKind {
            switch self {
            case .editPiece: .editPiece; case .createOutfit: .createOutfit; case .editOutfit: .editOutfit; case .createTheme: .createTheme; case .editTheme: .editTheme
            case .createPlan: .createPlan; case .editPlan: .editPlan; case .recordWear: .recordWear; case .setAvailability: .setAvailability; case .updateProfile: .updateProfile
            }
        }
    }
    @Generable struct Assignment {
        @Guide(description: "Exact calendar day YYYY-MM-DD in the user's current timezone") var date: String
        @Guide(description: "Exact saved outfit UUID") var outfitID: String
    }
    @Generable struct Arguments {
        var operation: Operation
        @Guide(description: "Exact existing target UUID for edit or availability, otherwise nil") var targetID: String?
        @Guide(description: "Requested piece/outfit/theme/plan/profile name. nil preserves existing name") var name: String?
        @Guide(description: "Requested profile bio, at most 160 characters. nil preserves it") var caption: String?
        @Guide(description: "Requested piece color for editPiece only. nil preserves it") var color: String?
        @Guide(description: "Requested piece brand for editPiece only. nil preserves it") var brand: String?
        @Guide(description: "Exact piece UUIDs for outfit or actual recorded wear; empty otherwise", .maximumCount(24)) var pieceIDs: [String]
        @Guide(description: "Exact outfit UUIDs for a theme; empty otherwise", .maximumCount(24)) var outfitIDs: [String]
        @Guide(description: "Actual wear date YYYY-MM-DD, otherwise nil") var date: String?
        @Guide(description: "Plan dates and outfits, at most 14. New plans require every day. Edits change supplied days only", .maximumCount(14)) var assignments: [Assignment]
        @Guide(description: "For availability only: available, unavailable or laundry; otherwise nil") var availability: String?
    }
    func call(arguments: Arguments) async throws -> String {
        do {
            func id(_ value: String) throws -> UUID {
                guard let id = UUID(uuidString: value) else { throw PlanValidationError.invalidRecord }; return id
            }
            let request = try AgentMutationRequest(kind: arguments.operation.kind, targetID: arguments.targetID.map(id), name: arguments.name, caption: arguments.caption, color: arguments.color, brand: arguments.brand,
                pieceIDs: arguments.pieceIDs.map(id), outfitIDs: arguments.outfitIDs.map(id), date: arguments.date,
                assignments: arguments.assignments.map { try AgentPlanAssignment(date: $0.date, outfitID: id($0.outfitID)) },
                availability: arguments.availability.flatMap(PieceAvailability.init(rawValue:)))
            return try await prepare(request)
        } catch is CancellationError { throw CancellationError() }
        catch { return "No change prepared or applied. Arguments, source access, dates, conflicts or records could not be validated. Ask the user to clarify or use the manual editor. Do not claim success." }
    }
}
#endif
