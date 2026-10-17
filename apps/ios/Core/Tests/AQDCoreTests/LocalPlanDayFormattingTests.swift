import Foundation
import Testing
@testable import AQDCore

struct LocalPlanDayFormattingTests {
    private let locale = Locale(identifier: "en_US")
    private let zone = "Asia/Manila"
    private func day(_ y: Int, _ m: Int, _ d: Int, zone: String? = nil) -> LocalPlanDay {
        LocalPlanDay(year: y, month: m, day: d, timeZoneID: zone ?? self.zone)
    }
    /// 2026-10-18 12:00 in Manila.
    private var now: Date { (try? day(2026, 10, 18).date()) ?? Date() }

    @Test func stylesReadConsistentlyAndOmitTheCurrentYear() {
        let friday = day(2026, 10, 16)
        #expect(friday.display(.compact, now: now, locale: locale) == "Oct 16")
        #expect(friday.display(.standard, now: now, locale: locale) == "Fri, Oct 16")
        #expect(friday.display(.full, now: now, locale: locale) == "Friday, October 16")
        #expect(!friday.display(.standard, now: now, locale: locale).contains("2026"))
    }

    @Test func otherYearsShowTheYear() {
        let old = day(2025, 12, 31)
        #expect(old.display(.compact, now: now, locale: locale).contains("2025"))
        #expect(old.display(.standard, now: now, locale: locale).contains("2025"))
    }

    @Test func relativeNamesTodayYesterdayTomorrowThenFallsBack() {
        #expect(day(2026, 10, 18).display(.relative, now: now, locale: locale) == "Today")
        #expect(day(2026, 10, 17).display(.relative, now: now, locale: locale) == "Yesterday")
        #expect(day(2026, 10, 19).display(.relative, now: now, locale: locale) == "Tomorrow")
        #expect(day(2026, 10, 25).display(.relative, now: now, locale: locale) == "Sun, Oct 25")
    }

    @Test func aDayKeepsItsOwnTimezoneRatherThanTheDevices() {
        let tokyo = day(2026, 10, 16, zone: "Asia/Tokyo")
        #expect(tokyo.display(.compact, now: now, locale: locale) == "Oct 16")
        #expect(day(2026, 10, 18, zone: "Pacific/Auckland").display(.relative, now: now, locale: locale) != "")
    }

    @Test func invalidDaysFallBackToTheirKey() {
        let bad = LocalPlanDay(year: 2026, month: 2, day: 31, timeZoneID: zone)
        #expect(bad.display(.standard, now: now, locale: locale) == bad.key)
        #expect(LocalPlanDay(year: 2026, month: 2, day: 3, timeZoneID: "Nowhere/Land").display() == "2026-02-03")
    }

    @Test func rangesCollapseWithinAMonth() {
        #expect(LocalPlanDay.displayRange(day(2026, 10, 16), day(2026, 10, 20), now: now, locale: locale) == "Oct 16 – 20")
        #expect(LocalPlanDay.displayRange(day(2026, 10, 30), day(2026, 11, 2), now: now, locale: locale) == "Oct 30 – Nov 2")
        #expect(LocalPlanDay.displayRange(day(2026, 10, 16), day(2026, 10, 16), now: now, locale: locale) == "Oct 16")
        #expect(LocalPlanDay.displayRange(day(2026, 12, 30), day(2027, 1, 2), now: now, locale: locale).contains("2027"))
    }
}

struct DateTimestampFormattingTests {
    @Test func timestampsOmitTheCurrentYearAndKeepTheTime() {
        let locale = Locale(identifier: "en_US"), zone = TimeZone(identifier: "UTC") ?? .current
        let now = Date(timeIntervalSince1970: 1_792_300_000)
        let stamp = now.displayTimestamp(now: now, locale: locale, timeZone: zone)
        #expect(stamp.contains("Oct") && !stamp.contains("2026") && (stamp.contains("AM") || stamp.contains("PM")))
        let old = Date(timeIntervalSince1970: 1_700_000_000).displayTimestamp(now: now, locale: locale, timeZone: zone)
        #expect(old.contains("2023"))
    }
}
