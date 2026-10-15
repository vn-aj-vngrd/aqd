import Foundation
import Testing
@testable import AQDCore

struct PrivateEntryTests {
    @Test func freshBypassAndLegacyEntryDoNotInventPreferenceCompletion() throws {
        var fresh = PrivateEntryState(alreadyEntered: false)
        #expect(fresh.page == .welcome)
        fresh.page = .introduction
        fresh.openMain()
        #expect(fresh.page == .main)
        #expect(fresh.tourOutcome == nil)
        #expect(PrivateEntryState(alreadyEntered: true).page == .main)
        try fresh.validated()
    }

    @Test func tourBackFinishSkipAndReplayRestoreTheirActualSource() throws {
        var entry = PrivateEntryState(alreadyEntered: false)
        try entry.startTour(from: .welcome)
        entry.backInTour()
        #expect(entry.tour == nil)
        #expect(entry.page == .welcome)
        try entry.startTour(from: .welcome)
        for _ in 0..<4 { entry.nextInTour() }
        #expect(entry.page == .ready)
        #expect(entry.tourOutcome == .finished)
        entry.reviewTourFromReady()
        #expect(entry.tour?.step == 3)
        #expect(entry.tour?.source == .welcome)
        entry.nextInTour()
        #expect(entry.page == .ready)
        entry.openMain()
        try entry.startTour(from: .settings)
        entry.nextInTour()
        let resumed = try JSONDecoder().decode(PrivateEntryState.self, from: JSONEncoder().encode(entry))
        #expect(resumed == entry)
        entry.skipTour()
        #expect(entry.page == .main)
        #expect(entry.tourOutcome == .finished, "Replay never resets the original completion record")
        #expect(entry.tour == nil)
    }

    @Test func mismatchedTourCallerAndUnsupportedProgressAreRefused() throws {
        var entry = PrivateEntryState(alreadyEntered: false)
        #expect(throws: PrivateEntryState.ValidationError.invalidState) { try entry.startTour(from: .settings) }
        try entry.startTour(from: .welcome)
        entry.tour?.step = 4
        #expect(throws: PrivateEntryState.ValidationError.invalidState) { try entry.validated() }
    }
}
