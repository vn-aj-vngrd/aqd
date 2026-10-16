import AQDCore
import SwiftUI

struct TodayView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(Date.now, format: .dateTime.weekday(.abbreviated).day())
                        .font(.subheadline).foregroundStyle(AppTheme.secondary)
                    if let error = state.todayError {
                        SemanticFeedback(role: .danger, message: error)
                        Button("Retry Today") { state.reloadToday() }.frame(minHeight: 44)
                    }
                    if let configuration = state.today {
                        ForEach(configuration.instances) { instance in
                            TimelineView(.periodic(from: .now, by: 60)) { _ in TodayCard(instance: instance) }
                        }
                    }

                }.padding(20)
            }
            .background(AppTheme.canvas)
            .navigationTitle("Today")
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button { state.openTodayEditor() } label: { Image(systemName: "slider.horizontal.3").font(.system(size: 22)).frame(width: 44, height: 44) }.accessibilityLabel("Customize Today").tint(AppTheme.secondary)
            } }
            .safeAreaInset(edge: .bottom) {
                if state.todayUndoAvailable { Button("Undo layout change") { state.undoTodayLayout() }.frame(minHeight: 44).padding(.horizontal, 20).background(AppTheme.canvas) }
            }
            .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
            .onAppear { state.reloadToday(); state.reloadPlanEntries(); state.reloadWear(); state.reloadOutfits(); state.reloadPieces(); state.reloadFits(); state.reloadThemes() }
        }.tint(AppTheme.actionText)
    }

}

struct PendingLocalView: View {
    let title: String
    let symbol: String
    var body: some View {
        NavigationStack {
            ContentUnavailableView("\(title) is being implemented", systemImage: symbol,
                                   description: Text("This source baseline is not complete V1. Your saved pieces remain private and usable in Closet."))
                .background(AppTheme.canvas)
                .navigationTitle(title)
        }
    }
}

struct BaselineAgentView: View {
    @Environment(AppState.self) private var state
    let close: () -> Void
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("Local Agent conversations aren’t implemented yet.").font(AppTypography.section)
                Text("This baseline doesn’t send chat or wardrobe data anywhere. You can still add and manage pieces manually.")
                    .foregroundStyle(AppTheme.secondary)
                SecondaryAction(title: "Open Closet") { state.selection = 1; close() }
                Spacer()
            }.padding(20).background(AppTheme.canvas)
                .navigationTitle("Agent").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Back", action: close) } }
        }.tint(AppTheme.actionText)
    }
}
