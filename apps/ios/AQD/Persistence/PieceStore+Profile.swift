import AQDCore
import CoreData
import CryptoKit
import Darwin
import Foundation
import SwiftData

extension PieceStore {
    func personalPhotoOwners(in context: ModelContext) throws -> [(id: UUID, recipe: PhotoEditRecipe)] {
        var owners: [(id: UUID, recipe: PhotoEditRecipe)] = try todayPhotoOwners(in: context)
        func append(_ id: UUID?, _ recipe: PhotoEditRecipe) { if let id { owners.append((id, recipe)) } }
        for record in try context.fetch(FetchDescriptor<StoredLocalIdentity>()) {
            let value = try record.value(); append(value.photoID, value.photoRecipe ?? .fitOriginal)
        }
        for record in try context.fetch(FetchDescriptor<StoredIdentityDraft>()) {
            let value = try record.value(); append(value.photoID, value.photoRecipe ?? .fitOriginal)
            if let base = value.base { append(base.photoID, base.photoRecipe ?? .fitOriginal) }
        }
        for record in try context.fetch(FetchDescriptor<StoredFitMemory>()) {
            let value = try record.value(); append(value.photoID, value.photoRecipe)
        }
        for record in try context.fetch(FetchDescriptor<StoredFitDraft>()) {
            let value = try record.value(); append(value.value.photoID, value.value.photoRecipe)
            if let base = value.base { append(base.photoID, base.photoRecipe) }
        }
        return owners
    }
    func personalPhotoReferences(in context: ModelContext) throws -> [UUID] {
        try personalPhotoOwners(in: context).map { $0.id }
    }
    func localIdentity() throws -> LocalProfileIdentity? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredLocalIdentity>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let value = try records.first?.value() else { return nil }
        guard value.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        return value
    }
    func identityDraft() throws -> LocalIdentityDraft? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredIdentityDraft>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let value = try records.first?.value() else { return nil }
        guard value.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        return value
    }
    func saveIdentityDraft(_ draft: LocalIdentityDraft) throws {
        guard allowsSave, draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        try draft.validatedForRetention()
        guard try savedIdentity(for: draft) == nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredIdentityDraft>())
        guard records.count <= 1, records.first.map({ $0.id == draft.id }) ?? true else { throw StoreError.operationConflict }
        if let record = records.first {
            if let previous = try record.value().photoID { try queueCleanup(photoID: previous, recipeDigest: try cleanupRecipeDigest(record.value().photoRecipe ?? .fitOriginal), context: context) }
            record.payload = try encode(draft)
        } else { context.insert(try StoredIdentityDraft(draft)) }
        try commit(context)
    }
    func savedIdentity(for draft: LocalIdentityDraft) throws -> LocalProfileIdentity? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredIdentitySave>()).filter { $0.id == draft.operationID }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let receipt = records.first else { return nil }
        guard try JSONDecoder().decode(LocalIdentityDraft.self, from: receipt.request) == draft else { throw StoreError.operationConflict }
        let value = try JSONDecoder().decode(LocalProfileIdentity.self, from: receipt.result)
        guard value == (try draft.result()) else { throw StoreError.invalidRecord }
        return value
    }
    func saveIdentity(_ draft: LocalIdentityDraft) throws -> LocalProfileIdentity {
        if let saved = try savedIdentity(for: draft) { return saved }
        guard allowsSave, draft.ownerID == (try todayConfiguration().ownerID), try identityDraft() == draft else { throw StoreError.staleDraft }
        guard try localIdentity() == draft.base else { throw StoreError.staleRevision }
        let result = try draft.result()
        if let photo = result.photoID, photo != draft.base?.photoID || result.photoRecipe != draft.base?.photoRecipe {
            _ = try photoRendition(id: photo, recipe: result.photoRecipe ?? .fitOriginal)
            _ = try photoThumbnail(id: photo, recipe: result.photoRecipe ?? .fitOriginal)
        }
        let context = ModelContext(container)
        if let record = try context.fetch(FetchDescriptor<StoredLocalIdentity>()).first { record.payload = try encode(result) }
        else { context.insert(try StoredLocalIdentity(result)) }
        if let previous = draft.base?.photoID { try queueCleanup(photoID: previous, recipeDigest: try cleanupRecipeDigest(draft.base?.photoRecipe ?? .fitOriginal), context: context) }
        context.insert(try StoredIdentitySave(draft, result: result))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
        return result
    }
    func finishIdentityDraft(_ draft: LocalIdentityDraft, discarding: Bool = false) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let saved = try savedIdentity(for: draft)
        guard discarding ? saved == nil : saved != nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        guard let record = try context.fetch(FetchDescriptor<StoredIdentityDraft>()).first, try record.value() == draft else { throw StoreError.staleDraft }
        if let id = draft.photoID { try queueCleanup(photoID: id, recipeDigest: try cleanupRecipeDigest(draft.photoRecipe ?? .fitOriginal), context: context) }
        if let id = draft.base?.photoID { try queueCleanup(photoID: id, recipeDigest: try cleanupRecipeDigest(draft.base?.photoRecipe ?? .fitOriginal), context: context) }
        context.delete(record); try commit(context)
    }
}

