import Foundation
import Testing
@testable import AQDCore

struct TodayPresentationTests {
    private let day = LocalPlanDay(year: 2026, month: 10, day: 18, timeZoneID: "Asia/Manila")
    private func entry(_ state: PlanEntryState, outfit: Bool = true, revision: Int = 3, review: Bool = false, on date: LocalPlanDay? = nil) -> OutfitPlanEntry {
        OutfitPlanEntry(id: UUID(), planID: UUID(), ownerID: UUID(), day: date ?? day, occasion: "Work",
                        outfitID: outfit ? UUID() : nil, outfitRevision: outfit ? revision : nil, state: state, requiresReview: review)
    }

    @Test func aPlannedLookOffersRecordWear() {
        let look = TodayPresentation.look(entry: entry(.planned), outfitRevision: 3, hasPieces: true)
        #expect(look.primary == .recordWear)
        #expect(look.status == "Planned, not recorded as worn")
    }

    @Test func aChangedOrFlaggedOutfitAsksForReviewBeforeWear() {
        #expect(TodayPresentation.look(entry: entry(.planned), outfitRevision: 4, hasPieces: true).primary == .reviewPlan)
        #expect(TodayPresentation.look(entry: entry(.planned, review: true), outfitRevision: 3, hasPieces: true).primary == .reviewPlan)
    }

    @Test func aDeletedOrMissingOutfitAsksToChooseOne() {
        #expect(TodayPresentation.look(entry: entry(.unassigned, outfit: false), outfitRevision: nil, hasPieces: true).primary == .chooseOutfit)
        #expect(TodayPresentation.look(entry: entry(.planned), outfitRevision: nil, hasPieces: true).primary == .chooseOutfit)
    }

    @Test func wornAndSkippedLooksOfferNothingFurther() {
        #expect(TodayPresentation.look(entry: entry(.worn), outfitRevision: 3, hasPieces: true) == .init(primary: nil, status: "Recorded wear"))
        #expect(TodayPresentation.look(entry: entry(.skipped), outfitRevision: 3, hasPieces: true) == .init(primary: nil, status: "Skipped"))
    }

    @Test func noPlanOffersTheFirstUsefulStep() {
        #expect(TodayPresentation.look(entry: nil, outfitRevision: nil, hasPieces: true).primary == .buildOutfit)
        #expect(TodayPresentation.look(entry: nil, outfitRevision: nil, hasPieces: false).primary == .addPiece)
    }

    @Test func relativeDaysCountCalendarDaysNotHours() {
        func at(_ d: Int) -> LocalPlanDay { LocalPlanDay(year: 2026, month: 10, day: d, timeZoneID: "Asia/Manila") }
        #expect(TodayPresentation.relativeDay(at(18), to: day) == .today)
        #expect(TodayPresentation.relativeDay(at(19), to: day) == .tomorrow)
        #expect(TodayPresentation.relativeDay(at(17), to: day) == .yesterday)
        #expect(TodayPresentation.relativeDay(at(25), to: day) == .other)
        #expect(TodayPresentation.relativeDay(LocalPlanDay(year: 2026, month: 11, day: 1, timeZoneID: "Asia/Manila"), to: LocalPlanDay(year: 2026, month: 10, day: 31, timeZoneID: "Asia/Manila")) == .tomorrow, "across a month end")
    }

    @Test func upcomingSkipsTodayOnlyWhenTodaysLookShowsIt() {
        let tomorrow = LocalPlanDay(year: 2026, month: 10, day: 19, timeZoneID: "Asia/Manila")
        let entries = [entry(.planned), entry(.planned, on: tomorrow)]
        #expect(TodayPresentation.upcoming(entries, today: day, hidingToday: true).map(\.day.key) == ["2026-10-19"])
        #expect(TodayPresentation.upcoming(entries, today: day, hidingToday: false).count == 2)
    }

    @Test func quickActionsDefaultToFourExplicitCommands() {
        #expect(TodayAction.defaults == [.addPiece, .buildOutfit, .planner, .recordWear])
        #expect(Set(TodayAction.defaults).count == 4)
    }

    @Test func aCardThatSavedItsOwnActionsKeepsThem() throws {
        let options = TodayWidgetOptions(actions: [.addFit, .recordWear])
        let data = try JSONEncoder().encode(options)
        #expect(try JSONDecoder().decode(TodayWidgetOptions.self, from: data).actions == [.addFit, .recordWear])
        #expect(TodayWidgetOptions().actions == nil, "an unconfigured card falls back to the defaults")
    }

    @Test func aCardShowsOneTitleNeverTheKindAndItsOwn() {
        #expect(TodayPresentation.title(kind: "Note", contentTitle: "A thought for today") == "A thought for today")
        #expect(TodayPresentation.title(kind: "Note", contentTitle: nil) == "Note")
        #expect(TodayPresentation.title(kind: "Photo", contentTitle: "   ") == "Photo", "a blank title falls back to the kind")
        #expect(TodayPresentation.title(kind: "Theme", contentTitle: "Weekday") == "Weekday")
    }

    @Test func theEyebrowAppearsOnlyWhenItAddsInformation() {
        #expect(TodayPresentation.header(kind: "Theme", contentTitle: "Weekday", context: nil) == .init(eyebrow: "Theme", title: "Weekday"), "the kind labels a named card")
        #expect(TodayPresentation.header(kind: "Weather", contentTitle: "Manila", context: nil).eyebrow == "Weather")
        #expect(TodayPresentation.header(kind: "Week in wear", contentTitle: nil, context: "Oct 18 to 24") == .init(eyebrow: "Oct 18 to 24", title: "Week in wear"))
        #expect(TodayPresentation.header(kind: "Quick actions", contentTitle: nil, context: nil) == .init(eyebrow: nil, title: "Quick actions"), "nothing useful to add")
    }

    @Test func theEyebrowNeverRepeatsTheTitle() {
        #expect(TodayPresentation.header(kind: "Theme", contentTitle: "theme", context: nil).eyebrow == nil)
        #expect(TodayPresentation.header(kind: "Upcoming plans", contentTitle: nil, context: "UPCOMING PLANS").eyebrow == nil)
        #expect(TodayPresentation.header(kind: "Today's look", contentTitle: nil, context: "  ").eyebrow == nil)
    }

    @Test func personalCardsShowTheirOwnTitleAloneOrTheKindAlone() {
        #expect(TodayPresentation.header(kind: "Note", contentTitle: "A thought for today", context: "Note", personal: true) == .init(eyebrow: nil, title: "A thought for today"))
        #expect(TodayPresentation.header(kind: "Photo", contentTitle: nil, context: nil, personal: true) == .init(eyebrow: nil, title: "Photo"))
    }
}
