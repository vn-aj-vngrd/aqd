import Foundation
import AQDCore
#if canImport(FoundationModels)
import FoundationModels

/// Outfit, theme and naming tools. Each only prepares a reviewable card; saving needs the owner's Apply.
@available(iOS 26, *)
struct AgentSuggestOutfitTool: Tool {
    let name = "suggestOutfit"
    let description = "Prepare a review of a new outfit built from the owner's available pieces for an occasion or mood. Pinned pieces are always included. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        var occasion: String?
        var mood: String?
        @Guide(description: "Exact piece UUIDs that must be in the outfit", .maximumCount(6)) var pinnedIDs: [String]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            try await handlers.suggestOutfit(arguments.occasion, arguments.mood, try arguments.pinnedIDs.map(AgentToolbox.id))
        }
    }
}

@available(iOS 26, *)
struct AgentProposeOutfitTool: Tool {
    let name = "proposeOutfit"
    let description = "Prepare a review to save a new outfit from exact available pieces with a name. Nothing is applied. If a piece is missing, say the closet needs it."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        @Guide(description: "Exact available piece UUIDs from findRecords", .maximumCount(24)) var pieceIDs: [String]
        @Guide(description: "At most 80 characters") var name: String
        var occasion: String?
        var mood: String?
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            try handlers.prepare(AgentMutationRequest(kind: .createOutfit, name: arguments.name, pieceIDs: try arguments.pieceIDs.map(AgentToolbox.id),
                                                      occasion: arguments.occasion, mood: arguments.mood), nil)
        }
    }
}

@available(iOS 26, *)
struct AgentProposeThemeTool: Tool {
    let name = "proposeTheme"
    let description = "Prepare a review to save a new theme that groups saved outfits. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        @Guide(description: "At most 80 characters") var name: String
        @Guide(description: "Exact saved outfit UUIDs from findRecords", .maximumCount(24)) var outfitIDs: [String]
        @Guide(description: "At most 160 characters") var description: String?
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            try handlers.prepare(AgentMutationRequest(kind: .createTheme, name: arguments.name, outfitIDs: try arguments.outfitIDs.map(AgentToolbox.id),
                                                      themeDescription: arguments.description), nil)
        }
    }
}

@available(iOS 26, *)
struct AgentRelabelTool: Tool {
    let name = "relabel"
    let description = "Prepare a review to rename a saved outfit or theme, or set an outfit's occasion or mood. Pieces and members stay unchanged. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        @Guide(description: "Exact outfit or theme UUID from findRecords") var targetID: String
        @Guide(description: "Revision from findRecords") var revision: Int?
        var name: String?
        @Guide(description: "Outfits only") var occasion: String?
        @Guide(description: "Outfits only") var mood: String?
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            try handlers.prepare(AgentMutationRequest(kind: .relabel, targetID: try AgentToolbox.id(arguments.targetID), name: arguments.name,
                                                      occasion: arguments.occasion, mood: arguments.mood), arguments.revision)
        }
    }
}

@available(iOS 26, *)
extension AgentToolbox {
    static func makeOutfitTool(_ id: AgentToolID, handlers: AgentToolHandlers) -> (any Tool)? {
        switch id {
        case .suggestOutfit: AgentSuggestOutfitTool(handlers: handlers)
        case .proposeOutfit: AgentProposeOutfitTool(handlers: handlers)
        case .proposeTheme: AgentProposeThemeTool(handlers: handlers)
        case .relabel: AgentRelabelTool(handlers: handlers)
        default: nil
        }
    }
}
#endif
