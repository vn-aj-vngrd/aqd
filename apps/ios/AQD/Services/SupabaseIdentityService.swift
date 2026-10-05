import Foundation
import Supabase

@MainActor
final class SupabaseIdentityService: IdentityService {
  private let client: SupabaseClient?
  let resendSeconds: TimeInterval

  init(bundle: Bundle = .main, namespace: String = "com.aqd.ios") {
    let seconds = bundle.object(forInfoDictionaryKey: "AQDAuthResendSeconds") as? String
    resendSeconds = max(1, TimeInterval(seconds ?? "60") ?? 60)
    if let raw = bundle.object(forInfoDictionaryKey: "AQDSupabaseURL") as? String,
      let url = URL(string: raw),
      url.scheme == "https"
        || (url.scheme == "http" && ["localhost", "127.0.0.1"].contains(url.host ?? "")),
      let key = bundle.object(forInfoDictionaryKey: "AQDSupabaseKey") as? String, !key.isEmpty
    {
      client = SupabaseClient(
        supabaseURL: url, supabaseKey: key,
        options: .init(
          auth: .init(
            storage: KeychainLocalStorage(service: namespace + ".auth"), flowType: .pkce)))
    } else {
      client = nil
    }
  }

  private func configuredClient() throws -> SupabaseClient {
    guard let client else { throw EntryError.unavailable }
    return client
  }

  func restoreAccount() async throws -> AccountIdentity? {
    guard let client, client.auth.currentSession != nil else { return nil }
    return identity(try await client.auth.session)
  }

  func sendEmail(_ email: String, redirect: URL) async throws {
    try await configuredClient().auth.signInWithOTP(email: email, redirectTo: redirect)
  }

  func verifyCallback(_ url: URL) async throws -> AccountIdentity {
    identity(try await configuredClient().auth.session(from: url))
  }

  func signInWithApple(token: String, nonce: String) async throws -> AccountIdentity {
    identity(
      try await configuredClient().auth.signInWithIdToken(
        credentials: .init(provider: .apple, idToken: token, nonce: nonce)))
  }

  func signOut() async throws { try await configuredClient().auth.signOut(scope: .local) }

  func profile() async throws -> PublicProfile? {
    let client = try configuredClient()
    let user = try await client.auth.session.user
    let profiles: [PublicProfile] = try await client.from("profiles").select().eq(
      "id", value: user.id
    ).limit(1).execute().value
    return profiles.first
  }

  func saveProfile(name: String, username: String) async throws -> PublicProfile {
    let client = try configuredClient()
    let user = try await client.auth.session.user
    let profile = PublicProfile(id: user.id, displayName: name, username: username.lowercased())
    return try await client.from("profiles").upsert(profile).select().single().execute().value
  }

  func accountPieces() async throws -> [RemotePiece] {
    try await configuredClient().from("private_pieces").select("id,name,category,photo_path").order(
      "created_at"
    ).limit(500).execute().value
  }

  func connect(operation: UUID, pieces: [Piece], store: LocalCloset) async throws
    -> ConnectionReceipt
  {
    let client = try configuredClient()
    let user = try await client.auth.session.user
    var records: [ConnectionPiece] = []
    for piece in pieces {
      var path: String?
      if let photo = store.photoURL(piece.photoFile) {
        path =
          "\(user.id.uuidString.lowercased())/\(operation.uuidString.lowercased())/\(piece.id.uuidString.lowercased()).jpg"
        let data = try Data(contentsOf: photo)
        _ = try await client.storage.from("closet").upload(
          path ?? "", data: data, options: .init(contentType: "image/jpeg", upsert: true))
      }
      records.append(
        ConnectionPiece(
          id: piece.id, name: piece.name, category: piece.category.rawValue, photoPath: path,
          createdAt: ISO8601DateFormatter().string(from: piece.createdAt)))
    }
    return try await client.rpc(
      "connect_closet", params: ConnectionRequest(operation: operation, pieces: records)
    ).execute().value
  }

  private func identity(_ session: Session) -> AccountIdentity {
    AccountIdentity(id: session.user.id, label: session.user.email ?? "Apple account")
  }
}

private struct ConnectionPiece: Encodable {
  let id: UUID
  let name: String
  let category: String
  let photoPath: String?
  let createdAt: String
  enum CodingKeys: String, CodingKey {
    case id, name, category
    case photoPath = "photo_path"
    case createdAt = "created_at"
  }
}
private struct ConnectionRequest: Encodable {
  let operation: UUID
  let pieces: [ConnectionPiece]
  enum CodingKeys: String, CodingKey {
    case operation = "p_operation_id"
    case pieces = "p_pieces"
  }
}
