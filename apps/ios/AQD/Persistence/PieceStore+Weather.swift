import AQDCore
import CoreData
import CryptoKit
import Darwin
import Foundation
import SwiftData

extension PieceStore {
    func weatherState() throws -> LocalWeatherState {
        let owner = try todayConfiguration().ownerID
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredWeatherState>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        let value = try records.first?.value() ?? LocalWeatherState(ownerID: owner)
        guard value.ownerID == owner else { throw StoreError.invalidRecord }; return value
    }
    func dismissWeatherSetupNotice() throws {
        guard allowsSave else { throw StoreError.staleRevision }
        var value = try weatherState()
        if value.setupNoticeDismissed == true { return }
        value.setupNoticeDismissed = true
        try value.validated()
        let context = ModelContext(container)
        if let record = try context.fetch(FetchDescriptor<StoredWeatherState>()).first { record.payload = try encode(value) }
        else { context.insert(try StoredWeatherState(value)) }
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
    func savedWeatherPreference(_ request: WeatherPreferenceRequest) throws -> WeatherPreference? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredWeatherSave>()).filter { $0.id == request.operationID }
        guard let receipt = records.first else { return nil }
        guard records.count == 1, try JSONDecoder().decode(WeatherPreferenceRequest.self, from: receipt.request) == request else { throw StoreError.operationConflict }
        let result = try JSONDecoder().decode(WeatherPreference.self, from: receipt.result)
        guard result.ownerID == request.base.ownerID, result.revision == request.base.revision + 1,
              result.enabled == request.enabled, result.place == request.place else { throw StoreError.invalidRecord }; return result
    }
    func saveWeatherPreference(_ request: WeatherPreferenceRequest) throws -> WeatherPreference {
        if let saved = try savedWeatherPreference(request) { return saved }
        var value = try weatherState()
        guard allowsSave, value.preference == request.base, value.revision < Int.max - 1 else { throw StoreError.staleRevision }
        value.enabled = request.enabled; value.place = request.place; value.revision += 1
        if !value.enabled { value.cache = [] }
        try value.validated()
        let context = ModelContext(container)
        if let record = try context.fetch(FetchDescriptor<StoredWeatherState>()).first { record.payload = try encode(value) }
        else { context.insert(try StoredWeatherState(value)) }
        context.insert(try StoredWeatherSave(request, result: value.preference))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave(); return value.preference
    }
    func saveWeatherSnapshot(_ snapshot: WeatherSnapshot, expected: WeatherPreference, now: Date) throws {
        var value = try weatherState()
        guard allowsSave, value.preference == expected, expected.enabled else { throw StoreError.staleRevision }
        try value.remember(snapshot, now: now); try value.validated()
        let context = ModelContext(container)
        guard let record = try context.fetch(FetchDescriptor<StoredWeatherState>()).first else { throw StoreError.invalidRecord }
        record.payload = try encode(value); try commit(context)
    }
}
