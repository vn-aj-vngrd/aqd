import Foundation

enum PieceCategory: String, Codable, CaseIterable, Identifiable {
  case tops, bottoms, dresses, layers, shoes, accessories
  var id: String { rawValue }
  var title: String { rawValue.capitalized }
  var symbol: String {
    switch self {
    case .tops, .layers: "tshirt"
    case .bottoms: "figure.walk"
    case .dresses: "figure.dress.line.vertical.figure"
    case .shoes: "shoe"
    case .accessories: "bag"
    }
  }
}

struct Piece: Codable, Identifiable, Equatable, Sendable {
  let id: UUID
  var name: String
  var category: PieceCategory
  var photoFile: String?
  var ownerID: UUID?
  var createdAt: Date
}

struct PieceDraft: Codable, Equatable {
  var id = UUID()
  var name = ""
  var category: PieceCategory?
  var photoFile: String?
  var hasChanges: Bool { !name.isEmpty || category != nil || photoFile != nil }
}

struct StylePreferences: Codable, Equatable {
  var everyday: Set<String> = []
  var styles: Set<String> = []
  var comfort = ""
  var dismissed = false
}

struct ClosetState: Codable {
  var version = 1
  var onboardingCompleted = false
  var captureStarted = false
  var pieces: [Piece] = []
  var draft = PieceDraft()
  var preferences = StylePreferences()
  var pendingAssociation: PendingAssociation?
  var pinnedPieceID: UUID?
}

struct PendingAssociation: Codable {
  let id: UUID
  let ownerID: UUID?
  let pieces: [Piece]
}

enum EntryRoute: Hashable {
  case welcome, firstPiece, editor, cameraDenied
  case saved(UUID)
  case closet, preferences
  case readiness(UUID)
  case signIn, email, checkEmail, expiredLink, authUnavailable, sessionExpired
  case publicProfile, connectCloset, closetConflict, connecting, profile
}

enum EntryError: LocalizedError {
  case invalidName, missingCategory, unreadableStorage, unavailable, invalidEmail, invalidUsername
  case staleLink, missingTransaction, closetConflict, differentAccount
  var errorDescription: String? {
    switch self {
    case .invalidName: "Enter a piece name between 1 and 80 characters."
    case .missingCategory: "Choose a category for this piece."
    case .unreadableStorage:
      "Your saved closet could not be read. It has not been replaced. Retry or restore a backup."
    case .unavailable: "Sign-in is unavailable. Your private closet and drafts are unchanged."
    case .invalidEmail: "Enter a valid email address."
    case .invalidUsername: "Use 3–30 letters, numbers, periods or underscores for your username."
    case .staleLink: "This link has expired or has already been used. Request a new link."
    case .missingTransaction: "Start sign-in on this iPhone before opening its email link."
    case .closetConflict: "This account already has a closet. Your records have been kept separate."
    case .differentAccount: "The signed-in account changed. Review it again before connecting."
    }
  }
}
