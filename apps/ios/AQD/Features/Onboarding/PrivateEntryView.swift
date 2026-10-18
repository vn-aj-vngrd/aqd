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
    @State private var previewArrived = false
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.section) {
                AQDWordmark().frame(maxWidth: .infinity, alignment: .center).padding(.top, AppSpacing.small)
                WelcomeWardrobe(pose: pose).padding(.horizontal, AppSpacing.small)
                VStack(spacing: AppSpacing.medium) {
                    Text(welcomeHeadline).font(.largeTitle.weight(.medium)).tracking(-0.8).multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("Keep your pieces together. Make looks you’ll wear.")
                        .font(AppTypography.body).foregroundStyle(AppTheme.secondary).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity)
            }.padding(.horizontal, AppSpacing.screen).padding(.vertical, AppSpacing.large)
        }.scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: AppSpacing.small) {
                Button {
                    if let previewDismiss { previewDismiss(false) } else { state.updateEntry { $0.page = .introduction } }
                } label: { GlassActionLabel(title: "Start my closet", prominent: true) }.buttonStyle(.plain)
                Button {
                    if let previewDismiss { previewDismiss(true) } else { state.beginTour(from: .welcome) }
                } label: { GlassActionLabel(title: "Take a quick tour") }.buttonStyle(.plain)
                Text("No account needed.").font(.footnote).foregroundStyle(AppTheme.secondary).padding(.top, AppSpacing.xSmall)
            }.padding(.horizontal, AppSpacing.screen).padding(.top, AppSpacing.small).padding(.bottom, AppSpacing.small)
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { settle(); return }
            let firstArrival: Bool
            if previewDismiss != nil {
                firstArrival = !previewArrived
                previewArrived = true
            } else { firstArrival = state.markWelcomeArrival() }
            guard firstArrival, !reduceMotion else { settle(); return }
            pose = .gathered
            do {
                await Task.yield()
                try Task.checkCancellation()
                guard !reduceMotion else { settle(); return }
                withAnimation(.spring(duration: 0.52, bounce: 0.12)) { pose = .forming }
                try await Task.sleep(for: .milliseconds(520))
                try Task.checkCancellation()
                withAnimation(.spring(duration: 0.68, bounce: 0.08)) { pose = .settled }
                try await Task.sleep(for: .milliseconds(680))
            } catch { settle() }
        }
        .onChange(of: reduceMotion) { _, reduced in if reduced { settle() } }
        .onDisappear { settle() }
    }
    private var welcomeHeadline: AttributedString {
        var text = AttributedString("More from what you already own.")
        text.foregroundColor = AppTheme.ink
        if let range = text.range(of: "already own.") { text[range].foregroundColor = AppTheme.ink }
        return text
    }
    private func settle() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { pose = .settled }
    }
}
