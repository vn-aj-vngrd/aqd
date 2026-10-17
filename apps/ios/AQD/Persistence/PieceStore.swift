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

enum LocalSchemaV7: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(7, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV6.models + [StoredOutfitWear.self, StoredOutfitWearDraft.self, StoredOutfitWearSave.self] }
}

enum LocalSchemaV8: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(8, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV7.models + [StoredOutfitMutation.self] }
}

enum LocalSchemaV9: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(9, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV8.models + [StoredPieceDeletionReview.self] }
}

enum LocalSchemaV10: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(10, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV9.models + [StoredThemeDeletion.self] }
}

enum LocalSchemaV11: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(11, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV10.models + [StoredPlanEntryDeletion.self] }
}

enum LocalSchemaV12: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(12, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV11.models + [StoredPlanDefinition.self, StoredPlanAuthoringDraft.self, StoredPlanAuthoringSave.self] }
}

enum LocalSchemaV13: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(13, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV12.models + [StoredPackingState.self, StoredPackingCheck.self] }
}

enum LocalSchemaV14: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(14, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV13.models + [StoredHistoryMutation.self] }
}

enum LocalSchemaV15: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(15, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV14.models + [StoredLocalIdentity.self, StoredIdentityDraft.self, StoredIdentitySave.self] }
}

enum LocalSchemaV16: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(16, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV15.models + [StoredFitMemory.self, StoredFitDraft.self, StoredFitSave.self, StoredFitDeletion.self] }
}

enum LocalSchemaV17: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(17, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV16.models + [StoredTodayLayout.self, StoredTodayDraft.self, StoredTodaySave.self, StoredTodayUndo.self, StoredTodayPersonalCard.self] }
}

enum LocalSchemaV18: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(18, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV17.models + [StoredTodayCardDeletion.self] }
}

enum LocalSchemaV19: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(19, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV18.models + [StoredPhotoSource.self] }
}

enum LocalSchemaV20: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(20, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV19.models + [StoredWeatherState.self, StoredWeatherSave.self] }
}

enum LocalSchemaV21: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(21, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV20.models + [StoredAgentConversation.self, StoredAgentOperation.self] }
}

enum LocalSchemaV22: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(22, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV21.models + [StoredLocalSettings.self, StoredSettingsSave.self, StoredLocalMutation.self] }
}

