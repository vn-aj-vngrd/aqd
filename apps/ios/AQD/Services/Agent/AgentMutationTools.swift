import Foundation
import AQDCore
#if canImport(FoundationModels)
import FoundationModels

/// Proposal tools only prepare a reviewable card; nothing is applied until the user taps Apply.
/// Targets are named by handle (p3) or name and resolved by the app, so an invented target is refused and the current revision is read at prepare time.
@available(iOS 26, *)
struct AgentEditClosetTool: Tool {
    let name = "editCloset"
    let description = "Prepare a review to rename a piece, change its color or brand, or set availability. Only when the user asks. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        @Guide(description: "The piece: its handle such as p3, or its name") var piece: String
        var name: String?
        var color: String?
        var brand: String?
        @Guide(description: "available, unavailable or laundry. Cannot combine with other fields") var availability: String?
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            let availability = try arguments.availability.map { value -> PieceAvailability in
                guard let parsed = PieceAvailability(rawValue: value) else { throw AgentToolRejection.invalidArguments }; return parsed
            }
            if availability != nil, arguments.name != nil || arguments.color != nil || arguments.brand != nil { throw AgentToolRejection.invalidArguments }
            let request = AgentMutationRequest(kind: availability == nil ? .editPiece : .setAvailability, targetID: try handlers.resolve(arguments.piece, [.piece]).id,
                name: arguments.name, color: arguments.color, brand: arguments.brand, availability: availability)
            return try handlers.prepare(request, .editCloset)
        }
    }
}

@available(iOS 26, *)
struct AgentEditOutfitTool: Tool {
    let name = "editOutfit"
    let description = "Prepare a review to create an outfit, or edit one when outfitID is set. Only when the user asks. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        @Guide(description: "The outfit to edit: its handle such as o2, or its name. Nil to create") var outfit: String?
        var name: String?
        @Guide(description: "Available pieces by handle or name", .maximumCount(24)) var pieces: [String]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            let request = AgentMutationRequest(kind: arguments.outfit == nil ? .createOutfit : .editOutfit, targetID: try arguments.outfit.map { try handlers.resolve($0, [.outfit]).id },
                name: arguments.name, pieceIDs: try arguments.pieces.map { try handlers.resolve($0, [.piece]).id })
            return try handlers.prepare(request, .editOutfit)
        }
    }
}

@available(iOS 26, *)
struct AgentEditThemeTool: Tool {
    let name = "editTheme"
    let description = "Prepare a review to create a theme from saved outfits, or edit one when themeID is set. Only when the user asks. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        @Guide(description: "The theme to edit: its handle such as t1, or its name. Nil to create") var theme: String?
        var name: String?
        @Guide(description: "Saved outfits by handle or name", .maximumCount(24)) var outfits: [String]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            let request = AgentMutationRequest(kind: arguments.theme == nil ? .createTheme : .editTheme, targetID: try arguments.theme.map { try handlers.resolve($0, [.theme]).id },
                name: arguments.name, outfitIDs: try arguments.outfits.map { try handlers.resolve($0, [.outfit]).id })
            return try handlers.prepare(request, .editTheme)
        }
    }
}

@available(iOS 26, *)
struct AgentEditPlanTool: Tool {
    let name = "editPlan"
    let description = "Prepare a review to create a plan, or change days of one when planID is set. Only when the user asks. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Assignment {
        @Guide(description: "Calendar day YYYY-MM-DD in the user's timezone") var date: String
        @Guide(description: "Saved outfit by handle or name") var outfit: String
    }
    @Generable struct Arguments {
        @Guide(description: "The plan to edit: its handle such as pl1, or its name. Nil to create") var plan: String?
        var name: String?
        @Guide(description: "Days and outfits, at most 14. New plans need every day; edits change supplied days only", .maximumCount(14)) var assignments: [Assignment]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            let request = AgentMutationRequest(kind: arguments.plan == nil ? .createPlan : .editPlan, targetID: try arguments.plan.map { try handlers.resolve($0, [.plan]).id },
                name: arguments.name, assignments: try arguments.assignments.map { AgentPlanAssignment(date: $0.date, outfitID: try handlers.resolve($0.outfit, [.outfit]).id) })
            return try handlers.prepare(request, .editPlan)
        }
    }
}

@available(iOS 26, *)
struct AgentRecordWearTool: Tool {
    let name = "recordWear"
    let description = "Prepare a review to record what the user actually wore on a day. Never for plans. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        @Guide(description: "Calendar day YYYY-MM-DD, not in the future") var date: String
        @Guide(description: "A saved outfit that was worn, by handle or name; its pieces are recorded. Nil when listing pieces") var outfit: String?
        @Guide(description: "Pieces worn, by handle or name, when no outfit is given", .maximumCount(24)) var pieces: [String]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            let worn = try arguments.outfit.map { try handlers.resolve($0, [.outfit]).id }
            return try handlers.prepare(AgentMutationRequest(kind: .recordWear, pieceIDs: worn == nil ? try arguments.pieces.map { try handlers.resolve($0, [.piece]).id } : [],
                                                             date: arguments.date, wearOutfitID: worn), .recordWear)
        }
    }
}

@available(iOS 26, *)
struct AgentEditProfileTool: Tool {
    let name = "editProfile"
    let description = "Prepare a review to change the profile name or bio. Only when the user asks. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        var name: String?
        @Guide(description: "At most 160 characters") var caption: String?
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            try handlers.prepare(AgentMutationRequest(kind: .updateProfile, name: arguments.name, caption: arguments.caption), .editProfile)
        }
    }
}

@available(iOS 26, *)
extension AgentToolbox {
    static func makeTools(_ ids: [AgentToolID], handlers: AgentToolHandlers) -> [any Tool] {
        ids.map { id -> any Tool in
            switch id {
            case .findRecords: AgentFindRecordsTool(handlers: handlers)
            case .showRecords: AgentShowRecordsTool(handlers: handlers)
            case .wearStats: AgentWearStatsTool(handlers: handlers)
            case .weatherFor: AgentWeatherTool(handlers: handlers)
            case .editCloset: AgentEditClosetTool(handlers: handlers)
            case .editOutfit: AgentEditOutfitTool(handlers: handlers)
            case .editTheme: AgentEditThemeTool(handlers: handlers)
            case .editPlan: AgentEditPlanTool(handlers: handlers)
            case .proposePlan: AgentProposePlanTool(handlers: handlers)
            case .proposeTrip: AgentProposeTripTool(handlers: handlers)
            case .askUser: AgentAskUserTool(handlers: handlers)
            case .recordWear: AgentRecordWearTool(handlers: handlers)
            case .editProfile: AgentEditProfileTool(handlers: handlers)
            case .suggestOutfit, .proposeOutfit, .proposeTheme, .relabel: makeOutfitTool(id, handlers: handlers) ?? AgentFindRecordsTool(handlers: handlers)
            case .addPieceFromPhoto: AgentAddPieceFromPhotoTool(handlers: handlers)
            }
        }
    }
}
#endif
