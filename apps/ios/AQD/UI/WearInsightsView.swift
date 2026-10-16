import AQDCore
import SwiftUI

struct LocalWearInsightsView: View {
    @Environment(AppState.self) private var state
    @State private var month: LocalPlanDay
    init(initialMonth: LocalPlanDay = LocalPlanDay()) { _month = State(initialValue: initialMonth) }
    @State private var summary: WearPeriodSummary?
    @State private var error: String?
    var body: some View {
        List {
            Section {
                HStack(spacing: 8) {
                    Button { changeMonth(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                        .accessibilityLabel("Previous month")
                    Text(monthTitle).font(AppTypography.fieldLabel).frame(maxWidth: .infinity)
                    Button { changeMonth(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                        .accessibilityLabel("Next month")
                }.buttonStyle(.borderless).listRowBackground(AppTheme.surface)
            }
            if let error {
                Section {
                    SemanticFeedback(role: .danger, message: error)
                    Button("Retry insights", action: reload)
                }.listRowBackground(AppTheme.surface)
            } else if let summary {
                if summary.occasions == 0 {
                    Section {
                        AppEmptyState("No wear recorded this month", systemImage: "chart.bar",
                                      description: Text("Your recorded wear will appear here."), fillsAvailableSpace: false)
                            .frame(maxWidth: .infinity).padding(.vertical, 24)
                    }.listRowBackground(AppTheme.surface)
                } else {
                    Section("This month") {
                        HStack(spacing: 20) {
                            metric("Wear occasions", value: summary.occasions)
                            metric("Item wears", value: summary.itemOccurrences)
                        }.padding(.vertical, 8)
                        if let utilization = summary.utilization {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Closet in use")
                                    Spacer()
                                    Text(utilization, format: .percent.precision(.fractionLength(0))).font(AppTypography.fieldLabel)
                                }
                                ProgressView(value: utilization).tint(AppTheme.actionText)
                                Text("\(summary.usedActiveCount) of \(summary.activeCount) active pieces")
                                    .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            }.padding(.vertical, 8)
                        }
                    }.listRowBackground(AppTheme.surface)
                    if summary.utilization != nil {
                        Section("Most worn") {
                            ForEach(ranked(summary, descending: true).prefix(5)) { periodRow($0, summary: summary) }
                        }.listRowBackground(AppTheme.surface)
                        Section("Least worn") {
                            ForEach(ranked(summary, descending: false).prefix(5)) { periodRow($0, summary: summary) }
                        }.listRowBackground(AppTheme.surface)
                    }
                }
                Section {
                    NavigationLink { LocalWearHistoryView(periodStart: summary.start, periodEnd: summary.end) } label: {
                        Label("Wear history", systemImage: "clock.arrow.circlepath")
                    }
                } footer: {
                    Text("Monthly insights use dated wear only. Plans and earlier estimates are excluded. Closet in use counts active pieces only.")
                }.listRowBackground(AppTheme.surface)
                if !allTimePieces.isEmpty {
                    Section {
                        ForEach(allTimePieces.prefix(5)) { piece in
                            let total = PieceWearSummary(piece: piece, records: state.wearRecords)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(piece.name).font(AppTypography.fieldLabel)
                                Text("\(total.total) total · \(total.recorded) recorded · \(total.priorEstimate ?? 0) earlier estimate")
                                    .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            }.padding(.vertical, 4)
                        }
                    } header: { Text("All-time totals") }
                    footer: { Text("Earlier estimates are included here. They have no recorded date.") }
                        .listRowBackground(AppTheme.surface)
                }
            }
        }.listStyle(.insetGrouped).scrollContentBackground(.hidden).background(AppTheme.canvas)
            .navigationTitle("Wear insights").navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink)
            .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
            .onAppear(perform: reload).onChange(of: state.wearRecords) { _, _ in reload() }
    }
    private var monthTitle: String {
        guard let date = try? month.date(), let zone = TimeZone(identifier: month.timeZoneID) else { return month.key }
        return date.formatted(Date.FormatStyle(date: .omitted, time: .omitted, timeZone: zone).month(.wide).year())
    }
    private func changeMonth(_ offset: Int) {
        guard let date = try? month.date(), let zone = TimeZone(identifier: month.timeZoneID) else { return }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
        guard let next = calendar.date(byAdding: .month, value: offset, to: date) else { return }
        month = LocalPlanDay(date: next, timeZone: zone); reload()
    }
    private var allTimePieces: [WardrobePiece] {
        state.pieces.filter { PieceWearSummary(piece: $0, records: state.wearRecords).total > 0 }.sorted { a, b in
            let first = PieceWearSummary(piece: a, records: state.wearRecords).total
            let second = PieceWearSummary(piece: b, records: state.wearRecords).total
            return first == second ? a.id.uuidString < b.id.uuidString : first > second
        }
    }
    private func metric(_ title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value, format: .number).font(.title2.weight(.semibold)).monospacedDigit()
            Text(title).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).accessibilityElement(children: .combine)
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
            }.frame(minHeight: 44)
        }.buttonStyle(.plain)
    }
}
