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

struct PlannerPresentationTests {
    private let zone = "Asia/Manila"
    private func day(_ d: Int) -> LocalPlanDay { LocalPlanDay(year: 2026, month: 10, day: d, timeZoneID: zone) }
    private func entry(_ d: Int, _ state: PlanEntryState, plan: UUID = UUID(), outfit: UUID? = nil, revision: Int? = nil, review: Bool = false) -> OutfitPlanEntry {
        OutfitPlanEntry(id: UUID(), planID: plan, ownerID: UUID(), day: day(d), occasion: "", outfitID: outfit,
                        outfitRevision: outfit == nil ? nil : (revision ?? 1), state: state, requiresReview: review)
    }
    private func plan(_ start: Int, _ end: Int, trip: Bool = false) -> PlanDefinition {
        PlanDefinition(ownerID: UUID(), name: "P", start: day(start), end: day(end), trip: trip ? TripConfiguration() : nil)
    }

    @Test func markersSeparateStatesAndFlagStaleOutfits() {
        let outfit = UUID()
        let entries = [entry(5, .planned, outfit: outfit, revision: 1), entry(5, .unassigned), entry(5, .worn, outfit: outfit),
                       entry(6, .skipped), entry(7, .planned, outfit: outfit, review: true)]
        let markers = PlannerPresentation.markers(for: entries, outfitRevisions: [outfit: 2])
        #expect(markers[day(5).key] == PlannerDayMarker(planned: 1, worn: 1, skipped: 0, gaps: 1, needsReview: 1))
        #expect(markers[day(6).key]?.hasOpenItems == false)
        #expect(markers[day(7).key]?.needsReview == 1)
        #expect(markers[day(9).key] == nil)
    }

    @Test func plansGroupByVisibleRangeThenUpcomingAndPast() {
        let visible = (5...11).map(day)
        let inside = plan(10, 12), before = plan(1, 3), after = plan(20, 22), spanning = plan(1, 30)
        let groups = PlannerPresentation.group([after, before, inside, spanning], visible: visible, today: day(8))
        #expect(groups.inRange.map(\.id) == [spanning.id, inside.id])
        #expect(groups.past.map(\.id) == [before.id])
        #expect(groups.upcoming.map(\.id) == [after.id])
    }

    @Test func summariesCountGapsReviewsAndPast() {
        let trip = plan(2, 4, trip: true)
        let entries = [entry(2, .unassigned, plan: trip.id), entry(3, .worn, plan: trip.id), entry(4, .planned, plan: trip.id, outfit: UUID(), review: true)]
        let summary = PlannerPresentation.summaries(plans: [trip], entries: entries, today: day(8))[0]
        #expect(summary.kind == .trip)
        #expect(summary.gaps == 1 && summary.worn == 1 && summary.needsReview == 1 && summary.entryCount == 3)
        #expect(summary.isPast)
    }
}
