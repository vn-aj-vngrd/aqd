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
                        if tour.step == 5 {
                            tourAgent(readState)
                        } else {
                            NativeTabs(selection: .constant(tour.step == 0 ? 0 : tour.step < 4 ? 1 : tour.step == 4 ? 2 : 4),
                                       today: { screen(TodayView(), state: readState) },
                                       closet: { screen(ClosetView(), state: readState) },
                                       planner: { screen(LocalPlannerView(), state: readState) },
                                       profile: { screen(LocalProfileView(), state: readState) },
                                       agent: { _ in screen(tourAgent(readState), state: readState) }, isReadOnlyPreview: true)
                                .ignoresSafeArea()
                        }
                    }.allowsHitTesting(false).accessibilityHidden(true)
                    AppTheme.scrimSoft.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
                    TourCard().padding(.horizontal, 16).padding(.bottom, 20)
                        .frame(maxHeight: max(0, geometry.size.height - 20), alignment: .bottom)
                }
                }
            } else { LoadingStatePage(title: "Opening tour") }
        }.background(AppTheme.canvas).interactiveDismissDisabled()
            .onAppear { if readState == nil { readState = state.makeTourReadState() }; selectPreview() }
            .onChange(of: state.entry.tour?.step) { selectPreview() }
    }
    private func selectPreview() {
        guard let step = state.entry.tour?.step else { return }
        readState?.closetScope = step == 2 ? "Outfits" : step == 3 ? "Themes" : "Pieces"
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
    /// One idea per step, then the exact control that does it.
    private let steps: [(title: String, detail: String, symbol: String, action: String)] = [
        ("Your day at a glance", "Today shows your planned look, what you wore this week and what’s coming up.",
         "square.grid.2x2", "Tap the grid button to choose and arrange your cards."),
        ("Add your pieces", "Take a photo or choose one from Photos, then give it a name and category.",
         "plus", "In Closet, tap + and choose Add a piece."),
        ("Make outfits", "Put your pieces together into looks you’ll actually wear.",
         "square.stack", "Tap + and choose Build an outfit."),
        ("Group looks into themes", "Keep outfits for work, weekends or a trip in one place.",
         "folder", "Tap + and choose Create a theme."),
        ("Plan what to wear", "Give a day, a routine or a trip its outfits. Trips come with a packing list.",
         "calendar", "In Planner, tap + to plan."),
        ("Ask your Agent", "Ask for an outfit, a trip plan or what you haven’t worn lately. Nothing changes until you tap Apply.",
         "sparkle", "Open the Agent tab and ask in your own words."),
        ("Yours, privately", "Your fit journal, style and settings live in Profile. Everything stays on this iPhone.",
         "play.rectangle", "Replay this tour anytime from Settings.")
    ]
    var body: some View {
        if let tour = state.entry.tour {
            let step = tour.step
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                ViewThatFits(in: .vertical) {
                    explanation(step).fixedSize(horizontal: false, vertical: true)
                    ScrollView { explanation(step) }
                }
                if typeSize.isAccessibilitySize { ActionStack { next(step); back } }
                else { HStack(spacing: 12) { back; next(step) } }
            }.padding(AppSpacing.screen).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                .onChange(of: step, initial: true) { _, value in focusedStep = value }
                .animation(nil, value: step)
        }
    }
    /// The first-run tour ends in Closet, where adding a piece is the next real step.
    private func openClosetAfterFirstRun() {
        if state.entry.tour == nil, state.entry.page == .main, state.entry.tourOutcome != nil, !state.profileSettings { state.selection = 1 }
    }
    private func explanation(_ step: Int) -> some View {
        let item = steps[min(step, steps.count - 1)]
        return VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(spacing: 12) {
                progress(step)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Step \(step + 1) of \(PrivateEntryState.tourStepCount)")
                    .accessibilityFocused($focusedStep, equals: step)
                Spacer(minLength: 0)
                Button { state.updateEntry { $0.skipTour() }; openClosetAfterFirstRun() } label: {
                    Text("Skip").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        .frame(minWidth: AppControlMetrics.minimumTarget, minHeight: AppControlMetrics.minimumTarget)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("Skip tour").accessibilityIdentifier("tour.skip")
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title).font(AppTypography.section).accessibilityAddTraits(.isHeader)
                Text(item.detail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 12) {
                Image(systemName: item.symbol).font(.system(size: 15, weight: .medium)).foregroundStyle(AppTheme.ink)
                    .frame(width: 32, height: 32).background(AppTheme.canvas, in: Circle()).accessibilityHidden(true)
                Text(item.action).font(AppTypography.supporting).foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    private func progress(_ step: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<PrivateEntryState.tourStepCount, id: \.self) { index in
                Capsule().fill(index == step ? AppTheme.ink : AppTheme.divider)
                    .frame(width: index == step ? 18 : 6, height: 6)
            }
        }
    }
    private var back: some View {
        Button { state.updateEntry { $0.backInTour() } } label: { GlassActionLabel(title: "Back", height: AppControlMetrics.minimumTarget) }
            .buttonStyle(.plain).accessibilityIdentifier("tour.back")
    }
    private func next(_ step: Int) -> some View {
        Button {
            state.updateEntry { $0.nextInTour() }
            if step >= PrivateEntryState.tourStepCount - 1 { openClosetAfterFirstRun() }
        } label: {
            GlassActionLabel(title: step == PrivateEntryState.tourStepCount - 1 ? "Done" : "Next", prominent: true, height: AppControlMetrics.minimumTarget)
        }.buttonStyle(.plain).accessibilityIdentifier("tour.next").id(step)
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
