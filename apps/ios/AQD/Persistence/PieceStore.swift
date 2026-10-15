import AQDCore
import Foundation
import CryptoKit
import Darwin
import CoreData
import SwiftData

@Model
final class StoredPiece {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String
    var photoID: UUID
    var photoQuarterTurns: Int = 0
    var photoCropX: Double?
    var photoCropY: Double?
    var photoCropWidth: Double?
    var photoCropHeight: Double?
    var color: String
    var brand: String
    var size: String
    var fit: String
    var material: String
    var season: String
    var condition: String
    var ownershipAge: String
    var tags: [String]
    var notes: String
    var priorWearCount: Int?
    var availability: String
    var revision: Int
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    init(_ piece: WardrobePiece) {
        id = piece.id
        name = piece.name
        category = piece.category.rawValue
        photoID = piece.photoID
        photoQuarterTurns = piece.photoRecipe.quarterTurns
        photoCropX = piece.photoRecipe.crop?.x
        photoCropY = piece.photoRecipe.crop?.y
        photoCropWidth = piece.photoRecipe.crop?.width
        photoCropHeight = piece.photoRecipe.crop?.height
        color = piece.details.color
        brand = piece.details.brand
        size = piece.details.size
        fit = piece.details.fit
        material = piece.details.material
        season = piece.details.season
        condition = piece.details.condition
        ownershipAge = piece.details.ownershipAge
        tags = piece.details.tags
        notes = piece.details.notes
        priorWearCount = piece.details.priorWearCount
        availability = piece.availability.rawValue
        revision = piece.revision
        isArchived = piece.isArchived
        createdAt = piece.createdAt
        updatedAt = piece.updatedAt
    }

    func recipe() throws -> PhotoEditRecipe {
        let components = [photoCropX, photoCropY, photoCropWidth, photoCropHeight]
        guard components.allSatisfy({ $0 == nil }) || components.allSatisfy({ $0 != nil }) else {
            throw PieceStore.StoreError.invalidRecord
        }
        let crop: NormalizedPhotoCrop?
        if let x = photoCropX, let y = photoCropY, let w = photoCropWidth, let h = photoCropHeight {
            crop = .init(x: x, y: y, width: w, height: h)
        } else { crop = nil }
        let result = PhotoEditRecipe(quarterTurns: photoQuarterTurns, crop: crop)
        try result.validated()
        return result
    }

    func value() throws -> WardrobePiece {
        guard let category = PieceCategory(rawValue: category),
              let availability = PieceAvailability(rawValue: availability), revision > 0 else {
            throw PieceStore.StoreError.invalidRecord
        }
        return WardrobePiece(id: id, name: name, category: category, photoID: photoID,
                             details: PieceDetails(color: color, brand: brand, size: size, fit: fit, material: material,
                                                   season: season, condition: condition, ownershipAge: ownershipAge,
                                                   tags: tags, notes: notes, priorWearCount: priorWearCount),
                             availability: availability, revision: revision, isArchived: isArchived,
                             createdAt: createdAt, updatedAt: updatedAt, photoRecipe: try recipe())
    }

    func apply(_ piece: WardrobePiece) {
        name = piece.name
        category = piece.category.rawValue
        photoID = piece.photoID
        photoQuarterTurns = piece.photoRecipe.quarterTurns
        photoCropX = piece.photoRecipe.crop?.x
        photoCropY = piece.photoRecipe.crop?.y
        photoCropWidth = piece.photoRecipe.crop?.width
        photoCropHeight = piece.photoRecipe.crop?.height
        color = piece.details.color
        brand = piece.details.brand
        size = piece.details.size
        fit = piece.details.fit
        material = piece.details.material
        season = piece.details.season
        condition = piece.details.condition
        ownershipAge = piece.details.ownershipAge
        tags = piece.details.tags
        notes = piece.details.notes
        priorWearCount = piece.details.priorWearCount
        availability = piece.availability.rawValue
        revision = piece.revision
        isArchived = piece.isArchived
        updatedAt = piece.updatedAt
    }
}

@Model
final class StoredPhoto {
    @Attribute(.unique) var id: UUID
    var pixelWidth: Int
    var pixelHeight: Int

    init(id: UUID, pixelWidth: Int, pixelHeight: Int) {
        self.id = id
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}

/// Exact operation acknowledgment proof, not a historical media owner.
/// A retry returns this immutable result even if superseded media has been released.
@Model
final class StoredPieceSave {
    @Attribute(.unique) var id: UUID
    var itemID: UUID
    var draftDigest: String
    var snapshot: Data

    init(id: UUID, itemID: UUID, draftDigest: String, snapshot: Data) {
        self.id = id
        self.itemID = itemID
        self.draftDigest = draftDigest
        self.snapshot = snapshot
    }
}

@Model
final class StoredPieceDraft {
    @Attribute(.unique) var id: UUID
    var itemID: UUID
    var operationID: UUID
    var payload: Data
    var updatedAt: Date

    init(draft: PieceDraft, operationID: UUID, payload: Data) {
        self.id = draft.id
        self.itemID = draft.itemID
        self.operationID = operationID
        self.payload = payload
        self.updatedAt = Date()
    }
}

/// Minimal local deletion acknowledgment prevents retry resurrecting a removed identity.
/// Cleanup candidates are committed with record removal, then reconciled separately.
/// This is not a remote-sync tombstone.
@Model
final class StoredPieceDeletion {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var itemID: UUID
    var expectedRevision: Int
    var pendingPhotoIDs: [UUID] = []

    init(operationID: UUID, itemID: UUID, expectedRevision: Int, pendingPhotoIDs: [UUID]) {
        id = operationID
        self.itemID = itemID
        self.expectedRevision = expectedRevision
        self.pendingPhotoIDs = pendingPhotoIDs
    }
}

/// A local cleanup intent, not a deletion receipt or a claim that media is unowned.
/// Stage it before file writes, and with every relinquished draft reference.
@Model
final class StoredPhotoCleanup {
    @Attribute(.unique) var id: UUID
    var recipeDigests: [String] = []

    init(photoID: UUID) { id = photoID }
}

enum LocalSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [StoredPiece.self, StoredPhoto.self, StoredPieceSave.self, StoredPieceDraft.self, StoredPieceDeletion.self, StoredTodayConfiguration.self] }
}

enum LocalSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV1.models + [StoredPhotoCleanup.self] }
}

enum LocalSchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(3, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV2.models + [StoredLocalExperience.self] }
}

enum LocalSchemaV4: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(4, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV3.models + [StoredOutfit.self, StoredOutfitDraft.self, StoredOutfitSave.self] }
}

enum LocalSchemaV5: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(5, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV4.models + [StoredOutfitTheme.self, StoredThemeDraft.self, StoredThemeSave.self] }
}

enum LocalSchemaV6: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(6, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV5.models + [StoredOutfitPlanEntry.self, StoredOutfitPlanDraft.self, StoredOutfitPlanSave.self] }
}

enum LocalMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [LocalSchemaV1.self, LocalSchemaV2.self, LocalSchemaV3.self, LocalSchemaV4.self, LocalSchemaV5.self, LocalSchemaV6.self] }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: LocalSchemaV1.self, toVersion: LocalSchemaV2.self),
         .lightweight(fromVersion: LocalSchemaV2.self, toVersion: LocalSchemaV3.self),
         .lightweight(fromVersion: LocalSchemaV3.self, toVersion: LocalSchemaV4.self),
         .lightweight(fromVersion: LocalSchemaV4.self, toVersion: LocalSchemaV5.self),
         .lightweight(fromVersion: LocalSchemaV5.self, toVersion: LocalSchemaV6.self)]
    }
}

/// All record operations are serialized on the UI actor and return immutable values.
/// Media is finalized before references are saved; it is not a database transaction.
@MainActor
final class PieceStore {
    enum StoreError: Error {
        case missingPhoto, invalidRecord, existingPiece, conflictingMedia, operationConflict, staleDraft, staleRevision, deletedPiece, unsupportedStore, corruptStore, cleanupPending, unsafeMediaPath
    }

    private let directory: URL
    private let mediaDirectory: URL
    private let container: ModelContainer
    private let allowsSave: Bool
    private let removeMediaFile: (URL) throws -> Void
    private let writeMediaFile: (Data, URL) throws -> Void
    private let beforeStyleSave: () throws -> Void
    private let afterStyleSave: () throws -> Void
    private let beforeExperienceRead: () throws -> Void
    private let beforeOutfitSave: () throws -> Void
    private let afterOutfitSave: () throws -> Void