enum LocalMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [LocalSchemaV1.self, LocalSchemaV2.self, LocalSchemaV3.self, LocalSchemaV4.self, LocalSchemaV5.self, LocalSchemaV6.self, LocalSchemaV7.self, LocalSchemaV8.self, LocalSchemaV9.self, LocalSchemaV10.self, LocalSchemaV11.self, LocalSchemaV12.self, LocalSchemaV13.self, LocalSchemaV14.self, LocalSchemaV15.self, LocalSchemaV16.self, LocalSchemaV17.self, LocalSchemaV18.self, LocalSchemaV19.self, LocalSchemaV20.self, LocalSchemaV21.self, LocalSchemaV22.self] }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: LocalSchemaV1.self, toVersion: LocalSchemaV2.self),
         .lightweight(fromVersion: LocalSchemaV2.self, toVersion: LocalSchemaV3.self),
         .lightweight(fromVersion: LocalSchemaV3.self, toVersion: LocalSchemaV4.self),
         .lightweight(fromVersion: LocalSchemaV4.self, toVersion: LocalSchemaV5.self),
         .lightweight(fromVersion: LocalSchemaV5.self, toVersion: LocalSchemaV6.self),
         .lightweight(fromVersion: LocalSchemaV6.self, toVersion: LocalSchemaV7.self),
         .lightweight(fromVersion: LocalSchemaV7.self, toVersion: LocalSchemaV8.self),
         .lightweight(fromVersion: LocalSchemaV8.self, toVersion: LocalSchemaV9.self),
         .lightweight(fromVersion: LocalSchemaV9.self, toVersion: LocalSchemaV10.self),
         .lightweight(fromVersion: LocalSchemaV10.self, toVersion: LocalSchemaV11.self),
         .lightweight(fromVersion: LocalSchemaV11.self, toVersion: LocalSchemaV12.self),
         .lightweight(fromVersion: LocalSchemaV12.self, toVersion: LocalSchemaV13.self),
         .lightweight(fromVersion: LocalSchemaV13.self, toVersion: LocalSchemaV14.self),
         .lightweight(fromVersion: LocalSchemaV14.self, toVersion: LocalSchemaV15.self),
         .lightweight(fromVersion: LocalSchemaV15.self, toVersion: LocalSchemaV16.self),
         .lightweight(fromVersion: LocalSchemaV16.self, toVersion: LocalSchemaV17.self),
         .lightweight(fromVersion: LocalSchemaV17.self, toVersion: LocalSchemaV18.self),
         .lightweight(fromVersion: LocalSchemaV18.self, toVersion: LocalSchemaV19.self),
         .lightweight(fromVersion: LocalSchemaV19.self, toVersion: LocalSchemaV20.self),
         .lightweight(fromVersion: LocalSchemaV20.self, toVersion: LocalSchemaV21.self),
         .lightweight(fromVersion: LocalSchemaV21.self, toVersion: LocalSchemaV22.self)]
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
        let version = Data("AQD-piece-store:22".utf8)
        let previousVersions = (1..<22).map { Data("AQD-piece-store:\($0)".utf8) }
        // A dangling symlink is existing storage too, not permission to create
        // a fresh store through a redirected path.
        let hasStore = (try? FileManager.default.attributesOfItem(atPath: storeURL.path)) != nil
        let hasVersion = FileManager.default.fileExists(atPath: versionURL.path)
        let schema = Schema(versionedSchema: LocalSchemaV22.self)
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
        let layoutContext = ModelContext(container)
        let layouts = try layoutContext.fetch(FetchDescriptor<StoredTodayLayout>())
        guard layouts.count <= 1 else { throw StoreError.corruptStore }
        if layouts.isEmpty {
            let marker = hasVersion ? try Data(contentsOf: versionURL) : nil
            let predatesFullToday = marker.map { old in (1..<17).contains { old == Data("AQD-piece-store:\($0)".utf8) } } ?? true
            guard allowsSave, predatesFullToday else { throw StoreError.corruptStore }
            let legacy = try layoutContext.fetch(FetchDescriptor<StoredTodayConfiguration>())
            guard legacy.count == 1, let source = legacy.first else { throw StoreError.corruptStore }
            layoutContext.insert(try StoredTodayLayout(source.value())); try commit(layoutContext)
        }
        _ = try todayConfiguration()
        // Advance the marker only after the native preservation migration succeeds.
        if allowsSave { try version.write(to: versionURL, options: [.atomic, .completeFileProtection]) }
        try protectStoreFiles()
    }

    private enum BootstrapSnapshotError: Error { case changed }

    private static func interruptedBootstrapNeedsToday(storeURL: URL, schema: Schema) throws -> Bool {
        for _ in 0..<3 {
            do { return try inspectStableBootstrapSnapshot(storeURL: storeURL, schema: schema) }
            catch BootstrapSnapshotError.changed { continue }
        }
        throw StoreError.unsupportedStore
    }

    private static func inspectStableBootstrapSnapshot(storeURL: URL, schema: Schema) throws -> Bool {
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
            var copiedFiles: [(suffix: String, hash: SHA256.Digest?)] = []
            for suffix in ["", "-wal"] {
                let source = sourceDirectory.appendingPathComponent(storeURL.lastPathComponent + suffix)
                let attributes: [FileAttributeKey: Any]
                do { attributes = try FileManager.default.attributesOfItem(atPath: source.path) }
                catch let error as CocoaError where error.code == .fileReadNoSuchFile && suffix == "-wal" {
                    copiedFiles.append((suffix, nil)); continue
                }
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
                guard bytes.count == status.st_size else { throw BootstrapSnapshotError.changed }
                remainingBytes -= bytes.count
                let destination = inspectionDirectory.appendingPathComponent(source.lastPathComponent)
                try bytes.write(to: destination, options: [.atomic, .completeFileProtection])
                try protect(destination)
                copiedFiles.append((suffix, SHA256.hash(data: bytes)))
            }
            // SQLite may checkpoint while separate DB/WAL files are copied.
            // Refuse a mixed snapshot rather than misclassifying committed
            // records as an empty bootstrap window. Recheck before inspection.
            var verificationBudget = 32 * 1024 * 1024
            for copied in copiedFiles {
                let source = sourceDirectory.appendingPathComponent(storeURL.lastPathComponent + copied.suffix)
                guard let expected = copied.hash else {
                    guard !FileManager.default.fileExists(atPath: source.path) else { throw BootstrapSnapshotError.changed }
                    continue
                }
                let descriptor = open(source.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
                guard descriptor >= 0 else { throw StoreError.unsupportedStore }
                let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
                defer { try? handle.close() }
                var status = stat()
                guard fstat(descriptor, &status) == 0, status.st_mode & S_IFMT == S_IFREG,
                      status.st_size >= 0, status.st_size <= verificationBudget else { throw StoreError.unsupportedStore }
                var hash = SHA256()
                var count = 0
                while let chunk = try handle.read(upToCount: min(64 * 1024, verificationBudget - count + 1)), !chunk.isEmpty {
                    guard chunk.count <= verificationBudget - count else { throw StoreError.unsupportedStore }
                    count += chunk.count; hash.update(data: chunk)
                }
                guard count == status.st_size, hash.finalize() == expected else { throw BootstrapSnapshotError.changed }
                verificationBudget -= count
            }
            // Copy the exact WAL when present (not SHM, media or unknown files),
            // so committed rows not yet checkpointed into the DB remain visible.
            let needsToday = try inspectBootstrapCopyNeedsToday(
                storeURL: inspectionDirectory.appendingPathComponent(storeURL.lastPathComponent), schema: schema)
            // Fail closed on cleanup failure; defer retries on every error path.
            try FileManager.default.removeItem(at: inspectionDirectory)
            return needsToday
        } catch BootstrapSnapshotError.changed { throw BootstrapSnapshotError.changed }
        catch { throw StoreError.unsupportedStore }
    }

    private static func inspectBootstrapCopyNeedsToday(storeURL: URL, schema: Schema) throws -> Bool {
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType, at: storeURL, options: [NSReadOnlyPersistentStoreOption: true])
            let candidates = [(schema, 22), (Schema(versionedSchema: LocalSchemaV21.self), 21), (Schema(versionedSchema: LocalSchemaV20.self), 20), (Schema(versionedSchema: LocalSchemaV19.self), 19), (Schema(versionedSchema: LocalSchemaV18.self), 18), (Schema(versionedSchema: LocalSchemaV17.self), 17), (Schema(versionedSchema: LocalSchemaV16.self), 16), (Schema(versionedSchema: LocalSchemaV15.self), 15), (Schema(versionedSchema: LocalSchemaV14.self), 14), (Schema(versionedSchema: LocalSchemaV13.self), 13), (Schema(versionedSchema: LocalSchemaV12.self), 12), (Schema(versionedSchema: LocalSchemaV11.self), 11), (Schema(versionedSchema: LocalSchemaV10.self), 10), (Schema(versionedSchema: LocalSchemaV9.self), 9), (Schema(versionedSchema: LocalSchemaV8.self), 8), (Schema(versionedSchema: LocalSchemaV7.self), 7), (Schema(versionedSchema: LocalSchemaV6.self), 6), (Schema(versionedSchema: LocalSchemaV5.self), 5), (Schema(versionedSchema: LocalSchemaV4.self), 4), (Schema(versionedSchema: LocalSchemaV3.self), 3), (Schema(versionedSchema: LocalSchemaV2.self), 2)]
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

    private static func bootstrapNeedsToday(in context: ModelContext, storeVersion: Int = 22) throws -> Bool {
        if storeVersion >= 22 {
            guard try context.fetchCount(FetchDescriptor<StoredLocalSettings>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredSettingsSave>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredLocalMutation>()) <= 1 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 21 {
            guard try context.fetchCount(FetchDescriptor<StoredAgentConversation>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredAgentOperation>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 20 {
            guard try context.fetchCount(FetchDescriptor<StoredWeatherState>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredWeatherSave>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 19 {
            guard try context.fetchCount(FetchDescriptor<StoredPhotoSource>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 18 {
            guard try context.fetchCount(FetchDescriptor<StoredTodayCardDeletion>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 17 {
            guard try context.fetchCount(FetchDescriptor<StoredTodayDraft>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredTodaySave>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredTodayUndo>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredTodayPersonalCard>()) == 0 else { throw StoreError.unsupportedStore }
            let layouts = try context.fetch(FetchDescriptor<StoredTodayLayout>())
            let legacy = try context.fetch(FetchDescriptor<StoredTodayConfiguration>())
            guard layouts.count <= 1 else { throw StoreError.unsupportedStore }
            if let layout = layouts.first {
                guard legacy.count == 1, let first = legacy.first, try layout.value() == first.value() else { throw StoreError.unsupportedStore }
            }
        }
        if storeVersion >= 16 {
            guard try context.fetchCount(FetchDescriptor<StoredFitMemory>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredFitDraft>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredFitSave>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredFitDeletion>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 15 {
            guard try context.fetchCount(FetchDescriptor<StoredLocalIdentity>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredIdentityDraft>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredIdentitySave>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 14 {
            guard try context.fetchCount(FetchDescriptor<StoredHistoryMutation>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 13 {
            guard try context.fetchCount(FetchDescriptor<StoredPackingState>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredPackingCheck>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 12 {
            guard try context.fetchCount(FetchDescriptor<StoredPlanDefinition>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredPlanAuthoringDraft>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredPlanAuthoringSave>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 11 {
            guard try context.fetchCount(FetchDescriptor<StoredPlanEntryDeletion>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 10 {
            guard try context.fetchCount(FetchDescriptor<StoredThemeDeletion>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 9 {
            guard try context.fetchCount(FetchDescriptor<StoredPieceDeletionReview>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 8 {
            guard try context.fetchCount(FetchDescriptor<StoredOutfitMutation>()) == 0 else { throw StoreError.unsupportedStore }
        }
        if storeVersion >= 7 {
            guard try context.fetchCount(FetchDescriptor<StoredOutfitWear>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredOutfitWearDraft>()) == 0,
                  try context.fetchCount(FetchDescriptor<StoredOutfitWearSave>()) == 0 else { throw StoreError.unsupportedStore }
        }
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
              (today.instances.map(\.kind) == [.todayLook, .weekInWear, .closetInUse] || today.instances.map(\.kind) == TodayWidgetKind.allCases) else {
            throw StoreError.unsupportedStore
        }
        return false
    }

    func todayConfiguration() throws -> TodayConfiguration {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredTodayLayout>())
        let legacy = try context.fetch(FetchDescriptor<StoredTodayConfiguration>())
        guard records.count == 1, let record = records.first, legacy.count == 1,
              let owner = legacy.first?.ownerID else { throw StoreError.invalidRecord }
        let value = try record.value()
        guard value.ownerID == owner else { throw StoreError.invalidRecord }
        return value
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

    func savePieceCategories(_ categories: [WardrobeCategory], expected: [WardrobeCategory]) throws {
        try WardrobeCategory.validate(categories)
        guard allowsSave else { throw StoreError.corruptStore }
        let context = ModelContext(container)
        var (record, value) = try experienceRecord(in: context)
        let current = value.pieceCategories ?? WardrobeCategory.defaults
        if current == categories { return }
        guard current == expected else { throw StoreError.staleRevision }
        value.pieceCategories = categories
        try value.validated()
        record.payload = try JSONEncoder().encode(value)
        try commit(context)
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
            if result.availability != .available { try flagFuturePlans(using: id, context: context) }
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
        let wear = [.mostWorn, .leastWorn, .lastWorn].contains(sort) ? try wearRecords() : []
        return try context.fetch(FetchDescriptor<StoredPiece>()).map { try $0.value() }.filter { piece in
            guard piece.isArchived == archived,
                  category == nil || piece.category == category,
                  availability == nil || piece.availability == availability else { return false }
            let details = piece.details
            let text = [piece.name, piece.category.rawValue, details.color, details.brand, details.size, details.fit,
                        details.material, details.season, details.condition, details.ownershipAge, details.notes] + details.tags
            return needle.isEmpty || text.contains { Self.searchText($0).contains(needle) }
        }.sorted {
            if sort == .mostWorn || sort == .leastWorn {
                let left = PieceWearSummary(piece: $0, records: wear).total
                let right = PieceWearSummary(piece: $1, records: wear).total
                if left != right { return sort == .mostWorn ? left > right : left < right }
            }
            if sort == .lastWorn {
                let left = PieceWearSummary(piece: $0, records: wear).lastWorn?.key
                let right = PieceWearSummary(piece: $1, records: wear).lastWorn?.key
                if left != right { return (left ?? "") > (right ?? "") }
            }
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
        guard allowsSave else { throw StoreError.corruptStore }
        if archived { try flagFuturePlans(using: id, context: context) }
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
    func isPieceDeletionAcknowledged(id: UUID, expectedRevision: Int, operationID: UUID, impact: PieceDeletionImpact? = nil) throws -> Bool {
        guard expectedRevision > 0 else { throw StoreError.invalidRecord }
        let context = ModelContext(container)
        let matches = try context.fetch(FetchDescriptor<StoredPieceDeletion>(predicate: #Predicate { $0.id == operationID }))
        guard !matches.isEmpty else { return false }
        guard matches.count == 1, let proof = matches.first,
              proof.expectedRevision > 0,
              Set(proof.pendingPhotoIDs).count == proof.pendingPhotoIDs.count else { throw StoreError.invalidRecord }
        guard proof.itemID == id, proof.expectedRevision == expectedRevision else { throw StoreError.operationConflict }
        if let impact {
            let reviews = try context.fetch(FetchDescriptor<StoredPieceDeletionReview>(predicate: #Predicate { $0.id == operationID }))
            guard reviews.count == 1, let review = reviews.first,
                  try JSONDecoder().decode(PieceDeletionImpact.self, from: review.impact) == impact else { throw StoreError.operationConflict }
        }
        guard try context.fetchCount(FetchDescriptor<StoredPieceDeletion>(predicate: #Predicate { $0.itemID == id })) == 1,
              try context.fetchCount(FetchDescriptor<StoredPiece>(predicate: #Predicate { $0.id == id })) == 0,
              try context.fetchCount(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.itemID == id || $0.operationID == operationID })) == 0,
              try context.fetchCount(FetchDescriptor<StoredPieceSave>(predicate: #Predicate { $0.itemID == id || $0.id == operationID })) == 0 else {
            throw StoreError.invalidRecord
        }
        return true
    }

    /// Reviewed wardrobe cascade. Future journal/media owners must extend the
    /// reference graph; wear snapshots deliberately retain no photo ownership.
    /// Record acknowledgment and recoverable filesystem cleanup are separate commits.
    func deletePiece(id: UUID, expectedRevision: Int, operationID: UUID, impact: PieceDeletionImpact? = nil) throws {
        let context = ModelContext(container)
        if let prior = try context.fetch(FetchDescriptor<StoredPieceDeletion>(predicate: #Predicate { $0.id == operationID })).first {
            guard try isPieceDeletionAcknowledged(id: id, expectedRevision: expectedRevision, operationID: operationID, impact: impact) else {
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
        guard allowsSave else { throw StoreError.corruptStore }
        let currentImpact = try pieceDeletionImpact(id: id)
        guard impact.map({ $0 == currentImpact }) ?? !currentImpact.hasDependencies else { throw StoreError.staleRevision }
        // Decode every owner before mutation; unreadable/unsupported payloads may hide references.
        let drafts = try decodedDrafts(context)
        let receipts = try decodedReceipts(context)
        let relatedDrafts = drafts.filter { $0.1.itemID == id }
        let relatedReceipts = receipts.filter { $0.1.id == id }
        let candidates = Set([stored.photoID] + relatedDrafts.compactMap { $0.1.photoID } + relatedReceipts.map { $0.1.photoID })
        try applyPieceDeletionImpact(currentImpact, context: context)
        context.insert(try StoredPieceDeletionReview(operationID: operationID, impact: currentImpact))
        context.delete(stored)
        for (draft, _) in relatedDrafts { context.delete(draft) }
        for (receipt, _) in relatedReceipts { context.delete(receipt) }
        let acknowledgment = StoredPieceDeletion(operationID: operationID, itemID: id, expectedRevision: expectedRevision,
                                                 pendingPhotoIDs: candidates.sorted { $0.uuidString < $1.uuidString })
        context.insert(acknowledgment)
        try prunePackingChecks(in: context)
        try commit(context)
        try finishCleanup(acknowledgment, context: context)
    }

    private func cleanupRecipeDigest(_ recipe: PhotoEditRecipe) throws -> String? {
        recipe == .fitOriginal ? nil : try PhotoPreparer.recipeDigest(recipe)
    }

    private func queueCleanup(photoID: UUID, recipeDigest: String? = nil, context: ModelContext) throws {
        let sources = try photoSources(in: context)
        for candidateID in [photoID] + [sources[photoID]].compactMap({ $0 }) {
            let existing = try context.fetch(FetchDescriptor<StoredPhotoCleanup>()).first { $0.id == candidateID }
            let candidate = existing ?? StoredPhotoCleanup(photoID: candidateID)
            if existing == nil { context.insert(candidate) }
            if candidateID == photoID, let recipeDigest, !candidate.recipeDigests.contains(recipeDigest) { candidate.recipeDigests.append(recipeDigest) }
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
        for owner in try personalPhotoOwners(in: context) where owner.recipe != .fitOriginal {
            retainedRecipeDigests[owner.id, default: []].insert(try PhotoPreparer.recipeDigest(owner.recipe))
        }
        // Older Fit acceptance wrote unused derivatives, and its staging intent
        // may already have been acknowledged while the original remained live.
        // Probe only the two exact Fit paths for validated live source identities.
        let fitDigest = try PhotoPreparer.recipeDigest(.fitOriginal)
        let identityPhotos = try personalPhotoReferences(in: context)
        let livePhotoIDs = try photoReferences(pieces.map(\.photoID) + drafts.compactMap(\.photoID) + identityPhotos, context: context)
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
        let personalOwners = try personalPhotoOwners(in: context)
        let identityPhotos = personalOwners.map { $0.id }
        let references = try photoReferences(pieces.map(\.photoID) + drafts.compactMap(\.photoID) + identityPhotos, context: context)
        // A failed editor can leave an unused rendition even when its source is saved.
        // Only exact durably staged recipes may be pruned from a shared source.
        guard stagedRecipeDigests.allSatisfy({ $0.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil }) else {
            throw StoreError.invalidRecord
        }
        for photoID in photoIDs where references.contains(photoID) {
            let recipes = pieces.filter { $0.photoID == photoID }.map(\.photoRecipe)
                + drafts.filter { $0.photoID == photoID }.map(\.photoRecipe)
                + personalOwners.filter { $0.id == photoID }.map { $0.recipe }
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
            for source in try context.fetch(FetchDescriptor<StoredPhotoSource>()).filter({ $0.id == photoID }) { context.delete(source) }
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
            let mutations = try context.fetch(FetchDescriptor<StoredLocalMutation>())
            guard mutations.count <= 1 else { throw StoreError.invalidRecord }
            if let mutation = mutations.first { mutation.stamp = UUID() } else { context.insert(StoredLocalMutation()) }
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
                           pieceIDs: draft.pieceIDs, mood: draft.mood, occasion: draft.occasion, isFavorite: previous?.isFavorite ?? false,
                           revision: draft.baseRevision + 1, createdAt: previous?.createdAt ?? Date())
        try saved.validated()
        if let existing {
            existing.payload = try JSONEncoder().encode(saved)
            try flagFuturePlans(outfitIDs: [saved.id], context: context)
        } else { context.insert(try StoredOutfit(saved)) }
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
        try prunePackingChecks(in: context)
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
        let namedPlan = try planDefinitions().first { $0.id == draft.planID }
        if draft.parentPlanID != nil && namedPlan == nil { throw StoreError.staleRevision }
        if let namedPlan {
            guard namedPlan.ownerID == draft.ownerID, draft.day.timeZoneID == namedPlan.start.timeZoneID,
                  draft.day.key >= namedPlan.start.key,
                  draft.day.key <= namedPlan.end.key else { throw PlanValidationError.invalidDay }
        }
        let overlaps = try planEntries().contains {
            $0.id != draft.entryID && $0.day == draft.day && $0.occasion.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == draft.occasion.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        guard !overlaps || draft.allowsOverlap == true else { throw PlanValidationError.overlap }
        guard try planDraft() == draft else { throw StoreError.staleDraft }
        if let outfit = draft.outfit {
            let active = Set(try pieces().filter { $0.availability == .available }.map(\.id))
            guard Set(outfit.pieceIDs).isSubset(of: active) else { throw StoreError.staleRevision }
        }
        let saved = OutfitPlanEntry(id: draft.entryID, planID: draft.planID, ownerID: draft.ownerID, day: draft.day,
                                    occasion: draft.occasion, outfitID: draft.outfit?.id, outfitRevision: draft.outfit?.revision,
                                    state: draft.outfit == nil ? .unassigned : .planned, revision: (draft.baseEntry?.revision ?? 0) + 1)
        try saved.validated()
        let context = ModelContext(container)
        let existing = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()).first { $0.id == draft.entryID }
        if let base = draft.baseEntry {
            guard let existing, try existing.value() == base else { throw StoreError.staleRevision }
            existing.payload = try JSONEncoder().encode(saved)
        } else {
            guard existing == nil else { throw StoreError.operationConflict }
            context.insert(try StoredOutfitPlanEntry(saved))
        }
        context.insert(try StoredOutfitPlanSave(draft: draft, saved: saved))
        try prunePackingChecks(in: context)
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

extension PieceStore {
    func ownedPiecesForWear() throws -> [WardrobePiece] { try pieces() + pieces(archived: true) }

    func wearRecords() throws -> [OutfitWearRecord] {
        let owner = try todayConfiguration().ownerID
        let values = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitWear>()).map { try $0.value() }
        guard values.allSatisfy({ $0.ownerID == owner }), Set(values.map(\.duplicateKey)).count == values.count else {
            throw StoreError.invalidRecord
        }
        return values.sorted {
            if $0.day.key != $1.day.key { return $0.day.key > $1.day.key }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
    func wearDraft() throws -> OutfitWearDraft? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitWearDraft>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let draft = try records.first?.value() else { return nil }
        guard draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        return draft
    }
    func saveWearDraft(_ draft: OutfitWearDraft) throws {
        guard allowsSave, draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        _ = try draft.day.date()
        guard Set(draft.pieceIDs).count == draft.pieceIDs.count else { throw StoreError.invalidRecord }
        guard try savedWear(for: draft) == nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredOutfitWearDraft>())
        guard records.count <= 1, records.first.map({ $0.id == draft.id }) ?? true else { throw StoreError.operationConflict }
        if let record = records.first { record.payload = try JSONEncoder().encode(draft) }
        else { context.insert(try StoredOutfitWearDraft(draft)) }
        try commit(context)
    }
    func matchingWear(for draft: OutfitWearDraft) throws -> OutfitWearRecord? {
        try wearRecords().first { $0.duplicateKey == draft.duplicateKey && $0.id != draft.baseRecord?.id }
    }
    func savedWear(for draft: OutfitWearDraft) throws -> OutfitWearRecord? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitWearSave>()).filter { $0.id == draft.operationID }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let receipt = records.first else { return nil }
        guard try JSONDecoder().decode(OutfitWearDraft.self, from: receipt.draft) == draft else { throw StoreError.operationConflict }
        let saved = try JSONDecoder().decode(OutfitWearRecord.self, from: receipt.snapshot)
        try saved.validated()
        guard saved.ownerID == draft.ownerID, saved.duplicateKey == draft.duplicateKey,
              saved.id == draft.wearID || saved.id == draft.acceptedDuplicateID else { throw StoreError.invalidRecord }
        return saved
    }
    func saveWear(_ draft: OutfitWearDraft) throws -> OutfitWearRecord {
        if let saved = try savedWear(for: draft) { return saved }
        guard allowsSave, draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        let pieces = try ownedPiecesForWear()
        try draft.validatedForSave(pieces: pieces)
        guard try wearDraft() == draft else { throw StoreError.staleDraft }
        if draft.baseRecord == nil, let id = draft.outfitID, try outfit(id: id) == nil { throw StoreError.staleRevision }
        let context = ModelContext(container)
        var editedRecord: StoredOutfitWear?
        if let base = draft.baseRecord {
            editedRecord = try context.fetch(FetchDescriptor<StoredOutfitWear>()).first { $0.id == base.id }
            guard let editedRecord, try editedRecord.value() == base else { throw StoreError.staleRevision }
        }
        var linkedRecord: StoredOutfitPlanEntry?
        if let reviewed = draft.planEntry {
            linkedRecord = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()).first { $0.id == reviewed.id }
            guard let linkedRecord, try linkedRecord.value() == reviewed else { throw StoreError.staleRevision }
        }
        let saved: OutfitWearRecord
        if let existing = try matchingWear(for: draft) {
            guard draft.baseRecord == nil, draft.acceptedDuplicateID == existing.id else { throw WearValidationError.alreadyRecorded }
            saved = existing
        } else {
            guard draft.acceptedDuplicateID == nil else { throw StoreError.staleRevision }
            let snapshots = try draft.pieceIDs.map { id -> WearPieceSnapshot in
                if let previous = draft.baseRecord?.pieces.first(where: { $0.id == id }) { return previous }
                guard let piece = pieces.first(where: { $0.id == id }) else { throw StoreError.staleRevision }
                return WearPieceSnapshot(piece)
            }
            saved = OutfitWearRecord(id: draft.wearID, ownerID: draft.ownerID, day: draft.day,
                                     outfitID: draft.outfitID, pieces: snapshots, revision: (draft.baseRecord?.revision ?? 0) + 1,
                                     planEntryID: draft.planEntry?.id ?? draft.baseRecord?.planEntryID)
            try saved.validated()
            if let editedRecord {
                editedRecord.payload = try encode(saved)
                if draft.baseRecord?.day != saved.day || draft.baseRecord?.duplicateKey != saved.duplicateKey {
                    try resetWearLinks(saved.id, in: context)
                }
            } else { context.insert(try StoredOutfitWear(saved)) }
        }
        if let linkedRecord, var entry = draft.planEntry {
            entry.state = .worn; entry.wearRecordID = saved.id; entry.revision += 1
            linkedRecord.payload = try encode(entry)
        }
        context.insert(try StoredOutfitWearSave(draft: draft, saved: saved))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
        return saved
    }
    func finishWearDraft(_ draft: OutfitWearDraft, discarding: Bool = false) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let saved = try savedWear(for: draft)
        guard discarding ? saved == nil : saved != nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredOutfitWearDraft>())
        guard records.count == 1, let record = records.first, try record.value() == draft else { throw StoreError.staleDraft }
        context.delete(record); try commit(context)
    }
}

extension PieceStore {
    func outfitDeletionReview(id: UUID) throws -> OutfitMutationRequest {
        guard let outfit = try outfit(id: id) else { throw StoreError.staleRevision }
        let dependencies = OutfitDeletionDependencies(
            themeRevisions: Dictionary(uniqueKeysWithValues: try themes().filter { $0.outfitIDs.contains(id) }.map { ($0.id, $0.revision) }),
            planRevisions: Dictionary(uniqueKeysWithValues: try planEntries().filter { $0.outfitID == id }.map { ($0.id, $0.revision) }))
        return OutfitMutationRequest(outfit: outfit, action: .delete(dependencies))
    }

    func outfitMutationReceipt(for request: OutfitMutationRequest) throws -> OutfitMutationReceipt? {
        try request.outfit.validated()
        let context = ModelContext(container)
        let proofs = try context.fetch(FetchDescriptor<StoredOutfitMutation>()).filter { $0.id == request.operationID }
        guard proofs.count <= 1 else { throw StoreError.invalidRecord }
        if let proof = proofs.first {
            guard try JSONDecoder().decode(OutfitMutationRequest.self, from: proof.request) == request else { throw StoreError.operationConflict }
            let receipt = try JSONDecoder().decode(OutfitMutationReceipt.self, from: proof.result)
            switch (request.action, receipt) {
            case (.favorite(let flag), .saved(let saved)):
                try saved.validated()
                guard saved.id == request.outfit.id, saved.ownerID == request.outfit.ownerID,
                      saved.isFavorite == flag, saved.revision == request.outfit.revision + 1 else { throw StoreError.invalidRecord }
            case (.delete, .deleted(let id)):
                guard id == request.outfit.id else { throw StoreError.invalidRecord }
            default: throw StoreError.invalidRecord
            }
            return receipt
        }
        return nil
    }

    func applyOutfitMutation(_ request: OutfitMutationRequest) throws -> OutfitMutationReceipt {
        try request.outfit.validated()
        let context = ModelContext(container)
        if let receipt = try outfitMutationReceipt(for: request) { return receipt }
        guard allowsSave, request.outfit.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        let records = try context.fetch(FetchDescriptor<StoredOutfit>())
        guard let record = records.first(where: { $0.id == request.outfit.id }), try record.value() == request.outfit else {
            throw StoreError.staleRevision
        }
        let result: OutfitMutationReceipt
        switch request.action {
        case .favorite(let flag):
            var value = request.outfit
            value.isFavorite = flag; value.revision += 1; value.updatedAt = Date()
            try value.validated()
            record.payload = try JSONEncoder().encode(value)
            result = .saved(value)
        case .delete(let dependencies):
            let current = try outfitDeletionReview(id: request.outfit.id)
            guard current.outfit == request.outfit, current.action == .delete(dependencies) else { throw StoreError.staleRevision }
            let themes = try context.fetch(FetchDescriptor<StoredOutfitTheme>())
            for themeRecord in themes {
                var theme = try themeRecord.value()
                if theme.outfitIDs.contains(request.outfit.id) {
                    theme.outfitIDs.removeAll { $0 == request.outfit.id }; theme.revision += 1
                    try theme.validated(); themeRecord.payload = try JSONEncoder().encode(theme)
                }
            }
            let plans = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>())
            for planRecord in plans {
                var plan = try planRecord.value()
                if plan.outfitID == request.outfit.id {
                    plan.outfitID = nil; plan.outfitRevision = nil; plan.requiresReview = true
                    if plan.state == .planned { plan.state = .unassigned }
                    plan.revision += 1; try plan.validated()
                    planRecord.payload = try JSONEncoder().encode(plan)
                }
            }
            context.delete(record)
            result = .deleted(request.outfit.id)
        }
        context.insert(try StoredOutfitMutation(request: request, result: result))
        try prunePackingChecks(in: context)
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
        return result
    }
}

extension PieceStore {
    func searchCloset(query: String, scope: ClosetSearchScope, favoritesOnly: Bool = false, themeID: UUID? = nil) throws -> ClosetSearchResults {
        let query = Self.searchText(query.trimmingCharacters(in: .whitespacesAndNewlines))
        switch scope {
        case .pieces:
            // Dedicated Pieces search is independent of browse filters. Archived
            // matches are explicit records, never hidden active constraints.
            return .pieces(try (pieces(query: query) + pieces(query: query, archived: true)).sorted {
                let order = $0.name.localizedStandardCompare($1.name)
                return order == .orderedSame ? $0.id.uuidString < $1.id.uuidString : order == .orderedAscending
            })
        case .outfits:
            let themes = try themes()
            let matching = try outfits().filter { outfit in
                guard !favoritesOnly || outfit.isFavorite else { return false }
                guard themeID == nil || themes.contains(where: { $0.id == themeID && $0.outfitIDs.contains(outfit.id) }) else { return false }
                let memberships = themes.filter { $0.outfitIDs.contains(outfit.id) }.map(\.name)
                let terms = [outfit.name, outfit.mood ?? "", outfit.occasion ?? ""] + memberships
                return query.isEmpty || Self.searchText(terms.joined(separator: " ")).contains(query)
            }
            return .outfits(matching)
        case .themes:
            return .themes(try themes().filter { query.isEmpty || Self.searchText($0.name + " " + $0.description).contains(query) })
        }
    }
    func closetIsEmpty() throws -> Bool {
        try pieces().isEmpty && pieces(archived: true).isEmpty && outfits().isEmpty && themes().isEmpty
    }
}

extension PieceStore {
    private struct AvailabilityRequest: Encodable {
        let id: UUID
        let value: PieceAvailability
        let expectedRevision: Int
    }

    @discardableResult
    func setAvailability(id: UUID, value: PieceAvailability, expectedRevision: Int, operationID: UUID) throws -> WardrobePiece {
        let context = ModelContext(container)
        let digest = "availability:" + digest(try encode(AvailabilityRequest(id: id, value: value, expectedRevision: expectedRevision)))
        if let receipt = try context.fetch(FetchDescriptor<StoredPieceSave>(predicate: #Predicate { $0.id == operationID })).first {
            guard receipt.draftDigest == digest else { throw StoreError.operationConflict }
            return try JSONDecoder().decode(WardrobePiece.self, from: receipt.snapshot)
        }
        guard allowsSave else { throw StoreError.corruptStore }
        try ensureUnusedDeletionOperation(operationID, context: context)
        guard try context.fetch(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.operationID == operationID })).isEmpty else {
            throw StoreError.operationConflict
        }
        guard let stored = try context.fetch(FetchDescriptor<StoredPiece>(predicate: #Predicate { $0.id == id })).first,
              stored.revision == expectedRevision else { throw StoreError.staleRevision }
        if value != .available { try flagFuturePlans(using: id, context: context) }
        stored.availability = value.rawValue; stored.revision += 1; stored.updatedAt = Date()
        let result = try stored.value()
        context.insert(StoredPieceSave(id: operationID, itemID: id, draftDigest: digest, snapshot: try encode(result)))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
        return result
    }

    private func flagFuturePlans(using pieceID: UUID, context: ModelContext) throws {
        let affected = Set(try context.fetch(FetchDescriptor<StoredOutfit>()).map { try $0.value() }
            .filter { $0.pieceIDs.contains(pieceID) }.map(\.id))
        try flagFuturePlans(outfitIDs: affected, context: context)
    }

    private func flagFuturePlans(outfitIDs: Set<UUID>, context: ModelContext) throws {
        let owner = try todayConfiguration().ownerID
        for record in try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()) {
            var plan = try record.value()
            guard plan.ownerID == owner else { throw StoreError.invalidRecord }
            let zone = TimeZone(identifier: plan.day.timeZoneID) ?? .current
            guard plan.state == .planned, plan.day.key >= LocalPlanDay(timeZone: zone).key,
                  let outfitID = plan.outfitID, outfitIDs.contains(outfitID), !plan.requiresReview else { continue }
            plan.requiresReview = true; plan.revision += 1; try plan.validated()
            record.payload = try encode(plan)
        }
    }
}

extension PieceStore {
    func pieceDeletionImpact(id: UUID) throws -> PieceDeletionImpact {
        guard let piece = try piece(id: id) else { throw StoreError.staleRevision }
        let affected = try outfits().filter { $0.pieceIDs.contains(id) }
        let ids = Set(affected.map(\.id))
        let themes = try themes().filter { !ids.isDisjoint(with: $0.outfitIDs) }
        let plans = try planEntries().filter { entry in
            let zone = TimeZone(identifier: entry.day.timeZoneID) ?? .current
            return entry.state == .planned && entry.day.key >= LocalPlanDay(timeZone: zone).key
                && entry.outfitID.map { ids.contains($0) } == true
        }
        return PieceDeletionImpact(pieceID: id, pieceRevision: piece.revision,
            outfitRevisions: Dictionary(uniqueKeysWithValues: affected.map { ($0.id, $0.revision) }),
            themeRevisions: Dictionary(uniqueKeysWithValues: themes.map { ($0.id, $0.revision) }),
            futurePlanRevisions: Dictionary(uniqueKeysWithValues: plans.map { ($0.id, $0.revision) }))
    }

    private func applyPieceDeletionImpact(_ impact: PieceDeletionImpact, context: ModelContext) throws {
        var emptyOutfits = Set<UUID>()
        for record in try context.fetch(FetchDescriptor<StoredOutfit>()) {
            var outfit = try record.value()
            guard impact.outfitRevisions[outfit.id] != nil else { continue }
            outfit.pieceIDs.removeAll { $0 == impact.pieceID }
            if outfit.pieceIDs.isEmpty { emptyOutfits.insert(outfit.id); context.delete(record) }
            else {
                outfit.revision += 1; outfit.updatedAt = Date(); try outfit.validated()
                record.payload = try encode(outfit)
            }
        }
        for record in try context.fetch(FetchDescriptor<StoredOutfitTheme>()) {
            var theme = try record.value()
            guard !emptyOutfits.isDisjoint(with: theme.outfitIDs) else { continue }
            theme.outfitIDs.removeAll { emptyOutfits.contains($0) }; theme.revision += 1
            try theme.validated(); record.payload = try encode(theme)
        }
        for record in try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()) {
            var plan = try record.value()
            guard impact.futurePlanRevisions[plan.id] != nil else { continue }
            plan.outfitID = nil; plan.outfitRevision = nil; plan.requiresReview = true; plan.state = .unassigned
            plan.revision += 1; try plan.validated(); record.payload = try encode(plan)
        }
    }
}

extension PieceStore {
    func isThemeDeletionAcknowledged(_ request: ThemeDeletionRequest) throws -> Bool {
        guard request.expectedRevision > 0 else { throw StoreError.invalidRecord }
        let context = ModelContext(container)
        let receipts = try context.fetch(FetchDescriptor<StoredThemeDeletion>()).filter { $0.id == request.operationID }
        guard receipts.count <= 1 else { throw StoreError.invalidRecord }
        guard let receipt = receipts.first else { return false }
        guard try JSONDecoder().decode(ThemeDeletionRequest.self, from: receipt.request) == request else { throw StoreError.operationConflict }
        guard try context.fetch(FetchDescriptor<StoredOutfitTheme>()).allSatisfy({ $0.id != request.themeID }) else { throw StoreError.invalidRecord }
        return true
    }

    func deleteTheme(_ request: ThemeDeletionRequest) throws {
        if try isThemeDeletionAcknowledged(request) { return }
        guard allowsSave else { throw StoreError.corruptStore }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredOutfitTheme>())
        guard let record = records.first(where: { $0.id == request.themeID }) else { throw StoreError.staleRevision }
        let theme = try record.value()
        guard theme.ownerID == (try todayConfiguration().ownerID), theme.revision == request.expectedRevision else { throw StoreError.staleRevision }
        // Memberships belong to this theme alone. Outfit identity, other themes,
        // favorites, plans, pieces and historical wear are independent owners.
        context.delete(record); context.insert(try StoredThemeDeletion(request))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
}

extension PieceStore {
    func deletePlanEntry(_ request: PlanEntryDeletionRequest) throws {
        guard request.expectedRevision > 0 else { throw StoreError.invalidRecord }
        let context = ModelContext(container)
        if let receipt = try context.fetch(FetchDescriptor<StoredPlanEntryDeletion>()).first(where: { $0.id == request.operationID }) {
            guard try JSONDecoder().decode(PlanEntryDeletionRequest.self, from: receipt.request) == request else { throw StoreError.operationConflict }
            return
        }
        guard allowsSave else { throw StoreError.corruptStore }
        guard let record = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()).first(where: { $0.id == request.entryID }) else { throw StoreError.staleRevision }
        let entry = try record.value()
        guard entry.ownerID == (try todayConfiguration().ownerID), entry.revision == request.expectedRevision,
              entry.state == .planned || entry.state == .unassigned else { throw StoreError.staleRevision }
        context.delete(record); context.insert(try StoredPlanEntryDeletion(request))
        try prunePackingChecks(in: context)
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
}

extension PieceStore {
    func planDefinitions() throws -> [PlanDefinition] {
        let owner = try todayConfiguration().ownerID
        let values = try ModelContext(container).fetch(FetchDescriptor<StoredPlanDefinition>()).map { try $0.value() }
        guard values.allSatisfy({ $0.ownerID == owner }) else { throw StoreError.invalidRecord }
        return values.sorted { $0.start.key == $1.start.key ? $0.id.uuidString < $1.id.uuidString : $0.start.key < $1.start.key }
    }
    func planAuthoringDraft() throws -> PlanAuthoringDraft? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredPlanAuthoringDraft>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let value = try records.first?.value() else { return nil }
        guard value.plan.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        return value
    }
    func savePlanAuthoringDraft(_ draft: PlanAuthoringDraft) throws {
        guard allowsSave, draft.plan.ownerID == (try todayConfiguration().ownerID), try savedPlanAuthoring(draft) == nil else { throw StoreError.operationConflict }
        _ = try draft.plan.start.date(); _ = try draft.plan.end.date()
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredPlanAuthoringDraft>())
        guard records.count <= 1, records.first.map({ $0.id == draft.id }) ?? true else { throw StoreError.operationConflict }
        if let record = records.first { record.payload = try encode(draft) }
        else { context.insert(try StoredPlanAuthoringDraft(draft)) }
        try commit(context)
    }
    func savedPlanAuthoring(_ draft: PlanAuthoringDraft) throws -> PlanAuthoringReceipt? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredPlanAuthoringSave>()).filter { $0.id == draft.operationID }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let proof = records.first else { return nil }
        guard try JSONDecoder().decode(PlanAuthoringDraft.self, from: proof.request) == draft else { throw StoreError.operationConflict }
        let result = try JSONDecoder().decode(PlanAuthoringReceipt.self, from: proof.result)
        try result.plan.validated()
        var expectedPlan = draft.plan; expectedPlan.revision = (draft.basePlan?.revision ?? 0) + 1
        guard result.plan == expectedPlan, Set(result.entries.map(\.id)).count == result.entries.count,
              Set(result.entries.map(\.id)) == Set(draft.slots.map(\.id)), result.entries.count == draft.slots.count else { throw StoreError.invalidRecord }
        for entry in result.entries {
            try entry.validated()
            guard let slot = draft.slots.first(where: { $0.id == entry.id }),
                  entry.ownerID == result.plan.ownerID, entry.planID == result.plan.id, entry.day == slot.day,
                  entry.occasion == slot.occasion, entry.outfitID == slot.outfit?.id,
                  entry.outfitRevision == slot.outfit?.revision,
                  entry.revision == (draft.editableBaseEntries.first(where: { $0.id == entry.id })?.revision ?? 0) + 1,
                  entry.state == (slot.outfit == nil ? .unassigned : .planned), !entry.requiresReview else { throw StoreError.invalidRecord }
        }
        return result
    }
    func savePlanAuthoring(_ draft: PlanAuthoringDraft) throws -> PlanAuthoringReceipt {
        if let saved = try savedPlanAuthoring(draft) { return saved }
        guard allowsSave, draft.plan.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        let existing = try planEntries()
        try draft.validatedForSave(outfits: outfits(), existing: existing)
        guard try planAuthoringDraft() == draft else { throw StoreError.staleDraft }
        let active = Set(try pieces().filter { $0.availability == .available }.map(\.id))
        guard draft.slots.allSatisfy({ $0.outfit.map { Set($0.pieceIDs).isSubset(of: active) } ?? true }) else { throw PlanValidationError.unavailablePieces }
        let baseEntries = Dictionary(uniqueKeysWithValues: draft.editableBaseEntries.map { ($0.id, $0) })
        var savedPlan = draft.plan; savedPlan.revision = (draft.basePlan?.revision ?? 0) + 1; try savedPlan.validated()
        let entries = draft.slots.map { slot in
            OutfitPlanEntry(id: slot.id, planID: draft.plan.id, ownerID: draft.plan.ownerID, day: slot.day,
                occasion: slot.occasion, outfitID: slot.outfit?.id, outfitRevision: slot.outfit?.revision,
                state: slot.outfit == nil ? .unassigned : .planned, revision: (baseEntries[slot.id]?.revision ?? 0) + 1)
        }
        for entry in entries { try entry.validated() }
        let context = ModelContext(container)
        let definitions = try context.fetch(FetchDescriptor<StoredPlanDefinition>())
        let record = definitions.first { $0.id == draft.plan.id }
        if let base = draft.basePlan {
            guard let record, try record.value() == base else { throw StoreError.staleRevision }
            let current = existing.filter { $0.planID == base.id }
            let reviewed = draft.baseEntries ?? []
            guard current.count == reviewed.count, current.allSatisfy({ reviewed.contains($0) }) else { throw StoreError.staleRevision }
            record.payload = try encode(savedPlan)
        } else {
            guard record == nil else { throw StoreError.operationConflict }
            context.insert(try StoredPlanDefinition(savedPlan))
        }
        let editableIDs = Set(baseEntries.keys)
        let newIDs = Set(entries.map(\.id))
        guard newIDs.isDisjoint(with: existing.filter { !editableIDs.contains($0.id) }.map(\.id)) else { throw StoreError.operationConflict }
        let replacing = Set(draft.resolutions.filter { $0.choice == .replace }.map { $0.existing.id })
            .union(editableIDs.subtracting(newIDs))
        let entryRecords = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>())
        for record in entryRecords where replacing.contains(record.id) { context.delete(record) }
        for entry in entries {
            if let record = entryRecords.first(where: { $0.id == entry.id }) { record.payload = try encode(entry) }
            else { context.insert(try StoredOutfitPlanEntry(entry)) }
        }
        let result = PlanAuthoringReceipt(plan: savedPlan, entries: entries)
        context.insert(try StoredPlanAuthoringSave(draft: draft, saved: result))
        try prunePackingChecks(in: context)
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
        return result
    }
    func finishPlanAuthoring(_ draft: PlanAuthoringDraft, discarding: Bool = false) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let receipt = try savedPlanAuthoring(draft)
        guard discarding ? receipt == nil : receipt != nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredPlanAuthoringDraft>())
        guard records.count == 1, let record = records.first, try record.value() == draft else { throw StoreError.staleDraft }
        context.delete(record); try commit(context)
    }
}

extension PieceStore {
    func packingState(planID: UUID) throws -> PackingState {
        guard try planDefinitions().contains(where: { $0.id == planID && $0.trip != nil }) else { throw StoreError.staleRevision }
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredPackingState>()).filter { $0.id == planID }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        return try records.first?.value() ?? PackingState(planID: planID)
    }
    func packingSummary(planID: UUID) throws -> TripPackingSummary {
        guard let plan = try planDefinitions().first(where: { $0.id == planID }) else { throw StoreError.staleRevision }
        return try TripPackingSummary(plan: plan, entries: planEntries(), outfits: outfits(), pieces: ownedPiecesForWear(), checkedIDs: packingState(planID: planID).checkedIDs)
    }
    func setPackingCheck(_ request: PackingCheckRequest) throws -> PackingState {
        guard request.expectedRevision >= 0, request.expectedRevision < Int.max - 1 else { throw StoreError.invalidRecord }
        let context = ModelContext(container)
        if let proof = try context.fetch(FetchDescriptor<StoredPackingCheck>()).first(where: { $0.id == request.operationID }) {
            guard try JSONDecoder().decode(PackingCheckRequest.self, from: proof.request) == request else { throw StoreError.operationConflict }
            let value = try JSONDecoder().decode(PackingState.self, from: proof.result)
            guard value.planID == request.planID, value.revision == request.expectedRevision + 1,
                  value.checkedIDs.contains(request.pieceID) == request.checked else { throw StoreError.invalidRecord }
            return value
        }
        guard allowsSave else { throw StoreError.corruptStore }
        let summary = try packingSummary(planID: request.planID)
        guard summary.items.contains(where: { $0.id == request.pieceID }) else { throw StoreError.staleRevision }
        var state = try packingState(planID: request.planID)
        guard state.revision == request.expectedRevision else { throw StoreError.staleRevision }
        state.checkedIDs.formIntersection(summary.items.map(\.id))
        if request.checked { state.checkedIDs.insert(request.pieceID) } else { state.checkedIDs.remove(request.pieceID) }
        state.revision += 1
        if let record = try context.fetch(FetchDescriptor<StoredPackingState>()).first(where: { $0.id == request.planID }) { record.payload = try encode(state) }
        else { context.insert(try StoredPackingState(state)) }
        context.insert(try StoredPackingCheck(request: request, result: state))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
        return state
    }
    private func prunePackingChecks(in context: ModelContext) throws {
        let records = try context.fetch(FetchDescriptor<StoredPackingState>())
        guard !records.isEmpty else { return }
        let definitions = try context.fetch(FetchDescriptor<StoredPlanDefinition>()).map { try $0.value() }
        let owner = try todayConfiguration().ownerID
        guard definitions.allSatisfy({ $0.ownerID == owner }) else { throw StoreError.invalidRecord }
        let entries = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()).map { try $0.value() }
        let outfits = try context.fetch(FetchDescriptor<StoredOutfit>()).map { try $0.value() }
        let pieces = try context.fetch(FetchDescriptor<StoredPiece>()).map { try $0.value() }
        guard entries.allSatisfy({ $0.ownerID == owner }), outfits.allSatisfy({ $0.ownerID == owner }) else { throw StoreError.invalidRecord }
        for record in records {
            var state = try record.value()
            guard let plan = definitions.first(where: { $0.id == state.planID }), plan.trip != nil else { throw StoreError.invalidRecord }
            let summary = try TripPackingSummary(plan: plan, entries: entries, outfits: outfits, pieces: pieces, checkedIDs: state.checkedIDs)
            let retained = state.checkedIDs.intersection(summary.items.map(\.id))
            if retained != state.checkedIDs {
                state.checkedIDs = retained; state.revision += 1
                guard state.revision < Int.max else { throw StoreError.invalidRecord }
                record.payload = try encode(state)
            }
        }
    }
}

extension PieceStore {
    func applyHistoryMutation(_ request: HistoryMutation) throws {
        let context = ModelContext(container)
        if let receipt = try context.fetch(FetchDescriptor<StoredHistoryMutation>()).first(where: { $0.id == request.operationID }) {
            guard try JSONDecoder().decode(HistoryMutation.self, from: receipt.request) == request else { throw StoreError.operationConflict }
            return
        }
        guard allowsSave else { throw StoreError.corruptStore }
        let owner = try todayConfiguration().ownerID
        let entries = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>())
        switch request.action {
        case .undoWear(let base):
            guard base.ownerID == owner,
                  let record = try context.fetch(FetchDescriptor<StoredOutfitWear>()).first(where: { $0.id == base.id }),
                  try record.value() == base else { throw StoreError.staleRevision }
            try resetWearLinks(base.id, in: context)
            context.delete(record)
        case .skip(let base):
            guard base.ownerID == owner, base.state == .planned || base.state == .unassigned,
                  let record = entries.first(where: { $0.id == base.id }), try record.value() == base else { throw StoreError.staleRevision }
            var updated = base; updated.state = .skipped; updated.revision += 1
            try updated.validated(); record.payload = try encode(updated)
        case .deletePlan(let base, let reviewed):
            guard base.ownerID == owner,
                  let record = try context.fetch(FetchDescriptor<StoredPlanDefinition>()).first(where: { $0.id == base.id }),
                  try record.value() == base else { throw StoreError.staleRevision }
            let affected = try entries.filter { try $0.value().planID == base.id }
            let current = try affected.map { try $0.value() }
            guard Set(current.map(\.id)) == Set(reviewed.map(\.id)), current.count == reviewed.count,
                  current.allSatisfy({ reviewed.contains($0) }) else { throw StoreError.staleRevision }
            affected.forEach { context.delete($0) }; context.delete(record)
            for packing in try context.fetch(FetchDescriptor<StoredPackingState>()) where packing.id == base.id { context.delete(packing) }
        }
        context.insert(try StoredHistoryMutation(request))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
}

extension PieceStore {
    private func resetWearLinks(_ wearID: UUID, in context: ModelContext) throws {
        for record in try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()) {
            var entry = try record.value()
            guard entry.wearRecordID == wearID else { continue }
            entry.wearRecordID = nil; entry.state = entry.outfitID == nil ? .unassigned : .planned; entry.revision += 1
            try entry.validated(); record.payload = try encode(entry)
        }
    }
}

extension PieceStore {
    private func personalPhotoOwners(in context: ModelContext) throws -> [(id: UUID, recipe: PhotoEditRecipe)] {
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
    private func personalPhotoReferences(in context: ModelContext) throws -> [UUID] {
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

extension PieceStore {
    func todayDraft() throws -> TodayLayoutDraft? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredTodayDraft>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let value = try records.first?.value() else { return nil }
        guard value.base.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }; return value
    }
    func todayPersonalCards() throws -> [TodayPersonalCard] {
        let owner = try todayConfiguration().ownerID
        let cards = try ModelContext(container).fetch(FetchDescriptor<StoredTodayPersonalCard>()).map { try $0.value() }
        guard cards.allSatisfy({ $0.ownerID == owner }) else { throw StoreError.invalidRecord }
        return cards.sorted { $0.id.uuidString < $1.id.uuidString }
    }
    func todayUndo() throws -> TodayLayoutUndo? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredTodayUndo>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let value = try records.first?.value() else { return nil }
        guard value.current == (try todayConfiguration()) else { throw StoreError.staleRevision }; return value
    }
    func saveTodayDraft(_ draft: TodayLayoutDraft) throws {
        try draft.validated()
        guard allowsSave, draft.base.ownerID == (try todayConfiguration().ownerID), try savedTodayLayout(draft) == nil else { throw StoreError.operationConflict }
        let context = ModelContext(container), records = try context.fetch(FetchDescriptor<StoredTodayDraft>())
        guard records.count <= 1, records.first.map({ $0.id == draft.id }) ?? true else { throw StoreError.operationConflict }
        if let record = records.first { try queueTodayPhotos(record.value(), context: context); record.payload = try encode(draft) }
        else { context.insert(try StoredTodayDraft(draft)) }
        try commit(context)
    }
    func savedTodayLayout(_ draft: TodayLayoutDraft) throws -> TodayConfiguration? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredTodaySave>()).filter { $0.id == draft.operationID }
        guard let receipt = records.first else { return nil }
        if let acknowledgment = try? JSONDecoder().decode(ArchiveOperationDigest.self, from: receipt.request) {
            guard records.count == 1, acknowledgment.digest == digest(try encode(draft)) else { throw StoreError.operationConflict }; return try draft.result()
        }
        guard records.count == 1, try JSONDecoder().decode(TodayLayoutDraft.self, from: receipt.request) == draft else { throw StoreError.operationConflict }
        let result = try JSONDecoder().decode(TodayConfiguration.self, from: receipt.result)
        guard result == (try draft.result()) else { throw StoreError.invalidRecord }; return result
    }
    func saveTodayLayout(_ draft: TodayLayoutDraft) throws -> TodayConfiguration {
        if let result = try savedTodayLayout(draft) { return result }
        guard allowsSave, try todayDraft() == draft, try todayConfiguration() == draft.base else { throw StoreError.staleDraft }
        let result = try draft.result(), context = ModelContext(container)
        let existing = try todayPersonalCards()
        for instance in result.instances {
            try instance.validatedContent(ownerID: result.ownerID, requireContent: instance.options != nil)
            if instance.isVisible, let pin = instance.options?.pinnedID,
               draft.base.instances.first(where: { $0.id == instance.id })?.options?.pinnedID != pin {
                let available: Bool
                switch instance.kind {
                case .todayLook: available = try planEntries().contains { $0.id == pin }
                case .upcomingPlans: available = try planDefinitions().contains { $0.id == pin }
                case .wearAgain: available = try pieces().contains { $0.id == pin && $0.availability == .available }
                case .favoriteOutfits: available = try outfits().contains { $0.id == pin }
                case .theme: available = try themes().contains { $0.id == pin }
                case .fitJournal: available = try fitMemories().contains { $0.id == pin }
                default: available = false
                }
                guard available else { throw TodayLayoutError.selectionRequired }
            }
            if let card = instance.options?.personal {
                let previous = existing.first { $0.id == card.id }
                guard previous == card || previous.map({ card.revision == $0.revision + 1 }) ?? (card.revision == 1) else { throw StoreError.staleRevision }
                if let id = card.photoID, card.photoID != previous?.photoID || card.photoRecipe != previous?.photoRecipe {
                    _ = try photoRendition(id: id, recipe: card.photoRecipe); _ = try photoThumbnail(id: id, recipe: card.photoRecipe)
                }
                if let record = try context.fetch(FetchDescriptor<StoredTodayPersonalCard>()).first(where: { $0.id == card.id }) {
                    if let previous { try queueTodayPhotos([previous], context: context) }
                    record.payload = try encode(card)
                } else { context.insert(try StoredTodayPersonalCard(card)) }
            }
        }
        guard let layout = try context.fetch(FetchDescriptor<StoredTodayLayout>()).first else { throw StoreError.invalidRecord }
        layout.payload = try encode(result)
        for old in try context.fetch(FetchDescriptor<StoredTodayUndo>()) {
            try queueTodayPhotos(old.value().previous.instances.compactMap { $0.options?.personal }, context: context); context.delete(old)
        }
        context.insert(try StoredTodayUndo(TodayLayoutUndo(previous: draft.base, current: result)))
        context.insert(try StoredTodaySave(draft, result: result))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave(); return result
    }
    func finishTodayDraft(_ draft: TodayLayoutDraft, discarding: Bool = false) throws {
        let result = try savedTodayLayout(draft)
        guard discarding ? result == nil : result != nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        guard let record = try context.fetch(FetchDescriptor<StoredTodayDraft>()).first, try record.value() == draft else { throw StoreError.staleDraft }
        try queueTodayPhotos(draft, context: context); context.delete(record); try commit(context)
    }
    private func queueTodayPhotos(_ cards: [TodayPersonalCard], context: ModelContext) throws {
        for card in cards { if let id = card.photoID { try queueCleanup(photoID: id, recipeDigest: try cleanupRecipeDigest(card.photoRecipe), context: context) } }
    }
    private func queueTodayPhotos(_ draft: TodayLayoutDraft, context: ModelContext) throws {
        let layouts = [draft.base, draft.value] + [draft.defaultsUndo].compactMap { $0 }
        let cards = layouts.flatMap { $0.instances.compactMap { $0.options?.personal } } + [draft.nested?.options?.personal, draft.nestedBase?.options?.personal].compactMap { $0 }
        try queueTodayPhotos(cards, context: context)
    }
    private func todayPhotoOwners(in context: ModelContext) throws -> [(id: UUID, recipe: PhotoEditRecipe)] {
        var cards = try context.fetch(FetchDescriptor<StoredTodayPersonalCard>()).map { try $0.value() }
        for record in try context.fetch(FetchDescriptor<StoredTodayLayout>()) { cards += try record.value().instances.compactMap { $0.options?.personal } }
        for record in try context.fetch(FetchDescriptor<StoredTodayUndo>()) { cards += try record.value().previous.instances.compactMap { $0.options?.personal } }
        for record in try context.fetch(FetchDescriptor<StoredTodayDraft>()) {
            let draft = try record.value()
            cards += ([draft.base, draft.value] + [draft.defaultsUndo].compactMap { $0 }).flatMap { $0.instances.compactMap { $0.options?.personal } }
            cards += [draft.nested?.options?.personal, draft.nestedBase?.options?.personal].compactMap { $0 }
        }
        return cards.compactMap { card in card.photoID.map { ($0, card.photoRecipe) } }
    }
}

extension PieceStore {
    func todayCardUsage(_ id: UUID) throws -> TodayCardUsage {
        func contains(_ configuration: TodayConfiguration) -> Bool { configuration.instances.contains { $0.options?.personal?.id == id } }
        let draft = try todayDraft()
        let inDraft = draft.map { value in
            contains(value.base) || contains(value.value) || value.defaultsUndo.map(contains) == true
                || value.nested?.options?.personal?.id == id || value.nestedBase?.options?.personal?.id == id
        } ?? false
        return TodayCardUsage(active: contains(try todayConfiguration()), draft: inDraft, undo: try todayUndo().map { contains($0.previous) } ?? false)
    }
    func reviewTodayCardDeletion(_ card: TodayPersonalCard) throws -> TodayCardDeletion {
        guard try pendingTodayCardDeletion() == nil, try todayPersonalCards().contains(card) else { throw StoreError.staleRevision }
        let usage = try todayCardUsage(card.id)
        guard !usage.active, !usage.draft else { throw StoreError.operationConflict }
        if let draft = try todayDraft(), try savedTodayLayout(draft) != nil { throw StoreError.operationConflict }
        return TodayCardDeletion(card: card, undo: usage.undo ? try todayUndo() : nil)
    }
    func pendingTodayCardDeletion() throws -> TodayCardDeletion? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredTodayCardDeletion>()).filter { !$0.acknowledged }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        let value = try records.first?.value()
        if let value { guard value.card.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord } }
        return value
    }
    func todayCardDeletionApplied(_ request: TodayCardDeletion) throws -> Bool {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredTodayCardDeletion>()).filter { $0.id == request.operationID }
        guard let record = records.first else { return false }
        if let acknowledgment = try? JSONDecoder().decode(ArchiveOperationDigest.self, from: record.payload) {
            guard records.count == 1, record.acknowledged, acknowledgment.digest == digest(try encode(request)) else { throw StoreError.operationConflict }; return record.applied
        }
        guard records.count == 1, try record.value() == request else { throw StoreError.operationConflict }; return record.applied
    }
    func deleteTodayCard(_ request: TodayCardDeletion) throws {
        if try todayCardDeletionApplied(request) { return }
        guard allowsSave, request.card.ownerID == (try todayConfiguration().ownerID), try todayPersonalCards().contains(request.card) else { throw StoreError.staleRevision }
        let usage = try todayCardUsage(request.card.id), undo = try todayUndo()
        let releasesUndo = undo.map { $0.previous.instances.contains { $0.options?.personal?.id == request.card.id } } ?? false
        guard !usage.active, !usage.draft, releasesUndo == (request.undo != nil),
              request.undo == nil || undo == request.undo else { throw StoreError.operationConflict }
        if let draft = try todayDraft(), try savedTodayLayout(draft) != nil { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let tasks = try context.fetch(FetchDescriptor<StoredTodayCardDeletion>())
        guard !tasks.contains(where: { $0.id == request.operationID && $0.acknowledged && !$0.applied }) else { throw StoreError.operationConflict }
        let pending = tasks.filter { !$0.acknowledged }
        guard pending.count <= 1, pending.first.map({ $0.id == request.operationID }) ?? true else { throw StoreError.operationConflict }
        let task: StoredTodayCardDeletion
        if let retained = pending.first { guard try retained.value() == request else { throw StoreError.operationConflict }; task = retained }
        else { task = try StoredTodayCardDeletion(request); context.insert(task); try commit(context) }
        guard let card = try context.fetch(FetchDescriptor<StoredTodayPersonalCard>()).first(where: { $0.id == request.card.id }), try card.value() == request.card else { throw StoreError.staleRevision }
        if request.undo != nil {
            for undo in try context.fetch(FetchDescriptor<StoredTodayUndo>()) {
                try queueTodayPhotos(undo.value().previous.instances.compactMap { $0.options?.personal }, context: context); context.delete(undo)
            }
        }
        try queueTodayPhotos([request.card], context: context)
        context.delete(card); task.applied = true
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
    func finishTodayCardDeletion(_ request: TodayCardDeletion, cancelling: Bool = false) throws {
        let context = ModelContext(container)
        guard let task = try context.fetch(FetchDescriptor<StoredTodayCardDeletion>()).first(where: { $0.id == request.operationID }),
              task.applied || cancelling else { throw StoreError.operationConflict }
        if let acknowledgment = try? JSONDecoder().decode(ArchiveOperationDigest.self, from: task.payload) {
            guard task.acknowledged, acknowledgment.digest == digest(try encode(request)) else { throw StoreError.operationConflict }; return
        }
        guard try task.value() == request else { throw StoreError.operationConflict }
        task.acknowledged = true; try commit(context)
    }
}

extension PieceStore {
    private func photoSources(in context: ModelContext) throws -> [UUID: UUID] {
        var sources: [UUID: UUID] = [:]
        for value in try context.fetch(FetchDescriptor<StoredPhotoSource>()) {
            guard value.id != value.originalID, sources.updateValue(value.originalID, forKey: value.id) == nil else { throw StoreError.invalidRecord }
        }
        guard sources.values.allSatisfy({ sources[$0] == nil }) else { throw StoreError.invalidRecord }
        return sources
    }
    private func photoReferences(_ ids: [UUID], context: ModelContext) throws -> Set<UUID> {
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

extension PieceStore {
    func agentConversations() throws -> [AgentConversation] {
        let owner = try todayConfiguration().ownerID
        return try ModelContext(container).fetch(FetchDescriptor<StoredAgentConversation>()).map {
            let value = try $0.value()
            guard value.ownerID == owner else { throw StoreError.invalidRecord }; return value
        }.sorted { $0.updatedAt == $1.updatedAt ? $0.id.uuidString < $1.id.uuidString : $0.updatedAt > $1.updatedAt }
    }
    @discardableResult func saveAgentConversation(_ value: AgentConversation, operationID: UUID) throws -> AgentConversation {
        try value.validated()
        guard value.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        let context = ModelContext(container), checksum = digest(try encode(value))
        if let receipt = try context.fetch(FetchDescriptor<StoredAgentOperation>()).first(where: { $0.id == operationID }) {
            guard receipt.conversationID == value.id, receipt.digest == checksum, let result = receipt.result else { throw StoreError.operationConflict }
            if let acknowledgment = try? JSONDecoder().decode(AgentSaveAcknowledgment.self, from: result) {
                var saved = value; saved.revision = acknowledgment.revision; saved.updatedAt = acknowledgment.updatedAt; return saved
            }
            return try JSONDecoder().decode(AgentConversation.self, from: result)
        }
        guard !(try context.fetch(FetchDescriptor<StoredAgentOperation>())).contains(where: { $0.conversationID == value.id && $0.result == nil }) else { throw StoreError.deletedPiece }
        let stored = try context.fetch(FetchDescriptor<StoredAgentConversation>()).first { $0.id == value.id }
        guard try stored?.value().revision ?? 0 == value.revision else { throw StoreError.staleRevision }
        var saved = value; saved.revision += 1; saved.updatedAt = Date()
        try beforeOutfitSave()
        if let stored { stored.payload = try encode(saved) } else { context.insert(try StoredAgentConversation(saved)) }
        context.insert(StoredAgentOperation(id: operationID, conversationID: value.id, digest: checksum, result: try encode(AgentSaveAcknowledgment(revision: saved.revision, updatedAt: saved.updatedAt))))
        try commit(context); try afterOutfitSave(); return saved
    }
    func deleteAgentConversation(id: UUID, expectedRevision: Int, operationID: UUID) throws {
        let context = ModelContext(container), checksum = "delete:\(id):\(expectedRevision)"
        if let receipt = try context.fetch(FetchDescriptor<StoredAgentOperation>()).first(where: { $0.id == operationID }) {
            guard receipt.conversationID == id, receipt.digest == checksum, receipt.result == nil else { throw StoreError.operationConflict }; return
        }
        guard let stored = try context.fetch(FetchDescriptor<StoredAgentConversation>()).first(where: { $0.id == id }),
              try stored.value().revision == expectedRevision,
              try stored.value().ownerID == todayConfiguration().ownerID else { throw StoreError.staleRevision }
        guard try !(stored.value().proposals ?? []).contains(where: { $0.status == .executing }) else { throw StoreError.operationConflict }
        try beforeOutfitSave(); context.delete(stored)
        // Superseded save acknowledgments no longer retain deleted conversation text.
        for receipt in try context.fetch(FetchDescriptor<StoredAgentOperation>()) where receipt.conversationID == id { context.delete(receipt) }
        context.insert(StoredAgentOperation(id: operationID, conversationID: id, digest: checksum, result: nil))
        try commit(context); try afterOutfitSave()
    }
}

private struct AgentSaveAcknowledgment: Codable {
    let revision: Int
    let updatedAt: Date
}

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
        for plan in plans { _ = try packingState(planID: plan.id) }
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

private struct ArchiveOperationDigest: Codable { let digest: String }
extension PieceStore {
    private func archivePieceDraft(_ record: StoredPieceDraft) throws -> PieceDraft {
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

#if DEBUG
extension PieceStore {
    /// Compare-and-swap the exact legacy seed text, never any user-edited fields.
    func replacePreviewSampleContexts(plans: [(before: OutfitPlanEntry, after: OutfitPlanEntry)], fits: [(before: FitMemory, after: FitMemory)]) throws {
        guard allowsSave, Set(plans.map { $0.before.id }).count == plans.count,
              Set(fits.map { $0.before.id }).count == fits.count else { throw StoreError.invalidRecord }
        let owner = try todayConfiguration().ownerID
        let context = ModelContext(container)
        for change in plans {
            let before = change.before, id = before.id
            guard let index = (0..<7).first(where: { PreviewSampleContent.id(301 + $0) == id }),
                  before.ownerID == owner, before.revision == 1, before.occasion == PreviewSampleContent.legacyPlanOccasion(index),
                  before.state == .planned, !before.requiresReview,
                  let record = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>(predicate: #Predicate { $0.id == id })).first,
                  try record.value() == before else { throw StoreError.staleRevision }
            var expected = before; expected.occasion = PreviewSampleContent.planContexts[index]; expected.revision += 1
            guard expected == change.after else { throw StoreError.invalidRecord }
            try expected.validated(); record.payload = try JSONEncoder().encode(expected)
        }
        for change in fits {
            let before = change.before, id = before.id
            guard let index = (0..<8).first(where: { PreviewSampleContent.id(401 + $0) == id }),
                  before.ownerID == owner, before.revision == 1, before.note == PreviewSampleContent.legacyFitNote,
                  let record = try context.fetch(FetchDescriptor<StoredFitMemory>(predicate: #Predicate { $0.id == id })).first,
                  try record.value() == before else { throw StoreError.staleRevision }
            var expected = before; expected.note = PreviewSampleContent.fitNotes[index]; expected.revision += 1
            guard expected == change.after else { throw StoreError.invalidRecord }
            try expected.validated(); record.payload = try JSONEncoder().encode(expected)
        }
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
    func replacePreviewSamplePhotos(_ replacements: [(piece: WardrobePiece, photoID: UUID)]) throws {
        guard allowsSave, Set(replacements.map { $0.piece.id }).count == replacements.count else { throw StoreError.invalidRecord }
        let context = ModelContext(container)
        for replacement in replacements {
            let piece = replacement.piece, id = piece.id
            guard PreviewSampleContent.sampleIDs["pieces", default: []].contains(id), piece.revision == 1,
                  piece.photoRecipe == .fitOriginal,
                  let record = try context.fetch(FetchDescriptor<StoredPiece>(predicate: #Predicate { $0.id == id })).first,
                  try record.value() == piece else { throw StoreError.staleRevision }
            _ = try originalPhoto(id: replacement.photoID); _ = try thumbnailPhoto(id: replacement.photoID)
            let result = WardrobePiece(id: id, name: piece.name, category: piece.category, photoID: replacement.photoID,
                details: piece.details, availability: piece.availability, revision: piece.revision + 1,
                isArchived: piece.isArchived, createdAt: piece.createdAt, updatedAt: Date(), photoRecipe: .fitOriginal)
            try queueCleanup(photoID: piece.photoID, context: context)
            record.apply(result)
        }
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
    /// Owner-requested sample population. All graph records commit together;
    /// existing records/drafts and actual wear remain unchanged.
    func insertPreviewSamples(_ samples: PreviewSampleContent.Bundle) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let owner = try todayConfiguration().ownerID
        let existing = try PreviewSampleContent.existingIDs(in: self)
        guard existing.values.allSatisfy(\.isEmpty) else { throw StoreError.operationConflict }
        let pieceIDs = Set(samples.pieces.map(\.id))
        let availableIDs = Set(samples.pieces.filter { $0.availability == .available }.map(\.id))
        let outfitIDs = Set(samples.outfits.map(\.id))
        guard pieceIDs.count == samples.pieces.count, outfitIDs.count == samples.outfits.count,
              pieceIDs == Set(PreviewSampleContent.sampleIDs["pieces", default: []]),
              outfitIDs == Set(PreviewSampleContent.sampleIDs["outfits", default: []]),
              Set(samples.themes.map(\.id)) == Set(PreviewSampleContent.sampleIDs["themes", default: []]),
              Set(samples.plans.map(\.id)) == Set(PreviewSampleContent.sampleIDs["plans", default: []]),
              Set(samples.fits.map(\.id)) == Set(PreviewSampleContent.sampleIDs["fits", default: []]) else { throw StoreError.invalidRecord }
        for piece in samples.pieces {
            try PieceDraft(name: piece.name, category: piece.category, photoID: piece.photoID, details: piece.details).validated()
            try piece.photoRecipe.validated()
            _ = try photoRendition(id: piece.photoID, recipe: piece.photoRecipe)
        }
        for outfit in samples.outfits {
            try outfit.validated()
            guard outfit.ownerID == owner, Set(outfit.pieceIDs).isSubset(of: availableIDs) else { throw StoreError.invalidRecord }
        }
        var names = Set(try themes().map { OutfitTheme.nameKey($0.name) })
        for theme in samples.themes {
            try theme.validated()
            guard theme.ownerID == owner, Set(theme.outfitIDs).isSubset(of: outfitIDs),
                  names.insert(OutfitTheme.nameKey(theme.name)).inserted else { throw StoreError.invalidRecord }
        }
        let existingPlans = try planEntries()
        for plan in samples.plans {
            try plan.validated()
            guard plan.ownerID == owner, plan.state == .planned,
                  samples.outfits.contains(where: { $0.id == plan.outfitID && $0.revision == plan.outfitRevision }),
                  !existingPlans.contains(where: { $0.day == plan.day && $0.occasion == plan.occasion }) else { throw StoreError.invalidRecord }
        }
        for fit in samples.fits {
            try fit.validated()
            guard fit.ownerID == owner, let snapshot = fit.outfit,
                  let outfit = samples.outfits.first(where: { $0.id == snapshot.id }),
                  try FitOutfitSnapshot(outfit: outfit, pieces: samples.pieces) == snapshot else { throw StoreError.invalidRecord }
            if let photo = fit.photoID { _ = try photoRendition(id: photo, recipe: fit.photoRecipe) }
        }
        let context = ModelContext(container)
        for value in samples.pieces { context.insert(StoredPiece(value)) }
        for value in samples.outfits { context.insert(try StoredOutfit(value)) }
        for value in samples.themes { context.insert(try StoredOutfitTheme(value)) }
        for value in samples.plans { context.insert(try StoredOutfitPlanEntry(value)) }
        for value in samples.fits { context.insert(try StoredFitMemory(value)) }
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
}
#endif
