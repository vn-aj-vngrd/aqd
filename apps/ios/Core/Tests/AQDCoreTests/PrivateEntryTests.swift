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
        for step in 0..<PrivateEntryState.tourStepCount {
            #expect(entry.tour?.step == step)
            try entry.validated()
            #expect(try JSONDecoder().decode(PrivateEntryState.self, from: JSONEncoder().encode(entry)) == entry)
            entry.nextInTour()
        }
        #expect(entry.page == .main, "Finishing the tour opens the app")
        #expect(entry.tourOutcome == .finished)
        #expect(entry.tour == nil)
        try entry.startTour(from: .settings)
        entry.nextInTour()
        let resumed = try JSONDecoder().decode(PrivateEntryState.self, from: JSONEncoder().encode(entry))
        #expect(resumed == entry)
        entry.skipTour()
        #expect(entry.page == .main)
        #expect(entry.tourOutcome == .finished, "Replay never resets the original completion record")
        #expect(entry.tour == nil)
    }

    @Test func developmentPreviewTourPreservesPrivacyAndReadyProgress() throws {
        for page in [PrivateEntryState.Page.privacy, .ready] {
            var entry = PrivateEntryState(alreadyEntered: false); entry.page = page
            try entry.startTour(from: .preview)
            for _ in 0..<PrivateEntryState.tourStepCount { try entry.validated(); entry.nextInTour() }
            #expect(entry.page == page && entry.tour == nil)
            try entry.startTour(from: .preview); entry.skipTour()
            #expect(entry.page == page && entry.tour == nil)
            try entry.startTour(from: .preview); entry.backInTour()
            #expect(entry.page == page && entry.tour == nil)
        }
    }

    @Test func mismatchedTourCallerAndUnsupportedProgressAreRefused() throws {
        var entry = PrivateEntryState(alreadyEntered: false)
        #expect(throws: PrivateEntryState.ValidationError.invalidState) { try entry.startTour(from: .settings) }
        try entry.startTour(from: .welcome)
        entry.tour?.step = PrivateEntryState.tourStepCount
        try entry.validated()
        entry.tour?.step = PrivateEntryState.tourStepCount + 1
        #expect(throws: PrivateEntryState.ValidationError.invalidState) { try entry.validated() }
    }
}
