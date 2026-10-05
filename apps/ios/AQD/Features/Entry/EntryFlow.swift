import Foundation
import Observation

@MainActor @Observable
final class EntryFlow {
  var draft: PieceDraft
  var preferences: StylePreferences
  var route: EntryRoute
  var message: String?
  private(set) var state: ClosetState
  private(set) var storageReadable = true
  private(set) var account: AccountIdentity?
  let store: LocalCloset
  var pieces: [Piece] { state.pieces.filter { $0.ownerID == nil || $0.ownerID == account?.id } }
  var localPieces: [Piece] { state.pieces.filter { $0.ownerID == nil } }

  init(directory: URL) {
    store = LocalCloset(directory: directory)
    do {
      let loaded = try store.load()
      state = loaded
      draft = loaded.draft
      preferences = loaded.preferences
      route =
        loaded.onboardingCompleted
        ? loaded.pinnedPieceID.map { .readiness($0) } ?? .closet
        : loaded.draft.hasChanges ? .editor : loaded.captureStarted ? .firstPiece : .welcome
    } catch {
      state = ClosetState()
      draft = PieceDraft()
      preferences = StylePreferences()
      route = .closet
      storageReadable = false
      message = EntryError.unreadableStorage.localizedDescription
    }
  }

  func startPrivately() {
    do {
      var next = state
      next.captureStarted = true
      try commit(next)
      route = .firstPiece
    } catch { message = error.localizedDescription }
  }

  func skipCapture() {
    do {
      var next = state
      next.onboardingCompleted = true
      try commit(next)
      route = .closet
    } catch { message = error.localizedDescription }
  }

  func preserveDraft() throws {
    var next = state
    next.draft = draft
    try commit(next)
  }

  func savePiece() throws {
    let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard (1...80).contains(name.count) else { throw EntryError.invalidName }
    guard let category = draft.category else { throw EntryError.missingCategory }
    let piece = Piece(
      id: draft.id, name: name, category: category, photoFile: draft.photoFile, ownerID: nil,
      createdAt: Date())
    var next = state
    if !next.pieces.contains(where: { $0.id == piece.id }) { next.pieces.append(piece) }
    next.draft = PieceDraft()
    next.onboardingCompleted = true
    try commit(next)
    draft = next.draft
    message = nil
    route = next.pinnedPieceID.map { .readiness($0) } ?? .saved(piece.id)
  }

  func missingCategories(around id: UUID) -> [PieceCategory] {
    let available = Set(pieces.map(\.category))
    let pin = pieces.first { $0.id == id }
    let required: [PieceCategory] =
      pin?.category == .dresses
      ? [.dresses, .shoes] : [.tops, .bottoms, .shoes]
    return required.filter { !available.contains($0) }
  }

  func buildAround(_ id: UUID) throws {
    var next = state
    next.pinnedPieceID = id
    try commit(next)
    route = .readiness(id)
  }

  func openCloset() {
    do {
      var next = state
      next.pinnedPieceID = nil
      try commit(next)
      route = .closet
    } catch { message = error.localizedDescription }
  }

  func setPhoto(_ data: Data) throws {
    guard storageReadable else { throw EntryError.unreadableStorage }
    let file = try store.savePhoto(data)
    var updated = draft
    updated.photoFile = file
    var next = state
    next.draft = updated
    try commit(next)
    draft = updated
  }

  func savePreferences(dismissed: Bool = false) throws {
    var next = state
    next.preferences = preferences
    next.preferences.dismissed = dismissed
    try commit(next)
    preferences = next.preferences
    route = .closet
  }

  func setAccount(_ account: AccountIdentity?) { self.account = account }

  func associationOperation() throws -> UUID {
    if let existing = state.pendingAssociation {
      guard existing.ownerID == account?.id else { throw EntryError.differentAccount }
      return existing.id
    }
    var next = state
    let id = UUID()
    next.pendingAssociation = PendingAssociation(id: id, ownerID: account?.id, pieces: localPieces)
    try commit(next)
    return id
  }

  func confirmAssociation(owner: UUID, ids: Set<UUID>) throws {
    guard account?.id == owner else { throw EntryError.differentAccount }
    var next = state
    for index in next.pieces.indices where ids.contains(next.pieces[index].id) {
      next.pieces[index].ownerID = owner
    }
    next.pendingAssociation = nil
    try commit(next)
  }

  func retryStorage() {
    do {
      let restored = try store.load()
      state = restored
      draft = restored.draft
      preferences = restored.preferences
      storageReadable = true
      message = nil
    } catch { message = EntryError.unreadableStorage.localizedDescription }
  }

  private func commit(_ next: ClosetState) throws {
    guard storageReadable else { throw EntryError.unreadableStorage }
    try store.save(next)
    state = next
  }
}

struct AccountIdentity: Equatable, Sendable {
  let id: UUID
  let label: String
}