extension PieceStore {
    func fitMemories() throws -> [FitMemory] {
        let owner = try todayConfiguration().ownerID
        let values = try ModelContext(container).fetch(FetchDescriptor<StoredFitMemory>()).map { try $0.value() }
        guard values.allSatisfy({ $0.ownerID == owner }) else { throw StoreError.invalidRecord }
        return values.sorted { $0.day.key == $1.day.key ? $0.id.uuidString < $1.id.uuidString : $0.day.key > $1.day.key }
    }
    func fitDraft() throws -> FitDraft? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredFitDraft>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let value = try records.first?.value() else { return nil }
        guard value.value.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }; return value
    }
    func saveFitDraft(_ draft: FitDraft) throws {
        guard allowsSave, draft.value.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        try draft.validated(requireContent: false)
        guard try savedFit(for: draft) == nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredFitDraft>())
        guard records.count <= 1, records.first.map({ $0.id == draft.id }) ?? true else { throw StoreError.operationConflict }
        if let record = records.first {
            if let previous = try record.value().value.photoID { try queueCleanup(photoID: previous, recipeDigest: try cleanupRecipeDigest(record.value().value.photoRecipe), context: context) }
            record.payload = try encode(draft)
        } else { context.insert(try StoredFitDraft(draft)) }
        try commit(context)
    }
    func savedFit(for draft: FitDraft) throws -> FitMemory? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredFitSave>()).filter { $0.id == draft.operationID }
        guard records.count <= 1 else { throw StoreError.invalidRecord }; guard let receipt = records.first else { return nil }
        guard try JSONDecoder().decode(FitDraft.self, from: receipt.request) == draft else { throw StoreError.operationConflict }
        let result = try JSONDecoder().decode(FitMemory.self, from: receipt.result)
        guard result == (try draft.result()) else { throw StoreError.invalidRecord }; return result
    }
    func saveFit(_ draft: FitDraft) throws -> FitMemory {
        if let saved = try savedFit(for: draft) { return saved }
        guard allowsSave, draft.value.ownerID == (try todayConfiguration().ownerID), try fitDraft() == draft else { throw StoreError.staleDraft }
        let current = try fitMemories().first { $0.id == draft.value.id }
        guard current == draft.base else { throw StoreError.staleRevision }
        let result = try draft.result()
        if let snapshot = result.outfit, snapshot != draft.base?.outfit {
            guard let outfit = try outfit(id: snapshot.id),
                  try FitOutfitSnapshot(outfit: outfit, pieces: ownedPiecesForWear()) == snapshot else { throw FitValidationError.outfitUnavailable }
        }
        if let id = result.photoID, id != draft.base?.photoID || result.photoRecipe != draft.base?.photoRecipe {
            _ = try photoRendition(id: id, recipe: result.photoRecipe)
            _ = try photoThumbnail(id: id, recipe: result.photoRecipe)
        }
        let context = ModelContext(container)
        if let record = try context.fetch(FetchDescriptor<StoredFitMemory>()).first(where: { $0.id == result.id }) { record.payload = try encode(result) }
        else { context.insert(try StoredFitMemory(result)) }
        if let old = draft.base?.photoID { try queueCleanup(photoID: old, recipeDigest: try cleanupRecipeDigest(draft.base?.photoRecipe ?? .fitOriginal), context: context) }
        context.insert(try StoredFitSave(draft, result: result))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave(); return result
    }
    func finishFitDraft(_ draft: FitDraft, discarding: Bool = false) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let saved = try savedFit(for: draft)
        guard discarding ? saved == nil : saved != nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        guard let record = try context.fetch(FetchDescriptor<StoredFitDraft>()).first, try record.value() == draft else { throw StoreError.staleDraft }
        if let id = draft.value.photoID { try queueCleanup(photoID: id, recipeDigest: try cleanupRecipeDigest(draft.value.photoRecipe), context: context) }
        if let id = draft.base?.photoID { try queueCleanup(photoID: id, recipeDigest: try cleanupRecipeDigest(draft.base?.photoRecipe ?? .fitOriginal), context: context) }
        context.delete(record); try commit(context)
    }
    func deleteFit(_ request: FitDeletionRequest) throws {
        let context = ModelContext(container)
        if let proof = try context.fetch(FetchDescriptor<StoredFitDeletion>()).first(where: { $0.id == request.operationID }) {
            guard try JSONDecoder().decode(FitDeletionRequest.self, from: proof.request) == request else { throw StoreError.operationConflict }; return
        }
        guard allowsSave, request.memory.ownerID == (try todayConfiguration().ownerID),
              let record = try context.fetch(FetchDescriptor<StoredFitMemory>()).first(where: { $0.id == request.memory.id }),
              try record.value() == request.memory else { throw StoreError.staleRevision }
        if let id = request.memory.photoID { try queueCleanup(photoID: id, recipeDigest: try cleanupRecipeDigest(request.memory.photoRecipe), context: context) }
        context.delete(record); context.insert(try StoredFitDeletion(request))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
}
