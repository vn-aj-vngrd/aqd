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
                           today: { AnyView(TodayView().environment(state)) },
                           closet: { AnyView(ClosetView().environment(state)) },
                           planner: { AnyView(PendingLocalView(title: "Planner", symbol: "calendar").environment(state)) },
                           profile: { AnyView(PendingLocalView(title: "Profile", symbol: "person.crop.circle").environment(state)) },
                           agent: { close in AnyView(BaselineAgentView(close: close).environment(state)) })
                    .ignoresSafeArea()
            }
        }
        .tint(AppTheme.actionText)
        .sheet(item: $state.capture) { model in
            PieceCaptureView(model: model).environment(state)
        }
    }
}
