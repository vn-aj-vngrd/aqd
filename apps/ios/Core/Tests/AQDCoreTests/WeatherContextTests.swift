import Foundation
import Testing
@testable import AQDCore

struct WeatherContextTests {
    @Test func providerExpiryAndFetchAgeSeparateFreshSavedAndHidden() throws {
        let place = WeatherPlace(name: "Manila", latitude: 14.6, longitude: 120.98, timeZoneID: "Asia/Manila")
        let day = LocalPlanDay(year: 2026, month: 10, day: 16, timeZoneID: place.timeZoneID)
        let now = try day.date()
        let reading = WeatherReading(day: day, symbol: "cloud", condition: "Cloudy", lowCelsius: 24, highCelsius: 30, precipitationChance: nil, providerDate: now, providerExpiry: now.addingTimeInterval(600), fetchedAt: now)
        #expect(reading.freshness(at: now.addingTimeInterval(599)) == .fresh)
        #expect(reading.freshness(at: now.addingTimeInterval(600)) == .saved)
        #expect(reading.freshness(at: now.addingTimeInterval(86_401)) == .hidden)
        let snapshot = WeatherSnapshot(place: place, readings: [reading], attribution: nil)
        #expect(snapshot.reading(for: day, now: now, qualified: true) == nil)
        #expect(reading.precipitationChance == nil)
    }
    @Test func unresolvedTimezoneAndWrongDestinationDayAreNeverSubstituted() throws {
        let place = WeatherPlace(name: "Unknown zone", latitude: 0, longitude: 0, timeZoneID: "Unknown/Zone")
        #expect(throws: (any Error).self) { try place.validated() }
        let resolved = WeatherPlace(name: "Tokyo", latitude: 35.68, longitude: 139.69, timeZoneID: "Asia/Tokyo")
        let day = LocalPlanDay(year: 2026, month: 10, day: 16, timeZoneID: "Asia/Tokyo")
        let selection = WeatherSelection(place: resolved, day: day)
        try selection.validated()
        let wrong = WeatherSelection(place: resolved, day: LocalPlanDay(year: 2026, month: 10, day: 16, timeZoneID: "Asia/Manila"))
        #expect(throws: (any Error).self) { try wrong.validated() }
    }
}
