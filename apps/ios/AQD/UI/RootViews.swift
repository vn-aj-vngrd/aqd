import AQDCore
import SwiftUI

struct TodayView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.subheadline).foregroundStyle(AppTheme.secondary)
                    if let error = state.todayError {
                        SemanticFeedback(role: .danger, message: error)
                        Button("Retry Today") { state.reloadToday() }.frame(minHeight: 44)
                    }
                    if let configuration = state.today {
                        if !configuration.instances.contains(where: { $0.kind == .weatherContext }) {
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Before you head out").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                                    Text("Weather").font(AppTypography.detailTitle)
                                }
                                TodayWeatherSummary()
                            }
                            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.group))
                        }
                        ForEach(configuration.instances) { instance in
                            TimelineView(.periodic(from: .now, by: 60)) { _ in TodayCard(instance: instance) }
                        }
                    }

                }.padding(20)
            }
            .background(AppTheme.canvas)
            .navigationTitle("Today")
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button { state.openTodayEditor() } label: { Image(systemName: "square.grid.2x2").font(.system(size: 17, weight: .regular)) }.accessibilityLabel("Customize Today").tint(AppTheme.secondary)
            } }
            .safeAreaInset(edge: .bottom) {
                if state.todayUndoAvailable { Button("Undo layout change") { state.undoTodayLayout() }.frame(minHeight: 44).padding(.horizontal, 20).background(AppTheme.canvas) }
            }
            .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
            .onAppear { state.reloadToday(); state.reloadPlanEntries(); state.reloadWear(); state.reloadOutfits(); state.reloadPieces(); state.reloadFits(); state.reloadThemes() }
        }.tint(AppTheme.ink)
    }

}

struct PendingLocalView: View {
    let title: String
    let symbol: String
    var body: some View {
        NavigationStack {
            AppEmptyState("\(title) is being implemented", systemImage: symbol,
                                   description: Text("This source baseline is not complete V1. Your saved pieces remain private and usable in Closet."))
                .background(AppTheme.canvas)
                .navigationTitle(title)
        }
    }
}
