import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct ActiveEditorTests {
    private func state() throws -> AppState {
        AppState(store: try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)))
    }

    @Test func onlyOneEditorOpensAtATime() throws {
        let state = try state()
        state.buildOutfit()
        let outfit = try #require(state.outfitEditor)
        #expect(state.hasActiveEditor)
        state.openTheme()
        state.addPiece()
        state.openFit()
        #expect(state.outfitEditor === outfit, "later openers are refused while an editor is open")
        #expect(state.themeEditor == nil && state.capture == nil && state.fitEditor == nil)
    }

    @Test func closingOneEditorNeverDismissesAnother() throws {
        let state = try state()
        state.buildOutfit()
        let outfit = try #require(state.outfitEditor)
        state.themeEditor = nil
        state.capture = nil
        #expect(state.outfitEditor === outfit, "clearing a different slot leaves the open editor alone")
        state.outfitEditor = nil
        #expect(!state.hasActiveEditor)
        state.addPiece()
        #expect(state.capture != nil && state.outfitEditor == nil)
    }
}
