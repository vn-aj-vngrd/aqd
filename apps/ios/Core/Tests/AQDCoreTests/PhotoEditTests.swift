import Foundation
import Testing
@testable import AQDCore

struct PhotoEditTests {
    @Test func draftReplacementResetsAndRecipeRoundTrips() throws {
        let recipe = try PhotoEditRecipe.portrait(originalWidth: 800, originalHeight: 400, quarterTurns: 1, zoom: 2, positionX: 0, positionY: 1)
        let crop = try #require(recipe.crop)
        #expect(crop.x == 0 && crop.width == 0.5)
        #expect(abs(crop.y - 0.6666666667) < 0.000001)
        #expect(abs(crop.height - 0.3333333333) < 0.000001)
        var draft = PieceDraft(name: "Shirt", category: .tops, photoID: UUID(), photoRecipe: recipe)
        #expect(try JSONDecoder().decode(PieceDraft.self, from: JSONEncoder().encode(draft)) == draft)
        let sameID = draft.photoID
        draft.photoID = sameID
        #expect(draft.photoRecipe == recipe)
        draft.photoID = UUID()
        #expect(draft.photoRecipe == .fit)
        draft.photoRecipe = recipe
        draft.photoID = nil
        #expect(draft.photoRecipe == .fit)
    }

    @Test func preEditorDraftAndReceiptDecodeAsFit() throws {
        let draft = PieceDraft(name: "Shirt", category: .tops, photoID: UUID())
        let piece = WardrobePiece(id: draft.itemID, name: draft.name, category: .tops, photoID: try #require(draft.photoID))
        func withoutRecipe<T: Encodable>(_ value: T) throws -> Data {
            var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? [String: Any])
            object.removeValue(forKey: "photoRecipe")
            return try JSONSerialization.data(withJSONObject: object)
        }
        #expect(try JSONDecoder().decode(PieceDraft.self, from: withoutRecipe(draft)).photoRecipe == .fit)
        #expect(try JSONDecoder().decode(WardrobePiece.self, from: withoutRecipe(piece)).photoRecipe == .fit)
    }

    @Test func rejectsNonfiniteAndUnboundedInputs() throws {
        for value in [Double.nan, .infinity, -1, 9] {
            #expect(throws: (any Error).self) {
                try PhotoEditRecipe.portrait(originalWidth: 800, originalHeight: 400, zoom: value)
            }
        }
        #expect(throws: (any Error).self) {
            try PhotoEditRecipe(crop: .init(x: .nan, y: 0, width: 1, height: 1)).validated()
        }
        #expect(throws: (any Error).self) {
            try PieceDraft(name: "Shirt", category: .tops, photoID: UUID(), photoRecipe: .init(quarterTurns: -1)).validated()
        }
    }

    @Test func portraitIsBoundedAndPositionUsesAvailablePan() throws {
        let recipe = try PhotoEditRecipe.portrait(originalWidth: 800, originalHeight: 400, quarterTurns: 0, zoom: 1, positionX: 1, positionY: 0)
        #expect(recipe.crop == .init(x: 0.625, y: 0, width: 0.375, height: 1))
        #expect(PhotoEditRecipe.fitOriginal.quarterTurns == 0)
        #expect(PhotoEditRecipe.fitOriginal.crop == nil)
        #expect(throws: (any Error).self) { try PhotoEditRecipe(quarterTurns: 4).validated() }
        #expect(throws: (any Error).self) { try PhotoEditRecipe(crop: .init(x: 0.9, y: 0, width: 0.2, height: 1)).validated() }
    }
}
