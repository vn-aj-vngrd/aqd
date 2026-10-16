import AQDCore
import CoreLocation
import Foundation
import UIKit
import WeatherKit

/// Only place/date reach Apple's native service. No wardrobe or identity payload.
enum NativeWeatherProvider {
    static func fetch(_ selection: WeatherSelection) async throws -> WeatherSnapshot {
        try selection.validated(); try Task.checkCancellation()
        guard let zone = TimeZone(identifier: selection.place.timeZoneID) else { throw WeatherContextError.invalidPlace }
        let now = Date(), today = LocalPlanDay(date: now, timeZone: zone)
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
        let start = calendar.startOfDay(for: try selection.day.date())
        let todayStart = calendar.startOfDay(for: now)
        guard let finalDay = calendar.date(byAdding: .day, value: 10, to: todayStart), start >= todayStart, start < finalDay,
              let end = calendar.date(byAdding: .day, value: 1, to: start) else { throw WeatherContextError.outsideForecast }
        let service = WeatherService.shared, location = CLLocation(latitude: selection.place.latitude, longitude: selection.place.longitude)
        let daily: Forecast<DayWeather>
        let current: CurrentWeather?
        if selection.day.key == today.key {
            (daily, current) = try await service.weather(for: location, including: .daily(startDate: start, endDate: end), .current)
        } else {
            daily = try await service.weather(for: location, including: .daily(startDate: start, endDate: end)); current = nil
        }
        try Task.checkCancellation()
        let supplied = try await service.attribution
        async let light = mark(supplied.combinedMarkLightURL)
        async let dark = mark(supplied.combinedMarkDarkURL)
        let assets = try await WeatherAttributionAssets(light: light, dark: dark, legalURL: supplied.legalPageURL)
        let fetchedAt = Date()
        let readings = daily.filter { LocalPlanDay(date: $0.date, timeZone: zone) == selection.day }.map { day in
            let validCurrent = current.flatMap { LocalPlanDay(date: $0.date, timeZone: zone) == selection.day ? $0 : nil }
            return WeatherReading(day: LocalPlanDay(date: day.date, timeZone: zone), symbol: day.symbolName, condition: day.condition.description,
                lowCelsius: day.lowTemperature.converted(to: .celsius).value, highCelsius: day.highTemperature.converted(to: .celsius).value,
                precipitationChance: day.precipitationChance.isFinite ? day.precipitationChance : nil, providerDate: daily.metadata.date,
                providerExpiry: min(daily.metadata.expirationDate, validCurrent?.metadata.expirationDate ?? .distantFuture), fetchedAt: fetchedAt,
                temperatureCelsius: validCurrent?.temperature.converted(to: .celsius).value, currentDate: validCurrent?.date)
        }
        let result = WeatherSnapshot(place: selection.place, readings: Array(readings.prefix(10)), attribution: assets)
        try result.validated(); return result
    }
    private static func mark(_ url: URL) async throws -> Data {
        guard url.scheme == "https" else { throw WeatherContextError.unavailable }
        var request = URLRequest(url: url); request.timeoutInterval = 20
        let (bytes, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200, bytes.count <= 1_048_576, UIImage(data: bytes) != nil else { throw WeatherContextError.unavailable }
        return bytes
    }
}
