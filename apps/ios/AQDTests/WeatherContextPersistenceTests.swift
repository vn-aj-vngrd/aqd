import AQDCore
import Foundation
import Testing
@testable import AQD

private actor WeatherProbe {
    var calls = 0
    private var ready: [CheckedContinuation<Void, Never>] = []
    private var result: CheckedContinuation<WeatherSnapshot, Error>?
    func provide(_ selection: WeatherSelection) async throws -> WeatherSnapshot {
        calls += 1
        return try await withCheckedThrowingContinuation { continuation in
            result = continuation; ready.forEach { $0.resume() }; ready = []
        }
    }
    func started() async { if result != nil { return }; await withCheckedContinuation { ready.append($0) } }
    func finish(_ snapshot: WeatherSnapshot) { result?.resume(returning: snapshot); result = nil }
}
private actor WeatherFailureCounter {
    var calls = 0
    func fail() throws -> WeatherSnapshot { calls += 1; throw WeatherContextError.unavailable }
}
@Suite(.serialized) @MainActor
struct WeatherContextPersistenceTests {
    @Test func reminderDismissalSeparatesSessionFromPermanentWithoutChangingWeather() throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let before = try store.weatherState()
        let client = WeatherClient(store: store)
        #expect(client.showsSetupNotice)
        client.hideSetupNotice(permanently: false)
        client.reload()
        #expect(!client.showsSetupNotice)
        #expect(try store.weatherState() == before)
        let nextLaunch = WeatherClient(store: store)
        #expect(nextLaunch.showsSetupNotice)
        nextLaunch.hideSetupNotice(permanently: true)
        #expect(!nextLaunch.showsSetupNotice)
        let reopened = try PieceStore(directory: store.localDirectory)
        #expect(!WeatherClient(store: reopened).showsSetupNotice)
        #expect(try reopened.weatherState().preference == before.preference)
        #expect(try reopened.weatherState().cache == before.cache)
        #expect(try reopened.wearRecords().isEmpty)
        let oldPayload = try JSONEncoder().encode(before)
        #expect(!String(decoding: oldPayload, as: UTF8.self).contains("setupNoticeDismissed"))
        #expect(try JSONDecoder().decode(LocalWeatherState.self, from: oldPayload).setupNoticeDismissed == nil)
    }
    @Test func reminderDismissalFailureStaysVisibleAndLostAcknowledgmentReconciles() throws {
        var denied = true, loseAcknowledgment = false
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            beforeOutfitSave: { if denied { throw CocoaError(.fileWriteNoPermission) } },
            afterOutfitSave: { if loseAcknowledgment { throw CocoaError(.fileReadUnknown) } })
        let client = WeatherClient(store: store)
        client.hideSetupNotice(permanently: true)
        #expect(client.showsSetupNotice && client.setupNoticeError != nil)
        #expect(try store.weatherState().setupNoticeDismissed != true)
        denied = false; loseAcknowledgment = true
        client.hideSetupNotice(permanently: true)
        #expect(!client.showsSetupNotice && client.setupNoticeError == nil)
        #expect(!WeatherClient(store: try PieceStore(directory: store.localDirectory)).showsSetupNotice)
    }
    private func selection() -> WeatherSelection {
        let place = WeatherPlace(name: "Manila", latitude: 14.6, longitude: 120.98, timeZoneID: "Asia/Manila")
        return WeatherSelection(place: place, day: LocalPlanDay(timeZone: TimeZone(identifier: place.timeZoneID)!))
    }
    private func snapshot(_ selection: WeatherSelection, now: Date) -> WeatherSnapshot {
        let reading = WeatherReading(day: selection.day, symbol: "cloud", condition: "Synthetic unit fixture", lowCelsius: 24, highCelsius: 30, precipitationChance: nil, providerDate: now, providerExpiry: now.addingTimeInterval(600), fetchedAt: now)
        let assets = WeatherAttributionAssets(light: Data([1]), dark: Data([1]), legalURL: URL(string: "https://example.com/unit-fixture")!)
        return WeatherSnapshot(place: selection.place, readings: [reading], attribution: assets)
    }
    @Test func preferenceUnknownRetryAndOffPurgeSurviveRestartWithoutWear() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var unknown = false
        let store = try PieceStore(directory: directory, afterOutfitSave: { if unknown { throw CocoaError(.fileReadUnknown) } })
        let initial = try store.weatherState(); #expect(!initial.enabled && initial.cache.isEmpty)
        let selected = selection(), now = Date()
        let request = WeatherPreferenceRequest(operationID: UUID(), base: initial.preference, enabled: true, place: selected.place)
        unknown = true; #expect(throws: (any Error).self) { try store.saveWeatherPreference(request) }
        let enabled = try store.saveWeatherPreference(request)
        unknown = false
        try store.saveWeatherSnapshot(snapshot(selected, now: now), expected: enabled, now: now)
        #expect(try store.weatherState().cache.count == 1)
        let off = WeatherPreferenceRequest(operationID: UUID(), base: enabled, enabled: false, place: selected.place)
        _ = try store.saveWeatherPreference(off)
        let reopened = try PieceStore(directory: directory)
        #expect(try !reopened.weatherState().enabled && reopened.weatherState().cache.isEmpty)
        #expect(throws: (any Error).self) { try reopened.saveWeatherSnapshot(snapshot(selected, now: now), expected: enabled, now: now) }
        #expect(try reopened.wearRecords().isEmpty)
    }
    @Test func concurrentConsumersShareARequestAndOffIgnoresLateResult() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), store = try PieceStore(directory: directory)
        let selected = selection(), now = Date(), initial = try store.weatherState()
        _ = try store.saveWeatherPreference(WeatherPreferenceRequest(operationID: UUID(), base: initial.preference, enabled: true, place: selected.place))
        let probe = WeatherProbe(), client = WeatherClient(store: store, qualified: true, provider: { try await probe.provide($0) })
        let first = Task { try await client.fetch(selected, consent: true, now: now) }
        await probe.started()
        let second = Task { try await client.fetch(selected, consent: true, now: now) }
        await probe.finish(snapshot(selected, now: now))
        _ = try await first.value; _ = try await second.value
        #expect(await probe.calls == 1)
        let later = WeatherSelection(place: selected.place, day: LocalPlanDay(date: now.addingTimeInterval(86_400), timeZone: TimeZone(identifier: selected.place.timeZoneID)!))
        let delayed = Task { try await client.fetch(later, consent: true, now: now) }
        await probe.started()
        let current = try store.weatherState()
        _ = try store.saveWeatherPreference(WeatherPreferenceRequest(operationID: UUID(), base: current.preference, enabled: false, place: current.place))
        client.invalidate(); await probe.finish(snapshot(later, now: now))
        do { _ = try await delayed.value; Issue.record("An off-state accepted a late response") } catch { }
        #expect(try store.weatherState().cache.isEmpty)
    }
    @Test func disabledQualificationAndMissingConsentNeverCallProvider() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), store = try PieceStore(directory: directory)
        let probe = WeatherProbe(), selected = selection(), client = WeatherClient(store: store, provider: { try await probe.provide($0) })
        do { _ = try await client.fetch(selected, consent: true); Issue.record("Unqualified request ran") } catch { }
        do { _ = try await client.fetch(selected, consent: false); Issue.record("Unconsented request ran") } catch { }
        #expect(await probe.calls == 0)
        #expect(try store.weatherState().revision == 0)
    }
    @Test func manualAndAutomaticAttemptsShareCooldownWithoutRetryLoops() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), store = try PieceStore(directory: directory)
        let counter = WeatherFailureCounter(), selected = selection(), now = Date()
        let client = WeatherClient(store: store, qualified: true, provider: { _ in try await counter.fail() })
        for (offset, manual) in [(0.0, false), (59.0, true), (60.0, true), (1859.0, false), (1860.0, false)] {
            do { _ = try await client.fetch(selected, consent: true, manual: manual, now: now.addingTimeInterval(offset)); Issue.record("Unavailable provider succeeded") } catch { }
        }
        #expect(await counter.calls == 3)
        #expect(try store.weatherState().cache.isEmpty)
    }
    @Test func parentWeatherContextPersistsOnlyInItsRecoverableDraft() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), store = try PieceStore(directory: directory), state = AppState(store: store)
        let selected = selection()
        state.buildOutfit(); let outfit = try #require(state.outfitEditor)
        outfit.update { $0.weather = selected }
        #expect(try store.outfitDraft()?.weather == selected)
        #expect(try !store.weatherState().enabled && store.outfits().isEmpty)
        outfit.discard()
        state.openPlan(day: selected.day); let plan = try #require(state.planEditor)
        plan.update { $0.weather = selected }
        #expect(try store.planDraft()?.weather == selected)
        #expect(try store.planEntries().isEmpty && store.wearRecords().isEmpty)
        #expect(try store.weatherState().revision == 0)
        plan.finish(discarding: true)
        #expect(try store.planDraft() == nil)
    }

}
