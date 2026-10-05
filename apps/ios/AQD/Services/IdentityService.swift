import Foundation

struct PublicProfile: Codable, Equatable, Sendable {
  let id: UUID
  var displayName: String
  var username: String
  enum CodingKeys: String, CodingKey {
    case id
    case displayName = "display_name"
    case username
  }
}

struct ConnectionReceipt: Decodable, Sendable {
  let pieceIDs: [UUID]
  let confirmedAt: String
  enum CodingKeys: String, CodingKey {
    case pieceIDs = "piece_ids"
    case confirmedAt = "confirmed_at"
  }
}

@MainActor
protocol IdentityService {
  var resendSeconds: TimeInterval { get }
  func restoreAccount() async throws -> AccountIdentity?
  func sendEmail(_ email: String, redirect: URL) async throws
  func verifyCallback(_ url: URL) async throws -> AccountIdentity
  func signInWithApple(token: String, nonce: String) async throws -> AccountIdentity
  func signOut() async throws
  func profile() async throws -> PublicProfile?
  func saveProfile(name: String, username: String) async throws -> PublicProfile
  func accountPieces() async throws -> [RemotePiece]
  func connect(operation: UUID, pieces: [Piece], store: LocalCloset) async throws
    -> ConnectionReceipt
}

struct RemotePiece: Codable, Identifiable, Sendable {
  let id: UUID
  let name: String
  let category: PieceCategory
  let photoPath: String?
  enum CodingKeys: String, CodingKey {
    case id, name, category
    case photoPath = "photo_path"
  }
}
