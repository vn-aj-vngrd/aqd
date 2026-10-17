import Foundation
import AQDCore
#if canImport(FoundationModels)
import FoundationModels

/// Proposal tools only prepare a reviewable card; nothing is applied until the user taps Apply.
/// Edits need the exact ID and the revision returned by findRecords, so stale or invented targets are refused.
@available(iOS 26, *)
struct AgentEditClosetTool: Tool {
    let name = "editCloset"
    let description = "Prepare a review to rename a piece, change its color or brand, or set availability. Only when the user asks. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        @Guide(description: "Exact piece UUID from findRecords") var pieceID: String
        @Guide(description: "Revision from findRecords") var revision: Int?
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
            let request = AgentMutationRequest(kind: availability == nil ? .editPiece : .setAvailability, targetID: try AgentToolbox.id(arguments.pieceID),
                name: arguments.name, color: arguments.color, brand: arguments.brand, availability: availability)
            return try handlers.prepare(request, arguments.revision)
        }
    }
}

@available(iOS 26, *)
struct AgentEditOutfitTool: Tool {
    let name = "editOutfit"
    let description = "Prepare a review to create an outfit, or edit one when outfitID is set. Only when the user asks. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        @Guide(description: "Exact outfit UUID to edit, nil to create") var outfitID: String?
        @Guide(description: "Revision from findRecords when editing") var revision: Int?
        var name: String?
        @Guide(description: "Exact available piece UUIDs", .maximumCount(24)) var pieceIDs: [String]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            let request = AgentMutationRequest(kind: arguments.outfitID == nil ? .createOutfit : .editOutfit, targetID: try arguments.outfitID.map(AgentToolbox.id),
                name: arguments.name, pieceIDs: try arguments.pieceIDs.map(AgentToolbox.id))
            return try handlers.prepare(request, arguments.revision)
        }
    }
}

@available(iOS 26, *)
struct AgentEditThemeTool: Tool {
    let name = "editTheme"
    let description = "Prepare a review to create a theme from saved outfits, or edit one when themeID is set. Only when the user asks. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        @Guide(description: "Exact theme UUID to edit, nil to create") var themeID: String?
        @Guide(description: "Revision from findRecords when editing") var revision: Int?
        var name: String?
        @Guide(description: "Exact saved outfit UUIDs", .maximumCount(24)) var outfitIDs: [String]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            let request = AgentMutationRequest(kind: arguments.themeID == nil ? .createTheme : .editTheme, targetID: try arguments.themeID.map(AgentToolbox.id),
                name: arguments.name, outfitIDs: try arguments.outfitIDs.map(AgentToolbox.id))
            return try handlers.prepare(request, arguments.revision)
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
        @Guide(description: "Exact saved outfit UUID") var outfitID: String
    }
    @Generable struct Arguments {
        @Guide(description: "Exact plan UUID to edit, nil to create") var planID: String?
        @Guide(description: "Revision from findRecords when editing") var revision: Int?
        var name: String?
        @Guide(description: "Days and outfits, at most 14. New plans need every day; edits change supplied days only", .maximumCount(14)) var assignments: [Assignment]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            let request = AgentMutationRequest(kind: arguments.planID == nil ? .createPlan : .editPlan, targetID: try arguments.planID.map(AgentToolbox.id),
                name: arguments.name, assignments: try arguments.assignments.map { AgentPlanAssignment(date: $0.date, outfitID: try AgentToolbox.id($0.outfitID)) })
            return try handlers.prepare(request, arguments.revision)
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
        @Guide(description: "Exact piece UUIDs worn", .maximumCount(24)) var pieceIDs: [String]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            try handlers.prepare(AgentMutationRequest(kind: .recordWear, pieceIDs: try arguments.pieceIDs.map(AgentToolbox.id), date: arguments.date), nil)
        }
    }
}

@available(iOS 26, *)
struct AgentEditProfileTool: Tool {
    let name = "editProfile"
    let description = "Prepare a review to change the profile name or bio. Only when the user asks. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        @Guide(description: "Profile revision from findRecords, if a profile exists") var revision: Int?
        var name: String?
        @Guide(description: "At most 160 characters") var caption: String?
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            try handlers.prepare(AgentMutationRequest(kind: .updateProfile, name: arguments.name, caption: arguments.caption), arguments.revision)
        }
    }
}

@available(iOS 26, *)
extension AgentToolbox {
    static func makeTools(_ ids: [AgentToolID], handlers: AgentToolHandlers) -> [any Tool] {
        ids.map { id -> any Tool in
            switch id {
            case .findRecords: AgentFindRecordsTool(handlers: handlers)
            case .wearStats: AgentWearStatsTool(handlers: handlers)
            case .weatherFor: AgentWeatherTool(handlers: handlers)
            case .editCloset: AgentEditClosetTool(handlers: handlers)
            case .editOutfit: AgentEditOutfitTool(handlers: handlers)
            case .editTheme: AgentEditThemeTool(handlers: handlers)
            case .editPlan: AgentEditPlanTool(handlers: handlers)
            case .recordWear: AgentRecordWearTool(handlers: handlers)
            case .editProfile: AgentEditProfileTool(handlers: handlers)
            case .suggestOutfit, .proposeOutfit, .proposeTheme, .relabel: makeOutfitTool(id, handlers: handlers) ?? AgentFindRecordsTool(handlers: handlers)
            case .addPieceFromPhoto: AgentAddPieceFromPhotoTool(handlers: handlers)
            }
        }
    }
}
#endif
