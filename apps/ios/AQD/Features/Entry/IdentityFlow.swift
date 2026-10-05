import Foundation
import Observation
import Supabase

struct EmailTransaction: Codable {
  let id: UUID
  let email: String
  let returnRoute: EntryRouteIntent
  var resendAt: Date
  var callbackURL: URL?
}
enum EntryRouteIntent: String, Codable { case closet, profile }

@MainActor @Observable
final class IdentityFlow {
  var email = ""
  var name = ""
  var username = ""
  var error: String?
  private(set) var busy = false
  private(set) var profile: PublicProfile?
  private(set) var remotePieces: [RemotePiece] = []
  private(set) var transaction: EmailTransaction?
  private(set) var returnIntent: EntryRouteIntent = .closet
  private var generation = UUID()
  private let transactionStorage: any AuthLocalStorage
  private var origin: EntryRoute = .closet
  private let service: any IdentityService
  private let flow: EntryFlow

  init(
    flow: EntryFlow, service: any IdentityService,
    transactionStorage: any AuthLocalStorage = KeychainLocalStorage(service: "com.aqd.ios.entry")
  ) {
    self.flow = flow
    self.service = service
    self.transactionStorage = transactionStorage
    if let data = try? transactionStorage.retrieve(key: "email-transaction"),
      let saved = try? JSONDecoder().decode(EmailTransaction.self, from: data)
    {
      transaction = saved
      email = saved.email
      returnIntent = saved.returnRoute
    }
  }

  func start(intent: EntryRouteIntent = .closet) {
    guard !busy else { return }
    recordOrigin(intent: intent)
    flow.route = .signIn
  }

  private func recordOrigin(intent: EntryRouteIntent) {
    generation = UUID()
    origin = flow.route
    returnIntent = intent
    error = nil
  }

  func setupProfile() {
    guard !busy else { return }
    recordOrigin(intent: .profile)
    flow.route = .publicProfile
  }

  func reviewConnection() async {
    guard !busy else { return }
    recordOrigin(intent: .profile)
    await retry()
  }

  func cancel() {
    generation = UUID()
    error = nil
    transaction = nil
    try? transactionStorage.remove(key: "email-transaction")
    flow.route = origin
  }

  func back(from route: EntryRoute) {
    generation = UUID()
    switch route {
    case .email: flow.route = .signIn
    case .checkEmail: flow.route = .email
    case .expiredLink: flow.route = .checkEmail
    case .authUnavailable: flow.route = email.isEmpty ? .signIn : .email
    default: cancel()
    }
  }

  func restore() async {
    let attempt = generation
    do {
      let account = try await service.restoreAccount()
      guard attempt == generation else { return }
      flow.setAccount(account)
      if account != nil {
        let restoredProfile = try await service.profile()
        guard attempt == generation else { return }
        profile = restoredProfile
      }
    } catch {
      guard attempt == generation else { return }
      flow.setAccount(nil)
      flow.route = .sessionExpired
    }
  }

  func sendEmail() async {
    guard !busy else { return }
    let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
    guard Self.validEmail(trimmed) else {
      error = EntryError.invalidEmail.localizedDescription
      return
    }
    if let transaction, transaction.email == trimmed, transaction.resendAt > Date() { return }
    let token = generation
    busy = true
    defer { busy = false }
    error = nil
    let id = UUID()
    var components = URLComponents()
    components.scheme = "com.aqd.ios"
    components.host = "auth"
    components.path = "/callback"
    components.queryItems = [URLQueryItem(name: "state", value: id.uuidString)]
    do {
      guard let redirect = components.url else { throw EntryError.unavailable }
      let pending = EmailTransaction(
        id: id, email: trimmed, returnRoute: returnIntent,
        resendAt: Date().addingTimeInterval(service.resendSeconds))
      try transactionStorage.store(key: "email-transaction", value: JSONEncoder().encode(pending))
      transaction = pending
      try await service.sendEmail(trimmed, redirect: redirect)
      guard generation == token else { return }
      email = trimmed
      flow.route = .checkEmail
    } catch {
      guard generation == token else { return }
      self.error =
        "We couldn’t send a sign-in link. Your email and private records are unchanged. Try again."
      transaction = nil
      try? transactionStorage.remove(key: "email-transaction")
      flow.route = .authUnavailable
    }
  }

