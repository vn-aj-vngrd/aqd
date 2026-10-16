import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor
struct PrivateEntryPersistenceTests {
    @Test func freshWelcomeTourResumeAndReplayPreserveEveryRealRecordAndDraft() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        let today = try #require(store).todayConfiguration()
        let draft = PieceDraft(name: "Existing interrupted capture")
        let operationID = UUID()
        try #require(store).saveDraft(draft, operationID: operationID)
        var entry = try #require(store).localExperience().entryState
        #expect(entry.page == .welcome)
        entry.welcomeSeen = true
        try entry.startTour(from: .welcome)
        entry.nextInTour()
        try #require(store).saveEntryState(entry)
        store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).localExperience().entryState == entry)
        entry.skipTour()
        try #require(store).saveEntryState(entry)
        #expect(try #require(store).localExperience().style == nil)
        #expect(try #require(store).localExperience().styleDraft == nil)
        try entry.startTour(from: .settings)
        for _ in 0..<PrivateEntryState.tourStepCount { entry.nextInTour() }
        try #require(store).saveEntryState(entry)
        #expect(try #require(store).pieces().isEmpty)
        #expect(try #require(store).latestDraft() == RecoverablePieceDraft(draft: draft, operationID: operationID))
        #expect(try #require(store).todayConfiguration() == today)
        #expect(try #require(store).localExperience().entryState.page == .main)
        store = nil
    }

    @Test func onboardingDiscardAndSaveReceiptHaveDifferentDurableEntryOutcomes() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        var entry = try #require(store).localExperience().entryState
        entry.page = .introduction
        try #require(store).saveEntryState(entry)
        let canceled = StylePreferenceDraft(source: .onboarding)
        try #require(store).saveStyleDraft(canceled)
        try #require(store).discardStyleDraft(id: canceled.id)
        #expect(try #require(store).localExperience().entryState.page == .introduction)
        #expect(try #require(store).localExperience().style == nil)
        var answers = StylePreferences()
        for step in 0..<PrivateEntryState.tourStepCount { answers.choose("No preference", at: step) }
        answers.body.decline(); answers.colors.declined = true
        let saved = StylePreferenceDraft(source: .onboarding, answers: answers)
        try #require(store).saveStyleDraft(saved)
        _ = try #require(store).saveStylePreferences(saved)
        store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).localExperience().entryState.page == .introduction)
        #expect(try #require(store).localExperience().pendingStyleReceipt == saved)
        try #require(store).acknowledgeStyleReceipt(operationID: saved.operationID)
        store = nil
        store = try PieceStore(directory: directory)
        #expect(try #require(store).localExperience().entryState.page == .introduction)
        #expect(try #require(store).localExperience().entryState.tour?.step == 0)
        #expect(try #require(store).localExperience().style?.revision == 1)
        #expect(try #require(store).pieces().isEmpty)
        store = nil
    }

    @Test func savedReceiptCanOpenTheRealClosetDurablyWithoutCreatingTourRecords() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        var answers = StylePreferences()
        for step in 0..<PrivateEntryState.tourStepCount { answers.choose("No preference", at: step) }
        answers.body.decline(); answers.colors.declined = true
        let draft = StylePreferenceDraft(source: .onboarding, answers: answers)
        try #require(store).saveStyleDraft(draft)
        _ = try #require(store).saveStylePreferences(draft)
        try #require(store).acknowledgeStyleReceipt(operationID: draft.operationID, openCloset: true)
        store = nil
        store = try PieceStore(directory: directory)
        let value = try #require(store).localExperience()
        #expect(value.entryState.page == .main)
        #expect(value.entryState.tour == nil)
        #expect(value.entryState.tourOutcome == nil)
        #expect(value.pendingStyleReceipt == nil)
        #expect(value.style?.answers == answers)
        #expect(try #require(store).pieces().isEmpty)
    }

    @Test func packagedIllustrationsDecodeOnceIntoTwelveCropsAndDoNotDependOnNetwork() throws {
        #expect(try #require(WelcomeGarments.layout).pieces.count == 12)
        #expect(WelcomeGarments.images.count == 12)
        #expect(TourArtwork.images.count == 6)
        let first = try #require(WelcomeGarments.images["shirt"])
        #expect(WelcomeGarments.images["shirt"] === first)
        #expect(first.size.width == 390)
        #expect(first.size.height == 380)
        #expect(Bundle.main.url(forResource: "LaunchScreen", withExtension: "storyboardc") != nil)
    }
}
