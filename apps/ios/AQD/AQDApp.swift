import SwiftUI

@main
struct AQDApp: App {
    @State private var state = AppState(deferOpening: true)

    var body: some Scene {
        WindowGroup {
            AppRootView(state: state).appAppearance(testAppearance)
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
        return .system
    }

}

private struct AppRootView: View {
    @Bindable var state: AppState

    var body: some View {
        Group {
            if state.isOpening {
                AQDWordmark()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(AppTheme.ink).background(AppTheme.canvas)
                    .accessibilityIdentifier("entry.splash")
            } else if let error = state.openingError {
                ContentUnavailableView {
                    Label("Your closet couldn’t open", systemImage: "externaldrive.badge.exclamationmark")
                } description: { Text(error) } actions: {
                    Button("Retry") { state.openStore() }
                }
            } else if state.entry.page != .main {
                PrivateEntryView().environment(state)
            } else {
                NativeTabs(selection: $state.selection,
                           today: { rootContent(TodayView()) },
                           closet: { rootContent(ClosetView()) },
                           planner: { rootContent(LocalPlannerView()) },
                           profile: { rootContent(LocalProfileView()) },
                           agent: { close in rootContent(BaselineAgentView(close: close)) })
                    .ignoresSafeArea()
            }
        }
        .task {
            guard state.isOpening else { return }
            await Task.yield()
            state.openStore()
        }
        .tint(AppTheme.actionText)
        .alert("Saved data unavailable", isPresented: Binding(
            get: { state.collectionError != nil },
            set: { if !$0 { state.collectionError = nil } }
        )) {
            Button("OK", role: .cancel) { state.collectionError = nil }
        } message: {
            Text(state.collectionError ?? "Keep your existing app data for recovery.")
        }
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
            StyleEditorView(model: model)
        }
        .fullScreenCover(isPresented: Binding(get: { state.entry.tour != nil }, set: { presented in
            if !presented && state.entry.tour != nil { state.updateEntry { $0.tour = nil } }
        })) { PrivateTourView().environment(state) }
    }

    /// Keep incomplete cleanup visible and retryable on every native destination,
    /// including the full-screen Agent, without obscuring its navigation controls.
    private func rootContent(_ content: some View) -> AnyView {
        AnyView(VStack(spacing: 0) {
            content
            PhotoCleanupRecoveryView()
        }.environment(state))
    }
}

/// Native root builders run once. Observe cleanup in this view's body so later
/// Discard/Back/Open failures and successful retries update the held controllers.
struct PhotoCleanupRecoveryView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        if let error = state.photoCleanupError {
            VStack(alignment: .leading, spacing: 8) {
                Text(error).font(.subheadline).foregroundStyle(AppTheme.warning)
                Button { state.retryPhotoCleanup() } label: {
                    Text("Retry photo cleanup").frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16).background(AppTheme.canvas)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
