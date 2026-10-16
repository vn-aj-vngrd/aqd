import AQDCore
import SwiftUI

struct LocalWearHistoryView: View {
    var pieceID: UUID? = nil
    var periodStart: LocalPlanDay? = nil
    var periodEnd: LocalPlanDay? = nil
    @Environment(AppState.self) private var state
    private var records: [OutfitWearRecord] {
        state.wearRecords.filter { record in
            (pieceID.map { id in record.pieces.contains { $0.id == id } } ?? true)
            && (periodStart.map { record.day.key >= $0.key } ?? true)
            && (periodEnd.map { record.day.key <= $0.key } ?? true)
        }
    }
    var body: some View {
        @Bindable var state = state
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let start = periodStart, let end = periodEnd {
                    Text("\(start.key) – \(end.key)").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }
                if let error = state.wearError {
                    SemanticFeedback(role: .danger, message: error)
                    Button("Retry history") { state.reloadWear() }.frame(minHeight: 44)
                } else {
                    if state.wearHistoryCalendar {
                        PlannerCalendarView(day: $state.wearHistoryDay, mode: $state.wearHistoryMode,
                            counts: Dictionary(grouping: records, by: { $0.day.key }).mapValues(\.count))
                        Text(state.wearHistoryDay.key).font(AppTypography.section)
                    }
                    let shown = records.filter { !state.wearHistoryCalendar || $0.day.key == state.wearHistoryDay.key }
                    if shown.isEmpty {
                        ContentUnavailableView(records.isEmpty ? "Your history starts here" : "No wear recorded for this day", systemImage: "clock",
                            description: Text("Record what you actually wore. Plans never count as wear."))
                        PrimaryAction(title: "Record a look") { state.openWear(day: recordingDay) }
                        SecondaryAction(title: "Open Planner") { state.plannerDay = recordingDay; state.selection = 2 }
                    }
                    ForEach(shown) { record in
                        NavigationLink { LocalWearDetailView(id: record.id) } label: { WearAgendaRow(record: record) }.buttonStyle(.plain)
                    }
                    if !state.wearHistoryCalendar && !shown.isEmpty {
                        PrimaryAction(title: "Record a look") { state.openWear(day: recordingDay) }
                    }
                }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle(state.wearHistoryCalendar ? "Wear calendar" : "Wear history")
            .navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink).onAppear { state.reloadWear() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button(state.wearHistoryCalendar ? "Recent" : "Calendar") { state.wearHistoryCalendar.toggle() }.frame(minHeight: 44)
                        Button { state.openWear(day: recordingDay) } label: { Label("Record wear", systemImage: "plus") }.frame(minWidth: 44, minHeight: 44)
                    }
                }
            }
    }
    private var recordingDay: LocalPlanDay { state.wearHistoryCalendar ? state.wearHistoryDay : LocalPlanDay() }
}

struct WearAgendaRow: View {
    let record: OutfitWearRecord
    var body: some View {
        HStack(spacing: 12) {
            OutfitComposition(pieceIDs: record.pieces.map(\.id), pieceHeight: 56, limit: 2).frame(width: 64, height: 80).clipped()
            VStack(alignment: .leading, spacing: 4) {
                Text(record.pieces.map(\.name).joined(separator: ", ")).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                Text("\(record.day.key) · \(record.pieces.count) pieces · Recorded").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.forward").font(.system(size: 22)).foregroundStyle(AppTheme.secondary).frame(width: 22).accessibilityHidden(true)
        }.padding(14).frame(minHeight: 108).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}
