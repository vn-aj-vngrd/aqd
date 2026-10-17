import AQDCore
import CoreData
import CryptoKit
import Darwin
import Foundation
import SwiftData

extension PieceStore {
    func photoSources(in context: ModelContext) throws -> [UUID: UUID] {
        var sources: [UUID: UUID] = [:]
        for value in try context.fetch(FetchDescriptor<StoredPhotoSource>()) {
            guard value.id != value.originalID, sources.updateValue(value.originalID, forKey: value.id) == nil else { throw StoreError.invalidRecord }
        }
        guard sources.values.allSatisfy({ sources[$0] == nil }) else { throw StoreError.invalidRecord }
        return sources
    }
    func photoReferences(_ ids: [UUID], context: ModelContext) throws -> Set<UUID> {
        let sources = try photoSources(in: context)
        return Set(ids + ids.compactMap { sources[$0] })
    }
    func backgroundOriginalID(for id: UUID) throws -> UUID? { try photoSources(in: ModelContext(container))[id] }
    func acceptBackgroundPhoto(_ prepared: PreparedPhoto, originalID: UUID) throws -> UUID {
        let context = ModelContext(container), sources = try photoSources(in: context)
        guard allowsSave, prepared.id != originalID, sources[originalID] == nil else { throw StoreError.invalidRecord }
        guard let original = try context.fetch(FetchDescriptor<StoredPhoto>()).first(where: { $0.id == originalID }),
              original.pixelWidth == prepared.pixelWidth, original.pixelHeight == prepared.pixelHeight else { throw StoreError.invalidRecord }
        _ = try originalPhoto(id: originalID)
        let id = try acceptPhoto(prepared)
        if let existing = sources[id] { guard existing == originalID else { throw StoreError.operationConflict } }
        else { context.insert(StoredPhotoSource(id: id, originalID: originalID)) }
        try queueCleanup(photoID: id, context: context); try commit(context)
        return id
    }
}
