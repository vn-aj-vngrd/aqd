import AQDCore
import SwiftUI

struct TodayView: View {
    @Environment(AppState.self) private var state
#if DEBUG
    @State private var previewsWidgets = ProcessInfo.processInfo.arguments.contains("--aqd-preview-all-widgets")
#endif
    private var previewing: Bool {
#if DEBUG
        previewsWidgets
#else
        false
#endif
    }
    private var visibleInstances: [TodayWidgetInstance]? {
#if DEBUG
        if previewsWidgets, let base = state.today { return PreviewSampleContent.widgetPreview(state: state, base: base) }
#endif
        return state.today?.instances
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("Today").font(AppTypography.rootTitle).accessibilityAddTraits(.isHeader)
                        Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                            .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }
                    if let error = state.todayError {
                        SemanticFeedback(role: .danger, message: error)
                        Button("Retry Today") { state.reloadToday() }.frame(minHeight: 44)
                    }
#if DEBUG
                    if previewsWidgets {
                        HStack {
                            Text("All widgets · Preview").font(AppTypography.supporting)
                            Spacer()
                            Button("Done") { previewsWidgets = false }.frame(minHeight: 44)
                        }
                        Text("Your saved Home layout is unchanged.").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    }
#endif
                    if let instances = visibleInstances {
                        if !instances.contains(where: { $0.kind == .weatherContext }) {
                            TodayWeatherNotice()
                        }
                        ForEach(instances) { instance in
                            TimelineView(.periodic(from: .now, by: 60)) { _ in TodayCard(instance: instance, isPreview: previewing) }
                        }
                    }

                }.padding(.horizontal, AppSpacing.screen)
                    .padding(.top, AppSpacing.large).padding(.bottom, AppSpacing.screen)
            }
            .background(AppTheme.canvas)
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("Record wear", systemImage: "tshirt") { state.openWear() }
                        .accessibilityIdentifier("today.recordWear")
                    Button("Add fit", systemImage: "photo") {
                        state.openFit()
                        if state.fitEditor == nil, let error = state.fitError { state.collectionError = error }
                    }
                    Button("Plan an outfit", systemImage: "calendar") { state.openPlan(day: LocalPlanDay()) }
                    Button("Build an outfit", systemImage: "square.stack") { state.buildOutfit() }
                } label: { Label("Add to Today", systemImage: "plus") }
                    .accessibilityIdentifier("today.add").tint(AppTheme.ink)
            } }
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button { state.openTodayEditor() } label: { Image(systemName: "square.grid.2x2").font(.system(size: 17, weight: .regular)) }.accessibilityLabel("Customize Today").tint(AppTheme.ink)
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
