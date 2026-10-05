import Foundation
import Testing

@testable import AQD

@MainActor
struct EntryRecoveryTests {
  private func directory() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  }

  @Test func invalidSaveKeepsDraftAndDoesNotShowAReceipt() throws {
    let url = directory()
    defer { try? FileManager.default.removeItem(at: url) }
    let flow = EntryFlow(directory: url)
    flow.startPrivately()
    flow.route = .editor
    flow.draft.name = "  "
    flow.draft.category = .shoes
    #expect(throws: (any Error).self) { try flow.savePiece() }
    #expect(flow.draft.category == .shoes)
    #expect(flow.route == .editor)
    #expect(flow.pieces.isEmpty)
  }

  @Test func interruptedCaptureRestoresItsDraftAndPhoto() throws {
    let url = directory()
    defer { try? FileManager.default.removeItem(at: url) }
    let flow = EntryFlow(directory: url)
    flow.startPrivately()
    flow.draft.name = "Travel shirt"
    flow.draft.category = .tops
    try flow.setPhoto(Data([1, 2, 3]))
    try flow.preserveDraft()
    let restored = EntryFlow(directory: url)
    #expect(restored.route == .editor)
    #expect(restored.draft.name == "Travel shirt")
    #expect(restored.store.photoURL(restored.draft.photoFile) != nil)
  }

  @Test func unreadableStorageCannotBeOverwritten() throws {
    let url = directory()
    defer { try? FileManager.default.removeItem(at: url) }
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    let file = url.appendingPathComponent("closet-v1.json")
    let original = Data("unreadable existing wardrobe".utf8)
    try original.write(to: file)
    let flow = EntryFlow(directory: url)
    flow.draft.name = "Sneakers"
    flow.draft.category = .shoes
    #expect(throws: (any Error).self) { try flow.savePiece() }
    #expect(try Data(contentsOf: file) == original)
    #expect(!flow.storageReadable)
  }

  @Test func failedWriteKeepsDraftAndInventory() throws {
    let url = directory()
    defer { try? FileManager.default.removeItem(at: url) }
    let flow = EntryFlow(directory: url)
    // An ordinary file in place of the storage directory forces a real write failure.
    try Data([1]).write(to: url)
    flow.draft.name = "Sneakers"
    flow.draft.category = .shoes
    #expect(throws: (any Error).self) { try flow.savePiece() }
    #expect(flow.draft.name == "Sneakers")
    #expect(flow.pieces.isEmpty)
  }

  @Test func skipPersistsAndPreferencesStartUnselected() throws {
    let url = directory()
    defer { try? FileManager.default.removeItem(at: url) }
    let flow = EntryFlow(directory: url)
    #expect(flow.preferences.everyday.isEmpty && flow.preferences.styles.isEmpty)
    flow.skipCapture()
    #expect(EntryFlow(directory: url).route == .closet)
  }

  @Test func signOutHidesAnotherAccountsRecordsWithoutDeletingThem() throws {
    let url = directory()
    defer { try? FileManager.default.removeItem(at: url) }
    let flow = EntryFlow(directory: url)
    flow.draft.name = "My shoes"
    flow.draft.category = .shoes
    try flow.savePiece()
    let owner = AccountIdentity(id: UUID(), label: "owner@example.com")
    flow.setAccount(owner)
    let ids = Set(flow.pieces.map(\.id))
    try flow.confirmAssociation(owner: owner.id, ids: ids)
    flow.setAccount(nil)
    #expect(flow.pieces.isEmpty)
    flow.setAccount(AccountIdentity(id: UUID(), label: "other@example.com"))
    #expect(flow.pieces.isEmpty)
    flow.setAccount(owner)
    #expect(flow.pieces.first?.name == "My shoes")
  }

  @Test func retryUsesTheSameConnectionOperationUntilConfirmation() throws {
    let url = directory()
    defer { try? FileManager.default.removeItem(at: url) }
    let flow = EntryFlow(directory: url)
    let first = try flow.associationOperation()
    #expect(try EntryFlow(directory: url).associationOperation() == first)
  }

  @Test func addingMissingCategoriesKeepsTheOriginalPiecePinned() throws {
    let url = directory()
    defer { try? FileManager.default.removeItem(at: url) }
    let flow = EntryFlow(directory: url)
    flow.draft.name = "First shoes"
    flow.draft.category = .shoes
    try flow.savePiece()
    let original = try #require(flow.pieces.first?.id)
    try flow.buildAround(original)
    flow.draft.name = "Travel shirt"
    flow.draft.category = .tops
    try flow.savePiece()
    #expect(flow.route == .readiness(original))
    #expect(EntryFlow(directory: url).state.pinnedPieceID == original)
  }
}
