import AQDCore
import Foundation
import SwiftData

@Model final class StoredWeatherState {
    @Attribute(.unique) var id: Int
    var payload: Data
    init(_ value: LocalWeatherState) throws { id = 1; payload = try JSONEncoder().encode(value) }
    func value() throws -> LocalWeatherState {
        let value = try JSONDecoder().decode(LocalWeatherState.self, from: payload)
        guard id == 1 else { throw PieceStore.StoreError.invalidRecord }; try value.validated(); return value
    }
}
struct WeatherPreferenceRequest: Codable, Equatable {
    let operationID: UUID
    let base: WeatherPreference
    let enabled: Bool
    let place: WeatherPlace?
}
@Model final class StoredWeatherSave {
    @Attribute(.unique) var id: UUID
    var request: Data
    var result: Data
    init(_ request: WeatherPreferenceRequest, result: WeatherPreference) throws { id = request.operationID; self.request = try JSONEncoder().encode(request); self.result = try JSONEncoder().encode(result) }
}
