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
                        } else if tour.step == 7 {
                            screen(NavigationStack { LocalSettingsView() }, state: readState)
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
            } else { ProgressView("Opening tour") }
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
    private let titles = ["Your day, your way", "Build your closet", "Put outfits together", "Organize with themes", "Plan ahead", "Meet your Agent", "Keep your fit memories", "Make AQD yours"]
    private let explanations = [
        ["Today brings together your planned look, recent wear, favorites and fit journal.", "Record wear only when you actually wear something. Planning never changes your wear history.", "Customize Today to show, hide and reorder widgets. Weather is optional."],
        ["Use + to add a piece from Photos or the camera. Review its crop, name and category before saving.", "Search, sort and filter your pieces. Open a piece for details, availability and wear history.", "Long-press a card for its available actions. Manage your categories in Settings."],
        ["Switch to Outfits and use + to build a look from your saved pieces.", "Favorite looks you return to, organize them into themes, or plan a date to wear them.", "Edit an outfit whenever you need. Changed planned compositions require a fresh review."],
        ["Themes collect outfits for work, evenings, travel or whatever makes sense to you.", "Create a theme, choose its outfits and add an optional description.", "Filter your themes and open one to explore its looks. Your pieces stay in Closet."],
        ["Planner shows your saved intentions in Week or Month. Select a date to see its entries.", "Use + for one day, several days, a routine, or an event or trip. Assign an outfit or leave a date unassigned.", "Review overlaps before saving. Trips include a packing list; recording actual wear is always a separate action."],
        ["Ask for ideas or help exploring your wardrobe. Text responses use Apple Intelligence on this iPhone when ready.", "Use + to choose My closet, Selected pieces or Without closet, and manage Style or wear context.", "Local tools prepare exact changes for your review. A chat reply never saves, deletes or records anything by itself."],
        ["Use Profile + to add a fit photo or link an outfit. Crop your photo and add a private note.", "Fit memories and recorded wear are separate. Wear insights and history use your actual records.", "Edit your avatar, name and caption. Your profile and journal stay private on this iPhone."],
        ["Open Profile options for Style and Settings. Choose appearance, categories and optional weather.", "Your data controls include export, reviewed restore and erasing local data. Keep a backup before replacing data.", "Replay this tour from Settings whenever you need. No account or cloud model is required for your private closet."]
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
            }.padding(AppSpacing.screen).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24))
                .onChange(of: step, initial: true) { _, value in focusedStep = value }
                .animation(nil, value: step)
        }
    }
    private func explanation(_ step: Int) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(spacing: 12) {
                Text("\(step + 1) of \(PrivateEntryState.tourStepCount)").font(.subheadline).foregroundStyle(AppTheme.secondary)
                    .accessibilityFocused($focusedStep, equals: step)
                Spacer(minLength: 0)
                Button { state.updateEntry { $0.skipTour() } } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.secondary)
                        .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("Skip tour").accessibilityIdentifier("tour.skip")
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(titles[step]).font(AppTypography.section)
                ForEach(explanations[step], id: \.self) { detail in
                    Text(detail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    private var back: some View {
        SecondaryAction(title: "Back", compact: true) { state.updateEntry { $0.backInTour() } }
            .accessibilityIdentifier("tour.back")
    }
    private func next(_ step: Int) -> some View {
        PrimaryAction(title: step == PrivateEntryState.tourStepCount - 1 ? "Finish tour" : "Next",
                      compact: true) { state.updateEntry { $0.nextInTour() } }
            .accessibilityIdentifier("tour.next").id(step)
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