    init(directory: URL, allowsSave: Bool = true,
         removeMediaFile: @escaping (URL) throws -> Void = { try FileManager.default.removeItem(at: $0) },
         beforeStyleSave: @escaping () throws -> Void = {},
         afterStyleSave: @escaping () throws -> Void = {},
         beforeExperienceRead: @escaping () throws -> Void = {},
         beforeOutfitSave: @escaping () throws -> Void = {},
         afterOutfitSave: @escaping () throws -> Void = {},
         writeMediaFile: @escaping (Data, URL) throws -> Void = { data, url in
             try data.write(to: url, options: [.atomic, .completeFileProtection])
         }) throws {
        self.directory = directory
        self.allowsSave = allowsSave
        self.removeMediaFile = removeMediaFile
        self.writeMediaFile = writeMediaFile
        self.beforeStyleSave = beforeStyleSave
        self.afterStyleSave = afterStyleSave
        self.beforeExperienceRead = beforeExperienceRead
        self.beforeOutfitSave = beforeOutfitSave
        self.afterOutfitSave = afterOutfitSave
        self.mediaDirectory = directory.appendingPathComponent("media", isDirectory: true)
        let storeURL = directory.appendingPathComponent("wardrobe.store")
        let versionURL = directory.appendingPathComponent("schema-version")
        let version = Data("AQD-piece-store:6".utf8)
        let previousVersions = [Data("AQD-piece-store:1".utf8), Data("AQD-piece-store:2".utf8), Data("AQD-piece-store:3".utf8), Data("AQD-piece-store:4".utf8), Data("AQD-piece-store:5".utf8)]
        // A dangling symlink is existing storage too, not permission to create
        // a fresh store through a redirected path.
        let hasStore = (try? FileManager.default.attributesOfItem(atPath: storeURL.path)) != nil
        let hasVersion = FileManager.default.fileExists(atPath: versionURL.path)
        let schema = Schema(versionedSchema: LocalSchemaV6.self)
        var needsTodaySeed = !hasStore
        var maySeedExperience = !hasVersion
        // Never create an empty replacement for unrecognized, incomplete or newer storage.
        if hasVersion {
            let marker = try Data(contentsOf: versionURL)
            guard marker == version || previousVersions.contains(marker) else { throw StoreError.unsupportedStore }
            maySeedExperience = marker == Data("AQD-piece-store:1".utf8) || marker == Data("AQD-piece-store:2".utf8)
            guard hasStore else { throw StoreError.corruptStore }
            do {
                _ = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL,
                                                                               options: [NSReadOnlyPersistentStoreOption: true])
            } catch { throw StoreError.corruptStore }
        } else if hasStore {
            // Recognize only the two current-schema first-use crash windows,
            // before any writable open or migration can alter unmarked bytes.
            needsTodaySeed = try Self.interruptedBootstrapNeedsToday(storeURL: storeURL, schema: schema)
        }
        if needsTodaySeed && !allowsSave { throw StoreError.corruptStore }
        try Self.createProtectedDirectory(directory)
        try Self.createProtectedDirectory(mediaDirectory)
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: allowsSave,
            cloudKitDatabase: .none
        )
        do {
            container = try ModelContainer(for: schema, migrationPlan: LocalMigrationPlan.self, configurations: [configuration])
        } catch {
            // No reset, fallback container or byte deletion on incompatible/corrupt stores.
            throw StoreError.unsupportedStore
        }
        if needsTodaySeed {
            // Seed only fresh or validated empty bootstrap storage. A committed
            // stock Today row retains its original owner and widget identities.
            let context = ModelContext(container)
            // The disposable DB/WAL inspection is an earlier snapshot.
            // Revalidate the opened store rather than upserting over a row that
            // was absent from the earlier inspection copy.
            if try Self.bootstrapNeedsToday(in: context) {
                context.insert(StoredTodayConfiguration(TodayConfiguration(ownerID: UUID())))
                try commit(context)
            }
        }
        let experienceContext = ModelContext(container)
        if try experienceContext.fetchCount(FetchDescriptor<StoredLocalExperience>()) == 0 {
            guard allowsSave, maySeedExperience else { throw StoreError.corruptStore }
            // Existing closets bypass first-run entry; their records are never
            // reconstructed from illustrative onboarding or tour content.
            experienceContext.insert(try StoredLocalExperience(LocalExperience(enteredPrivateSpace: hasStore && hasVersion)))
            try commit(experienceContext)
        }
        _ = try localExperience()
        // Advance the marker only after the native preservation migration succeeds.
        if allowsSave { try version.write(to: versionURL, options: [.atomic, .completeFileProtection]) }
        try protectStoreFiles()
    }

    private static func interruptedBootstrapNeedsToday(storeURL: URL, schema: Schema) throws -> Bool {
        // Even read-only Core Data/SwiftData opens may change SQLite sidecars or
        // metadata. Only inspect a disposable copy, never the unmarked source.
        let inspectionDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AQD-bootstrap-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: inspectionDirectory) }
        do {
            try createProtectedDirectory(inspectionDirectory)
            let sourceDirectory = storeURL.deletingLastPathComponent()
            guard try FileManager.default.attributesOfItem(atPath: sourceDirectory.path)[.type] as? FileAttributeType == .typeDirectory else {
                throw StoreError.unsupportedStore
            }
            // First-use stores are tiny. Bound both memory and transient disk use;
            // large unmarked stores are not a supported bootstrap recovery case.
            var remainingBytes = 32 * 1024 * 1024
            for suffix in ["", "-wal"] {
                let source = sourceDirectory.appendingPathComponent(storeURL.lastPathComponent + suffix)
                let attributes: [FileAttributeKey: Any]
                do { attributes = try FileManager.default.attributesOfItem(atPath: source.path) }
                catch let error as CocoaError where error.code == .fileReadNoSuchFile && suffix == "-wal" { continue }
                guard attributes[.type] as? FileAttributeType == .typeRegular,
                      source.resolvingSymlinksInPath().standardizedFileURL == sourceDirectory.resolvingSymlinksInPath()
                        .appendingPathComponent(source.lastPathComponent).standardizedFileURL else {
                    throw StoreError.unsupportedStore
                }
                // O_NOFOLLOW also refuses a leaf symlink substituted after the
                // path check. fstat validates the file actually being copied.
                let descriptor = open(source.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
                guard descriptor >= 0 else { throw StoreError.unsupportedStore }
                let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
                defer { try? handle.close() }
                var status = stat()
                guard fstat(descriptor, &status) == 0,
                      status.st_mode & S_IFMT == S_IFREG,
                      status.st_size >= 0, status.st_size <= remainingBytes else {
                    throw StoreError.unsupportedStore
                }
                var bytes = Data()
                while let chunk = try handle.read(upToCount: min(64 * 1024, remainingBytes - bytes.count + 1)), !chunk.isEmpty {
                    guard chunk.count <= remainingBytes - bytes.count else { throw StoreError.unsupportedStore }
                    bytes.append(chunk)
                }
                guard bytes.count == status.st_size else { throw StoreError.unsupportedStore }
                remainingBytes -= bytes.count
                let destination = inspectionDirectory.appendingPathComponent(source.lastPathComponent)
                try bytes.write(to: destination, options: [.atomic, .completeFileProtection])
                try protect(destination)
            }
            // Copy the exact WAL when present (not SHM, media or unknown files),
            // so committed rows not yet checkpointed into the DB remain visible.
            let needsToday = try inspectBootstrapCopyNeedsToday(
                storeURL: inspectionDirectory.appendingPathComponent(storeURL.lastPathComponent), schema: schema)
            // Fail closed on cleanup failure; defer retries on every error path.
            try FileManager.default.removeItem(at: inspectionDirectory)
            return needsToday
        } catch { throw StoreError.unsupportedStore }
    }

    private static func inspectBootstrapCopyNeedsToday(storeURL: URL, schema: Schema) throws -> Bool {
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType, at: storeURL, options: [NSReadOnlyPersistentStoreOption: true])
            let candidates = [(schema, 6), (Schema(versionedSchema: LocalSchemaV5.self), 5), (Schema(versionedSchema: LocalSchemaV4.self), 4), (Schema(versionedSchema: LocalSchemaV3.self), 3), (Schema(versionedSchema: LocalSchemaV2.self), 2)]
            let match = candidates.first { candidate in
                let model: NSManagedObjectModel?
                if #available(iOS 26, *) { model = NSManagedObjectModel.makeManagedObjectModel(for: candidate.0) }
                else { model = NSManagedObjectModel().makeManagedObjectModel(for: candidate.0) }
                return model.map { model in
                    (metadata[NSStoreModelVersionHashesKey] as? [String: Data]) == model.entityVersionHashesByName
                        && model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
                } ?? false
            }
            guard let (matchedSchema, storeVersion) = match else {
                throw StoreError.unsupportedStore
            }
            // No migration plan, no writable connection: exact native schema
            // compatibility must precede inspection of the narrowly allowed rows.
            let configuration = ModelConfiguration(schema: matchedSchema, url: storeURL,
                allowsSave: false, cloudKitDatabase: .none)
            let readOnly = try ModelContainer(for: matchedSchema, configurations: [configuration])
            let context = ModelContext(readOnly)
            return try bootstrapNeedsToday(in: context, storeVersion: storeVersion)
        } catch {
            // Refuse unmarked corrupt/foreign/populated layouts without reset.
            throw StoreError.unsupportedStore
        }
    }

    private static func bootstrapNeedsToday(in context: ModelContext, storeVersion: Int = 6) throws -> Bool {
        if storeVersion >= 6 {
            guard try context.fetchCount(FetchDescriptor<StoredOutfitPlanEntry>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredOutfitPlanDraft>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredOutfitPlanSave>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 5 {
            guard try context.fetchCount(FetchDescriptor<StoredOutfitTheme>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredThemeDraft>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredThemeSave>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 4 {
            guard try context.fetchCount(FetchDescriptor<StoredOutfit>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredOutfitDraft>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredOutfitSave>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 3 {
            let records = try context.fetch(FetchDescriptor<StoredLocalExperience>())
            if !records.isEmpty {
                guard records.count == 1, let record = records.first, record.id == 1,
                      try JSONDecoder().decode(LocalExperience.self, from: record.payload) == LocalExperience(enteredPrivateSpace: false) else {
                    throw StoreError.unsupportedStore
                }
            }
        }
        guard try context.fetchCount(FetchDescriptor<StoredPiece>()) == 0,
              try context.fetchCount(FetchDescriptor<StoredPhoto>()) == 0,
              try context.fetchCount(FetchDescriptor<StoredPieceDraft>()) == 0,
              try context.fetchCount(FetchDescriptor<StoredPieceSave>()) == 0,
              try context.fetchCount(FetchDescriptor<StoredPieceDeletion>()) == 0,
              try context.fetchCount(FetchDescriptor<StoredPhotoCleanup>()) == 0 else {
            throw StoreError.unsupportedStore
        }
        let records = try context.fetch(FetchDescriptor<StoredTodayConfiguration>())
        if records.isEmpty { return true }
        guard records.count == 1, let record = records.first else { throw StoreError.unsupportedStore }
        let today = try record.value()
        guard today.revision == 1,
              today.instances.map(\.kind) == [.todayLook, .weekInWear, .closetInUse] else {
            throw StoreError.unsupportedStore
        }
        return false
    }

    func todayConfiguration() throws -> TodayConfiguration {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredTodayConfiguration>())
        guard records.count == 1, let record = records.first else { throw StoreError.invalidRecord }
        return try record.value()
    }

    func localExperience() throws -> LocalExperience {
        try beforeExperienceRead()
        return try experienceRecord(in: ModelContext(container)).value
    }

    private func experienceRecord(in context: ModelContext) throws -> (record: StoredLocalExperience, value: LocalExperience) {
        let records = try context.fetch(FetchDescriptor<StoredLocalExperience>())
        guard records.count == 1, let record = records.first, record.id == 1 else { throw StoreError.invalidRecord }
        let value = try JSONDecoder().decode(LocalExperience.self, from: record.payload)
        try value.validated()
        return (record, value)
    }

    func saveStyleDraft(_ draft: StylePreferenceDraft) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        try draft.validated()
        let context = ModelContext(container)
        var (record, value) = try experienceRecord(in: context)
        guard value.pendingStyleReceipt == nil else { throw StoreError.operationConflict }
        if let existing = value.styleDraft, existing.id != draft.id { throw StoreError.operationConflict }
        guard (value.style?.revision ?? 0) == draft.baseRevision else { throw StoreError.staleRevision }
        value.styleDraft = draft
        record.payload = try JSONEncoder().encode(value)
        try commit(context)
    }

    func discardStyleDraft(id: UUID) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let context = ModelContext(container)
        var (record, value) = try experienceRecord(in: context)
        guard value.styleDraft?.id == id else { throw StoreError.operationConflict }
        value.styleDraft = nil
        record.payload = try JSONEncoder().encode(value)
        try commit(context)
    }

    func saveStylePreferences(_ draft: StylePreferenceDraft) throws -> SavedStylePreferences {
        try draft.validated()
        try draft.validatedForSave()
        let context = ModelContext(container)
        var (record, value) = try experienceRecord(in: context)
        if let receipt = value.style, receipt.operationID == draft.operationID {
            guard receipt.answers == draft.answers else { throw StoreError.operationConflict }
            return receipt
        }
        guard allowsSave else { throw StoreError.corruptStore }
        guard value.styleDraft == draft else { throw StoreError.staleDraft }
        guard (value.style?.revision ?? 0) == draft.baseRevision else { throw StoreError.staleRevision }
        let saved = SavedStylePreferences(answers: draft.answers, revision: draft.baseRevision + 1, operationID: draft.operationID)
        value.style = saved
        value.styleDraft = nil
        value.pendingStyleReceipt = draft
        record.payload = try JSONEncoder().encode(value)
        try beforeStyleSave()
        try commit(context)
        try afterStyleSave()
        return saved
    }

    func acknowledgeStyleReceipt(operationID: UUID, openCloset: Bool = false) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let context = ModelContext(container)
        var (record, value) = try experienceRecord(in: context)
        guard value.style?.operationID == operationID else { throw StoreError.operationConflict }
        guard value.pendingStyleReceipt != nil else { return }
        if openCloset {
            var entry = value.entryState
            entry.openMain()
            value.entry = entry
            value.enteredPrivateSpace = true
        } else if value.pendingStyleReceipt?.source == .onboarding {
            var entry = value.entryState
            entry.page = .introduction
            entry.tour = nil
            try entry.startTour(from: .introduction)
            value.entry = entry
            value.enteredPrivateSpace = false
        }
        value.pendingStyleReceipt = nil
        record.payload = try JSONEncoder().encode(value)
        try commit(context)
    }

    func saveEntryState(_ entry: PrivateEntryState) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        try entry.validated()
        let context = ModelContext(container)
        var (record, value) = try experienceRecord(in: context)
        value.entry = entry
        value.enteredPrivateSpace = entry.page == .main
        record.payload = try JSONEncoder().encode(value)
        try commit(context)
    }

    func acceptPhoto(_ photo: PreparedPhoto) throws -> UUID {
        guard allowsSave else { throw StoreError.corruptStore }
        try ensureOwnedMediaDirectory()
        let original = originalURL(id: photo.id)
        let thumbnail = mediaDirectory.appendingPathComponent("\(photo.id.uuidString)-thumbnail.jpg")
        // Refuse conflicts/foreign paths before claiming ownership of any files.
        for (url, data) in [(original, photo.originalData), (thumbnail, photo.thumbnailData)] {
            if (try? FileManager.default.attributesOfItem(atPath: url.path)) != nil {
                guard try readMedia(url) == data else { throw StoreError.conflictingMedia }
            }
        }
        // The durable intent precedes the first byte: failed/abandoned staging is
        // discoverable after restart even when no accepted-photo record was saved.
        let context = ModelContext(container)
        try queueCleanup(photoID: photo.id, context: context)
        try commit(context)
        if !FileManager.default.fileExists(atPath: original.path) {
            try writeMediaFile(photo.originalData, original)
        }
        if !FileManager.default.fileExists(atPath: thumbnail.path) {
            try writeMediaFile(photo.thumbnailData, thumbnail)
        }
        try Self.protect(original)
        try Self.protect(thumbnail)
        let id = photo.id
        let existing = try context.fetch(FetchDescriptor<StoredPhoto>(predicate: #Predicate { $0.id == id }))
        if existing.isEmpty {
            context.insert(StoredPhoto(id: id, pixelWidth: photo.pixelWidth, pixelHeight: photo.pixelHeight))
            try commit(context)
        }
        return id
    }

    func saveDraft(_ draft: PieceDraft, operationID: UUID) throws {
        // Incomplete metadata remains recoverable, but media coordinates must always be safe.
        try draft.photoRecipe.validated()
        let context = ModelContext(container)
        try ensureUnusedDeletionOperation(operationID, context: context)
        let itemID = draft.itemID
        guard try context.fetch(FetchDescriptor<StoredPieceDeletion>(predicate: #Predicate { $0.itemID == itemID })).isEmpty else {
            throw StoreError.deletedPiece
        }
        let payload = try encode(draft)
        if let prior = try context.fetch(FetchDescriptor<StoredPieceSave>(predicate: #Predicate { $0.id == operationID })).first {
            guard prior.draftDigest == digest(payload) else { throw StoreError.operationConflict }
            return // An acknowledged operation must not resurrect its draft.
        }
        let id = draft.id
        let sameOperation = try context.fetch(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.operationID == operationID }))
        guard sameOperation.allSatisfy({ $0.id == id && $0.itemID == itemID }) else { throw StoreError.operationConflict }
        if let stored = try context.fetch(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.id == id })).first {
            guard stored.itemID == itemID else { throw StoreError.staleDraft }
            let previous = try decodedDrafts(context).first { $0.0.id == id }?.1
            if let previous, let oldPhotoID = previous.photoID,
               oldPhotoID != draft.photoID || previous.photoRecipe != draft.photoRecipe {
                try queueCleanup(photoID: oldPhotoID,
                                 recipeDigest: try cleanupRecipeDigest(previous.photoRecipe), context: context)
            }
            stored.payload = payload
            stored.operationID = operationID
            stored.updatedAt = Date()
        } else {
            context.insert(StoredPieceDraft(draft: draft, operationID: operationID, payload: payload))
        }
        try commit(context)
    }

    /// Resume the same edit/operation, never silently choose between competing drafts.
    func recoverableDraft(itemID: UUID) throws -> RecoverablePieceDraft? {
        let context = ModelContext(container)
        let matches = try decodedDrafts(context).filter { $0.1.itemID == itemID }
        guard matches.count <= 1 else { throw StoreError.invalidRecord }
        guard let (stored, draft) = matches.first else { return nil }
        try ensureUnusedDeletionOperation(stored.operationID, context: context)
        let operationID = stored.operationID
        guard try context.fetch(FetchDescriptor<StoredPieceDeletion>(predicate: #Predicate { $0.itemID == itemID })).isEmpty else {
            throw StoreError.invalidRecord
        }
        let recovered = RecoverablePieceDraft(draft: draft, operationID: operationID)
        _ = try pendingSavedPiece(for: recovered)
        return recovered
    }

    /// Add piece resumes only a creation, never an existing piece's retained edit.
    /// Validate recovery records before selection; do not erase unrelated/stale drafts.
    func newPieceDraft() throws -> RecoverablePieceDraft? {
        let context = ModelContext(container)
        let savedIDs = Set(try context.fetch(FetchDescriptor<StoredPiece>()).map { try $0.value().id })
        let drafts = try decodedDrafts(context).filter {
            guard $0.1.baseRevision == nil else { return false }
            let pending = try pendingSavedPiece(for: RecoverablePieceDraft(draft: $0.1, operationID: $0.0.operationID))
            return pending != nil || !savedIDs.contains($0.1.itemID)
        }.sorted {
            $0.0.updatedAt == $1.0.updatedAt ? $0.0.id.uuidString < $1.0.id.uuidString : $0.0.updatedAt > $1.0.updatedAt
        }
        guard let (stored, draft) = drafts.first else { return nil }
        // Item recovery also refuses competing drafts and consumed operation identities.
        guard let recovered = try recoverableDraft(itemID: draft.itemID),
              recovered.operationID == stored.operationID else { throw StoreError.invalidRecord }
        return recovered
    }

    func latestDraft() throws -> RecoverablePieceDraft? {
        let context = ModelContext(container)
        let drafts = try context.fetch(FetchDescriptor<StoredPieceDraft>()).sorted {
            $0.updatedAt == $1.updatedAt ? $0.id.uuidString < $1.id.uuidString : $0.updatedAt > $1.updatedAt
        }
        guard let stored = drafts.first else { return nil }
        return RecoverablePieceDraft(draft: try JSONDecoder().decode(PieceDraft.self, from: stored.payload), operationID: stored.operationID)
    }

    func discardDraft(id: UUID) throws {
        let context = ModelContext(container)
        // Decode before removing any owner: corruption must not erase recovery data.
        for (stored, draft) in try decodedDrafts(context) where stored.id == id {
            if let photoID = draft.photoID {
                try queueCleanup(photoID: photoID, recipeDigest: try cleanupRecipeDigest(draft.photoRecipe), context: context)
            }
            context.delete(stored)
        }
        try commit(context)
    }

    private func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }

    /// Opt-in keeps the exact draft as a temporary media owner and presentation link.
    /// Retrying completed proof never recreates a link that was acknowledged.
    func savePiece(_ draft: PieceDraft, operationID: UUID, retainForPresentation: Bool = false) throws -> WardrobePiece {
        try draft.validated()
        guard let photoID = draft.photoID, let category = draft.category else { throw StoreError.invalidRecord }
        let context = ModelContext(container)
        try ensureUnusedDeletionOperation(operationID, context: context)
        let payload = try encode(draft)
        let digest = digest(payload)
        let prior = try context.fetch(FetchDescriptor<StoredPieceSave>(predicate: #Predicate { $0.id == operationID })).first
        if let prior {
            guard prior.draftDigest == digest else {
                throw StoreError.operationConflict
            }
            return try JSONDecoder().decode(WardrobePiece.self, from: prior.snapshot)
        }
        let itemID = draft.itemID
        let draftID = draft.id
        let sameItemDrafts = try context.fetch(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.itemID == itemID }))
        guard sameItemDrafts.allSatisfy({ $0.id == draftID }) else { throw StoreError.staleDraft }
        let sameOperation = try context.fetch(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.operationID == operationID }))
        guard sameOperation.allSatisfy({ $0.id == draftID }) else { throw StoreError.operationConflict }
        let savedDraft = try context.fetch(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.id == draftID })).first
        if let savedDraft {
            guard savedDraft.payload == payload, savedDraft.operationID == operationID else { throw StoreError.staleDraft }
        }
        try ensureUnusedDeletionOperation(operationID, context: context)
        let id = draft.itemID
        guard try context.fetch(FetchDescriptor<StoredPieceDeletion>(predicate: #Predicate { $0.itemID == id })).isEmpty else {
            throw StoreError.deletedPiece
        }
        let existing = try context.fetch(FetchDescriptor<StoredPiece>(predicate: #Predicate { $0.id == id })).first
        // Unchanged metadata edits remain possible even when existing media is missing.
        let existingRecipe = try existing?.recipe()
        if existing?.photoID != photoID || existingRecipe != draft.photoRecipe {
            if draft.photoRecipe != .fitOriginal {
                _ = try photoRendition(id: photoID, recipe: draft.photoRecipe)
                _ = try photoThumbnail(id: photoID, recipe: draft.photoRecipe)
            } else if existing?.photoID == photoID {
                _ = try originalPhoto(id: photoID)
                _ = try thumbnailPhoto(id: photoID)
            }
        }
        // Existing missing media remains editable. Only a new/replaced source needs accepted files.
        if existing?.photoID != photoID {
            let photos = try context.fetch(FetchDescriptor<StoredPhoto>(predicate: #Predicate { $0.id == photoID }))
            guard photos.count == 1 else { throw StoreError.missingPhoto }
            do {
                _ = try originalPhoto(id: photoID)
                _ = try thumbnailPhoto(id: photoID)
            } catch { throw StoreError.missingPhoto }
        }
        if let existing {
            guard let base = draft.baseRevision else { throw StoreError.existingPiece }
            guard base == existing.revision else { throw StoreError.staleRevision }
        } else if draft.baseRevision != nil {
            throw StoreError.staleRevision
        }
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let date = Date()
        let result = WardrobePiece(id: id, name: name, category: category, photoID: photoID,
                                  details: draft.details, availability: draft.availability,
                                  revision: (existing?.revision ?? 0) + 1, isArchived: existing?.isArchived ?? false,
                                  createdAt: existing?.createdAt ?? date, updatedAt: date, photoRecipe: draft.photoRecipe)
        if let existing {
            if existing.photoID != photoID || existingRecipe != draft.photoRecipe {
                // Relinquish the old current owner in the same record transaction.
                // Keep acknowledgment snapshots intact; they do not own these bytes.
                try queueCleanup(photoID: existing.photoID,
                                 recipeDigest: try cleanupRecipeDigest(try existing.recipe()), context: context)
            }
            existing.apply(result)
        } else { context.insert(StoredPiece(result)) }
        context.insert(StoredPieceSave(id: operationID, itemID: id, draftDigest: digest, snapshot: try encode(result)))
        if retainForPresentation {
            if savedDraft == nil {
                context.insert(StoredPieceDraft(draft: draft, operationID: operationID, payload: payload))
            }
        } else if let savedDraft { context.delete(savedDraft) }
        try commit(context)
        return result
    }

    /// Read-only recovery: completed proof alone is never a presentation link.
    /// A newer current revision permits a historical receipt, never a record rewind.
    func pendingSavedPiece(for recovered: RecoverablePieceDraft) throws -> WardrobePiece? {
        let context = ModelContext(container)
        let draft = recovered.draft
        let draftID = draft.id
        let operationID = recovered.operationID
        let itemID = draft.itemID
        guard let stored = try context.fetch(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.id == draftID })).first else {
            return nil
        }
        let payload = try encode(draft)
        guard stored.itemID == itemID, stored.operationID == operationID, stored.payload == payload else {
            throw StoreError.invalidRecord
        }
        try ensureUnusedDeletionOperation(operationID, context: context)
        guard try context.fetch(FetchDescriptor<StoredPieceDeletion>(predicate: #Predicate { $0.itemID == itemID })).isEmpty else {
            throw StoreError.deletedPiece
        }
        guard let proof = try context.fetch(FetchDescriptor<StoredPieceSave>(predicate: #Predicate { $0.id == operationID })).first else {
            // A consumed payload under a different operation is not a fresh draft.
            let payloadDigest = digest(payload)
            guard try context.fetch(FetchDescriptor<StoredPieceSave>()).allSatisfy({ $0.draftDigest != payloadDigest }) else {
                throw StoreError.invalidRecord
            }
            return nil
        }
        guard try decodedDrafts(context).filter({ $0.1.itemID == itemID }).count == 1,
              try context.fetch(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.operationID == operationID })).count == 1 else {
            throw StoreError.invalidRecord
        }
        try draft.validated()
        let snapshot = try JSONDecoder().decode(WardrobePiece.self, from: proof.snapshot)
        try snapshot.photoRecipe.validated()
        guard proof.itemID == itemID, proof.draftDigest == digest(payload),
              proof.snapshot == (try encode(snapshot)), snapshot.id == itemID,
              snapshot.name == draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
              snapshot.category == draft.category, snapshot.photoID == draft.photoID,
              snapshot.photoRecipe == draft.photoRecipe, snapshot.details == draft.details,
              snapshot.availability == draft.availability,
              snapshot.revision > 0, snapshot.revision - 1 == (draft.baseRevision ?? 0),
              let current = try piece(id: itemID), current.createdAt == snapshot.createdAt,
              current == snapshot || current.revision > snapshot.revision else {
            throw StoreError.invalidRecord
        }
        return snapshot
    }

    /// Atomically relinquish only the validated pending link, preserving immutable proof.
    /// Missing links are already acknowledged; mismatched identities are refused.
    func acknowledgePiecePresentation(draftID: UUID, operationID: UUID) throws {
        let context = ModelContext(container)
        guard let stored = try context.fetch(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.id == draftID })).first else {
            guard try context.fetch(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.operationID == operationID })).isEmpty else {
                throw StoreError.operationConflict
            }
            return
        }
        guard stored.operationID == operationID else { throw StoreError.operationConflict }
        let draft = try JSONDecoder().decode(PieceDraft.self, from: stored.payload)
        guard try pendingSavedPiece(for: RecoverablePieceDraft(draft: draft, operationID: operationID)) != nil else {
            throw StoreError.invalidRecord
        }
        if let photoID = draft.photoID {
            try queueCleanup(photoID: photoID, recipeDigest: try cleanupRecipeDigest(draft.photoRecipe), context: context)
        }
        context.delete(stored)
        try commit(context)
    }

    func piece(id: UUID) throws -> WardrobePiece? {
        let context = ModelContext(container)
        guard let stored = try context.fetch(FetchDescriptor<StoredPiece>(predicate: #Predicate { $0.id == id })).first else {
            return nil
        }
        return try stored.value()
    }

    /// Filters combine on-device. Recently added uses creation time, newest first;
    /// equal dates fall back to folded name order, then identity for deterministic ties.
    func pieces(query: String = "", category: PieceCategory? = nil, archived: Bool = false,
                availability: PieceAvailability? = nil, sort: PieceSort = .name) throws -> [WardrobePiece] {
        let context = ModelContext(container)
        let needle = Self.searchText(query.trimmingCharacters(in: .whitespacesAndNewlines))
        return try context.fetch(FetchDescriptor<StoredPiece>()).map { try $0.value() }.filter { piece in
            guard piece.isArchived == archived,
                  category == nil || piece.category == category,
                  availability == nil || piece.availability == availability else { return false }
            let details = piece.details
            let text = [piece.name, piece.category.rawValue, details.color, details.brand, details.size, details.fit,
                        details.material, details.season, details.condition, details.ownershipAge, details.notes] + details.tags
            return needle.isEmpty || text.contains { Self.searchText($0).contains(needle) }
        }.sorted {
            if sort == .recentlyAdded, $0.createdAt != $1.createdAt {
                return $0.createdAt > $1.createdAt
            }
            let left = Self.searchText($0.name)
            let right = Self.searchText($1.name)
            return left == right ? $0.id.uuidString < $1.id.uuidString : left < right
        }
    }

    private static func searchText(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    private struct ArchiveRequest: Encodable {
        let id: UUID
        let archived: Bool
        let expectedRevision: Int
    }

    @discardableResult
    func setArchived(id: UUID, archived: Bool, expectedRevision: Int, operationID: UUID) throws -> WardrobePiece {
        let context = ModelContext(container)
        let digest = "archive:" + SHA256.hash(data: try encode(ArchiveRequest(id: id, archived: archived, expectedRevision: expectedRevision)))
            .map { String(format: "%02x", $0) }.joined()
        if let prior = try context.fetch(FetchDescriptor<StoredPieceSave>(predicate: #Predicate { $0.id == operationID })).first {
            guard prior.draftDigest == digest else { throw StoreError.operationConflict }
            return try JSONDecoder().decode(WardrobePiece.self, from: prior.snapshot)
        }
        try ensureUnusedDeletionOperation(operationID, context: context)
        guard try context.fetch(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.operationID == operationID })).isEmpty else {
            throw StoreError.operationConflict
        }
        guard let stored = try context.fetch(FetchDescriptor<StoredPiece>(predicate: #Predicate { $0.id == id })).first,
              stored.revision == expectedRevision else { throw StoreError.staleRevision }
        stored.isArchived = archived
        stored.revision += 1
        stored.updatedAt = Date()
        let result = try stored.value()
        context.insert(StoredPieceSave(id: operationID, itemID: id, draftDigest: digest, snapshot: try encode(result)))
        try commit(context)
        return result
    }

    private func ensureUnusedDeletionOperation(_ operationID: UUID, context: ModelContext) throws {
        guard try context.fetch(FetchDescriptor<StoredPieceDeletion>(predicate: #Predicate { $0.id == operationID })).isEmpty else {
            throw StoreError.operationConflict
        }
    }

    /// Read-only proof of this exact record removal, not proof of erased media.
    /// Missing operations are unacknowledged; mismatched or contradictory proof is refused.
    func isPieceDeletionAcknowledged(id: UUID, expectedRevision: Int, operationID: UUID) throws -> Bool {
        guard expectedRevision > 0 else { throw StoreError.invalidRecord }
        let context = ModelContext(container)
        let matches = try context.fetch(FetchDescriptor<StoredPieceDeletion>(predicate: #Predicate { $0.id == operationID }))
        guard !matches.isEmpty else { return false }
        guard matches.count == 1, let proof = matches.first,
              proof.expectedRevision > 0,
              Set(proof.pendingPhotoIDs).count == proof.pendingPhotoIDs.count else { throw StoreError.invalidRecord }
        guard proof.itemID == id, proof.expectedRevision == expectedRevision else { throw StoreError.operationConflict }
        guard try context.fetchCount(FetchDescriptor<StoredPieceDeletion>(predicate: #Predicate { $0.itemID == id })) == 1,
              try context.fetchCount(FetchDescriptor<StoredPiece>(predicate: #Predicate { $0.id == id })) == 0,
              try context.fetchCount(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.itemID == id || $0.operationID == operationID })) == 0,
              try context.fetchCount(FetchDescriptor<StoredPieceSave>(predicate: #Predicate { $0.itemID == id || $0.id == operationID })) == 0 else {
            throw StoreError.invalidRecord
        }
        return true
    }

    /// Piece-only deletion, not full LOCAL-03 or erase. Today/journal/outfit/plan/history
    /// owners must extend the reference graph before those models can retain media.
    /// Record acknowledgment and recoverable filesystem cleanup are separate commits.
    func deletePiece(id: UUID, expectedRevision: Int, operationID: UUID) throws {
        let context = ModelContext(container)
        if let prior = try context.fetch(FetchDescriptor<StoredPieceDeletion>(predicate: #Predicate { $0.id == operationID })).first {
            guard try isPieceDeletionAcknowledged(id: id, expectedRevision: expectedRevision, operationID: operationID) else {
                throw StoreError.invalidRecord
            }
            try finishCleanup(prior, context: context)
            return
        }
        guard try context.fetch(FetchDescriptor<StoredPieceSave>(predicate: #Predicate { $0.id == operationID })).isEmpty,
              try context.fetch(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.operationID == operationID })).isEmpty else {
            throw StoreError.operationConflict
        }
        guard let stored = try context.fetch(FetchDescriptor<StoredPiece>(predicate: #Predicate { $0.id == id })).first,
              stored.revision == expectedRevision else { throw StoreError.staleRevision }
        // Decode every owner before mutation; unreadable/unsupported payloads may hide references.
        let drafts = try decodedDrafts(context)
        let receipts = try decodedReceipts(context)
        let relatedDrafts = drafts.filter { $0.1.itemID == id }
        let relatedReceipts = receipts.filter { $0.1.id == id }
        let candidates = Set([stored.photoID] + relatedDrafts.compactMap { $0.1.photoID } + relatedReceipts.map { $0.1.photoID })
        context.delete(stored)
        for (draft, _) in relatedDrafts { context.delete(draft) }
        for (receipt, _) in relatedReceipts { context.delete(receipt) }
        let acknowledgment = StoredPieceDeletion(operationID: operationID, itemID: id, expectedRevision: expectedRevision,
                                                 pendingPhotoIDs: candidates.sorted { $0.uuidString < $1.uuidString })
        context.insert(acknowledgment)
        try commit(context)
        try finishCleanup(acknowledgment, context: context)
    }

    private func cleanupRecipeDigest(_ recipe: PhotoEditRecipe) throws -> String? {
        recipe == .fitOriginal ? nil : try PhotoPreparer.recipeDigest(recipe)
    }

    private func queueCleanup(photoID: UUID, recipeDigest: String? = nil, context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<StoredPhotoCleanup>(predicate: #Predicate { $0.id == photoID })).first
        let candidate = existing ?? StoredPhotoCleanup(photoID: photoID)
        if existing == nil { context.insert(candidate) }
        if let recipeDigest, !candidate.recipeDigests.contains(recipeDigest) {
            candidate.recipeDigests.append(recipeDigest)
        }
    }

    func hasPendingPhotoCleanup() throws -> Bool {
        let context = ModelContext(container)
        return try !context.fetch(FetchDescriptor<StoredPhotoCleanup>()).isEmpty
            || context.fetch(FetchDescriptor<StoredPieceDeletion>()).contains { !$0.pendingPhotoIDs.isEmpty }
    }

    /// Relaunch recovery uses durable acknowledgments, not a vanished screen's operation ID.
    /// Only durable, explicitly staged candidates are considered; unknown files are never swept.
    func reconcilePendingPhotoCleanup() throws {
        guard allowsSave else { throw StoreError.cleanupPending }
        let context = ModelContext(container)
        // Stores written before replacement queued the relinquished current photo
        // may still have media referenced only by completed receipts. Their validated
        // snapshots provide exact cleanup candidates, never a directory-wide sweep.
        let pieces = try context.fetch(FetchDescriptor<StoredPiece>()).map { try $0.value() }
        let drafts = try decodedDrafts(context).map { $0.1 }
        let receipts = try decodedReceipts(context)
        try ensureOwnedMediaDirectory()
        var piecesByID: [UUID: WardrobePiece] = [:]
        var retainedRecipeDigests: [UUID: Set<String>] = [:]
        for piece in pieces {
            guard piecesByID.updateValue(piece, forKey: piece.id) == nil else { throw StoreError.invalidRecord }
            if piece.photoRecipe != .fitOriginal {
                retainedRecipeDigests[piece.photoID, default: []].insert(try PhotoPreparer.recipeDigest(piece.photoRecipe))
            }
        }
        for draft in drafts {
            if let photoID = draft.photoID, draft.photoRecipe != .fitOriginal {
                retainedRecipeDigests[photoID, default: []].insert(try PhotoPreparer.recipeDigest(draft.photoRecipe))
            }
        }
        // Older Fit acceptance wrote unused derivatives, and its staging intent
        // may already have been acknowledged while the original remained live.
        // Probe only the two exact Fit paths for validated live source identities.
        let fitDigest = try PhotoPreparer.recipeDigest(.fitOriginal)
        let livePhotoIDs = Set(pieces.map(\.photoID) + drafts.compactMap(\.photoID))
        for photoID in livePhotoIDs.sorted(by: { $0.uuidString < $1.uuidString }) {
            let fitFiles = try ["rendition", "thumbnail"].map {
                try editURL(id: photoID, recipe: .fitOriginal, kind: $0)
            }
            if try fitFiles.contains(where: managedArtifactExists) {
                try queueCleanup(photoID: photoID, recipeDigest: fitDigest, context: context)
            }
        }
        var probedReceipts: Set<String> = []
        for (_, snapshot) in receipts {
            if let current = piecesByID[snapshot.id],
               current.photoID == snapshot.photoID, current.photoRecipe == snapshot.photoRecipe { continue }
            let recipeDigest = try PhotoPreparer.recipeDigest(snapshot.photoRecipe)
            guard probedReceipts.insert("\(snapshot.photoID.uuidString):\(recipeDigest)").inserted else { continue }
            let isOwned = livePhotoIDs.contains(snapshot.photoID)
            // A live source is not obsolete merely because a historical receipt
            // names it. Shared live recipes are owners; Fit derivatives were probed above.
            if isOwned && (snapshot.photoRecipe == .fitOriginal
                || retainedRecipeDigests[snapshot.photoID, default: []].contains(recipeDigest)) { continue }
            var paths = try ["rendition", "thumbnail"].map {
                try editURL(id: snapshot.photoID, recipe: snapshot.photoRecipe, kind: $0)
            }
            if !isOwned {
                paths += [originalURL(id: snapshot.photoID),
                          mediaDirectory.appendingPathComponent("\(snapshot.photoID.uuidString)-thumbnail.jpg")]
            }
            // Discover only exact, still-present legacy artifacts. Immutable proof
            // alone must never recreate an already-reconciled candidate or write the store.
            if try paths.contains(where: managedArtifactExists) {
                try queueCleanup(photoID: snapshot.photoID, recipeDigest: recipeDigest, context: context)
            }
        }
        if context.hasChanges { try commit(context) }
        var firstFailure: (any Error)?
        let acknowledgments = try context.fetch(FetchDescriptor<StoredPieceDeletion>())
            .filter { !$0.pendingPhotoIDs.isEmpty }.sorted { $0.id.uuidString < $1.id.uuidString }
        for acknowledgment in acknowledgments {
            do { try finishCleanup(acknowledgment, context: context) }
            catch { context.rollback(); if firstFailure == nil { firstFailure = error } }
        }
        let candidates = try context.fetch(FetchDescriptor<StoredPhotoCleanup>()).sorted { $0.id.uuidString < $1.id.uuidString }
        for candidate in candidates {
            do {
                try cleanPhotos([candidate.id], stagedRecipeDigests: candidate.recipeDigests, context: context)
                context.delete(candidate)
                try commit(context)
            } catch { context.rollback(); if firstFailure == nil { firstFailure = error } }
        }
        if let firstFailure { throw firstFailure }
    }

    /// Missing exact paths mean completed work; permission/I/O failures and redirected
    /// or nonregular artifacts remain visible refusals, never false absence.
    private func managedArtifactExists(_ url: URL) throws -> Bool {
        do {
            guard try FileManager.default.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType == .typeRegular else {
                throw StoreError.unsafeMediaPath
            }
            return true
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile { return false }
    }

    private func decodedDrafts(_ context: ModelContext) throws -> [(StoredPieceDraft, PieceDraft)] {
        try context.fetch(FetchDescriptor<StoredPieceDraft>()).map { stored in
            let value = try JSONDecoder().decode(PieceDraft.self, from: stored.payload)
            guard value.id == stored.id, value.itemID == stored.itemID else { throw StoreError.invalidRecord }
            try value.photoRecipe.validated()
            return (stored, value)
        }
    }

    private func decodedReceipts(_ context: ModelContext) throws -> [(StoredPieceSave, WardrobePiece)] {
        try context.fetch(FetchDescriptor<StoredPieceSave>()).map { stored in
            let value = try JSONDecoder().decode(WardrobePiece.self, from: stored.snapshot)
            guard value.id == stored.itemID, value.revision > 0 else { throw StoreError.invalidRecord }
            try value.photoRecipe.validated()
            return (stored, value)
        }
    }

    private func finishCleanup(_ acknowledgment: StoredPieceDeletion, context: ModelContext) throws {
        guard !acknowledgment.pendingPhotoIDs.isEmpty else { return }
        try cleanPhotos(acknowledgment.pendingPhotoIDs, context: context)
        acknowledgment.pendingPhotoIDs = []
        try commit(context)
    }

    private func cleanPhotos(_ photoIDs: [UUID], stagedRecipeDigests: [String] = [], context: ModelContext) throws {
        // A read-only reopen may inspect records, but cannot acknowledge filesystem work.
        guard allowsSave else { throw StoreError.cleanupPending }
        try ensureOwnedMediaDirectory()
        // Recompute the live graph on every retry, not the graph at deletion time.
        let pieces = try context.fetch(FetchDescriptor<StoredPiece>()).map { try $0.value() }
        let drafts = try decodedDrafts(context).map { $0.1 }
        // Corrupt acknowledgment proof still blocks cleanup, even though completed
        // snapshots are not owners. Only current pieces and recoverable drafts own bytes.
        _ = try decodedReceipts(context)
        let references = Set(pieces.map(\.photoID) + drafts.compactMap(\.photoID))
        // A failed editor can leave an unused rendition even when its source is saved.
        // Only exact durably staged recipes may be pruned from a shared source.
        guard stagedRecipeDigests.allSatisfy({ $0.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil }) else {
            throw StoreError.invalidRecord
        }
        for photoID in photoIDs where references.contains(photoID) {
            let recipes = pieces.filter { $0.photoID == photoID }.map(\.photoRecipe)
                + drafts.filter { $0.photoID == photoID }.map(\.photoRecipe)
            // Fit reads the source files, never its historical edit artifacts.
            let retained = Set(try recipes.filter { $0 != .fitOriginal }.map { try PhotoPreparer.recipeDigest($0) })
            for digest in stagedRecipeDigests where !retained.contains(digest) {
                for kind in ["rendition", "thumbnail"] {
                    try removeOwnedMediaFile(mediaDirectory.appendingPathComponent("\(photoID.uuidString)-edit-\(digest)-\(kind).jpg"))
                }
            }
        }
        for photoID in photoIDs where !references.contains(photoID) {
            try removeOwnedMediaFile(originalURL(id: photoID))
            try removeOwnedMediaFile(mediaDirectory.appendingPathComponent("\(photoID.uuidString)-thumbnail.jpg"))
            let pattern = "^" + photoID.uuidString + "-edit-[0-9a-f]{64}-(rendition|thumbnail)\\.jpg$"
            for file in try FileManager.default.contentsOfDirectory(at: mediaDirectory, includingPropertiesForKeys: nil)
                where file.lastPathComponent.range(of: pattern, options: .regularExpression) != nil {
                try removeOwnedMediaFile(file)
            }
            // Keep the photo record until all files are known absent. If any step fails,
            // the durable candidate list still permits a same-operation retry after reopen.
            for photo in try context.fetch(FetchDescriptor<StoredPhoto>(predicate: #Predicate { $0.id == photoID })) {
                context.delete(photo)
            }
        }
    }

    private func removeOwnedMediaFile(_ url: URL) throws {
        // UUID filenames alone are not enough: refuse symlinks/directories rather than
        // following foreign paths or recursively pruning unknown contents.
        // Resolve legitimate system ancestors (e.g. /var), but never a redirected media folder.
        let ownedMedia = directory.resolvingSymlinksInPath().appendingPathComponent("media", isDirectory: true)
        guard try FileManager.default.attributesOfItem(atPath: directory.path)[.type] as? FileAttributeType == .typeDirectory,
              mediaDirectory.resolvingSymlinksInPath().standardizedFileURL == ownedMedia.standardizedFileURL,
              url.deletingLastPathComponent().standardizedFileURL == mediaDirectory.standardizedFileURL else {
            throw StoreError.unsafeMediaPath
        }
        let attributes: [FileAttributeKey: Any]
        do { attributes = try FileManager.default.attributesOfItem(atPath: url.path) }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile { return }
        guard attributes[.type] as? FileAttributeType == .typeRegular else { throw StoreError.unsafeMediaPath }
        try removeMediaFile(url)
        // Even a boundary reporting success must have actually removed the file.
        do {
            _ = try FileManager.default.attributesOfItem(atPath: url.path)
            throw StoreError.cleanupPending
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile { return }
    }

    private func digest(_ payload: Data) -> String {
        SHA256.hash(data: payload).map { String(format: "%02x", $0) }.joined()
    }

    private func commit(_ context: ModelContext) throws {
        do {
            // Protection errors precede database commit; never report a failed write after acknowledgment.
            try protectStoreFiles()
            try context.save()
        } catch { context.rollback(); throw error }
    }

    func acceptPhotoEdit(_ edit: PreparedPhotoEdit) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let id = edit.sourcePhotoID
        let context = ModelContext(container)
        guard try context.fetch(FetchDescriptor<StoredPhoto>(predicate: #Predicate { $0.id == id })).count == 1,
              edit.recipeDigest == (try PhotoPreparer.recipeDigest(edit.recipe)),
              edit.pixelWidth > 0, edit.pixelHeight > 0,
              !edit.renditionData.isEmpty, !edit.thumbnailData.isEmpty else { throw StoreError.invalidRecord }
        _ = try originalPhoto(id: id)
        let files = [("rendition", edit.renditionData), ("thumbnail", edit.thumbnailData)]
        for (kind, data) in files {
            let url = try editURL(id: id, recipe: edit.recipe, kind: kind)
            if (try? FileManager.default.attributesOfItem(atPath: url.path)) != nil {
                guard try readMedia(url) == data else { throw StoreError.conflictingMedia }
            }
        }
        if edit.recipe == .fitOriginal {
            // Keep ownership/digest/path/conflict validation above, but no Fit
            // derivatives are needed: both public reads use the accepted source.
            _ = try thumbnailPhoto(id: id)
            return
        }
        try queueCleanup(photoID: id, recipeDigest: edit.recipeDigest, context: context)
        try commit(context)
        for (kind, data) in files {
            let url = try editURL(id: id, recipe: edit.recipe, kind: kind)
            try ensureOwnedMediaDirectory()
            if FileManager.default.fileExists(atPath: url.path) {
                guard try readMedia(url) == data else { throw StoreError.conflictingMedia }
            } else {
                if (try? FileManager.default.attributesOfItem(atPath: url.path)) != nil { throw StoreError.unsafeMediaPath }
                try writeMediaFile(data, url)
            }
            try Self.protect(url)
        }
    }

    func photoRendition(id: UUID, recipe: PhotoEditRecipe) throws -> Data {
        try recipe.validated()
        if recipe == .fitOriginal { return try originalPhoto(id: id) }
        return try readMedia(editURL(id: id, recipe: recipe, kind: "rendition"))
    }

    func photoThumbnail(id: UUID, recipe: PhotoEditRecipe) throws -> Data {
        try recipe.validated()
        if recipe == .fitOriginal { return try thumbnailPhoto(id: id) }
        return try readMedia(editURL(id: id, recipe: recipe, kind: "thumbnail"))
    }

    private func editURL(id: UUID, recipe: PhotoEditRecipe, kind: String) throws -> URL {
        mediaDirectory.appendingPathComponent("\(id.uuidString)-edit-\(try PhotoPreparer.recipeDigest(recipe))-\(kind).jpg")
    }

    private func ensureOwnedMediaDirectory() throws {
        let owned = directory.resolvingSymlinksInPath().appendingPathComponent("media", isDirectory: true)
        guard mediaDirectory.resolvingSymlinksInPath().standardizedFileURL == owned.standardizedFileURL,
              try FileManager.default.attributesOfItem(atPath: mediaDirectory.path)[.type] as? FileAttributeType == .typeDirectory else {
            throw StoreError.unsafeMediaPath
        }
    }

    private func readMedia(_ url: URL) throws -> Data {
        try ensureOwnedMediaDirectory()
        guard try FileManager.default.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType == .typeRegular else {
            throw StoreError.unsafeMediaPath
        }
        return try Data(contentsOf: url)
    }

    func originalPhoto(id: UUID) throws -> Data {
        try readMedia(originalURL(id: id))
    }

    func thumbnailPhoto(id: UUID) throws -> Data {
        try readMedia(mediaDirectory.appendingPathComponent("\(id.uuidString)-thumbnail.jpg"))
    }

    private func originalURL(id: UUID) -> URL {
        mediaDirectory.appendingPathComponent("\(id.uuidString).jpg")
    }

    private func protectStoreFiles() throws {
        guard try FileManager.default.attributesOfItem(atPath: directory.path)[.type] as? FileAttributeType == .typeDirectory else {
            throw StoreError.unsafeMediaPath
        }
        // Reapply before commits too: WAL/SHM can be created or replaced after initialization.
        for file in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            try Self.protect(file)
        }
    }

    private static func createProtectedDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true,
                                              attributes: [.protectionKey: FileProtectionType.complete])
        try protect(url)
    }

    private static func protect(_ url: URL) throws {
        guard try FileManager.default.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType != .typeSymbolicLink else {
            throw StoreError.unsafeMediaPath
        }
        var ownedURL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try ownedURL.setResourceValues(values)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
    }
}

extension PieceStore {
    func outfits() throws -> [Outfit] {
        let owner = try todayConfiguration().ownerID
        return try ModelContext(container).fetch(FetchDescriptor<StoredOutfit>()).map {
            let value = try $0.value()
            guard value.ownerID == owner else { throw StoreError.invalidRecord }
            return value
        }.sorted {
            if $0.updatedAt != $1.updatedAt { return $0.updatedAt > $1.updatedAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    func outfit(id: UUID) throws -> Outfit? { try outfits().first { $0.id == id } }

    func outfitDraft() throws -> OutfitDraft? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitDraft>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let value = try records.first?.value() else { return nil }
        guard value.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        return value
    }

    func saveOutfitDraft(_ draft: OutfitDraft) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        try draft.validated()
        guard draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        let context = ModelContext(container)
        let receipts = try context.fetch(FetchDescriptor<StoredOutfitSave>())
        // An acknowledged operation is immutable until the receipt is dismissed.
        guard !receipts.contains(where: { $0.id == draft.operationID }) else { throw StoreError.operationConflict }
        let records = try context.fetch(FetchDescriptor<StoredOutfitDraft>())
        guard records.count <= 1, records.first.map({ $0.id == draft.id }) ?? true else { throw StoreError.operationConflict }
        if let record = records.first { record.payload = try JSONEncoder().encode(draft) }
        else { context.insert(try StoredOutfitDraft(draft)) }
        try commit(context)
    }

    func discardOutfitDraft(id: UUID) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredOutfitDraft>())
        guard records.count == 1, let record = records.first, record.id == id else { throw StoreError.staleDraft }
        let draft = try record.value()
        let operation = draft.operationID
        guard try !context.fetch(FetchDescriptor<StoredOutfitSave>()).contains(where: { $0.id == operation }) else {
            throw StoreError.operationConflict
        }
        context.delete(record)
        try commit(context)
    }

    func savedOutfit(for draft: OutfitDraft) throws -> Outfit? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitSave>()).filter { $0.id == draft.operationID }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let receipt = records.first else { return nil }
        guard try JSONDecoder().decode(OutfitDraft.self, from: receipt.draft) == draft else { throw StoreError.operationConflict }
        let value = try JSONDecoder().decode(Outfit.self, from: receipt.snapshot)
        try value.validated()
        guard value.ownerID == draft.ownerID, value.id == draft.outfitID else { throw StoreError.invalidRecord }
        return value
    }

    func saveOutfit(_ draft: OutfitDraft) throws -> Outfit {
        // Read the immutable receipt first. A retry still acknowledges a past
        // successful save if a selected piece has subsequently been archived.
        if let saved = try savedOutfit(for: draft) { return saved }
        guard allowsSave else { throw StoreError.corruptStore }
        try draft.validatedForSave(pieces: pieces())
        guard draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        guard try outfitDraft() == draft else { throw StoreError.staleDraft }
        let context = ModelContext(container)
        let existing = try context.fetch(FetchDescriptor<StoredOutfit>()).first { $0.id == draft.outfitID }
        let previous = try existing?.value()
        guard (previous == nil || previous?.ownerID == draft.ownerID), (previous?.revision ?? 0) == draft.baseRevision else { throw StoreError.staleRevision }
        let saved = Outfit(id: draft.outfitID, ownerID: draft.ownerID, name: draft.trimmedName,
                           pieceIDs: draft.pieceIDs, isFavorite: previous?.isFavorite ?? false,
                           revision: draft.baseRevision + 1, createdAt: previous?.createdAt ?? Date())
        try saved.validated()
        if let existing { existing.payload = try JSONEncoder().encode(saved) }
        else { context.insert(try StoredOutfit(saved)) }
        let themeRecords = try context.fetch(FetchDescriptor<StoredOutfitTheme>())
        let selectedThemes = Set(draft.themeIDs ?? [])
        let existingThemes = try themeRecords.map { try $0.value() }
        guard existingThemes.allSatisfy({ $0.ownerID == draft.ownerID }), selectedThemes.isSubset(of: Set(existingThemes.filter { $0.ownerID == draft.ownerID }.map(\.id))) else {
            throw StoreError.staleRevision
        }
        for record in themeRecords {
            var theme = try record.value()
            let hadMembership = theme.outfitIDs.contains(saved.id)
            let wantsMembership = selectedThemes.contains(theme.id)
            if hadMembership != wantsMembership {
                if wantsMembership { theme.outfitIDs.append(saved.id) }
                else { theme.outfitIDs.removeAll { $0 == saved.id } }
                theme.revision += 1
                record.payload = try JSONEncoder().encode(theme)
            }
        }
        context.insert(try StoredOutfitSave(draft: draft, saved: saved))
        try beforeOutfitSave()
        try commit(context)
        try afterOutfitSave()
        return saved
    }

    func acknowledgeOutfitReceipt(_ draft: OutfitDraft) throws {
        guard allowsSave, try savedOutfit(for: draft) != nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredOutfitDraft>())
        guard records.count == 1, let record = records.first, try record.value() == draft else { throw StoreError.staleDraft }
        context.delete(record)
        try commit(context)
    }
}

extension PieceStore {
    func themes() throws -> [OutfitTheme] {
        let owner = try todayConfiguration().ownerID
        let values = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitTheme>()).map { try $0.value() }
        guard values.allSatisfy({ $0.ownerID == owner }), Set(values.map { OutfitTheme.nameKey($0.name) }).count == values.count else {
            throw StoreError.invalidRecord
        }
        return values.sorted {
            let comparison = $0.name.localizedStandardCompare($1.name)
            return comparison == .orderedSame ? $0.id.uuidString < $1.id.uuidString : comparison == .orderedAscending
        }
    }

    func themeDraft() throws -> ThemeDraft? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredThemeDraft>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let draft = try records.first?.value() else { return nil }
        guard draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        return draft
    }

    func saveThemeDraft(_ draft: ThemeDraft) throws {
        guard allowsSave, draft.ownerID == (try todayConfiguration().ownerID), draft.baseRevision >= 0,
              Set(draft.outfitIDs).count == draft.outfitIDs.count else { throw StoreError.invalidRecord }
        guard try savedTheme(for: draft) == nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredThemeDraft>())
        guard records.count <= 1, records.first.map({ $0.id == draft.id }) ?? true else { throw StoreError.operationConflict }
        if let record = records.first { record.payload = try JSONEncoder().encode(draft) }
        else { context.insert(try StoredThemeDraft(draft)) }
        try commit(context)
    }

    func savedTheme(for draft: ThemeDraft) throws -> OutfitTheme? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredThemeSave>()).filter { $0.id == draft.operationID }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let receipt = records.first else { return nil }
        guard try JSONDecoder().decode(ThemeDraft.self, from: receipt.draft) == draft else { throw StoreError.operationConflict }
        let value = try JSONDecoder().decode(OutfitTheme.self, from: receipt.snapshot)
        try value.validated()
        guard value.id == draft.themeID, value.ownerID == draft.ownerID else { throw StoreError.invalidRecord }
        return value
    }

    func saveTheme(_ draft: ThemeDraft) throws -> OutfitTheme {
        if let saved = try savedTheme(for: draft) { return saved }
        guard allowsSave, draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.corruptStore }
        try draft.validatedForSave(themes: themes(), outfits: outfits())
        guard try themeDraft() == draft else { throw StoreError.staleDraft }
        let context = ModelContext(container)
        let record = try context.fetch(FetchDescriptor<StoredOutfitTheme>()).first { $0.id == draft.themeID }
        let previous = try record?.value()
        guard (previous == nil || previous?.ownerID == draft.ownerID), (previous?.revision ?? 0) == draft.baseRevision else { throw StoreError.staleRevision }
        let saved = OutfitTheme(id: draft.themeID, ownerID: draft.ownerID,
                               name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines), description: draft.description,
                               outfitIDs: draft.outfitIDs, revision: draft.baseRevision + 1)
        if let record { record.payload = try JSONEncoder().encode(saved) }
        else { context.insert(try StoredOutfitTheme(saved)) }
        context.insert(try StoredThemeSave(draft: draft, saved: saved))
        try beforeOutfitSave()
        try commit(context)
        try afterOutfitSave()
        return saved
    }

    func finishThemeDraft(_ draft: ThemeDraft, discarding: Bool = false) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let saved = try savedTheme(for: draft)
        guard discarding ? saved == nil : saved != nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredThemeDraft>())
        guard records.count == 1, let record = records.first, try record.value() == draft else { throw StoreError.staleDraft }
        context.delete(record)
        try commit(context)
    }
}

