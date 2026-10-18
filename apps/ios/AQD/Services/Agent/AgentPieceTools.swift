import Foundation
import AQDCore
#if canImport(FoundationModels)
import FoundationModels

/// Drafts a new piece from a chat photo. The model supplies guesses only; the user adds the full-quality photo and saves in the Closet editor.
@available(iOS 26, *)
struct AgentAddPieceFromPhotoTool: Tool {
    let name = "addPieceFromPhoto"
    let description = "Prepare a review to add a new piece from a photo the user attached. Guess only what the photo or its text shows. Nothing is saved."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        @Guide(description: "ID of the attached image from the attachment reference") var attachmentID: String
        @Guide(description: "Short piece name, nil if unclear") var name: String?
        @Guide(description: "Tops, Bottoms, Dresses, Layers, Shoes or Accessories; nil if unclear") var category: String?
        var color: String?
        var brand: String?
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            let request = AgentMutationRequest(kind: .addPiece, name: arguments.name, color: arguments.color, brand: arguments.brand,
                category: arguments.category, attachmentID: try AgentToolbox.id(arguments.attachmentID))
            return try handlers.prepare(request, nil, .addPieceFromPhoto)
        }
    }
}
#endif
