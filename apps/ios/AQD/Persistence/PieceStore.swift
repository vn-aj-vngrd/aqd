import AQDCore
import CoreData
import CryptoKit
import Darwin
import Foundation
import SwiftData

/// All record operations are serialized on the UI actor and return immutable values.
/// Media is finalized before references are saved; it is not a database transaction.
@MainActor
final class PieceStore {
    enum StoreError: Error {
        case missingPhoto, invalidRecord, existingPiece, conflictingMedia, operationConflict, staleDraft, staleRevision, deletedPiece, unsupportedStore, corruptStore, cleanupPending, unsafeMediaPath
    }

    let directory: URL
    let mediaDirectory: URL
    let container: ModelContainer
    let allowsSave: Bool
    let removeMediaFile: (URL) throws -> Void
    let writeMediaFile: (Data, URL) throws -> Void
    let beforeStyleSave: () throws -> Void
    let afterStyleSave: () throws -> Void
    let beforeExperienceRead: () throws -> Void
    let beforeOutfitSave: () throws -> Void
    let afterOutfitSave: () throws -> Void

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

    enum BootstrapSnapshotError: Error { case changed }

    static func interruptedBootstrapNeedsToday(storeURL: URL, schema: Schema) throws -> Bool {
        for _ in 0..<3 {
            do { return try inspectStableBootstrapSnapshot(storeURL: storeURL, schema: schema) }
            catch BootstrapSnapshotError.changed { continue }
        }
        throw StoreError.unsupportedStore
    }

    static func inspectStableBootstrapSnapshot(storeURL: URL, schema: Schema) throws -> Bool {
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

    static func inspectBootstrapCopyNeedsToday(storeURL: URL, schema: Schema) throws -> Bool {
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

    static func bootstrapNeedsToday(in context: ModelContext, storeVersion: Int = 22) throws -> Bool {
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

    func experienceRecord(in context: ModelContext) throws -> (record: StoredLocalExperience, value: LocalExperience) {
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

    func encode<T: Encodable>(_ value: T) throws -> Data {
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

    static func searchText(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    struct ArchiveRequest: Encodable {
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

    func ensureUnusedDeletionOperation(_ operationID: UUID, context: ModelContext) throws {
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

    func cleanupRecipeDigest(_ recipe: PhotoEditRecipe) throws -> String? {
        recipe == .fitOriginal ? nil : try PhotoPreparer.recipeDigest(recipe)
    }

    func queueCleanup(photoID: UUID, recipeDigest: String? = nil, context: ModelContext) throws {
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
    func managedArtifactExists(_ url: URL) throws -> Bool {
        do {
            guard try FileManager.default.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType == .typeRegular else {
                throw StoreError.unsafeMediaPath
            }
            return true
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile { return false }
    }

    func decodedDrafts(_ context: ModelContext) throws -> [(StoredPieceDraft, PieceDraft)] {
        try context.fetch(FetchDescriptor<StoredPieceDraft>()).map { stored in
            let value = try JSONDecoder().decode(PieceDraft.self, from: stored.payload)
            guard value.id == stored.id, value.itemID == stored.itemID else { throw StoreError.invalidRecord }
            try value.photoRecipe.validated()
            return (stored, value)
        }
    }

    func decodedReceipts(_ context: ModelContext) throws -> [(StoredPieceSave, WardrobePiece)] {
        try context.fetch(FetchDescriptor<StoredPieceSave>()).map { stored in
            let value = try JSONDecoder().decode(WardrobePiece.self, from: stored.snapshot)
            guard value.id == stored.itemID, value.revision > 0 else { throw StoreError.invalidRecord }
            try value.photoRecipe.validated()
            return (stored, value)
        }
    }

    func finishCleanup(_ acknowledgment: StoredPieceDeletion, context: ModelContext) throws {
        guard !acknowledgment.pendingPhotoIDs.isEmpty else { return }
        try cleanPhotos(acknowledgment.pendingPhotoIDs, context: context)
        acknowledgment.pendingPhotoIDs = []
        try commit(context)
    }

    func cleanPhotos(_ photoIDs: [UUID], stagedRecipeDigests: [String] = [], context: ModelContext) throws {
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

    func removeOwnedMediaFile(_ url: URL) throws {
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

    func digest(_ payload: Data) -> String {
        SHA256.hash(data: payload).map { String(format: "%02x", $0) }.joined()
    }

    func commit(_ context: ModelContext) throws {
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

    func editURL(id: UUID, recipe: PhotoEditRecipe, kind: String) throws -> URL {
        mediaDirectory.appendingPathComponent("\(id.uuidString)-edit-\(try PhotoPreparer.recipeDigest(recipe))-\(kind).jpg")
    }

    func ensureOwnedMediaDirectory() throws {
        let owned = directory.resolvingSymlinksInPath().appendingPathComponent("media", isDirectory: true)
        guard mediaDirectory.resolvingSymlinksInPath().standardizedFileURL == owned.standardizedFileURL,
              try FileManager.default.attributesOfItem(atPath: mediaDirectory.path)[.type] as? FileAttributeType == .typeDirectory else {
            throw StoreError.unsafeMediaPath
        }
    }

    func readMedia(_ url: URL) throws -> Data {
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

    func originalURL(id: UUID) -> URL {
        mediaDirectory.appendingPathComponent("\(id.uuidString).jpg")
    }

    func protectStoreFiles() throws {
        guard try FileManager.default.attributesOfItem(atPath: directory.path)[.type] as? FileAttributeType == .typeDirectory else {
            throw StoreError.unsafeMediaPath
        }
        // Reapply before commits too: WAL/SHM can be created or replaced after initialization.
        for file in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            try Self.protect(file)
        }
    }

    static func createProtectedDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true,
                                              attributes: [.protectionKey: FileProtectionType.complete])
        try protect(url)
    }

    static func protect(_ url: URL) throws {
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
