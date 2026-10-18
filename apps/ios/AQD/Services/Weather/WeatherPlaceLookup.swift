import AQDCore
import CoreLocation
import Foundation
import MapKit
import Observation

@Observable @MainActor final class WeatherPlaceLookup: NSObject, @preconcurrency CLLocationManagerDelegate {
    var query = ""
    var results: [MKMapItem] = []
    var selected: WeatherPlace?
    var pending = false
    var error: String?
    @ObservationIgnored private var token = UUID()
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var search: MKLocalSearch?
    @ObservationIgnored private var manager: CLLocationManager?
    @ObservationIgnored private var geocoder = CLGeocoder()
    @ObservationIgnored private var awaitingLocation = false
    @ObservationIgnored private var locationRequested = false
    @ObservationIgnored private var timeout: Task<Void, Never>?
    func cancel() {
        token = UUID(); task?.cancel(); search?.cancel(); timeout?.cancel()
        manager?.stopUpdatingLocation(); geocoder.cancelGeocode(); awaitingLocation = false; locationRequested = false; pending = false
    }
    /// Called only by the disclosed Search button, never while typing.
    func searchCity() {
        cancel(); let requested = token, text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        pending = true; error = nil
        let request = MKLocalSearch.Request(); request.naturalLanguageQuery = text; request.resultTypes = .address
        let search = MKLocalSearch(request: request); self.search = search
        task = Task {
            do {
                let response = try await search.start()
                guard !Task.isCancelled, requested == token else { return }
                results = response.mapItems; pending = false
                if results.isEmpty { error = "No city matched. Try a city and country, or continue without weather." }
            } catch { if requested == token { pending = false; self.error = "City search could not finish. Keep the saved place, retry or continue without weather." } }
        }
    }
    func choose(_ item: MKMapItem) {
        guard let zone = item.placemark.timeZone else { error = "This place’s timezone is unavailable. Choose another city; your plan date is unchanged."; return }
        let place = WeatherPlace(name: [item.placemark.locality ?? item.name, item.placemark.administrativeArea, item.placemark.country].compactMap { $0 }.joined(separator: ", "), latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude, timeZoneID: zone.identifier)
        do { try place.validated(); selected = place; cancel(); error = nil }
        catch { self.error = "This place could not be resolved. Choose another city." }
    }
    /// The only location-permission entry. Approximate foreground location is sufficient.
    func useCurrentLocation() {
        cancel(); pending = true; error = nil; awaitingLocation = true
        let manager = manager ?? CLLocationManager(); self.manager = manager; manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
        else { beginLocationIfAuthorized(manager) }
        let requested = token
        timeout = Task {
            try? await Task.sleep(for: .seconds(20))
            guard !Task.isCancelled, token == requested, pending else { return }
            cancel(); error = "Location lookup timed out. Choose a city or continue without weather." }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { if awaitingLocation { beginLocationIfAuthorized(manager) } }
    private func beginLocationIfAuthorized(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if !locationRequested { locationRequested = true; manager.requestLocation() }
        case .denied, .restricted: cancel(); error = "Location access is unavailable. Choose a city without location permission, or continue without weather."
        case .notDetermined: break
        @unknown default: cancel(); error = "Location access is unavailable. Choose a city."
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        guard awaitingLocation else { return }; cancel(); self.error = "Your location could not be resolved. Choose a city or continue without weather."
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard awaitingLocation, let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        awaitingLocation = false; manager.stopUpdatingLocation()
        let requested = token
        task = Task {
            do {
                let matches = try await geocoder.reverseGeocodeLocation(location)
                guard !Task.isCancelled, token == requested, let match = matches.first, let zone = match.timeZone else {
                    if token == requested { cancel(); error = "The location timezone is unavailable. Choose a city." }; return
                }
                let place = WeatherPlace(name: [match.locality, match.administrativeArea, match.country].compactMap { $0 }.joined(separator: ", "), latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, timeZoneID: zone.identifier)
                try place.validated(); selected = place; cancel(); error = nil
            } catch { if token == requested { cancel(); self.error = "The location timezone could not be resolved. Choose a city." } }
        }
    }
}
