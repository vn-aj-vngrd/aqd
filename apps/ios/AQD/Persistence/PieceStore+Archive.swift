import AQDCore
import CoreData
import CryptoKit
import Darwin
import Foundation
import SwiftData

extension PieceStore {
    var localDirectory: URL { directory }
    func archiveSeed() throws -> LocalArchiveSeed {
        let stamp = try mutationStamp()
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("AQD-archive-\(UUID().uuidString)", isDirectory: true)
        do {
            try LocalArchiveIO.protectedDirectory(temporary); try LocalArchiveIO.protectedDirectory(temporary.appendingPathComponent("media"))
            guard try FileManager.default.attributesOfItem(atPath: directory.path)[.type] as? FileAttributeType == .typeDirectory,
                  try FileManager.default.attributesOfItem(atPath: mediaDirectory.path)[.type] as? FileAttributeType == .typeDirectory else { throw StoreError.unsafeMediaPath }
            try LocalArchiveIO.write(LocalArchiveIO.read(directory.appendingPathComponent("schema-version"), maximum: 100), to: temporary.appendingPathComponent("schema-version"))
            let photos = Set(try ModelContext(container).fetch(FetchDescriptor<StoredPhoto>()).map { $0.id.uuidString })
            let files = try FileManager.default.contentsOfDirectory(at: mediaDirectory, includingPropertiesForKeys: nil).filter { photos.contains(String($0.lastPathComponent.prefix(36))) }
            return LocalArchiveSeed(directory: temporary, database: directory.appendingPathComponent("wardrobe.store"), media: files, stamp: stamp)
        } catch { try? FileManager.default.removeItem(at: temporary); throw error }
    }
    func validateArchiveContents() throws -> LocalArchiveSummary {
        let owner = try todayConfiguration().ownerID
        let owned = try pieces() + pieces(archived: true), outfits = try outfits(), themes = try themes(), plans = try planDefinitions(), entries = try planEntries(), wear = try wearRecords(), fits = try fitMemories(), conversations = try agentConversations(), cards = try todayPersonalCards()
        let experience = try localExperience(); try experience.validated()
        _ = try localSettings(); _ = try weatherState(); _ = try todayDraft(); _ = try todayUndo()
        _ = try identityDraft(); _ = try localIdentity(); _ = try fitDraft(); _ = try outfitDraft(); _ = try themeDraft(); _ = try planDraft(); _ = try planAuthoringDraft(); _ = try wearDraft()
        let context = ModelContext(container)
        for record in try context.fetch(FetchDescriptor<StoredPieceDraft>()) { _ = try archivePieceDraft(record) }
        let pieceIDs = Set(owned.map(\.id)), outfitIDs = Set(outfits.map(\.id)), planIDs = Set(plans.map(\.id))
        guard outfits.allSatisfy({ $0.ownerID == owner && Set($0.pieceIDs).isSubset(of: pieceIDs) }),
              themes.allSatisfy({ $0.ownerID == owner && Set($0.outfitIDs).isSubset(of: outfitIDs) }),
              entries.allSatisfy({ $0.ownerID == owner && ($0.outfitID.map { outfitIDs.contains($0) } ?? true) }),
              Set(owned.map(\.id)).count == owned.count, Set(outfits.map(\.id)).count == outfits.count,
              Set(plans.map(\.id)).count == plans.count, Set(entries.map(\.id)).count == entries.count else { throw StoreError.invalidRecord }
        // Entries created individually predate grouped definitions; their stable plan IDs remain valid.
        // Only trips carry packing state; a routine or weekly plan has none and must not fail validation.
        for plan in plans where plan.trip != nil { _ = try packingState(planID: plan.id) }
        for state in try context.fetch(FetchDescriptor<StoredPackingState>()) { guard planIDs.contains(try state.value().planID) else { throw StoreError.invalidRecord } }
        var photoOwners = owned.map { (id: $0.photoID, recipe: $0.photoRecipe) }
        photoOwners += try personalPhotoOwners(in: context) + todayPhotoOwners(in: context)
        for record in try context.fetch(FetchDescriptor<StoredPieceDraft>()) {
            let draft = try archivePieceDraft(record); if let id = draft.photoID { photoOwners.append((id: id, recipe: draft.photoRecipe)) }
        }
        let sources = try photoSources(in: context)
        for photo in photoOwners {
            _ = try originalPhoto(id: photo.id); _ = try photoRendition(id: photo.id, recipe: photo.recipe); _ = try photoThumbnail(id: photo.id, recipe: photo.recipe)
            if let original = sources[photo.id] { _ = try originalPhoto(id: original) }
        }
        var drafts = try context.fetchCount(FetchDescriptor<StoredPieceDraft>())
        drafts += [try outfitDraft() != nil, try themeDraft() != nil, try planDraft() != nil, try planAuthoringDraft() != nil,
                   try wearDraft() != nil, try fitDraft() != nil, try identityDraft() != nil, try todayDraft() != nil, experience.styleDraft != nil].filter { $0 }.count
        return LocalArchiveSummary(ownerID: owner, pieces: owned.count, outfits: outfits.count, themes: themes.count, plans: plans.count,
            entries: entries.count, wear: wear.count, fits: fits.count, conversations: conversations.count, personalCards: cards.count, drafts: drafts)
    }
}

struct ArchiveOperationDigest: Codable { let digest: String }
extension PieceStore {
    func archivePieceDraft(_ record: StoredPieceDraft) throws -> PieceDraft {
        let draft = try JSONDecoder().decode(PieceDraft.self, from: record.payload)
        guard draft.id == record.id, draft.itemID == record.itemID else { throw StoreError.invalidRecord }; try draft.photoRecipe.validated(); return draft
    }
    /// Apply only to the disposable export snapshot. Preserve pending recovery payloads.
    func compactArchiveAcknowledgments() throws {
        let context = ModelContext(container), active = try todayDraft()?.operationID
        var changed = false
        for receipt in try context.fetch(FetchDescriptor<StoredTodaySave>()) where receipt.id != active {
            if (try? JSONDecoder().decode(ArchiveOperationDigest.self, from: receipt.request)) == nil {
                let request = try JSONDecoder().decode(TodayLayoutDraft.self, from: receipt.request)
                receipt.request = try encode(ArchiveOperationDigest(digest: digest(try encode(request)))); receipt.result = Data(); changed = true
            }
        }
        for task in try context.fetch(FetchDescriptor<StoredTodayCardDeletion>()) where task.acknowledged {
            if (try? JSONDecoder().decode(ArchiveOperationDigest.self, from: task.payload)) == nil {
                let request = try task.value(); task.payload = try encode(ArchiveOperationDigest(digest: digest(try encode(request)))); changed = true
            }
        }
        if changed { try commit(context) }
    }
}

extension PieceStore {
    static func archiveSchema(at url: URL) throws -> Int {
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: url, options: [NSReadOnlyPersistentStoreOption: true])
        for (index, version) in LocalMigrationPlan.schemas.enumerated() {
            let schema = Schema(versionedSchema: version), model: NSManagedObjectModel?
            if #available(iOS 26, *) { model = NSManagedObjectModel.makeManagedObjectModel(for: schema) }
            else { model = NSManagedObjectModel().makeManagedObjectModel(for: schema) }
            if let model, (metadata[NSStoreModelVersionHashesKey] as? [String: Data]) == model.entityVersionHashesByName { return index + 1 }
        }
        throw LocalArchiveError.newer
    }
}
