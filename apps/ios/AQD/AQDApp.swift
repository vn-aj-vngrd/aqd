import SwiftUI

@main
struct AQDApp: App {
    @State private var state = AppState()

    var body: some Scene {
        WindowGroup {
            AppRootView(state: state)
        }
    }
}

private struct AppRootView: View {
    @Bindable var state: AppState

    var body: some View {
        Group {
            if let error = state.openingError {
                ContentUnavailableView {
                    Label("Your closet couldn’t open", systemImage: "externaldrive.badge.exclamationmark")
                } description: { Text(error) } actions: {
                    Button("Retry") { state.openStore() }
                }
            } else {
                NativeTabs(selection: $state.selection,
                           today: { rootContent(TodayView()) },
                           closet: { rootContent(ClosetView()) },
                           planner: { rootContent(PendingLocalView(title: "Planner", symbol: "calendar")) },
                           profile: { rootContent(PendingLocalView(title: "Profile", symbol: "person.crop.circle")) },
                           agent: { close in rootContent(BaselineAgentView(close: close)) })
                    .ignoresSafeArea()
            }
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
        .sheet(item: $state.capture) { model in
            PieceCaptureView(model: model).environment(state)
        }
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
