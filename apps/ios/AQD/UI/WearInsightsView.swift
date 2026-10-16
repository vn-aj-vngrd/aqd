import AQDCore
import SwiftUI

struct LocalWearInsightsView: View {
    @Environment(AppState.self) private var state
    @State private var month: LocalPlanDay
    init(initialMonth: LocalPlanDay = LocalPlanDay()) { _month = State(initialValue: initialMonth) }
    @State private var summary: WearPeriodSummary?
    @State private var error: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DatePicker("Period", selection: Binding(get: { (try? month.date()) ?? Date() }, set: { month = LocalPlanDay(date: $0); reload() }), displayedComponents: .date)
                if let error { SemanticFeedback(role: .danger, message: error); Button("Retry insights", action: reload).frame(minHeight: 44) }
                else if let summary {
                    Text("\(summary.start.key) – \(summary.end.key)").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    if summary.occasions == 0 || summary.activeCount == 0 {
                        ContentUnavailableView("Not enough recorded history", systemImage: "chart.bar", description: Text("Record a wear to see which pieces you reach for. Earlier estimates are excluded from this period."))
                        PrimaryAction(title: "Record a look") { state.openWear() }
                        SecondaryAction(title: "Open Closet") { state.selection = 1 }
                    }
                    if summary.occasions > 0 {
                        Text("\(summary.occasions) wear occasions · \(summary.itemOccurrences) individual item wears").font(AppTypography.body)
                    }
                    if let utilization = summary.utilization {
                        Text("Closet in use").font(AppTypography.section)
                        VStack(alignment: .leading, spacing: 12) {
                            Text(utilization, format: .percent.precision(.fractionLength(0))).font(.largeTitle)
                            Text("\(summary.usedActiveCount) of \(summary.activeCount) active pieces recorded this month")
                            ProgressView(value: utilization).tint(AppTheme.actionText)
                        }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                        Text("Most worn this month").font(AppTypography.section)
                        ForEach(ranked(summary, descending: true).prefix(5)) { piece in periodRow(piece, summary: summary) }
                        Text("Least worn this month").font(AppTypography.section)
                        ForEach(ranked(summary, descending: false).prefix(5)) { piece in periodRow(piece, summary: summary) }
                    }
                    Text("Only dated AQD records count in this period. Plans and earlier estimates are excluded. Archived and deleted pieces do not enter the active-closet denominator.")
                        .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    NavigationLink("View source history") { LocalWearHistoryView(periodStart: summary.start, periodEnd: summary.end) }.frame(minHeight: 44)
                    if !state.pieces.isEmpty {
                        Text("All-time totals").font(AppTypography.section)
                        Text("Includes separately labelled earlier estimates. Estimates have no recorded date.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        ForEach(state.pieces.sorted { a, b in
                            let first = PieceWearSummary(piece: a, records: state.wearRecords).total
                            let second = PieceWearSummary(piece: b, records: state.wearRecords).total
                            return first == second ? a.id.uuidString < b.id.uuidString : first > second
                        }.prefix(5)) { piece in
                            let total = PieceWearSummary(piece: piece, records: state.wearRecords)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(piece.name).font(AppTypography.body)
                                Text("\(total.total) total · \(total.recorded) recorded · \(total.priorEstimate ?? 0) estimated earlier")
                                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                            }
                        }
                    }
                }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Wear insights").navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink)
            .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
            .onAppear(perform: reload).onChange(of: state.wearRecords) { _, _ in reload() }
    }
    private func reload() {
        state.reloadWear(); state.reloadPieces()
        guard state.wearError == nil, state.collectionError == nil else { error = "Your history or Closet could not be read. Retry before using these statistics."; summary = nil; return }
        do { summary = try WearPeriodSummary(month: month, pieces: state.pieces, records: state.wearRecords); error = nil }
        catch { self.error = "This period could not be calculated."; summary = nil }
    }
    private func ranked(_ summary: WearPeriodSummary, descending: Bool) -> [WardrobePiece] {
        state.pieces.sorted { a, b in
            let first = summary.counts[a.id, default: 0], second = summary.counts[b.id, default: 0]
            return first == second ? a.id.uuidString < b.id.uuidString : descending ? first > second : first < second
        }
    }
    private func periodRow(_ piece: WardrobePiece, summary: WearPeriodSummary) -> some View {
        NavigationLink(value: ClosetRoute.piece(piece.id)) {
            HStack(spacing: 12) {
                Text(piece.name).font(AppTypography.body).foregroundStyle(AppTheme.ink).frame(maxWidth: .infinity, alignment: .leading)
                Text("\(summary.counts[piece.id, default: 0]) recorded").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }.padding(14).frame(minHeight: 54).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
    }
}
