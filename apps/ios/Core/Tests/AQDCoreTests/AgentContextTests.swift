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
    @Test func markdownRejectsExecutableLinksAndRetainsExactSourceForCopy() {
        #expect(!AgentMarkdownPolicy.allowsLink("javascript:alert(1)"))
        #expect(!AgentMarkdownPolicy.allowsLink("file:///private/data"))
        #expect(AgentMarkdownPolicy.allowsLink("https://example.com/style"))
        #expect(AgentMarkdownPolicy.plainText("**A look**\n[Source](https://example.com)", incomplete: true).contains("Incomplete"))
    }
}
