import AQDCore
import SwiftUI

/// Shared calendar state belongs to AppState, so source returns retain date/view.
enum PlannerRoute: Hashable { case entry(UUID), plan(UUID), packing(UUID), dates(UUID, Bool) }

struct PlannerCalendarView: View {
    @Binding var day: LocalPlanDay
    @Binding var mode: PlannerCalendarMode
    let counts: [String: Int]
    var countLabel = "plans"
    @Environment(\.calendar) private var calendar
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var chooseDate = false
    @State private var error: String?
    private var zone: TimeZone { TimeZone(identifier: day.timeZoneID) ?? .current }
    private var days: [LocalPlanDay] { (try? PlannerCalendar.days(containing: day, mode: mode, calendar: calendar)) ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Button { chooseDate = true } label: {
                    Text(formatted((try? day.date()) ?? Date(), style: .dateTime.month(.wide).year()))
                        .font(AppTypography.fieldLabel).foregroundStyle(AppTheme.ink)
                }.frame(minHeight: 44)
                Spacer(minLength: 0)
                Button(mode == .week ? "Month" : "Week") { mode = mode == .week ? .month : .week }
                    .frame(minWidth: 44, minHeight: 44).tint(AppTheme.actionText)
                Button { move(-1) } label: { Image(systemName: "chevron.backward") }.frame(width: 44, height: 44)
                    .accessibilityLabel(mode == .week ? "Previous week" : "Previous month")
                Button { move(1) } label: { Image(systemName: "chevron.forward") }.frame(width: 44, height: 44)
                    .accessibilityLabel(mode == .week ? "Next week" : "Next month")
            }
            if mode == .week {
                ViewThatFits(in: .horizontal) {
                    weekDays
                    ScrollView(.horizontal) { weekDays }
                        .scrollIndicators(.hidden)
                }.padding(8).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            } else {
                if !typeSize.isAccessibilitySize {
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { index in
                            Text(calendar.veryShortStandaloneWeekdaySymbols[(index + calendar.firstWeekday - 1) % 7])
                                .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).frame(maxWidth: .infinity)
                        }
                    }.padding(.horizontal, 8).accessibilityHidden(true)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: typeSize.isAccessibilitySize ? 3 : 7), spacing: 8) {
                    ForEach(days, id: \.key) { dateCell($0, showWeekday: typeSize.isAccessibilitySize) }
                }.padding(8).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            }
            if let error { SemanticFeedback(role: .danger, message: error) }
        }.tint(AppTheme.ink)
            .sheet(isPresented: $chooseDate) {
                NavigationStack {
                    VStack(spacing: 20) {
                        DatePicker("Select date", selection: Binding(get: { (try? day.date()) ?? Date() }, set: {
                            day = LocalPlanDay(date: $0, timeZone: zone)
                        }), displayedComponents: .date).datePickerStyle(.graphical).environment(\.timeZone, zone)
                        Button("Today") { day = LocalPlanDay(timeZone: zone); chooseDate = false }.frame(minHeight: 44)
                    }.padding(20).navigationTitle("Select date").navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) {
                            Button { chooseDate = false } label: { Image(systemName: "checkmark") }.accessibilityLabel("Done").tint(AppTheme.ink)
                        } }
                }
            }
    }

    private var weekDays: some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.key) { dateCell($0, showWeekday: true).frame(maxWidth: .infinity) }
        }.frame(maxWidth: .infinity)
    }

    private func dateCell(_ value: LocalPlanDay, showWeekday: Bool) -> some View {
        let date = (try? value.date()) ?? Date()
        let selected = value.key == day.key
        let today = value.key == LocalPlanDay(timeZone: zone).key
        let count = counts[value.key, default: 0]
        var displayCalendar = calendar
        displayCalendar.timeZone = zone
        let number = displayCalendar.component(.day, from: date)
        let fullDate = formatted(date, style: .dateTime.weekday(.wide).month(.wide).day().year())
        return Button { day = value } label: {
            VStack(spacing: 4) {
                if showWeekday { Text(formatted(date, style: .dateTime.weekday(.narrow))).font(AppTypography.metadata) }
                Text(number.formatted()).font(AppTypography.body)
                Circle().fill(count > 0 ? (selected ? AppTheme.onAccent : AppTheme.accent) : .clear).frame(width: 4, height: 4)
            }.frame(minWidth: 44, maxWidth: .infinity, minHeight: showWeekday ? 64 : 44)
                .foregroundStyle(selected ? AppTheme.onAccent : AppTheme.ink)
                .background(selected ? AppTheme.accent : .clear, in: RoundedRectangle(cornerRadius: 12))
                .overlay { if today && !selected { RoundedRectangle(cornerRadius: 12).stroke(AppTheme.actionText, lineWidth: 1) } }
        }.buttonStyle(.plain).accessibilityLabel(fullDate)
            .accessibilityValue("\(today ? "Today. " : "")\(count) \(countLabel)\(selected ? ". Selected" : "")")
            .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
    private func formatted(_ date: Date, style: Date.FormatStyle) -> String {
        var style = style; style.timeZone = zone
        return date.formatted(style)
    }
    private func move(_ amount: Int) {
        do { day = try PlannerCalendar.move(day, mode: mode, by: amount, calendar: calendar); error = nil }
        catch { self.error = "This date couldn’t be opened. Choose another date." }
    }
}
