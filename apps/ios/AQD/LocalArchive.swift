import Foundation
import CryptoKit
import Darwin
import SQLite3
import ImageIO
import UniformTypeIdentifiers

enum LocalArchiveError: Error { case invalid, newer, tooLarge, sourceChanged, missingMedia, unsafePath, cleanupPending }
struct LocalArchiveSummary: Codable, Equatable, Sendable {
    let ownerID: UUID
    let pieces: Int
    let outfits: Int
    let themes: Int
    let plans: Int
    let entries: Int
    let wear: Int
    let fits: Int
    let conversations: Int
    let personalCards: Int
    let drafts: Int
    var description: String { "\(pieces) pieces · \(outfits) outfits · \(themes) themes · \(plans) plans / \(entries) dates · \(wear) wear records · \(fits) fit memories · \(conversations) conversations · \(personalCards) personal cards · \(drafts) drafts" }
}
struct LocalArchiveFile: Sendable { let path: String; let data: Data }
struct LocalArchiveHeader: Codable, Sendable {
    struct File: Codable, Sendable { let path: String; let size: Int; let sha256: String }
    let databaseSchema: Int
    let createdAt: Date
    let summary: LocalArchiveSummary
    let files: [File]
}
struct LocalArchivePackage: Sendable {
    static let supportedFormatVersion = 2
    static let maximumBytes = 64 * 1024 * 1024
    static var maximumSizeDescription: String { ByteCountFormatter.string(fromByteCount: Int64(maximumBytes), countStyle: .memory) }
    static let maximumHeader = 1024 * 1024
    static let schema = 22
    let header: LocalArchiveHeader
    let files: [LocalArchiveFile]
    init(summary: LocalArchiveSummary, files: [LocalArchiveFile], databaseSchema: Int = schema) throws {
        try Self.validatePaths(files.map(\.path))
        header = LocalArchiveHeader(databaseSchema: databaseSchema, createdAt: Date(), summary: summary,
            files: files.map { LocalArchiveHeader.File(path: $0.path, size: $0.data.count, sha256: Self.hash($0.data)) })
        self.files = files
    }
    private init(header: LocalArchiveHeader, files: [LocalArchiveFile]) { self.header = header; self.files = files }
    static func hash(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
    func encoded() throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let metadata = try encoder.encode(header)
        guard metadata.count <= Self.maximumHeader else { throw LocalArchiveError.tooLarge }
        var result = Data("AQDARCH\n".utf8)
        // Owned file names retain their legacy .jpg identities. Detect content,
        // and flag PNG archives so old readers report a newer format safely.
        let hasPNG = files.contains { $0.path.hasPrefix("media/") && $0.data.starts(with: [137, 80, 78, 71, 13, 10, 26, 10]) }
        for number in [UInt32(hasPNG ? 2 : 1), UInt32(metadata.count)] { result.append(contentsOf: [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: number >> $0) }) }
        result.append(metadata)
        for file in files { guard file.data.count <= Self.maximumBytes - result.count else { throw LocalArchiveError.tooLarge }; result.append(file.data) }
        return result
    }
    static func decode(_ data: Data) throws -> Self {
        guard data.count <= maximumBytes else { throw LocalArchiveError.tooLarge }
        guard data.count >= 16, data.prefix(8) == Data("AQDARCH\n".utf8) else { throw LocalArchiveError.invalid }
        func integer(_ range: Range<Int>) -> Int { data[range].reduce(0) { ($0 << 8) | Int($1) } }
        let version = integer(8..<12), size = integer(12..<16)
        guard version <= supportedFormatVersion else { throw LocalArchiveError.newer }
        guard version >= 1, size > 0, size <= maximumHeader, size <= data.count - 16 else { throw LocalArchiveError.invalid }
        let header = try JSONDecoder().decode(LocalArchiveHeader.self, from: data.subdata(in: 16..<(16 + size)))
        guard header.databaseSchema <= schema else { throw LocalArchiveError.newer }
        guard header.databaseSchema > 0, header.createdAt.timeIntervalSince1970.isFinite else { throw LocalArchiveError.invalid }
        try validatePaths(header.files.map(\.path))
        var offset = 16 + size, files: [LocalArchiveFile] = []
        for file in header.files {
            guard file.size > 0, file.size <= data.count - offset, file.sha256.count == 64 else { throw LocalArchiveError.invalid }
            let bytes = data.subdata(in: offset..<(offset + file.size)); offset += file.size
            guard hash(bytes) == file.sha256 else { throw LocalArchiveError.invalid }
            files.append(LocalArchiveFile(path: file.path, data: bytes))
        }
        guard offset == data.count, files.first(where: { $0.path == "schema-version" })?.data == Data("AQD-piece-store:\(header.databaseSchema)".utf8) else { throw LocalArchiveError.invalid }
        return Self(header: header, files: files)
    }
    private static func validatePaths(_ paths: [String]) throws {
        guard paths.count >= 2, paths.count <= 10000, Set(paths).count == paths.count, paths.contains("wardrobe.store"), paths.contains("schema-version") else { throw LocalArchiveError.invalid }
        let uuid = "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}"
        for path in paths where path != "wardrobe.store" && path != "schema-version" {
            guard path.range(of: "^media/" + uuid + "(-thumbnail|-edit-[0-9a-f]{64}-(rendition|thumbnail))?\\.jpg$", options: .regularExpression) != nil else { throw LocalArchiveError.unsafePath }
        }
    }
}

