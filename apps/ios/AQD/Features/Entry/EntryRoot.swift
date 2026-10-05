import AVFoundation
import PhotosUI
import SwiftUI

struct EntryRoot: View {
  @Bindable var flow: EntryFlow
  @Bindable var identity: IdentityFlow
  @State private var path: [EntryRoute] = []
  @State private var showSources = false
  @State private var showPhotos = false
  @State private var showCamera = false
  @State private var selectedPhoto: PhotosPickerItem?
  @State private var preparingPhoto = false
  private let media = MediaPreparation()
  private var root: EntryRoute { flow.state.onboardingCompleted ? .closet : .welcome }
  private var navigationPath: Binding<[EntryRoute]> {
    Binding(
      get: { path },
      set: { routes in
        path = routes
        flow.route = routes.last ?? root
      })
  }

  var body: some View {
    GeometryReader { viewport in
      navigation.environment(\.entryCompact, viewport.size.height < 700)
    }
  }

  private var navigation: some View {
    NavigationStack(path: navigationPath) {
      screen(root)
        .navigationDestination(for: EntryRoute.self) { route in screen(route) }
    }.tint(AQDColor.ink)
      .onChange(of: flow.route) { _, route in
        guard route != path.last else { return }
        if route == root {
          path = []
        } else if let index = path.firstIndex(of: route) {
          path = Array(path.prefix(index + 1))
        } else {
          path.append(route)
        }
      }
      .task {
        if flow.route != root { path = [flow.route] }
        await identity.restore()
      }
      .onOpenURL { url in Task { await identity.handleCallback(url) } }
      .confirmationDialog("Add a photo", isPresented: $showSources, titleVisibility: .visible) {
        Button("Choose from Photos") { showPhotos = true }
        Button("Take photo") { Task { await camera() } }
        Button("Add without a photo") { flow.route = .editor }
        Button("Cancel", role: .cancel) {}
      }
      .photosPicker(isPresented: $showPhotos, selection: $selectedPhoto, matching: .images)
      .onChange(of: selectedPhoto) { _, photo in
        guard let photo else { return }
        Task {
          preparingPhoto = true
          defer {
            preparingPhoto = false
            selectedPhoto = nil
          }
          do {
            guard let data = try await photo.loadTransferable(type: Data.self) else {
              throw MediaError.invalidImage
            }
            try await prepare(data)
          } catch { flow.message = error.localizedDescription }
        }
      }
      .fullScreenCover(isPresented: $showCamera) {
        CameraCapture { data in
          showCamera = false
          if let data {
            Task {
              do { try await prepare(data) } catch { flow.message = error.localizedDescription }
            }
          }
        }.ignoresSafeArea()
      }
      .onChange(of: flow.draft) { _, _ in
        do { try flow.preserveDraft() } catch { flow.message = error.localizedDescription }
      }
  }

  @ViewBuilder private func screen(_ route: EntryRoute) -> some View {
    Group {
      switch route {
      case .welcome: welcome
      case .firstPiece: firstPiece
      case .editor: PieceEditor(flow: flow, preparing: preparingPhoto) { showSources = true }
      case .cameraDenied: cameraRecovery
      case .saved(let id): saved(id)
      case .closet: closet
      case .preferences: PreferencesView(flow: flow)
      case .readiness(let id): readiness(id)
      case .signIn, .email, .checkEmail, .expiredLink, .authUnavailable, .sessionExpired,
        .publicProfile, .connectCloset, .closetConflict, .connecting, .profile:
        IdentityScreens(route: route, flow: flow, identity: identity)
      }
    }.background(AQDColor.canvas.ignoresSafeArea())
  }

