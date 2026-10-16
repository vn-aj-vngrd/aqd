import Foundation
import Testing
@testable import AQDCore

struct PlannerCalendarTests {
    @Test func weekAndMonthUseRealCalendarDaysAcrossLeapYearAndDST() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let leap = LocalPlanDay(year: 2024, month: 2, day: 29, timeZoneID: "Asia/Manila")
        let month = try PlannerCalendar.days(containing: leap, mode: .month, calendar: calendar)
        #expect(month.count == 35)
        #expect(month.first?.key == "2024-01-29")
        #expect(month.last?.key == "2024-03-03")
        let dst = LocalPlanDay(year: 2026, month: 3, day: 8, timeZoneID: "America/New_York")
        let week = try PlannerCalendar.days(containing: dst, mode: .week, calendar: calendar)
        #expect(week.count == 7)
        #expect(week.first?.key == "2026-03-02")
        #expect(week.last?.key == "2026-03-08")
        #expect(week.allSatisfy { $0.timeZoneID == dst.timeZoneID })
    }
}
