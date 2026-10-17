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

struct PlannerQueryTests {
    private let zone = "Asia/Manila"
    private func day(_ d: Int) -> LocalPlanDay { LocalPlanDay(year: 2026, month: 10, day: d, timeZoneID: zone) }
    private func entry(_ state: PlanEntryState, outfit: UUID? = nil, review: Bool = false) -> OutfitPlanEntry {
        OutfitPlanEntry(id: UUID(), planID: UUID(), ownerID: UUID(), day: day(1), occasion: "", outfitID: outfit,
                        outfitRevision: outfit == nil ? nil : 1, state: state, requiresReview: review)
    }
    private func plan(_ name: String, _ start: Int, routine: Bool = false, trip: Bool = false) -> PlanDefinition {
        PlanDefinition(ownerID: UUID(), name: name, start: day(start), end: day(start + 1),
                       routine: routine ? RoutineConfiguration() : nil, trip: trip ? TripConfiguration() : nil)
    }

    @Test func statusFilterSelectsEntries() {
        let outfit = UUID()
        let entries = [entry(.planned, outfit: outfit), entry(.unassigned), entry(.worn, outfit: outfit), entry(.skipped), entry(.planned, outfit: outfit, review: true)]
        func count(_ status: PlannerQuery.Status) -> Int { PlannerQuery(status: status).apply(to: entries, outfitRevisions: [outfit: 1]).count }
        #expect(count(.all) == 5 && count(.open) == 3 && count(.toChoose) == 1)
        #expect(count(.needsReview) == 1 && count(.worn) == 1 && count(.skipped) == 1)
    }

    @Test func kindFilterAndSortOrderPlans() {
        let plans = [plan("Beta", 9, trip: true), plan("alpha", 3), plan("Gamma", 6, routine: true)]
        #expect(PlannerQuery(kind: .trips).apply(to: plans).map(\.name) == ["Beta"])
        #expect(PlannerQuery(kind: .routines).apply(to: plans).map(\.name) == ["Gamma"])
        #expect(PlannerQuery(sort: .soonest).apply(to: plans).map(\.name) == ["alpha", "Gamma", "Beta"])
        #expect(PlannerQuery(sort: .latest).apply(to: plans).map(\.name) == ["Beta", "Gamma", "alpha"])
        #expect(PlannerQuery(sort: .name).apply(to: plans).map(\.name) == ["alpha", "Beta", "Gamma"])
        #expect(PlannerQuery().isDefault && !PlannerQuery(kind: .trips).isDefault)
    }

    @Test func searchMatchesNamesDestinationsOccasionsAndOutfits() {
        let outfit = UUID()
        var trip = plan("Weekend", 4, trip: true); trip.trip?.destination = "Café Lisbon"
        let plans = [trip, plan("Office", 5)]
        #expect(PlannerQuery(text: " cafe ").apply(to: plans).map(\.name) == ["Weekend"])
        #expect(PlannerQuery(text: "zzz").apply(to: plans).isEmpty)
        var withOccasion = entry(.planned, outfit: outfit); withOccasion.occasion = "Dinner"
        let entries = [withOccasion, entry(.skipped)]
        #expect(PlannerQuery(text: "dinn").apply(to: entries).count == 1)
        #expect(PlannerQuery(text: "linen").apply(to: entries, outfitNames: [outfit: "Linen set"]).count == 1)
        #expect(PlannerQuery(text: "").apply(to: entries).count == 2)
    }
}
