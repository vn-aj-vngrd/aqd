import Foundation

/// The one place a calendar day becomes user-visible text, so every screen reads the same way.
/// Dates keep the day and timezone they were recorded with; the year appears only when it is not the current year.
public extension LocalPlanDay {
    enum DisplayStyle: Sendable {
        /// "Oct 16"
        case compact
        /// "Fri, Oct 16": rows, details and metadata.
        case standard
        /// "Friday, October 16": screen headers and VoiceOver.
        case full
        /// "Today", "Yesterday" or "Tomorrow", otherwise standard.
        case relative
    }

    func display(_ style: DisplayStyle = .standard, now: Date = Date(), locale: Locale = .current) -> String {
        guard let date = try? date(), let zone = TimeZone(identifier: timeZoneID) else { return key }
        let today = LocalPlanDay(date: now, timeZone: zone)
        if style == .relative, let todayDate = try? today.date() {
            var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
            switch calendar.dateComponents([.day], from: todayDate, to: date).day {
            case 0: return "Today"
            case -1: return "Yesterday"
            case 1: return "Tomorrow"
            default: break
            }
        }
        var format = Date.FormatStyle(locale: locale, timeZone: zone)
        switch style {
        case .compact: format = format.month(.abbreviated).day()
        case .standard, .relative: format = format.weekday(.abbreviated).month(.abbreviated).day()
        case .full: format = format.weekday(.wide).month(.wide).day()
        }
        if year != today.year { format = format.year() }
        return date.formatted(format)
    }

    /// "Oct 16 – 20" within a month, "Oct 30 – Nov 2" across months, a single date when the ends match.
    static func displayRange(_ start: LocalPlanDay, _ end: LocalPlanDay, now: Date = Date(), locale: Locale = .current) -> String {
        guard start.key != end.key else { return start.display(.compact, now: now, locale: locale) }
        let first = start.display(.compact, now: now, locale: locale)
        if start.year == end.year, start.month == end.month, start.timeZoneID == end.timeZoneID,
           let date = try? end.date(), let zone = TimeZone(identifier: end.timeZoneID) {
            let day = date.formatted(Date.FormatStyle(locale: locale, timeZone: zone).day())
            return "\(first) – \(day)"
        }
        return "\(first) – \(end.display(.compact, now: now, locale: locale))"
    }
}

public extension Date {
    /// "Oct 16, 2:30 PM" for moments in time (receipts, updates); the year appears only when it is not the current one.
    func displayTimestamp(now: Date = Date(), locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = timeZone
        var format = Date.FormatStyle(locale: locale, timeZone: timeZone).month(.abbreviated).day().hour().minute()
        if calendar.component(.year, from: self) != calendar.component(.year, from: now) { format = format.year() }
        return formatted(format)
    }
}
