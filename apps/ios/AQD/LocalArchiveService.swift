import Foundation

struct LocalArchiveSeed: Sendable {
    let directory: URL
    let media: [URL]
    let stamp: UUID?
}
struct ValidatedLocalArchive {
    let directory: URL
    let store: PieceStore
    let summary: LocalArchiveSummary
    let migratedFrom: Int?
}
@MainActor enum LocalArchiveService {
    private static var inFlight: Set<URL> = []
    private static var stagedStores: [URL: WeakLocalStore] = [:]
    static var hasInFlightWork: Bool { !inFlight.isEmpty }
    static func cleanupTemporaryArchives() throws -> Bool {
        var complete = true
        let root = FileManager.default.temporaryDirectory
        let pattern = "^AQD-(archive|restore|bootstrap)-[0-9A-Fa-f-]{36}$"
        for url in try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) where url.lastPathComponent.range(of: pattern, options: .regularExpression) != nil {
            if inFlight.contains(url) || stagedStores[url]?.value != nil { complete = false; continue }
            guard try FileManager.default.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType == .typeDirectory else { throw LocalArchiveError.unsafePath }
            try FileManager.default.removeItem(at: url)
        }
        stagedStores = stagedStores.filter { $0.value.value != nil }
        return complete
    }
    static func create(store: PieceStore) async throws -> (data: Data, summary: LocalArchiveSummary) {
        let seed = try store.archiveSeed(); inFlight.insert(seed.directory)
        defer { inFlight.remove(seed.directory); try? FileManager.default.removeItem(at: seed.directory) }
        let copying = Task.detached(priority: .utility) {
            var remaining = LocalArchivePackage.maximumBytes
            for source in seed.media {
                try Task.checkCancellation()
                let bytes = try LocalArchiveIO.read(source, maximum: remaining); remaining -= bytes.count
                try autoreleasepool { try LocalArchiveIO.validatePhoto(bytes) }
                try LocalArchiveIO.write(bytes, to: seed.directory.appendingPathComponent("media").appendingPathComponent(source.lastPathComponent))
            }
        }
        try await withTaskCancellationHandler { try await copying.value } onCancel: { copying.cancel() }
        try Task.checkCancellation()
        let copy = try PieceStore(directory: seed.directory)
        try copy.reconcilePendingPhotoCleanup()
        try copy.compactArchiveAcknowledgments()
        let summary = try copy.validateArchiveContents()
        let finalDatabase = seed.directory.appendingPathComponent("export.store")
        try LocalArchiveIO.snapshot(database: seed.directory.appendingPathComponent("wardrobe.store"), to: finalDatabase)
        try LocalArchiveIO.validateDatabase(finalDatabase)
        let encoding = Task.detached(priority: .utility) {
            var files = [LocalArchiveFile(path: "wardrobe.store", data: try LocalArchiveIO.read(finalDatabase)),
                         LocalArchiveFile(path: "schema-version", data: Data("AQD-piece-store:\(LocalArchivePackage.schema)".utf8))]
            var remaining = LocalArchivePackage.maximumBytes - files.reduce(0) { $0 + $1.data.count }
            let media = seed.directory.appendingPathComponent("media")
            for url in try FileManager.default.contentsOfDirectory(at: media, includingPropertiesForKeys: nil).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                try Task.checkCancellation()
                let bytes = try LocalArchiveIO.read(url, maximum: remaining); remaining -= bytes.count
                files.append(LocalArchiveFile(path: "media/" + url.lastPathComponent, data: bytes))
            }
            return try LocalArchivePackage(summary: summary, files: files).encoded()
        }
        let data = try await withTaskCancellationHandler { try await encoding.value } onCancel: { encoding.cancel() }
        guard try store.mutationStamp() == seed.stamp else { throw LocalArchiveError.sourceChanged }
        try Task.checkCancellation(); return (data, summary)
    }
    static func stage(_ package: LocalArchivePackage, directory proposedDirectory: URL? = nil) async throws -> ValidatedLocalArchive {
        let directory = proposedDirectory ?? FileManager.default.temporaryDirectory.appendingPathComponent("AQD-restore-\(UUID().uuidString)", isDirectory: true)
        inFlight.insert(directory); defer { inFlight.remove(directory) }
        do {
            try LocalArchiveIO.protectedDirectory(directory); try LocalArchiveIO.protectedDirectory(directory.appendingPathComponent("media"))
            let writing = Task.detached(priority: .utility) {
                for file in package.files {
                    try Task.checkCancellation()
                    if file.path.hasPrefix("media/") { try autoreleasepool { try LocalArchiveIO.validatePhoto(file.data) } }
                    try LocalArchiveIO.write(file.data, to: directory.appendingPathComponent(file.path))
                }
                try LocalArchiveIO.validateDatabase(directory.appendingPathComponent("wardrobe.store"))
            }
            try await withTaskCancellationHandler { try await writing.value } onCancel: { writing.cancel() }
            try Task.checkCancellation()
            let actualSchema = try PieceStore.archiveSchema(at: directory.appendingPathComponent("wardrobe.store"))
            guard actualSchema == package.header.databaseSchema else { throw LocalArchiveError.invalid }
            let store = try PieceStore(directory: directory)
            let summary = try store.validateArchiveContents()
            guard summary == package.header.summary else { throw LocalArchiveError.invalid }
            stagedStores[directory] = WeakLocalStore(store)
            return ValidatedLocalArchive(directory: directory, store: store, summary: summary,
                migratedFrom: package.header.databaseSchema < LocalArchivePackage.schema ? package.header.databaseSchema : nil)
        } catch { try? FileManager.default.removeItem(at: directory); throw error }
    }
}
