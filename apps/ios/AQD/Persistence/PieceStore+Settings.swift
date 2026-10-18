import AQDCore
import CoreData
import CryptoKit
import Darwin
import Foundation
import SwiftData

extension PieceStore {
    func localSettings() throws -> LocalSettings {
        let owner = try todayConfiguration().ownerID
        let rows = try ModelContext(container).fetch(FetchDescriptor<StoredLocalSettings>())
        guard rows.count <= 1 else { throw StoreError.invalidRecord }
        let value = try rows.first?.value() ?? LocalSettings(ownerID: owner)
        guard value.ownerID == owner else { throw StoreError.invalidRecord }; return value
    }
    func mutationStamp() throws -> UUID? {
        let rows = try ModelContext(container).fetch(FetchDescriptor<StoredLocalMutation>())
        guard rows.count <= 1, rows.allSatisfy({ $0.id == 1 }) else { throw StoreError.invalidRecord }; return rows.first?.stamp
    }
    @discardableResult func saveLocalSettings(_ request: LocalSettingsRequest) throws -> LocalSettings {
        let context = ModelContext(container)
        if let receipt = try context.fetch(FetchDescriptor<StoredSettingsSave>()).first(where: { $0.id == request.operationID }) {
            if let fingerprint = String(data: receipt.request, encoding: .utf8), fingerprint.hasPrefix("sha256:") {
                guard fingerprint == "sha256:" + digest(try encode(request)) else { throw StoreError.operationConflict }
            } else {
                guard try JSONDecoder().decode(LocalSettingsRequest.self, from: receipt.request) == request else { throw StoreError.operationConflict }
            }
            return try JSONDecoder().decode(LocalSettings.self, from: receipt.result)
        }
        guard request.base == (try localSettings()) else { throw StoreError.staleRevision }
        let value = try request.result()
        try beforeOutfitSave()
        if let record = try context.fetch(FetchDescriptor<StoredLocalSettings>()).first { record.payload = try encode(value) }
        else { context.insert(try StoredLocalSettings(value)) }
        let removed = Set((request.base.feedback ?? []).map(\.id)).subtracting((value.feedback ?? []).map(\.id))
        if !removed.isEmpty {
            for receipt in try context.fetch(FetchDescriptor<StoredSettingsSave>()) {
                var prior = try JSONDecoder().decode(LocalSettings.self, from: receipt.result)
                if !(Set((prior.feedback ?? []).map(\.id)).intersection(removed)).isEmpty {
                    prior.feedback?.removeAll { removed.contains($0.id) }
                    receipt.result = try encode(prior)
                    if let oldRequest = try? JSONDecoder().decode(LocalSettingsRequest.self, from: receipt.request) {
                        receipt.request = Data(("sha256:" + digest(try encode(oldRequest))).utf8)
                    }
                }
            }
        }
        context.insert(try StoredSettingsSave(request, result: value, fingerprint: digest(try encode(request)))); try commit(context); try afterOutfitSave(); return value
    }
}
