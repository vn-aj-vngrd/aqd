import SwiftUI

@main
struct AQDApp: App {
    @State private var state = AppState(deferOpening: true)

    init() {
        #if DEBUG
        Self.clearStaleLaunchSnapshots()
        #endif
    }

    #if DEBUG
    /// iOS keeps launch and resume snapshots per build in the app's Library. After a Debug reinstall they can still show the previous
    /// build's first frame, so each new build clears them once; the system rebuilds them the next time the app goes to the background.
    private static func clearStaleLaunchSnapshots() {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let key = "debug.clearedLaunchSnapshotsFor"
        guard UserDefaults.standard.string(forKey: key) != build,
              let library = try? FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else { return }
        try? FileManager.default.removeItem(at: library.appendingPathComponent("SplashBoard", isDirectory: true))
        UserDefaults.standard.set(build, forKey: key)
    }
    #endif

    var body: some Scene {
        WindowGroup {
            AppRootView(state: state) { store, coordinator, destination in
                state.detachForDataReplacement()
                state = AppState(store: store, dataRoot: coordinator.legacyRoot, coordinator: coordinator)
                state.selection = destination
                state.showingSplash = false
            }.appAppearance(testAppearance)
        }
    }
    private var testAppearance: AppAppearance {
        #if DEBUG
        let process = ProcessInfo.processInfo
        if process.arguments.contains("--aqd-ui-testing"),
           UUID(uuidString: process.environment["AQD_TEST_STORE_ID"] ?? "") != nil {
            return AppAppearance(rawValue: process.environment["AQD_TEST_APPEARANCE"] ?? "") ?? .system
        }
        #endif
        return state.appearance
    }
}

private struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var state: AppState
    let onInstall: (PieceStore, LocalDataCoordinator, Int) -> Void
    @State private var pendingInstallation: (PieceStore, LocalDataCoordinator, Int)?
    @State private var splashShown = true
    @State private var splashExiting = false
    #if DEBUG
    @State private var welcomePreview = false
    @State private var tourAfterWelcome = false
    @State private var agentEval: AgentClosetEvalRunner?
    #endif

    /// Shows the glass mark for about a second, waits for the closet to open, then lifts the mark away and fades the app in.
    /// UI tests and Reduce Motion skip the showcase and only cross-fade.
    private func runSplash() async {
        let quick = reduceMotion || ProcessInfo.processInfo.arguments.contains("--aqd-ui-testing")
        do {
            try await Task.sleep(for: .milliseconds(quick ? 0 : 1150))
            while state.isOpening { try await Task.sleep(for: .milliseconds(40)) }
        } catch { return }
        state.showingSplash = false
        if quick { withAnimation(.easeOut(duration: 0.25)) { splashShown = false }; return }
        withAnimation(.easeIn(duration: 0.4)) { splashExiting = true }
        do { try await Task.sleep(for: .milliseconds(160)) } catch { return }
        withAnimation(.easeOut(duration: 0.45)) { splashShown = false }
    }

    var body: some View {
        Group {
            if state.isOpening {
                Color("LaunchCanvas").ignoresSafeArea()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Opening your closet").accessibilityIdentifier("entry.splash")
                    .transition(.opacity)
            } else if let error = state.openingError {
                CenteredPageContent {
                    AppEmptyState("Your closet couldn’t open", systemImage: "externaldrive.badge.exclamationmark", description: Text(error), fillsAvailableSpace: false)
                    PrimaryAction(title: "Retry") { state.openStore() }
                    SecondaryAction(title: "Choose an archive") { state.openRestore() }
                }
            } else if state.entry.page != .main {
                // The first-run tour sits in the root, not a cover, so leaving the preferences sheet lands directly on it.
                if state.entry.tour != nil { rootContent(PrivateTourView()) } else { rootContent(PrivateEntryView()) }
            } else {
                NativeTabs(selection: $state.selection,
                           today: { rootContent(TodayView()) },
                           closet: { rootContent(ClosetView()) },
                           planner: { rootContent(LocalPlannerView()) },
                           profile: { rootContent(LocalProfileView()) },
                           agent: { close in rootContent(LocalAgentView(close: close)) }, agentLaunchID: state.agentLaunchID, isTabBarHidden: state.isRootTabBarHidden)
                    .id(ObjectIdentifier(state)).ignoresSafeArea()
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: state.isOpening)
        .task(id: ObjectIdentifier(state)) {
            if state.isOpening { await Task.yield(); state.openStore() }
            #if DEBUG
            let process = ProcessInfo.processInfo
            if process.arguments.contains("--aqd-preview-welcome"), !process.arguments.contains("--aqd-ui-testing") {
                welcomePreview = true
            }
            // UI tests only: fill the UUID-isolated test store with the bundled preview closet.
            if process.arguments.contains("--aqd-ui-testing"), process.environment["AQD_TEST_SEED_SAMPLES"] == "1", let store = state.store {
                let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                if (try? await PreviewSampleContent.populate(store: store, outputDirectory: directory)) != nil {
                    state.reloadPieces(); state.reloadOutfits(); state.reloadThemes(); state.reloadPlanEntries()
                }
            }
            if process.arguments.contains("--aqd-add-all-widgets"), !process.arguments.contains("--aqd-ui-testing"), let store = state.store {
                state.isOpening = true
                do {
                    let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    _ = try await PreviewSampleContent.addAllWidgets(store: store, outputDirectory: directory)
                    state.reloadToday(); state.reloadThemes(); state.reloadFits(); state.selection = 0
                } catch {
                    if let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                        try? LocalArchiveIO.write(Data(String(reflecting: error).utf8), to: directory.appendingPathComponent("AQD-all-widgets-error.txt"))
                    }
                    state.todayError = "Widgets could not all be added. Your existing layout and any draft are retained; a local backup is kept if saving began."
                }
                state.isOpening = false
            }
            if process.arguments.contains("--aqd-add-preview-samples"), !process.arguments.contains("--aqd-ui-testing"), let store = state.store {
                state.isOpening = true
                do {
                    let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    _ = try await PreviewSampleContent.populate(store: store, outputDirectory: directory)
                    state.reloadPieces(); state.reloadOutfits(); state.reloadThemes(); state.reloadPlanEntries(); state.reloadFits(); state.reloadToday()
                    state.selection = 1; state.closetScope = "Pieces"
                } catch {
                    if let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                        try? LocalArchiveIO.write(Data(String(reflecting: error).utf8), to: directory.appendingPathComponent("AQD-preview-samples-error.txt"))
                    }
                    state.collectionError = "Sample setup could not finish. Your existing records have not been replaced. A local backup is retained if setup reached that step."
                }
                state.isOpening = false
            }
            if process.arguments.contains("--aqd-seed-week-of-use"), !process.arguments.contains("--aqd-ui-testing"), let store = state.store {
                state.isOpening = true
                do {
                    let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    _ = try await RealisticClosetSeed.run(store: store, outputDirectory: directory)
                    state.reloadPieces(); state.reloadOutfits(); state.reloadThemes(); state.reloadPlanEntries(); state.reloadFits(); state.reloadWear(); state.reloadToday()
                    state.selection = 1; state.closetScope = "Pieces"
                } catch {
                    if let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                        try? LocalArchiveIO.write(Data(String(reflecting: error).utf8), to: directory.appendingPathComponent("AQD-week-seed-error.txt"))
                    }
                    state.collectionError = "The week of sample content could not finish. A backup was made first and your other records are untouched."
                }
                state.isOpening = false
            }
            if process.arguments.contains("--aqd-agent-eval"), !process.arguments.contains("--aqd-ui-testing"), agentEval == nil {
                let flag = process.arguments.firstIndex(of: "--aqd-agent-eval-label").map { $0 + 1 }
                let label = flag.flatMap { process.arguments.indices.contains($0) ? process.arguments[$0] : nil } ?? "run"
                let suite = process.arguments.firstIndex(of: "--aqd-agent-eval-suite").map { $0 + 1 }.flatMap { process.arguments.indices.contains($0) ? process.arguments[$0] : nil } ?? "golden"
                let runner = AgentClosetEvalRunner(suite: suite); agentEval = runner
                if let source = process.arguments.firstIndex(of: "--aqd-agent-eval-rescore").map({ $0 + 1 }).flatMap({ process.arguments.indices.contains($0) ? process.arguments[$0] : nil }) {
                    await runner.rescore(label: label, from: source)
                } else { await runner.run(label: label) }
            }
            if process.arguments.contains("--aqd-refresh-transparent-samples"), !process.arguments.contains("--aqd-ui-testing"), let store = state.store {
                state.isOpening = true
                do {
                    let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    _ = try await PreviewSampleContent.refreshTransparentPhotos(store: store, outputDirectory: directory)
                    state.reloadPieces(); state.reloadOutfits(); state.reloadFits(); state.selection = 1
                } catch {
                    if let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                        try? LocalArchiveIO.write(Data(String(reflecting: error).utf8), to: directory.appendingPathComponent("AQD-transparent-samples-error.txt"))
                    }
                    state.collectionError = "Sample photos could not be refreshed. Your records are retained; a local backup is kept if staging began."
                }
                state.isOpening = false
            }
            if process.arguments.contains("--aqd-refresh-sample-contexts"), !process.arguments.contains("--aqd-ui-testing"), let store = state.store {
                state.isOpening = true
                do {
                    let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    _ = try await PreviewSampleContent.refreshContexts(store: store, outputDirectory: directory)
                    state.reloadPlanEntries(); state.reloadFits(); state.reloadToday(); state.selection = 2
                } catch {
                    if let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                        try? LocalArchiveIO.write(Data(String(reflecting: error).utf8), to: directory.appendingPathComponent("AQD-sample-contexts-error.txt"))
                    }
                    state.collectionError = "Sample descriptions could not finish refreshing. Your records are retained; a local backup is kept if updates began."
                }
                state.isOpening = false
            }

            #endif
            for _ in 0..<10 {
                if state.dataCoordinator?.isWaitingForPreviousStore != true && !LocalArchiveService.hasInFlightWork { break }
                try? await Task.sleep(for: .milliseconds(30))
            }
            state.retryLocalDataCleanup()
        }
        #if DEBUG
        .fullScreenCover(isPresented: Binding(get: { agentEval != nil }, set: { if !$0 { agentEval = nil } })) {
            if let agentEval { AgentClosetEvalView(runner: agentEval) }
        }
        .fullScreenCover(isPresented: $welcomePreview, onDismiss: {
            if tourAfterWelcome {
                tourAfterWelcome = false
                state.beginTour(from: state.entry.page == .main ? .settings : state.entry.page == .welcome ? .welcome : state.entry.page == .introduction ? .introduction : .preview)
            }
        }) {
            WelcomeView(previewDismiss: { tour in tourAfterWelcome = tour; welcomePreview = false })
                .environment(state).background(AppTheme.canvas)
        }
        #endif
        .tint(AppTheme.ink)
        .overlay {
            if splashShown { LaunchSplash(exiting: splashExiting).transition(.opacity).accessibilityHidden(true) }
        }
        .task { await runSplash() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { state.weatherClient?.suspend() } }
        .appConfirmation("Saved data unavailable", isPresented: Binding(
            get: { state.collectionError != nil },
            set: { if !$0 { state.collectionError = nil } }
        )) {
            Button("OK", role: .cancel) { state.collectionError = nil }
        } message: {
            Text(state.collectionError ?? "Keep your existing app data for recovery.")
        }
        .onChange(of: ObjectIdentifier(state), initial: true) { state.installReplacement = onInstall }
        .fullScreenCover(item: Binding(get: { state.restoreInSettings ? nil : state.restoreModel }, set: { state.restoreModel = $0 }), onDismiss: {
            if let pending = pendingInstallation { pendingInstallation = nil; onInstall(pending.0, pending.1, pending.2) }
        }) { model in
            if model.kind == .erase {
                LocalEraseView(model: model, onCancel: { state.restoreModel = nil }, onInstall: { store, coordinator, destination in
                    pendingInstallation = (store, coordinator, destination); state.restoreModel = nil
                }).environment(state)
            } else {
                LocalRestoreView(model: model, onCancel: { state.restoreModel = nil }, onInstall: { store, coordinator, destination in
                    pendingInstallation = (store, coordinator, destination); state.restoreModel = nil
                })
            }
        }
        .sheet(item: $state.todayEditor) { model in TodayEditorView(model: model).environment(state).toggleStyle(AppToggleStyle()) }
        .sheet(item: $state.fitEditor, onDismiss: { state.openPendingFitWear() }) { model in FitEditorView(model: model).environment(state).toggleStyle(AppToggleStyle()) }
        .sheet(item: $state.identityEditor) { model in LocalIdentityEditorView(model: model).environment(state).toggleStyle(AppToggleStyle()) }
        .sheet(item: $state.themeEditor, onDismiss: { state.reloadThemes(); state.reloadOutfits() }) { model in
            ThemeEditorView(model: model).environment(state).toggleStyle(AppToggleStyle())
        }
        .sheet(item: $state.wearEditor) { model in
            OutfitWearEditorView(model: model).environment(state).toggleStyle(AppToggleStyle())
        }
        .sheet(item: $state.planAuthoringEditor) { model in
            PlanAuthoringView(model: model).environment(state).toggleStyle(AppToggleStyle())
        }
        .sheet(item: $state.planEditor) { model in
            OutfitPlanEditorView(model: model).environment(state).toggleStyle(AppToggleStyle())
        }
        .sheet(item: $state.outfitEditor, onDismiss: { state.openPendingOutfitCapture() }) { model in
            OutfitEditorView(model: model).environment(state).toggleStyle(AppToggleStyle())
        }
        .sheet(item: $state.capture, onDismiss: { state.retryPhotoCleanup(); state.finishOutfitCaptureReturn() }) { model in
            PieceCaptureView(model: model).environment(state).toggleStyle(AppToggleStyle())
        }
        .fullScreenCover(item: $state.styleEditor) { model in
            rootContent(StyleEditorView(model: model))
        }
        .fullScreenCover(isPresented: Binding(get: { state.entry.tour != nil && state.entry.page == .main }, set: { presented in
            if !presented && state.entry.tour != nil { state.updateEntry { $0.tour = nil } }
        })) { rootContent(PrivateTourView()) }
    }

    /// Root destinations own their content. Background recovery notices belong to Settings.
    private func rootContent(_ content: some View) -> AnyView {
        // Each tab is its own UIKit-hosted tree, so app-wide styles set on the window root must be repeated here.
        AnyView(content.environment(state).toggleStyle(AppToggleStyle()))
    }
}