  func handleCallback(_ url: URL) async {
    guard !busy, url.scheme == "com.aqd.ios", url.host == "auth", url.path == "/callback",
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let transaction
    else {
      error = EntryError.missingTransaction.localizedDescription
      return
    }
    let states = components.queryItems?.filter { $0.name == "state" } ?? []
    guard states.count == 1, states.first?.value == transaction.id.uuidString else {
      error = EntryError.staleLink.localizedDescription
      return
    }
    let token = generation
    busy = true
    defer { busy = false }
    do {
      var pending = transaction
      pending.callbackURL = url
      try transactionStorage.store(key: "email-transaction", value: JSONEncoder().encode(pending))
      self.transaction = pending
      let account = try await service.verifyCallback(url)
      guard token == generation else {
        try? await service.signOut()
        return
      }
      flow.setAccount(account)
      try transactionStorage.remove(key: "email-transaction")
      self.transaction = nil
      await signedIn(attempt: token)
      if token != generation {
        try? await service.signOut()
        flow.setAccount(nil)
      }
    } catch {
      guard token == generation else { return }
      if let auth = error as? AuthError, auth.errorCode == .otpExpired {
        flow.route = .expiredLink
        self.error = EntryError.staleLink.localizedDescription
      } else {
        flow.route = .authUnavailable
        self.error =
          "We couldn’t verify this link. Retry when you’re online; your closet is unchanged."
      }
    }
  }

  func apple(token: String, nonce: String) async {
    guard !busy else { return }
    busy = true
    defer { busy = false }
    let attempt = generation
    do {
      let account = try await service.signInWithApple(token: token, nonce: nonce)
      guard generation == attempt else {
        try? await service.signOut()
        return
      }
      flow.setAccount(account)
      await signedIn(attempt: attempt)
      if attempt != generation {
        try? await service.signOut()
        flow.setAccount(nil)
      }
    } catch {
      if generation == attempt {
        self.error = "Apple sign-in couldn’t complete. Try email or continue privately."
        flow.route = .authUnavailable
      }
    }
  }

  private func signedIn(attempt: UUID) async {
    do {
      let loadedProfile = try await service.profile()
      guard attempt == generation else { return }
      let loadedPieces = try await service.accountPieces()
      guard attempt == generation else { return }
      profile = loadedProfile
      remotePieces = loadedPieces
      error = nil
      if let pending = flow.state.pendingAssociation, pending.ownerID == flow.account?.id {
        flow.route = .connecting
      } else {
        flow.route =
          !flow.localPieces.isEmpty
          ? (remotePieces.isEmpty ? .connectCloset : .closetConflict) : destination
      }
    } catch {
      guard attempt == generation else { return }
      self.error =
        "You’re signed in, but account records couldn’t load. Retry before connecting your closet."
      flow.route = .authUnavailable
    }
  }

  var destination: EntryRoute {
    returnIntent == .profile && profile == nil
      ? .publicProfile : returnIntent == .profile ? .profile : .closet
  }
  func keepSeparate() { flow.route = destination }

  func connectCloset() async {
    guard !busy, let account = flow.account, !flow.localPieces.isEmpty else { return }
    busy = true
    error = nil
    flow.route = .connecting
    do {
      let operation = try flow.associationOperation()
      let pieces = flow.state.pendingAssociation?.pieces ?? flow.localPieces
      let receipt = try await service.connect(
        operation: operation, pieces: pieces, store: flow.store)
      guard Set(receipt.pieceIDs) == Set(pieces.map(\.id)) else { throw EntryError.unavailable }
      try flow.confirmAssociation(owner: account.id, ids: Set(receipt.pieceIDs))
      if flow.route == .connecting { flow.route = destination }
    } catch {
      if let failure = error as? PostgrestError, failure.message.contains("closet_conflict") {
        flow.route = .closetConflict
      } else {
        self.error =
          "Connection is not confirmed. Your records remain on this iPhone. Check status to retry safely."
      }
    }
    busy = false
  }

  func createProfile() async {
    guard !busy else { return }
    let displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard (1...80).contains(displayName.count) else {
      error = "Enter a display name between 1 and 80 characters."
      return
    }
    guard username.range(of: "^[a-zA-Z0-9_.]{3,30}$", options: .regularExpression) != nil else {
      error = EntryError.invalidUsername.localizedDescription
      return
    }
    busy = true
    let attempt = generation
    defer { busy = false }
    do {
      let saved = try await service.saveProfile(name: displayName, username: username)
      guard attempt == generation else { return }
      profile = saved
      flow.route = .profile
      error = nil
    } catch {
      guard attempt == generation else { return }
      if let failure = error as? PostgrestError, failure.code == "23505" {
        self.error = "That username is taken. Choose another; your input is kept."
      } else {
        self.error = "Your profile couldn’t save. Try again; your input is kept."
      }
    }
  }

  func signOut() async {
    guard !busy else { return }
    busy = true
    do {
      try await service.signOut()
      flow.setAccount(nil)
      profile = nil
      remotePieces = []
      name = ""
      username = ""
      email = ""
      cancel()
    } catch { self.error = "Sign-out couldn’t complete. Try again." }
    busy = false
  }

  func retry() async {
    guard !busy else { return }
    if flow.account != nil {
      busy = true
      await signedIn(attempt: generation)
      busy = false
    } else if let callback = transaction?.callbackURL {
      await handleCallback(callback)
    } else if transaction != nil {
      flow.route = .checkEmail
    } else {
      await sendEmail()
    }
  }

  static func validEmail(_ value: String) -> Bool {
    value.count <= 254
      && value.range(of: "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$", options: .regularExpression) != nil
  }
}