/// Only regular files under the selected sandbox roots; no leaf symlinks or unbounded reads.
enum LocalArchiveIO {
    static func read(_ url: URL, maximum: Int = LocalArchivePackage.maximumBytes) throws -> Data {
        let descriptor = open(url.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
        guard descriptor >= 0 else { throw LocalArchiveError.invalid }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true); defer { try? handle.close() }
        var status = stat()
        guard fstat(descriptor, &status) == 0, status.st_mode & S_IFMT == S_IFREG, status.st_size >= 0, status.st_size <= maximum else { throw LocalArchiveError.tooLarge }
        var result = Data()
        while let chunk = try handle.read(upToCount: min(65536, maximum - result.count + 1)), !chunk.isEmpty {
            try Task.checkCancellation(); guard chunk.count <= maximum - result.count else { throw LocalArchiveError.tooLarge }; result.append(chunk)
        }
        guard result.count == status.st_size else { throw LocalArchiveError.sourceChanged }; return result
    }
    /// Existing recovery files are not archive payloads. Hash them with bounded memory.
    static func fingerprint(_ url: URL) throws -> String {
        let descriptor = open(url.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
        guard descriptor >= 0 else { throw LocalArchiveError.invalid }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true); defer { try? handle.close() }
        var status = stat()
        guard fstat(descriptor, &status) == 0, status.st_mode & S_IFMT == S_IFREG, status.st_size >= 0 else { throw LocalArchiveError.invalid }
        var digest = SHA256(), count: Int64 = 0
        while let chunk = try handle.read(upToCount: 65536), !chunk.isEmpty {
            try Task.checkCancellation()
            guard chunk.count <= status.st_size - count else { throw LocalArchiveError.sourceChanged }
            digest.update(data: chunk); count += Int64(chunk.count)
        }
        guard count == status.st_size else { throw LocalArchiveError.sourceChanged }
        return digest.finalize().map { String(format: "%02x", $0) }.joined()
    }
    static func protectedDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.complete])
        try protect(url)
    }
    static func protect(_ url: URL) throws {
        var target = url; var values = URLResourceValues(); values.isExcludedFromBackup = true; try target.setResourceValues(values)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
    }
    static func write(_ data: Data, to url: URL) throws { try data.write(to: url, options: [.atomic, .completeFileProtection]); try protect(url) }
    static func snapshot(database source: URL, to destination: URL) throws {
        try Task.checkCancellation()
        guard try FileManager.default.attributesOfItem(atPath: source.path)[.type] as? FileAttributeType == .typeRegular,
              !FileManager.default.fileExists(atPath: destination.path) else { throw LocalArchiveError.unsafePath }
        try write(Data(), to: destination)
        var input: OpaquePointer?, output: OpaquePointer?
        guard sqlite3_open_v2(source.path, &input, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { if input != nil { sqlite3_close(input) }; throw LocalArchiveError.invalid }
        defer { sqlite3_close(input) }
        guard sqlite3_open_v2(destination.path, &output, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK else { if output != nil { sqlite3_close(output) }; throw LocalArchiveError.invalid }
        defer { sqlite3_close(output) }
        sqlite3_progress_handler(output, 1000, { _ in Task<Never, Never>.isCancelled ? 1 : 0 }, nil)
        guard let backup = sqlite3_backup_init(output, "main", input, "main") else { throw LocalArchiveError.invalid }
        var open = true
        defer { if open { sqlite3_backup_finish(backup) } }
        while true {
            try Task.checkCancellation()
            let step = sqlite3_backup_step(backup, 256)
            if step == SQLITE_DONE { break }
            guard step == SQLITE_OK else { throw LocalArchiveError.sourceChanged }
        }
        let finish = sqlite3_backup_finish(backup); open = false
        guard finish == SQLITE_OK else { throw LocalArchiveError.invalid }
        for query in ["PRAGMA wal_checkpoint(TRUNCATE)", "PRAGMA journal_mode=DELETE", "VACUUM"] {
            try Task.checkCancellation()
            guard sqlite3_exec(output, query, nil, nil, nil) == SQLITE_OK else { try Task.checkCancellation(); throw LocalArchiveError.invalid }
        }
        try protect(destination)
    }
    static func validatePhoto(_ data: Data) throws {
        guard data.count <= 64 * 1024 * 1024,
              let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let type = CGImageSourceGetType(source) as String?,
              (type == UTType.jpeg.identifier && data.suffix(2).elementsEqual([0xFF, 0xD9]) ||
               type == UTType.png.identifier && data.suffix(12).elementsEqual([0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130])),
              CGImageSourceGetCount(source) == 1, CGImageSourceGetStatus(source) == .statusComplete,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
              width > 0, height > 0, width <= 32768, height <= 32768, width <= 40_000_000 / height,
              CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCache: false] as CFDictionary) != nil else { throw LocalArchiveError.missingMedia }
    }
    static func validateDatabase(_ url: URL) throws {
        try Task.checkCancellation()
        var database: OpaquePointer?
        guard sqlite3_open_v2(url.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { if database != nil { sqlite3_close(database) }; throw LocalArchiveError.invalid }; defer { sqlite3_close(database) }
        sqlite3_progress_handler(database, 1000, { _ in Task<Never, Never>.isCancelled ? 1 : 0 }, nil)
        for query in ["PRAGMA integrity_check", "SELECT count(*) FROM sqlite_master WHERE type IN ('trigger','view')"] {
            try Task.checkCancellation()
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else { throw LocalArchiveError.invalid }; defer { sqlite3_finalize(statement) }
            let code = sqlite3_step(statement)
            try Task.checkCancellation()
            guard code == SQLITE_ROW, let value = sqlite3_column_text(statement, 0) else { throw LocalArchiveError.invalid }
            let actual = String(cString: value)
            guard actual == (query.hasPrefix("PRAGMA") ? "ok" : "0") else { throw LocalArchiveError.invalid }
        }
    }
}