  private var welcome: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("AQD").font(.system(.title2, design: .default).weight(.medium)).tracking(2.3).padding(
          .vertical, 8)
        EntryHero()
        VStack(alignment: .leading, spacing: 12) {
          EntryHeading(title: "More from what you already own.")
          Text("Keep your pieces together. Make looks you’ll wear.").foregroundStyle(
            AQDColor.secondary)
        }.padding(.top, 8)
        VStack(spacing: 12) {
          PrimaryAction(title: "Start my closet", disabled: !flow.storageReadable) {
            flow.startPrivately()
          }.accessibilityIdentifier("entry.start")
          SecondaryAction(title: "I already have an account") { identity.start() }
          Text("Start privately on this iPhone. No account needed.").font(.footnote)
            .foregroundStyle(AQDColor.secondary).frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.top, 16)
        InlineNotice(text: flow.message)
      }.frame(maxWidth: 350).padding(.horizontal, 20).padding(.bottom, 40).frame(
        maxWidth: .infinity)
    }.toolbar(.hidden, for: .navigationBar)
  }

  private var firstPiece: some View {
    EntryPage(
      title: "Start with something you wear.",
      detail: "One piece is enough to begin. Add the rest whenever you like."
    ) {
      EntryHero(firstPiece: true)
      VStack(spacing: 12) {
        PrimaryAction(title: "Choose a photo", busy: preparingPhoto) { showSources = true }
        SecondaryAction(title: "Add without a photo") { flow.route = .editor }
          .accessibilityIdentifier("entry.manual")
      }.padding(.top, 16)
      Text("Name it, choose a category, and save. Nothing is shared.").font(.callout)
        .foregroundStyle(AQDColor.secondary)
      InlineNotice(text: flow.message)
    }.entryNavigationTitle("Your first piece")
      .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Skip") { flow.skipCapture() } } }
  }

  private func saved(_ id: UUID) -> some View {
    EntryPage(
      title: "Your first piece is saved.", detail: "Keep it private. Now build a look around it."
    ) {
      if let piece = flow.pieces.first(where: { $0.id == id }) {
        PieceImage(piece: piece, store: flow.store).frame(height: 240)
        IdentityRow(label: piece.name, value: "Private · Available")
        PrimaryAction(title: "Build my first outfit") {
          do { try flow.buildAround(id) } catch { flow.message = error.localizedDescription }
        }
      }
      SecondaryAction(title: "Open my closet") { flow.openCloset() }
      Button {
        flow.route = .preferences
      } label: {
        HStack {
          Text("Set style preferences")
          Spacer()
          Text("Optional").foregroundStyle(AQDColor.secondary)
          Image(systemName: "chevron.right")
        }.frame(minHeight: 44)
      }
    }.entryNavigationTitle("First piece saved")
      .navigationBarBackButtonHidden()
  }

  private var closet: some View {
    EntryPage(
      title: "Your private closet.",
      detail: flow.pieces.isEmpty
        ? "Add a piece to begin. A name and category are enough."
        : "Saved on this iPhone. Nothing is published."
    ) {
      if !flow.storageReadable {
        InlineNotice(text: flow.message)
        PrimaryAction(title: "Retry reading closet") { flow.retryStorage() }
      } else {
        ForEach(flow.pieces) { piece in
          HStack(spacing: 16) {
            PieceImage(piece: piece, store: flow.store).frame(width: 64, height: 80).clipped()
            VStack(alignment: .leading, spacing: 8) {
              Text(piece.name)
              Text(piece.category.title).font(.subheadline).foregroundStyle(AQDColor.secondary)
            }
          }.frame(maxWidth: .infinity, alignment: .leading)
        }
        PrimaryAction(title: "Add a piece") { flow.route = .firstPiece }
        Text(
          "Device-only records may be lost if this app is removed. Sign in to review connecting them to your account."
        ).font(.footnote).foregroundStyle(AQDColor.secondary)
        InlineNotice(text: flow.message)
      }
    }.entryNavigationTitle("Closet")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Profile", systemImage: "person.crop.circle") { flow.route = .profile }
        }
      }
  }

  private func readiness(_ id: UUID) -> some View {
    let missing = flow.missingCategories(around: id)
    return EntryPage(
      title: missing.isEmpty ? "Your pieces are ready." : "Build around your first piece.",
      detail: "Your saved piece stays pinned while you add the categories around it."
    ) {
      if let piece = flow.pieces.first(where: { $0.id == id }) {
        IdentityRow(label: "Pinned piece", value: piece.name)
      }
      ForEach(missing) { category in
        Button("Add \(category.title.lowercased())", systemImage: category.symbol) {
          flow.draft.category = category
          flow.route = .editor
        }.frame(minHeight: 44)
      }
      if missing.isEmpty {
        Text(
          "Your pieces are saved and ready for outfit composition. Outfit creation is the next implementation milestone."
        ).foregroundStyle(AQDColor.secondary)
      }
      SecondaryAction(title: "Open my closet") { flow.openCloset() }
    }.entryNavigationTitle("First outfit")
  }

  private func prepare(_ data: Data) async throws {
    let photo = try await media.prepare(data)
    try flow.setPhoto(photo)
    flow.message = nil
    flow.route = .editor
  }
  private func camera() async {
    let permission = AVCaptureDevice.authorizationStatus(for: .video)
    var allowed = permission == .authorized
    if permission == .notDetermined { allowed = await AVCaptureDevice.requestAccess(for: .video) }
    if allowed && UIImagePickerController.isSourceTypeAvailable(.camera) {
      showCamera = true
    } else {
      flow.route = .cameraDenied
    }
  }

  private var cameraRecovery: some View {
    EntryPage(
      title: "Camera access is turned off.",
      detail: "You can still add a piece from Photos or enter its details."
    ) {
      Button("Choose from Photos", systemImage: "photo") { showPhotos = true }.frame(minHeight: 44)
      Button("Add without a photo", systemImage: "square.and.pencil") { flow.route = .editor }
        .frame(minHeight: 44)
      PrimaryAction(title: "Open Settings") {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      }
      Text("AQD asks for camera access only when you choose to take a photo.").font(.footnote)
        .foregroundStyle(AQDColor.secondary)
    }.entryNavigationTitle("Camera access")
  }
}
