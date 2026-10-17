import SwiftUI

@main
struct AQDApp: App {
    @State private var state = AppState(deferOpening: true)

    var body: some Scene {
        WindowGroup {
            AppRootView(state: state) { store, coordinator, destination in
                state.detachForDataReplacement()
                state = AppState(store: store, dataRoot: coordinator.legacyRoot, coordinator: coordinator)
                state.selection = destination
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
    #if DEBUG
    @State private var welcomePreview = false
    @State private var tourAfterWelcome = false
    #endif

    var body: some View {
        Group {
            if state.isOpening {
                Color("LaunchCanvas").ignoresSafeArea()
                    .accessibilityLabel("Opening your closet").accessibilityIdentifier("entry.splash")
                    .transition(.opacity)
            } else if let error = state.openingError {
                CenteredPageContent {
                    AppEmptyState("Your closet couldn’t open", systemImage: "externaldrive.badge.exclamationmark", description: Text(error), fillsAvailableSpace: false)
                    PrimaryAction(title: "Retry") { state.openStore() }
                    SecondaryAction(title: "Choose an archive") { state.openRestore() }
                }
            } else if state.entry.page != .main {
                rootContent(PrivateEntryView())
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
        .onChange(of: scenePhase) { _, phase in if phase != .active { state.weatherClient?.suspend() } }
        .appConfirmation("Saved data unavailable", isPresented: Binding(
            get: { state.collectionError != nil },
            set: { if !$0 { state.collectionError = nil } }
        )) {
            Button("OK", role: .cancel) { state.collectionError = nil }
        } message: {
            Text(state.collectionError ?? "Keep your existing app data for recovery.")
        }
        .fullScreenCover(item: $state.restoreModel, onDismiss: {
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
        .sheet(item: $state.todayEditor) { model in TodayEditorView(model: model).environment(state) }
        .sheet(item: $state.fitEditor) { model in FitEditorView(model: model).environment(state) }
        .sheet(item: $state.identityEditor) { model in LocalIdentityEditorView(model: model).environment(state) }
        .sheet(item: $state.themeEditor, onDismiss: { state.reloadThemes(); state.reloadOutfits() }) { model in
            ThemeEditorView(model: model).environment(state)
        }
        .sheet(item: $state.wearEditor) { model in
            OutfitWearEditorView(model: model).environment(state)
        }
        .sheet(item: $state.planAuthoringEditor) { model in
            PlanAuthoringView(model: model).environment(state)
        }
        .sheet(item: $state.planEditor) { model in
            OutfitPlanEditorView(model: model).environment(state)
        }
        .sheet(item: $state.outfitEditor, onDismiss: { state.openPendingOutfitCapture() }) { model in
            OutfitEditorView(model: model).environment(state)
        }
        .sheet(item: $state.capture, onDismiss: { state.retryPhotoCleanup(); state.finishOutfitCaptureReturn() }) { model in
            PieceCaptureView(model: model).environment(state)
        }
        .fullScreenCover(item: $state.styleEditor, onDismiss: {
            if state.reloadEntryAfterStyle {
                state.reloadEntryAfterStyle = false
                state.reloadEntry()
            }
        }) { model in
            rootContent(StyleEditorView(model: model))
        }
        .fullScreenCover(isPresented: Binding(get: { state.entry.tour != nil }, set: { presented in
            if !presented && state.entry.tour != nil { state.updateEntry { $0.tour = nil } }
        })) { rootContent(PrivateTourView()) }
    }

    /// Root destinations own their content. Background recovery notices belong to Settings.
    private func rootContent(_ content: some View) -> AnyView {
        AnyView(content.environment(state))
    }
}