extension PieceStore {
    func planEntries() throws -> [OutfitPlanEntry] {
        let owner = try todayConfiguration().ownerID
        let values = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitPlanEntry>()).map { try $0.value() }
        guard values.allSatisfy({ $0.ownerID == owner }) else { throw StoreError.invalidRecord }
        return values.sorted {
            if $0.day.key != $1.day.key { return $0.day.key < $1.day.key }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    func planDraft() throws -> OutfitPlanDraft? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitPlanDraft>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let value = try records.first?.value() else { return nil }
        guard value.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        return value
    }

    func savePlanDraft(_ draft: OutfitPlanDraft) throws {
        guard allowsSave, draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        _ = try draft.day.date()
        guard try savedPlan(for: draft) == nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredOutfitPlanDraft>())
        guard records.count <= 1, records.first.map({ $0.id == draft.id }) ?? true else { throw StoreError.operationConflict }
        if let record = records.first { record.payload = try JSONEncoder().encode(draft) }
        else { context.insert(try StoredOutfitPlanDraft(draft)) }
        try commit(context)
    }

    func savedPlan(for draft: OutfitPlanDraft) throws -> OutfitPlanEntry? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitPlanSave>()).filter { $0.id == draft.operationID }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let receipt = records.first else { return nil }
        guard try JSONDecoder().decode(OutfitPlanDraft.self, from: receipt.draft) == draft else { throw StoreError.operationConflict }
        let saved = try JSONDecoder().decode(OutfitPlanEntry.self, from: receipt.snapshot)
        try saved.validated()
        guard saved.id == draft.entryID, saved.ownerID == draft.ownerID else { throw StoreError.invalidRecord }
        return saved
    }

    func savePlan(_ draft: OutfitPlanDraft) throws -> OutfitPlanEntry {
        if let saved = try savedPlan(for: draft) { return saved }
        guard allowsSave, draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        try draft.validatedForSave(outfits: outfits())
        let overlaps = try planEntries().contains {
            $0.day == draft.day && $0.occasion.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == draft.occasion.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        guard !overlaps || draft.allowsOverlap == true else { throw PlanValidationError.overlap }
        guard try planDraft() == draft else { throw StoreError.staleDraft }
        if let outfit = draft.outfit {
            let active = Set(try pieces().filter { $0.availability == .available }.map(\.id))
            guard Set(outfit.pieceIDs).isSubset(of: active) else { throw StoreError.staleRevision }
        }
        let saved = OutfitPlanEntry(id: draft.entryID, planID: draft.planID, ownerID: draft.ownerID, day: draft.day,
                                    occasion: draft.occasion, outfitID: draft.outfit?.id, outfitRevision: draft.outfit?.revision,
                                    state: draft.outfit == nil ? .unassigned : .planned)
        try saved.validated()
        let context = ModelContext(container)
        guard try !context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()).contains(where: { $0.id == draft.entryID }) else {
            throw StoreError.operationConflict
        }
        context.insert(try StoredOutfitPlanEntry(saved))
        context.insert(try StoredOutfitPlanSave(draft: draft, saved: saved))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
        return saved
    }

    func finishPlanDraft(_ draft: OutfitPlanDraft, discarding: Bool = false) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let saved = try savedPlan(for: draft)
        guard discarding ? saved == nil : saved != nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredOutfitPlanDraft>())
        guard records.count == 1, let record = records.first, try record.value() == draft else { throw StoreError.staleDraft }
        context.delete(record); try commit(context)
    }
}
