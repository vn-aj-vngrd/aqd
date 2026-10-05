import Foundation
import Testing

@testable import AQD

@MainActor
struct EntryFlowTests {
  @Test func privateSaveSurvivesRestartWithoutCreatingAnAccount() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let flow = EntryFlow(directory: directory)
    flow.startPrivately()
    flow.draft.name = " Everyday shoes "
    flow.draft.category = .shoes
    try flow.savePiece()
    let reopened = EntryFlow(directory: directory)
    #expect(reopened.pieces.first?.name == "Everyday shoes")
    #expect(reopened.pieces.first?.id == flow.pieces.first?.id)
    #expect(reopened.route == .closet)
    #expect(reopened.account == nil)
  }
}
