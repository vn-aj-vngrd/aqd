import AuthenticationServices
import CryptoKit
import Security
import SwiftUI

struct IdentityScreens: View {
  let route: EntryRoute
  @Bindable var flow: EntryFlow
  @Bindable var identity: IdentityFlow
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.openURL) private var openURL
  @State private var nonce: String?
  @State private var legal: LegalDocument?
  @State private var reviewingRecords = false

  var body: some View {
    content.navigationTitle(navigationTitle).navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden(route != .profile)
      .toolbar {
        if route != .profile {
          ToolbarItem(placement: .topBarLeading) {
            Button("Back", systemImage: "chevron.left") { identity.back(from: route) }
              .tint(AQDColor.ink).disabled(route == .connecting && identity.busy)
          }
        }
      }
      .sheet(item: $legal) { LegalView(document: $0) }
      .sheet(isPresented: $reviewingRecords) {
        NavigationStack {
          List {
            Section("On this iPhone") { ForEach(flow.localPieces) { Text($0.name) } }
            Section("Account closet") { ForEach(identity.remotePieces) { Text($0.name) } }
          }.navigationTitle("Review pieces").toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { reviewingRecords = false } }
          }
        }
      }
  }

  @ViewBuilder private var content: some View {
    switch route {
    case .signIn: signIn
    case .email: email
    case .checkEmail: checkEmail
    case .expiredLink: expired
    case .authUnavailable: unavailable
    case .sessionExpired: sessionExpired
    case .publicProfile: publicProfile
    case .connectCloset: connect
    case .closetConflict: collision
    case .connecting: connecting
    default: profile
    }
  }
  private var navigationTitle: String {
    switch route {
    case .signIn: "Sign in"
    case .email: "Continue with email"
    case .checkEmail: "Check your email"
    case .expiredLink: "Sign-in link expired"
    case .authUnavailable: "Sign-in unavailable"
    case .sessionExpired: "Session expired"
    case .publicProfile: "Public profile"
    case .connectCloset, .closetConflict: "Connect your closet"
    case .connecting: "Connecting closet"
    default: "Profile"
    }
  }

  private var signIn: some View {
    EntryPage(
      title: "Make room for connection.",
      detail: "Sign in to share a look, follow a closet, or start a conversation."
    ) {
      SignInWithAppleButton(.continue) { request in
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
          identity.error = "Couldn’t start secure Apple sign-in. Try again."
          return
        }
        let value = bytes.map { String(format: "%02x", $0) }.joined()
        nonce = value
        request.requestedScopes = [.email]
        request.nonce = SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }
          .joined()
      } onCompletion: { result in
        switch result {
        case .success(let authorization):
          guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let data = credential.identityToken, let token = String(data: data, encoding: .utf8),
            let nonce
          else {
            identity.error = "Apple sign-in didn’t return a valid identity. Try email."
            return
          }
          Task { await identity.apple(token: token, nonce: nonce) }
        case .failure(let error):
          if (error as? ASAuthorizationError)?.code != .canceled {
            identity.error = "Apple sign-in couldn’t complete. Try again or use email."
          }
        }
        nonce = nil
      }.signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black).frame(height: 50)
        .clipShape(.capsule).disabled(identity.busy)
      SecondaryAction(title: "Continue with email") { flow.route = .email }.accessibilityIdentifier(
        "auth.emailMethod")
      Text("Signing in never publishes your closet.").font(.footnote).foregroundStyle(
        AQDColor.secondary)
      legalLinks
      InlineNotice(text: identity.error)
    }
  }

  private var email: some View {
    EntryPage(
      title: "A link. No password.",
      detail: "We’ll email you a secure link to sign in or create your account."
    ) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Email address").font(.subheadline)
        TextField("name@example.com", text: $identity.email).keyboardType(.emailAddress)
          .textContentType(.emailAddress)
          .textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(
            .roundedBorder
          ).accessibilityLabel("Email address").accessibilityIdentifier("auth.email")
          .submitLabel(.go).onSubmit { Task { await identity.sendEmail() } }
      }
      InlineNotice(text: identity.error)
      PrimaryAction(title: "Send sign-in link", busy: identity.busy) {
        Task { await identity.sendEmail() }
      }.accessibilityIdentifier("auth.send")
      Text("Use an address you can open on this iPhone.").font(.callout).foregroundStyle(
        AQDColor.secondary
      ).background(AQDColor.canvas)
      legalLinks
    }
  }

  private var checkEmail: some View {
    EntryPage(
      title: "Your sign-in link is on its way.",
      detail: "Open the link sent to your email address, then return to AQD."
    ) {
      IdentityRow(label: "Email", value: identity.email)
      PrimaryAction(title: "Open Mail") {
        if let url = URL(string: "message://") {
          openURL(url) { accepted in
            if !accepted {
              identity.error = "Mail is not available here. Open your email app to use the link."
            }
          }
        }
      }
      SecondaryAction(title: "Use a different email") { flow.route = .email }
      TimelineView(.periodic(from: .now, by: 1)) { context in
        let remaining = max(
          0,
          Int(
            ceil((identity.transaction?.resendAt ?? .distantPast).timeIntervalSince(context.date))))
        Button(remaining > 0 ? "Send another link in \(remaining)s" : "Send another link") {
          Task { await identity.sendEmail() }
        }
        .frame(minHeight: 44).disabled(remaining > 0 || identity.busy)
      }
      InlineNotice(text: identity.error)
      Text("Your private closet stays here while you sign in.").font(.footnote).foregroundStyle(
        AQDColor.secondary)
    }
  }

  private var expired: some View {
    EntryPage(
      title: "Let’s send a fresh link.",
      detail: "This link has expired or has already been used. Your private closet is unchanged."
    ) {
      IdentityRow(label: "Email", value: identity.email)
      PrimaryAction(title: "Send a new link", busy: identity.busy) {
        Task { await identity.sendEmail() }
      }
      SecondaryAction(title: "Use a different email") { flow.route = .email }
      SecondaryAction(title: "Continue privately") { identity.cancel() }
      InlineNotice(text: identity.error)
    }
  }

  private var unavailable: some View {
    EntryPage(
      title: "We couldn’t sign you in.",
      detail: "Your private records and pending action are unchanged."
    ) {
      IdentityRow(label: "Connection", value: "Could not reach sign-in")
      if !identity.email.isEmpty { IdentityRow(label: "Your email", value: identity.email) }
      InlineNotice(text: identity.error)
      PrimaryAction(title: "Try again", busy: identity.busy) { Task { await identity.retry() } }
      SecondaryAction(title: "Use another sign-in method") { flow.route = .signIn }
      Text("You can keep using your private closet while sign-in is unavailable.").font(.footnote)
        .foregroundStyle(AQDColor.secondary)
    }
  }

  private var sessionExpired: some View {
    EntryPage(
      title: "Sign in to continue.",
      detail:
        "Your closet on this iPhone is still available. Publishing and messages need a current session."
    ) {
      IdentityRow(label: "Private drafts", value: "Kept on this iPhone")
      IdentityRow(label: "Connected actions", value: "Paused until sign-in")
      PrimaryAction(title: "Sign in again") { identity.start(intent: .profile) }
      SecondaryAction(title: "Use my private closet") { flow.route = .closet }
      Text("Nothing is sent automatically after verification.").font(.footnote).foregroundStyle(
        AQDColor.secondary)
    }
  }

  private var publicProfile: some View {
    EntryPage(
      title: "How would you like to be known?",
      detail: "Set up your public identity when you’re ready to join the community."
    ) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Display name").font(.subheadline)
        TextField("Your name", text: $identity.name).textContentType(.name).textFieldStyle(
          .roundedBorder
        ).accessibilityLabel("Display name").accessibilityIdentifier("profile.name")
        Text("Username").font(.subheadline).padding(.top, 12)
        TextField("Choose a username", text: $identity.username).textInputAutocapitalization(.never)
          .autocorrectionDisabled().textFieldStyle(.roundedBorder).accessibilityLabel("Username")
          .accessibilityIdentifier(
            "profile.username")
      }
      Text("Letters, numbers, periods and underscores.").font(.footnote).foregroundStyle(
        AQDColor.secondary)
      Text("Your name and username are public. Your pieces stay private until you publish them.")
        .foregroundStyle(AQDColor.secondary)
      InlineNotice(text: identity.error)
      PrimaryAction(title: "Create profile", busy: identity.busy) {
        Task { await identity.createProfile() }
      }
    }
  }

  private var connect: some View {
    EntryPage(
      title: "Keep this closet with this account?",
      detail: "Review the account before connecting the private pieces saved on this iPhone."
    ) {
      accountRow
      Button {
        reviewingRecords = true
      } label: {
        IdentityRow(label: "On this iPhone", value: "Review \(flow.localPieces.count) pieces")
      }.frame(minHeight: 44)
      Text(
        "Nothing will be published. Your records stay on this iPhone until the connection succeeds."
      ).foregroundStyle(AQDColor.secondary)
      PrimaryAction(title: "Connect this closet", busy: identity.busy) {
        Task { await identity.connectCloset() }
      }
      SecondaryAction(title: "Use a different account") {
        Task {
          await identity.signOut()
          identity.start()
        }
      }
      InlineNotice(text: identity.error)
    }
  }

  private var collision: some View {
    EntryPage(
      title: "Two closets. One careful choice.",
      detail:
        "This account already has a closet. Review both before connecting records from this iPhone."
    ) {
      accountRow
      Button {
        reviewingRecords = true
      } label: {
        IdentityRow(label: "Account closet", value: "Review \(identity.remotePieces.count) records")
      }.frame(minHeight: 44)
      Button {
        reviewingRecords = true
      } label: {
        IdentityRow(label: "This iPhone", value: "Review \(flow.localPieces.count) records")
      }.frame(minHeight: 44)
      Text("Nothing has been moved, replaced, or deleted.").foregroundStyle(AQDColor.secondary)
      PrimaryAction(title: "Keep them separate") { identity.keepSeparate() }
      SecondaryAction(title: "Use a different account") {
        Task {
          await identity.signOut()
          identity.start()
        }
      }
      Text("Combining closets will be available only when it can safely preserve every record.")
        .font(.footnote).foregroundStyle(AQDColor.secondary)
    }
  }

  private var connecting: some View {
    EntryPage(
      title: "Connecting your closet.",
      detail: "Keep this account and this iPhone’s records in view while the connection completes."
    ) {
      accountRow
      IdentityRow(
        label: "Local records", value: identity.busy ? "Preparing backup" : "Confirmation pending")
      if identity.busy { ProgressView("Connecting").frame(maxWidth: .infinity) }
      InlineNotice(text: identity.error)
      PrimaryAction(title: "Check connection status", busy: identity.busy) {
        Task { await identity.connectCloset() }
      }
      SecondaryAction(title: "Return to my closet") { flow.route = .closet }
      Text("These records are saved locally. Backed up appears only after server confirmation.")
        .font(.footnote).foregroundStyle(AQDColor.secondary)
    }
  }

  private var profile: some View {
    EntryPage(
      title: identity.profile?.displayName ?? "Your profile.",
      detail: flow.account == nil
        ? "Use your private closet without an account. Sign in when you’re ready to connect."
        : "Your account and private wardrobe are separate from what you choose to share."
    ) {
      if let profile = identity.profile {
        IdentityRow(label: "Public username", value: "@" + profile.username)
      }
      if flow.account != nil {
        accountRow
        if identity.profile == nil {
          PrimaryAction(title: "Set up public profile") { flow.route = .publicProfile }
        }
        if !flow.localPieces.isEmpty {
          SecondaryAction(title: "Review connecting my closet") { Task { await identity.retry() } }
        }
        Button("Sign out", role: .destructive) { Task { await identity.signOut() } }.frame(
          minHeight: 44
        ).disabled(identity.busy)
      } else {
        PrimaryAction(title: "Sign in") { identity.start(intent: .profile) }
      }
      SecondaryAction(title: "Style preferences") { flow.route = .preferences }
      InlineNotice(text: identity.error)
      legalLinks
    }
  }

  private var accountRow: some View {
    IdentityRow(label: "Signed-in account", value: flow.account?.label ?? "Sign-in required")
  }
  private var legalLinks: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: 20) {
        legalButton(.terms)
        legalButton(.privacy)
      }
      VStack(alignment: .leading, spacing: 0) {
        legalButton(.terms)
        legalButton(.privacy)
      }
    }
  }
  private func legalButton(_ document: LegalDocument) -> some View {
    Button {
      legal = document
    } label: {
      Text(document == .terms ? "Terms of service" : "Privacy policy")
        .font(.footnote).foregroundStyle(AQDColor.ink)
        .frame(minHeight: 44).contentShape(.rect)
    }.buttonStyle(.plain)
  }
}

enum LegalDocument: String, Identifiable {
  case terms, privacy
  var id: String { rawValue }
}
private struct LegalView: View {
  let document: LegalDocument
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Text("Development preview").font(.headline)
          Text(
            document == .privacy
              ? "Pieces and photos start on this iPhone. Sign-in sends your email or Apple identity to Supabase. Connecting a closet uploads only the records you review. Nothing is automatically published. Device-only records are not recoverable after app removal unless backed up separately."
              : "AQD is currently a development preview. You own the clothing records and photos you provide. Add only media you have permission to use. Community publication, billing and distribution are not available in this build."
          )
          Text(
            "Final launch terms, retention, deletion and support policies are still required before public distribution."
          ).foregroundStyle(AQDColor.secondary)
        }.padding(20)
      }.navigationTitle(document == .privacy ? "Privacy policy" : "Terms of service")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
    }
  }
}
