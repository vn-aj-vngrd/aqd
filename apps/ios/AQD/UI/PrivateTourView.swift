import AQDCore
import SwiftUI

struct PrivateTourView: View {
    @Environment(AppState.self) private var state
    @State private var readState: AppState?
    var body: some View {
        Group {
            if let tour = state.entry.tour, let readState {
                GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    Group {
                        if tour.step == 2 {
                            tourAgent(readState)
                        } else {
                            NativeTabs(selection: .constant(tour.step == 3 ? 4 : tour.step),
                                       today: { screen(TodayView(), state: readState) },
                                       closet: { screen(ClosetView(), state: readState) },
                                       planner: { screen(LocalPlannerView(), state: readState) },
                                       profile: { screen(LocalProfileView(), state: readState) },
                                       agent: { _ in screen(tourAgent(readState), state: readState) }, isReadOnlyPreview: true)
                                .ignoresSafeArea()
                        }
                    }.allowsHitTesting(false).accessibilityHidden(true)
                    Color.black.opacity(0.12).ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
                    TourCard().padding(.horizontal, 16).padding(.bottom, 20)
                        .frame(maxHeight: max(0, geometry.size.height - 20), alignment: .bottom)
                }
                }
            } else { ProgressView("Opening tour") }
        }.background(AppTheme.canvas).interactiveDismissDisabled()
            .onAppear { if readState == nil { readState = state.makeTourReadState() } }
    }
    private func screen(_ view: some View, state: AppState) -> AnyView { AnyView(view.environment(state)) }
    private func tourAgent(_ readState: AppState) -> some View {
        NavigationStack {
            if let model = readState.agentModel {
                AgentConversationView(model: model, close: {}, automaticallyFocusComposer: false)
            } else {
                AppEmptyState("Conversations couldn’t open", systemImage: "exclamationmark.bubble",
                              description: Text("Your local records are retained."))
                    .navigationTitle("Agent").navigationBarTitleDisplayMode(.inline)
            }
        }.environment(readState)
    }
}

extension AppState {
    /// Current records, separate navigation, no draft resumption or cleanup work.
    /// Tour views are input-blocked; only the coach writes entry-step metadata.
    func makeTourReadState() -> AppState {
        let readState = AppState(deferOpening: true)
        readState.isOpening = false; readState.store = store
        readState.settings = settings; readState.weatherClient = weatherClient
        readState.reloadPieces(); readState.reloadOutfits(); readState.reloadThemes()
        readState.reloadPlanEntries(); readState.reloadWear(); readState.reloadToday()
        readState.reloadIdentity(); readState.reloadFits()
        if let store {
            readState.agentModel = try? AgentModel(store: store, reconcileInterruptedAttempt: false)
        }
        return readState
    }
}

private struct TourCard: View {
    @Environment(AppState.self) private var state
    @Environment(\.dynamicTypeSize) private var typeSize
    @AccessibilityFocusState private var focusedStep: Int?
    private let titles = ["Today", "Closet", "Agent", "Profile"]
    private let explanations = [
        "See what’s planned and record what you actually wear. Plans and recorded wear stay separate.",
        "Pieces, outfits and themes live in Closet. Planner has its own tab for dates and plans.",
        "Ask about your wardrobe and review drafts before saving. Apple Intelligence assists where available; manual tools remain usable.",
        "Keep your fit memories together. Edit your profile from the avatar, explore Wear insights, or open More for Style and Settings."
    ]
    var body: some View {
        if let tour = state.entry.tour {
            let step = tour.step
            VStack(alignment: .leading, spacing: 16) {
                ViewThatFits(in: .vertical) {
                    explanation(step).fixedSize(horizontal: false, vertical: true)
                    ScrollView { explanation(step) }
                }
                if typeSize.isAccessibilitySize { ActionStack { next(step); back } }
                else { HStack(spacing: 12) { back; next(step) } }
            }.padding(20).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24))
                .onChange(of: step, initial: true) { _, value in focusedStep = value }
                .transaction { $0.disablesAnimations = true }
        }
    }
    private func explanation(_ step: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text("\(step + 1) of 4 · Your app").font(.subheadline).foregroundStyle(AppTheme.secondary)
                    .accessibilityFocused($focusedStep, equals: step)
                Spacer(minLength: 0)
                Button("Skip tour") { state.updateEntry { $0.skipTour() } }.frame(minHeight: 44)
                    .foregroundStyle(AppTheme.ink)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(titles[step]).font(AppTypography.section)
                Text(explanations[step]).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    private var back: some View {
        SecondaryAction(title: "Back") { state.updateEntry { $0.backInTour() } }
            .background(AppTheme.imageGround, in: Capsule()).accessibilityIdentifier("tour.back")
    }
    private func next(_ step: Int) -> some View {
        PrimaryAction(title: step == 3 ? "Finish tour" : "Next") { state.updateEntry { $0.nextInTour() } }.id(step)
    }
}

@MainActor enum TourArtwork {
    static let images: [String: UIImage] = {
        let names = ["tour-fit-blue-coat", "tour-fit-street", "tour-afternoon", "tour-coffee", "tour-evening", "tour-work"]
        return Dictionary(uniqueKeysWithValues: names.compactMap { name in
            let ext = name.hasPrefix("tour-fit") ? "jpg" : "png"
            guard let url = Bundle.main.url(forResource: name, withExtension: ext), let image = UIImage(contentsOfFile: url.path) else { return nil }
            return (name, image)
        })
    }()
    @ViewBuilder static func image(_ name: String, fill: Bool = false) -> some View {
        if let image = images[name] {
            if fill { Image(uiImage: image).resizable().scaledToFill() }
            else { Image(uiImage: image).resizable().scaledToFit() }
        } else { Image(systemName: "tshirt").resizable().scaledToFit().foregroundStyle(AppTheme.secondary) }
    }
}
