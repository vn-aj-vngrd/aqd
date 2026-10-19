import AQDCore
import SwiftUI

struct PrivateEntryView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        NavigationStack {
            Group {
                switch state.entry.page {
                case .welcome: WelcomeView()
                case .introduction: introduction
                case .privacy: privacy
                case .ready: ready
                case .main: EmptyView()
                }
            }.background(AppTheme.canvas)
                .toolbar(state.entry.page == .welcome ? .hidden : .visible, for: .navigationBar)
                .toolbar {
                    if state.entry.page == .introduction || state.entry.page == .privacy || state.entry.page == .ready {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                state.updateEntry {
                                    if $0.page == .ready { $0.reviewTourFromReady() }
                                    else { $0.page = $0.page == .privacy ? .introduction : .welcome }
                                }
                            } label: { Label("Back", systemImage: "chevron.backward") }.tint(AppTheme.ink)
                        }
                    }
                }
        }.tint(AppTheme.ink)
    }

    private var introduction: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Start with what you wear.").font(AppTypography.section)
                EntryIllustration(kind: .introduction)
                Text("Choose or take a photo of one piece.\nAdd its name and category.").foregroundStyle(AppTheme.secondary)
                Button { state.updateEntry { $0.page = .privacy } } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lock").foregroundStyle(AppTheme.secondary).frame(width: 20)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Private on this iPhone").font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.ink)
                            Text("Device loss or app deletion can erase your closet. Keep a separate copy before changing devices.")
                                .font(.footnote).foregroundStyle(AppTheme.secondary)
                        }
                    }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }.buttonStyle(.plain).accessibilityLabel("Private on this iPhone, Learn more")
                ActionStack {
                    PrimaryAction(title: "Personalize my closet") { state.openStyle(source: .onboarding) }
                    SecondaryAction(title: "Take the tour") { state.beginTour(from: .introduction) }
                }
            }.padding(.horizontal, 20).padding(.vertical, 24).frame(maxWidth: .infinity, alignment: .leading)
        }.navigationTitle("Start privately").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                ActionFooter { SecondaryAction(title: "Explore first") { state.enterMain() } }
            }
    }
    private var privacy: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                EntryIllustration(kind: .privacy)
                    .padding(12).background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: AppRadius.card))
                Text("Wear what you own.").font(.title.weight(.medium))
                Text("Keep your pieces, outfits and clothing plans on this iPhone. No account needed.")
                Text("Your closet has no automatic cloud backup. Device loss or deleting AQD can erase it. Keep a separate copy before deleting AQD or changing devices.")
                    .font(.subheadline).foregroundStyle(AppTheme.secondary)
            }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
        }.navigationTitle("Your closet, privately").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                ActionFooter {
                    ActionStack {
                        PrimaryAction(title: "Add piece") { state.enterMain(capture: true) }
                        SecondaryAction(title: "Open Closet") { state.enterMain(selection: 1) }
                    }
                }
            }
    }
    private var ready: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                EntryIllustration(kind: .ready)
                HStack(spacing: 4) {
                    roadmap("Add a piece", symbol: "camera", active: true)
                    Image(systemName: "chevron.forward").font(.footnote).foregroundStyle(AppTheme.secondary)
                    roadmap("Make a look", symbol: "tshirt", active: false)
                    Image(systemName: "chevron.forward").font(.footnote).foregroundStyle(AppTheme.secondary)
                    roadmap("Plan a day", symbol: "calendar", active: false)
                }.accessibilityElement(children: .ignore).accessibilityLabel("Add a piece, make a look, plan a day. Illustrative roadmap.")
                Text("Start with a photo of one piece you love.\nThen combine your pieces into an outfit.")
                    .font(.subheadline).foregroundStyle(AppTheme.secondary)
                ActionStack {
                    PrimaryAction(title: "Add piece") { state.enterMain(capture: true) }
                    SecondaryAction(title: "Open Today") { state.enterMain() }
                }
            }.padding(.horizontal, 20).padding(.vertical, 24)
        }.navigationTitle("Ready when you are").navigationBarTitleDisplayMode(.inline)
    }
    private func roadmap(_ title: String, symbol: String, active: Bool) -> some View {
        VStack(spacing: 8) { Image(systemName: symbol).font(.title3); Text(title).font(.subheadline) }
            .foregroundStyle(active ? AppTheme.ink : AppTheme.secondary).frame(maxWidth: .infinity, minHeight: 68)
    }
}

