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
    private var calendarShown: Bool {
        get { periodStart == nil && state.wearHistoryCalendar }
        nonmutating set { state.wearHistoryCalendar = newValue }
    }
    var body: some View {
        @Bindable var state = state
        VStack(alignment: .leading, spacing: 16) {
            if let start = periodStart, let end = periodEnd {
                Text("\(start.displayDate) – \(end.displayDate)").font(AppTypography.supporting)
                    .foregroundStyle(AppTheme.secondary).padding(.horizontal, 20)
            }
            if calendarShown {
                PlannerCalendarHeader(day: $state.wearHistoryDay, mode: $state.wearHistoryMode,
                    counts: Dictionary(grouping: records, by: { $0.day.key }).mapValues(\.count), countLabel: "recorded wears")
                    .padding(.horizontal, 20)
                Text(state.wearHistoryDay.displayDate).font(AppTypography.section).padding(.horizontal, 20)
            }
            let shown = records.filter { !calendarShown || $0.day.key == state.wearHistoryDay.key }
            if let error = state.wearError {
                SemanticFeedback(role: .danger, message: error).padding(20)
                Button("Retry history") { state.reloadWear() }.frame(minHeight: 44)
            } else if shown.isEmpty {
                EmptyStatePage(title: records.isEmpty ? "Your history starts here" : "No wear recorded for this day",
                               systemImage: "clock", description: Text("Record what you actually wore. Plans never count as wear.")) {
                    PrimaryAction(title: "Record a look") { state.openWear(day: recordingDay) }
                    SecondaryAction(title: "Open Planner") { state.plannerDay = recordingDay; state.selection = 2 }
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(shown) { record in
                            NavigationLink { LocalWearDetailView(id: record.id) } label: { WearAgendaRow(record: record) }.buttonStyle(.plain)
                        }
                        if !calendarShown { PrimaryAction(title: "Record a look") { state.openWear(day: recordingDay) } }
                    }.padding(20)
                }
            }
        }.background(AppTheme.canvas).navigationTitle(calendarShown ? "Wear calendar" : "Wear history")
            .navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink).onAppear { state.reloadWear() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if periodStart == nil { Button(calendarShown ? "Recent" : "Calendar") { calendarShown.toggle() }.frame(minHeight: 44) }
                        Button { state.openWear(day: recordingDay) } label: { Label("Record wear", systemImage: "plus") }.frame(minWidth: 44, minHeight: 44)
                    }
                }
            }
    }
    private var recordingDay: LocalPlanDay { calendarShown ? state.wearHistoryDay : LocalPlanDay() }
}

struct WearAgendaRow: View {
    let record: OutfitWearRecord
    var body: some View {
        HStack(spacing: 12) {
            OutfitComposition(pieceIDs: record.pieces.map(\.id), pieceHeight: 56, limit: 2).frame(width: 64, height: 80).clipped()
            VStack(alignment: .leading, spacing: 4) {
                Text(record.pieces.map(\.displayName).joined(separator: ", ")).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                Text("\(record.day.key) · \(record.pieces.count) pieces · Recorded").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.forward").font(AppTypography.disclosure).foregroundStyle(AppTheme.secondary).frame(width: 22).accessibilityHidden(true)
        }.padding(14).frame(minHeight: 108).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}
