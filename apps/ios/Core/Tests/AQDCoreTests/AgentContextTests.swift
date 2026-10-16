import Foundation
import Testing
@testable import AQDCore

struct AgentContextTests {
    @Test func generalContextDoesNotIncludeWardrobeOrPrivateMetadataAndSelectedContextRejectsStaleIDs() throws {
        var context = AgentContext(); context.scope = .general
        let piece = WardrobePiece(id: UUID(), name: "Cotton shirt", category: .tops, photoID: UUID(), details: PieceDetails(notes: "private secret"))
        let empty = try AgentContextSnapshot.build(context, pieces: [piece], outfits: [], themes: [], maximumPieces: 10)
        #expect(empty.pieces.isEmpty)
        context.scope = .selected
        context.selected = [AgentSelectedRecord(id: piece.id, kind: .piece, revision: piece.revision)]
        let selected = try AgentContextSnapshot.build(context, pieces: [piece], outfits: [], themes: [], maximumPieces: 10)
        let encoded = String(decoding: try JSONEncoder().encode(selected), as: UTF8.self)
        #expect(selected.pieces.count == 1 && !encoded.contains("private secret") && !encoded.contains(piece.photoID.uuidString))
        context.selected = [AgentSelectedRecord(id: piece.id, kind: .piece, revision: piece.revision + 1)]
        #expect(throws: (any Error).self) { try AgentContextSnapshot.build(context, pieces: [piece], outfits: [], themes: [], maximumPieces: 10) }
    }
    @Test(arguments: [false, true]) func selectedParentsRequireReviewedDescendants(themeSelection: Bool) throws {
        let owner = UUID()
        var piece = WardrobePiece(id: UUID(), name: "Reviewed shirt", category: .tops, photoID: UUID())
        var outfit = Outfit(id: UUID(), ownerID: owner, name: "Reviewed outfit", pieceIDs: [piece.id])
        let theme = OutfitTheme(id: UUID(), ownerID: owner, name: "Reviewed theme", outfitIDs: [outfit.id])
        let kind: AgentSelectedRecord.Kind = themeSelection ? .theme : .outfit
        let id = themeSelection ? theme.id : outfit.id
        var context = AgentContext(); context.scope = .selected
        // Existing selections without descendant consent must decode and request reselection.
        let legacy = AgentSelectedRecord(id: id, kind: kind, revision: 1)
        context.selected = [try JSONDecoder().decode(AgentSelectedRecord.self, from: JSONEncoder().encode(legacy))]
        #expect(throws: (any Error).self) { try AgentContextSnapshot.build(context, pieces: [piece], outfits: [outfit], themes: [theme], maximumPieces: 10) }
        context.selected = [try AgentContextSnapshot.selection(id: id, kind: kind, pieces: [piece], outfits: [outfit], themes: [theme])]
        context = try JSONDecoder().decode(AgentContext.self, from: JSONEncoder().encode(context))
        #expect(try AgentContextSnapshot.build(context, pieces: [piece], outfits: [outfit], themes: [theme], maximumPieces: 10).pieces.first?.name == "Reviewed shirt")
        piece = WardrobePiece(id: piece.id, name: "Unreviewed shirt", category: piece.category, photoID: piece.photoID, revision: piece.revision + 1)
        #expect(throws: (any Error).self) { try AgentContextSnapshot.build(context, pieces: [piece], outfits: [outfit], themes: [theme], maximumPieces: 10) }
        context.selected = [try AgentContextSnapshot.selection(id: id, kind: kind, pieces: [piece], outfits: [outfit], themes: [theme])]
        #expect(try AgentContextSnapshot.build(context, pieces: [piece], outfits: [outfit], themes: [theme], maximumPieces: 10).pieces.first?.name == "Unreviewed shirt")
        #expect(throws: (any Error).self) { try AgentContextSnapshot.build(context, pieces: [], outfits: [outfit], themes: [theme], maximumPieces: 10) }
        let archived = WardrobePiece(id: piece.id, name: piece.name, category: piece.category, photoID: piece.photoID, revision: piece.revision, isArchived: true)
        #expect(throws: (any Error).self) { try AgentContextSnapshot.build(context, pieces: [archived], outfits: [outfit], themes: [theme], maximumPieces: 10) }
        outfit.pieceIDs = []; outfit.revision += 1
        #expect(throws: (any Error).self) { try AgentContextSnapshot.build(context, pieces: [piece], outfits: [outfit], themes: [theme], maximumPieces: 10) }
    }
    @Test func markdownRejectsExecutableLinksAndRetainsExactSourceForCopy() {
        #expect(!AgentMarkdownPolicy.allowsLink("javascript:alert(1)"))
        #expect(!AgentMarkdownPolicy.allowsLink("file:///private/data"))
        #expect(AgentMarkdownPolicy.allowsLink("https://example.com/style"))
        #expect(AgentMarkdownPolicy.plainText("**A look**\n[Source](https://example.com)", incomplete: true).contains("Incomplete"))
    }
}
