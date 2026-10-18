import AQDCore
import SwiftUI
import Charts

struct LocalWearInsightsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var month: LocalPlanDay
    init(initialMonth: LocalPlanDay = LocalPlanDay()) { _month = State(initialValue: initialMonth) }
    @State private var summary: WearPeriodSummary?
    @State private var error: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                HStack {
                    Text(monthTitle).font(AppTypography.section)
                    Spacer(minLength: 12)
                    monthButton(-1)
                    monthButton(1)
                }
                if let error {
                    SemanticFeedback(role: .danger, message: error)
                    Button("Retry insights", action: reload).frame(minHeight: 44)
                } else if let summary {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 12) {
                        metric("Wear records", value: summary.occasions)
                        metric("Pieces worn", value: summary.counts.count)
                        metric("Days recorded", value: summary.dailyOccasions.count)
                        metric("Active pieces", value: summary.activeCount)
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily wear").font(AppTypography.detailTitle)
                        let peak = max(1, summary.dailyOccasions.values.max() ?? 0)
                        Chart(Array(1...summary.end.day), id: \.self) { day in
                            BarMark(x: .value("Day", day), y: .value("Wear records", summary.dailyOccasions[day, default: 0]))
                                .foregroundStyle(AppTheme.ink).cornerRadius(3)
                                .accessibilityLabel("\(monthTitle), day \(day)")
                                .accessibilityValue("\(summary.dailyOccasions[day, default: 0]) wear records")
                        }.chartYScale(domain: 0...peak)
                            .chartXAxis { AxisMarks(values: [1, 8, 15, 22, summary.end.day]) { _ in AxisValueLabel() } }
                            .chartYAxis { AxisMarks(values: [0, peak]) { _ in AxisGridLine(); AxisValueLabel() } }
                            .chartXAxisLabel("Day of month").frame(height: 180)
                            .accessibilityLabel("Daily recorded wear")
                        Text(summary.occasions == 0 ? "No wear recorded this month. Your dated records will build this chart." : "\(summary.itemOccurrences) item wears across \(summary.occasions) wear records.")
                            .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }.padding(20).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                    if let utilization = summary.utilization {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Closet in use").font(AppTypography.detailTitle)
                                Spacer()
                                Text(utilization, format: .percent.precision(.fractionLength(0))).font(AppTypography.section).monospacedDigit()
                            }
                            ProgressView(value: utilization).tint(AppTheme.ink)
                            Text("\(summary.usedActiveCount) of \(summary.activeCount) active pieces worn this month")
                                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }.padding(20).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                        ranking("Most worn", pieces: Array(ranked(summary, descending: true).prefix(5)), summary: summary)
                        ranking("Least worn", pieces: Array(ranked(summary, descending: false).prefix(5)), summary: summary)
                    }
                    if !allTimePieces.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("All-time totals").font(AppTypography.detailTitle)
                            ForEach(allTimePieces.prefix(5)) { piece in
                                let total = PieceWearSummary(piece: piece, records: state.wearRecords)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(piece.displayName).font(AppTypography.fieldLabel).truncated()
                                    Text("\(total.total) total, \(total.recorded) recorded, \(total.priorEstimate ?? 0) earlier estimate")
                                        .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                                }
                            }
                            Text("Earlier estimates have no recorded date.").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                    }
                    Text("Monthly insights use dated wear only. Plans and earlier estimates are excluded. Closet in use counts active pieces only.")
                        .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                } else { ProgressView("Loading insights").frame(maxWidth: .infinity) }
            }.padding(.horizontal, 20).padding(.vertical, 16)
        }.background(AppTheme.canvas)
            .navigationTitle("Wear insights").navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { LocalWearHistoryView(periodStart: summary?.start, periodEnd: summary?.end).secondaryPage() } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }.accessibilityLabel("Wear history").disabled(summary == nil)
            } }
            .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
            .onAppear(perform: reload).onChange(of: state.wearRecords) { _, _ in reload() }
    }
    @ViewBuilder private func monthButton(_ offset: Int) -> some View {
        if #available(iOS 26.0, *), !reduceTransparency, contrast != .increased {
            monthAction(offset).glassEffect(.regular.interactive(), in: Circle())
        } else {
            monthAction(offset).background(AppTheme.surface, in: Circle())
                .overlay { Circle().stroke(contrast == .increased ? AppTheme.controlBoundary : AppTheme.divider, lineWidth: 1) }
        }
    }
    private func monthAction(_ offset: Int) -> some View {
        Button { withAnimation(reduceMotion ? nil : AQDMotion.reflow) { changeMonth(offset) } } label: {
            Image(systemName: offset < 0 ? "chevron.backward" : "chevron.forward").frame(width: 44, height: 44).contentShape(Circle())
        }.buttonStyle(.plain).accessibilityLabel(offset < 0 ? "Previous month" : "Next month")
    }
    private func ranking(_ title: String, pieces: [WardrobePiece], summary: WearPeriodSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(AppTypography.detailTitle)
            ForEach(pieces) { piece in periodRow(piece, summary: summary) }
        }.padding(20).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
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
        }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card)).accessibilityElement(children: .combine)
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
                Text(piece.displayName).font(AppTypography.body).foregroundStyle(AppTheme.ink).frame(maxWidth: .infinity, alignment: .leading)
                Text("\(summary.counts[piece.id, default: 0]) recorded").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }.frame(minHeight: 44)
        }.buttonStyle(.plain)
    }
}
