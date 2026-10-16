import Foundation

public enum WeatherContextError: Error { case invalidPlace, invalidReading, unavailable, consentRequired, cooldown, outsideForecast, staleResult }
public struct WeatherPlace: Codable, Equatable, Sendable, Identifiable {
    public var id: String { "\(latitude),\(longitude),\(timeZoneID)" }
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let timeZoneID: String
    public init(name: String, latitude: Double, longitude: Double, timeZoneID: String) { self.name = name; self.latitude = latitude; self.longitude = longitude; self.timeZoneID = timeZoneID }
    public func validated() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, latitude.isFinite, longitude.isFinite,
              (-90...90).contains(latitude), (-180...180).contains(longitude), TimeZone(identifier: timeZoneID) != nil else { throw WeatherContextError.invalidPlace }
    }
}
public struct WeatherSelection: Codable, Equatable, Sendable {
    public var place: WeatherPlace
    public var day: LocalPlanDay
    public var key: String { place.id + ":" + day.key }
    public init(place: WeatherPlace, day: LocalPlanDay) { self.place = place; self.day = day }
    public func validated() throws { try place.validated(); _ = try day.date(); guard day.timeZoneID == place.timeZoneID else { throw WeatherContextError.invalidPlace } }
}
public enum WeatherFreshness: String, Codable, Sendable { case fresh, saved, hidden }
public struct WeatherReading: Codable, Equatable, Sendable {
    public let day: LocalPlanDay
    public let symbol: String
    public let condition: String
    public let lowCelsius: Double
    public let highCelsius: Double
    public let precipitationChance: Double?
    public var temperatureCelsius: Double?
    public var currentDate: Date?
    public let providerDate: Date
    public let providerExpiry: Date
    public let fetchedAt: Date
    public init(day: LocalPlanDay, symbol: String, condition: String, lowCelsius: Double, highCelsius: Double, precipitationChance: Double?, providerDate: Date, providerExpiry: Date, fetchedAt: Date, temperatureCelsius: Double? = nil, currentDate: Date? = nil) {
        self.day = day; self.symbol = symbol; self.condition = condition; self.lowCelsius = lowCelsius; self.highCelsius = highCelsius; self.precipitationChance = precipitationChance
        self.providerDate = providerDate; self.providerExpiry = providerExpiry; self.fetchedAt = fetchedAt; self.temperatureCelsius = temperatureCelsius; self.currentDate = currentDate
    }
    public func validated() throws {
        _ = try day.date()
        guard !symbol.isEmpty, !condition.isEmpty, lowCelsius.isFinite, highCelsius.isFinite, lowCelsius <= highCelsius,
              precipitationChance.map({ $0.isFinite && (0...1).contains($0) }) ?? true,
              temperatureCelsius.map(\.isFinite) ?? true, (temperatureCelsius == nil) == (currentDate == nil),
              providerDate.timeIntervalSince1970.isFinite, providerExpiry.timeIntervalSince1970.isFinite,
              fetchedAt.timeIntervalSince1970.isFinite, providerExpiry >= providerDate else { throw WeatherContextError.invalidReading }
    }
    public func freshness(at now: Date) -> WeatherFreshness {
        let age = now.timeIntervalSince(fetchedAt)
        guard age >= 0, age <= 86_400 else { return .hidden }
        return age < 1_800 && now < providerExpiry ? .fresh : .saved
    }
}
public struct WeatherAttributionAssets: Codable, Equatable, Sendable {
    public let light: Data
    public let dark: Data
    public let legalURL: URL
    public init(light: Data, dark: Data, legalURL: URL) { self.light = light; self.dark = dark; self.legalURL = legalURL }
    public var isAvailable: Bool { !light.isEmpty && !dark.isEmpty && light.count <= 1_048_576 && dark.count <= 1_048_576 && legalURL.scheme == "https" && legalURL.host != nil }
}
public struct WeatherSnapshot: Codable, Equatable, Sendable {
    public let place: WeatherPlace
    public var readings: [WeatherReading]
    public var attribution: WeatherAttributionAssets?
    public init(place: WeatherPlace, readings: [WeatherReading], attribution: WeatherAttributionAssets?) { self.place = place; self.readings = readings; self.attribution = attribution }
    public func validated() throws {
        try place.validated()
        guard readings.count <= 10, Set(readings.map(\.day.key)).count == readings.count else { throw WeatherContextError.invalidReading }
        for reading in readings { try reading.validated(); guard reading.day.timeZoneID == place.timeZoneID else { throw WeatherContextError.invalidPlace } }
        if let attribution { guard attribution.isAvailable else { throw WeatherContextError.invalidReading } }
    }
    public func reading(for day: LocalPlanDay, now: Date, qualified: Bool) -> WeatherReading? {
        guard qualified, attribution?.isAvailable == true, day.timeZoneID == place.timeZoneID,
              let zone = TimeZone(identifier: place.timeZoneID), day.key >= LocalPlanDay(date: now, timeZone: zone).key,
              let reading = readings.first(where: { $0.day == day }), reading.freshness(at: now) != .hidden else { return nil }
        return reading
    }
}
public struct LocalWeatherState: Codable, Equatable, Sendable {
    public let ownerID: UUID
    public var revision: Int
    public var enabled: Bool
    public var place: WeatherPlace?
    public var cache: [WeatherSnapshot]
    public init(ownerID: UUID) { self.ownerID = ownerID; revision = 0; enabled = false; place = nil; cache = [] }
    public func validated() throws {
        guard revision >= 0, revision < Int.max, !enabled || place != nil, enabled || cache.isEmpty,
              cache.count <= 5, Set(cache.map(\.place.id)).count == cache.count else { throw WeatherContextError.invalidReading }
        try place?.validated(); for snapshot in cache { try snapshot.validated() }
    }
    public mutating func remember(_ snapshot: WeatherSnapshot, now: Date) throws {
        try snapshot.validated(); guard enabled else { throw WeatherContextError.consentRequired }
        let previous = cache.first { $0.place.id == snapshot.place.id }
        var merged = snapshot
        merged.readings += (previous?.readings ?? []).filter { old in !snapshot.readings.contains { $0.day == old.day } && old.freshness(at: now) != .hidden }
        merged.readings = Array(merged.readings.sorted { $0.fetchedAt > $1.fetchedAt }.prefix(10))
        if merged.attribution == nil { merged.attribution = previous?.attribution }
        cache.removeAll { $0.place.id == snapshot.place.id }; cache.insert(merged, at: 0); cache = Array(cache.prefix(5))
    }
}

public struct WeatherPreference: Codable, Equatable, Sendable {
    public let ownerID: UUID
    public let revision: Int
    public let enabled: Bool
    public let place: WeatherPlace?
    public init(ownerID: UUID, revision: Int, enabled: Bool, place: WeatherPlace?) { self.ownerID = ownerID; self.revision = revision; self.enabled = enabled; self.place = place }
}
public extension LocalWeatherState {
    var preference: WeatherPreference { WeatherPreference(ownerID: ownerID, revision: revision, enabled: enabled, place: place) }
}