struct WelcomeView: View {
    var previewDismiss: ((Bool) -> Void)? = nil
    @Environment(AppState.self) private var state
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var pose: WelcomeWardrobe.Pose = .settled
    /// 0 nothing, 1 the mark, 2 the promise, 3 the action. Rest state is fully shown.
    @State private var stage = 3
    @State private var glint: CGFloat = -1
    @State private var played = false
    @State private var tilt = DeviceTilt()
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                // Brand, then the closet, then the promise sitting just above the button, so nothing floats in empty space.
                VStack(spacing: AppSpacing.section) {
                    brand
                    Spacer(minLength: 0)
                    WelcomeWardrobe(pose: pose, tilt: reduceMotion ? .zero : CGSize(width: tilt.x, height: tilt.y)).padding(.horizontal, AppSpacing.small)
                    Spacer(minLength: 0)
                    VStack(spacing: AppSpacing.small) {
                        Text(welcomeHeadline).font(.largeTitle.weight(.medium)).tracking(-0.8).multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Text("Keep your pieces together. Make looks you’ll wear.")
                            .font(AppTypography.body).foregroundStyle(AppTheme.secondary).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity)
                        .opacity(stage >= 2 ? 1 : 0).offset(y: stage >= 2 ? 0 : 14)
                }
                .padding(.horizontal, AppSpacing.screen).padding(.top, AppSpacing.small).padding(.bottom, AppSpacing.medium)
                .frame(minHeight: geometry.size.height)
            }.scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: AppSpacing.small) {
                Button {
                    if let previewDismiss { previewDismiss(false) } else { state.openStyle(source: .onboarding) }
                } label: { GlassActionLabel(title: "Start my closet", prominent: true) }.buttonStyle(.plain)
                    .accessibilityIdentifier("welcome.start")
                Text("Private on this iPhone. No account needed.").font(.footnote).foregroundStyle(AppTheme.secondary).padding(.top, AppSpacing.xSmall)
            }.padding(.horizontal, AppSpacing.screen).padding(.top, AppSpacing.small).padding(.bottom, AppSpacing.small)
                .opacity(stage >= 3 ? 1 : 0).offset(y: stage >= 3 ? 0 : 18)
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { settle(); tilt.stop(); return }
            if previewDismiss == nil { state.markWelcomeArrival() }
            if !reduceMotion { tilt.start() }
            guard !played, !reduceMotion else { settle(); return }
            played = true
            await play()
        }
        .onChange(of: reduceMotion) { _, reduced in if reduced { settle(); tilt.stop() } else { tilt.start() } }
        .onDisappear { settle(); tilt.stop() }
    }
    /// One orchestrated entrance: the mark surfaces, the closet assembles piece by piece, then the promise and the action rise,
    /// and a single highlight crosses the glass. Every arrival plays it; Reduce Motion shows the finished screen at once.
    private func play() async {
        var still = Transaction(); still.disablesAnimations = true
        withTransaction(still) { stage = 0; pose = .gathered; glint = -1 }
        do {
            await Task.yield()
            withAnimation(.smooth(duration: 0.8)) { stage = 1 }
            try await Task.sleep(for: .milliseconds(260))
            pose = .forming
            try await Task.sleep(for: .milliseconds(620))
            pose = .settled
            try await Task.sleep(for: .milliseconds(380))
            withAnimation(.smooth(duration: 0.6)) { stage = 2 }
            try await Task.sleep(for: .milliseconds(160))
            withAnimation(.smooth(duration: 0.6)) { stage = 3 }
            try await Task.sleep(for: .milliseconds(240))
            withAnimation(.easeInOut(duration: 1.2)) { glint = 1 }
        } catch { settle() }
    }
    /// The glass Q alone, small, like a maker's label rather than a hero. A soft highlight crosses it once on arrival.
    private var brand: some View {
        AQDMark(size: 64)
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(colors: [AppTheme.onMedia.opacity(0), AppTheme.onMedia.opacity(0.55), AppTheme.onMedia.opacity(0)],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: proxy.size.width * 0.45)
                        .rotationEffect(.degrees(20))
                        .offset(x: glint * proxy.size.width)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
                .mask { Image("BrandMark").resizable().scaledToFit() }
                .allowsHitTesting(false).accessibilityHidden(true)
            }
            .rotation3DEffect(.degrees(reduceMotion ? 0 : tilt.x * 12), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .rotation3DEffect(.degrees(reduceMotion ? 0 : -tilt.y * 10), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
            .opacity(stage >= 1 ? 1 : 0)
            .scaleEffect(stage >= 1 ? 1 : 0.9)
            .blur(radius: stage >= 1 ? 0 : 8)
            .frame(maxWidth: .infinity).accessibilityAddTraits(.isHeader)
    }
    private var welcomeHeadline: AttributedString {
        var text = AttributedString("More from what you already own.")
        text.foregroundColor = AppTheme.ink
        return text
    }
    private func settle() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { pose = .settled; stage = 3; glint = 1 }
    }
}
