import Foundation
import Supabase
import Testing

@testable import AQD

@MainActor
struct IdentityFlowTests {
  private func fixture() -> (EntryFlow, IdentityFlow, TestIdentityService, URL) {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let flow = EntryFlow(directory: directory)
    let service = TestIdentityService()
    let identity = IdentityFlow(
      flow: flow, service: service,
      transactionStorage: KeychainLocalStorage(service: "com.aqd.tests." + UUID().uuidString))
    return (flow, identity, service, directory)
  }

  @Test func invalidEmailKeepsInputWithoutStartingVerification() async {
    let (flow, identity, _, url) = fixture()
    defer { try? FileManager.default.removeItem(at: url) }
    identity.start()
    flow.route = .email
    identity.email = "not an email"
    await identity.sendEmail()
    #expect(flow.route == .email)
    #expect(identity.email == "not an email")
    #expect(identity.transaction == nil)
  }

  @Test func cancellationRestoresTheInitiatingWelcomeAndKeepsTheDraft() async {
    let (flow, identity, _, url) = fixture()
    defer { try? FileManager.default.removeItem(at: url) }
    flow.draft.name = "My shirt"
    identity.start()
    identity.email = "person@example.com"
    await identity.sendEmail()
    identity.cancel()
    #expect(flow.route == .welcome)
    #expect(flow.draft.name == "My shirt")
    #expect(flow.account == nil)
  }

  @Test func unrelatedCallbackCannotSignInOrMoveRecords() async throws {
    let (flow, identity, _, url) = fixture()
    defer { try? FileManager.default.removeItem(at: url) }
    identity.start()
    identity.email = "person@example.com"
    await identity.sendEmail()
    await identity.handleCallback(
      URL(string: "com.aqd.ios://auth/callback?state=wrong&code=untrusted")!)
    #expect(flow.account == nil)
    #expect(identity.error != nil)
  }

  @Test func authSuccessRequiresExplicitAssociationAndDoesNotCreateAProfile() async throws {
    let (flow, identity, _, url) = fixture()
    defer { try? FileManager.default.removeItem(at: url) }
    flow.draft.name = "Shoes"
    flow.draft.category = .shoes
    try flow.savePiece()
    identity.start()
    identity.email = "person@example.com"
    await identity.sendEmail()
    let state = try #require(identity.transaction?.id.uuidString)
    await identity.handleCallback(
      URL(string: "com.aqd.ios://auth/callback?state=\(state)&code=valid")!)
    #expect(flow.route == .connectCloset)
    #expect(flow.localPieces.count == 1)
    #expect(identity.profile == nil)
    await identity.connectCloset()
    #expect(flow.localPieces.isEmpty)
    #expect(flow.pieces.count == 1)
  }

  @Test func accountCollisionLeavesEveryLocalRecordUnchanged() async throws {
    let (flow, identity, service, url) = fixture()
    defer { try? FileManager.default.removeItem(at: url) }
    flow.draft.name = "Shoes"
    flow.draft.category = .shoes
    try flow.savePiece()
    let id = try #require(flow.pieces.first?.id)
    service.records = [
      RemotePiece(id: UUID(), name: "Existing shirt", category: .tops, photoPath: nil)
    ]
    identity.start()
    await identity.apple(token: "test-token", nonce: "test-nonce")
    #expect(flow.route == .closetConflict)
    #expect(flow.localPieces.first?.id == id)
  }

  @Test func aFailedEmailRequestDoesNotClaimThatMailWasSent() async {
    let (flow, identity, service, url) = fixture()
    defer { try? FileManager.default.removeItem(at: url) }
    service.offline = true
    identity.start()
    identity.email = "person@example.com"
    await identity.sendEmail()
    #expect(flow.route == .authUnavailable)
    #expect(identity.email == "person@example.com")
    #expect(identity.transaction == nil)
  }

  @Test func staleOrCancelledSignInDoesNotResumeAfterTheTaskFinishes() async {
    let (flow, identity, service, url) = fixture()
    defer { try? FileManager.default.removeItem(at: url) }
    service.delay = true
    identity.start()
    identity.email = "person@example.com"
    let request = Task { await identity.sendEmail() }
    await Task.yield()
    identity.cancel()
    await request.value
    #expect(flow.route == .welcome)
    #expect(flow.account == nil)
  }
}

/// A deterministic external auth/network boundary; no application collaborators are mocked.
@MainActor private final class TestIdentityService: IdentityService {
  let resendSeconds: TimeInterval = 1
  var offline = false
  var delay = false
  var records: [RemotePiece] = []
  let user = AccountIdentity(id: UUID(), label: "person@example.com")
  func restoreAccount() async throws -> AccountIdentity? { nil }
  func sendEmail(_ email: String, redirect: URL) async throws {
    if delay { try await Task.sleep(for: .milliseconds(30)) }
    if offline { throw URLError(.notConnectedToInternet) }
  }
  func verifyCallback(_ url: URL) async throws -> AccountIdentity { user }
  func signInWithApple(token: String, nonce: String) async throws -> AccountIdentity { user }
  func signOut() async throws {}
  func profile() async throws -> PublicProfile? { nil }
  func saveProfile(name: String, username: String) async throws -> PublicProfile {
    PublicProfile(id: user.id, displayName: name, username: username)
  }
  func accountPieces() async throws -> [RemotePiece] { records }
  func connect(operation: UUID, pieces: [Piece], store: LocalCloset) async throws
    -> ConnectionReceipt
  {
    ConnectionReceipt(pieceIDs: pieces.map(\.id), confirmedAt: "2026-10-05T00:00:00Z")
  }
}
