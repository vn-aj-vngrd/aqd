import AQDCore
import Foundation
import Observation

/// Numerical release requires signed service access, supplied attribution and LOCAL16.
enum WeatherQualification { static let enabled = false }

@Observable @MainActor final class WeatherClient {
    typealias Provider = @Sendable (WeatherSelection) async throws -> WeatherSnapshot
    let store: PieceStore
    let qualified: Bool
    @ObservationIgnored private let provider: Provider
    @ObservationIgnored private var flights: [String: (id: UUID, task: Task<WeatherSnapshot, Error>)] = [:]
    @ObservationIgnored private var attempts: [String: Date] = [:]
    @ObservationIgnored private var consumers: [String: Set<UUID>] = [:]
    var epoch = UUID()
    var local: LocalWeatherState?
    var error: String?
    init(store: PieceStore, qualified: Bool = WeatherQualification.enabled, provider: @escaping Provider = { try await NativeWeatherProvider.fetch($0) }) {
        self.store = store; self.qualified = qualified; self.provider = provider; reload()
    }
    func reload() {
        do { local = try store.weatherState(); error = nil }
        catch { self.error = "Saved Weather preferences could not be read. Your private tasks still work without weather." }
    }
    func suspend() {
        epoch = UUID(); for flight in flights.values { flight.task.cancel() }; flights = [:]; consumers = [:]
    }
    func invalidate() { suspend(); attempts = [:]; reload() }
    func cached(_ selection: WeatherSelection, now: Date = Date()) -> WeatherSnapshot? {
        guard local?.enabled == true else { return nil }
        return local?.cache.first { $0.place == selection.place && $0.reading(for: selection.day, now: now, qualified: qualified) != nil }
    }
    func fetch(_ selection: WeatherSelection, consent: Bool, manual: Bool = false, foreground: Bool = true, now: Date = Date()) async throws -> WeatherSnapshot {
        try selection.validated()
        guard consent, foreground else { throw WeatherContextError.consentRequired }
        guard qualified else { throw WeatherContextError.unavailable }
        let startingEpoch = epoch, preference = try store.weatherState().preference
        let key = selection.key
        if !manual, let cached = cached(selection, now: now), cached.reading(for: selection.day, now: now, qualified: qualified)?.freshness(at: now) == .fresh { return cached }
        if let existing = flights[key] {
            let value = try await wait(existing.task, key: key, flightID: existing.id)
            try validate(value, selection: selection, epoch: startingEpoch, preference: preference)
            return value
        }
        let cooldown: TimeInterval = manual ? 60 : 1_800
        guard attempts[key].map({ now.timeIntervalSince($0) >= cooldown }) ?? true else { throw WeatherContextError.cooldown }
        attempts[key] = now
        let flightID = UUID(), provider = provider
        let task = Task { try Task.checkCancellation(); return try await provider(selection) }
        flights[key] = (flightID, task)
        defer { if flights[key]?.id == flightID { flights.removeValue(forKey: key) } }
        let value = try await wait(task, key: key, flightID: flightID)
        try Task.checkCancellation()
        try validate(value, selection: selection, epoch: startingEpoch, preference: preference)
        if preference.enabled { try store.saveWeatherSnapshot(value, expected: preference, now: now); reload() }
        return value
    }
    private func wait(_ task: Task<WeatherSnapshot, Error>, key: String, flightID: UUID) async throws -> WeatherSnapshot {
        let consumer = UUID()
        consumers[key, default: []].insert(consumer)
        defer { release(consumer, key: key, flightID: flightID) }
        return try await withTaskCancellationHandler {
            let value = try await task.value
            try Task.checkCancellation(); return value
        } onCancel: {
            Task { @MainActor in self.release(consumer, key: key, flightID: flightID) }
        }
    }
    private func release(_ consumer: UUID, key: String, flightID: UUID) {
        guard flights[key]?.id == flightID else { return }
        consumers[key]?.remove(consumer)
        if consumers[key]?.isEmpty == true { flights[key]?.task.cancel(); consumers.removeValue(forKey: key) }
    }
    private func validate(_ snapshot: WeatherSnapshot, selection: WeatherSelection, epoch: UUID, preference: WeatherPreference) throws {
        guard self.epoch == epoch, try store.weatherState().preference == preference, snapshot.place == selection.place else { throw WeatherContextError.staleResult }
        try snapshot.validated()
        guard snapshot.readings.contains(where: { $0.day == selection.day }) else { throw WeatherContextError.outsideForecast }
    }
}
