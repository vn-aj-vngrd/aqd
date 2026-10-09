import AQDCore
import Foundation
import SwiftData
import Testing
@testable import AQD

@MainActor
struct TodayPersistenceTests {
    @Test func firstUseStockHasStableOwnerAndInstanceIDsAfterReadOnlyReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store: PieceStore? = try PieceStore(directory: directory)
        let first = try #require(store).todayConfiguration()
        #expect(first.instances.map(\.kind) == [.todayLook, .weekInWear, .closetInUse])
        #expect(Set(first.instances.map(\.id)).count == 3)
        #expect(try #require(store).todayConfiguration() == first)
        store = nil
        let readOnly = try PieceStore(directory: directory, allowsSave: false)
        #expect(try readOnly.todayConfiguration() == first)
    }
}

// Quiescent fixture ownership is part of the byte-preservation measurement.
// The temporary hold/drop × refusal/no-op matrix is retained with its local log;
// its local pass does not attribute the intermittent hosted mutation to a writer.
@Suite(.serialized)
@MainActor
struct BootstrapWriterLifetimeTests {
    @Test(arguments: [5, 6], [false, true])
    func heldBootstrapFixturePreservesBytesWithRefusalAndNoOpControl(layout: Int, attemptRefusal: Bool) async throws {
        for repetition in 0..<4 {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("AQD-lifetime-guard-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let (container, context) = try fixture(directory: directory, layout: layout)
            let detail = "Held lifetime layout=\(layout) \(attemptRefusal ? "refusal" : "noOp") repeat=\(repetition)"
            try await withExtendedOwnerLifetime(container, context) {
                try await observe(directory: directory, attemptRefusal: attemptRefusal, detail: detail)
            }
        }
    }

    private func fixture(directory: URL, layout: Int) throws -> (ModelContainer, ModelContext) {
        let media = directory.appendingPathComponent("media", isDirectory: true)
        try FileManager.default.createDirectory(at: media, withIntermediateDirectories: true)
        // An opaque regular file with no managed UUID filename or record owner.
        try Data([0x00, 0x7f, 0xff, 0x42]).write(to: media.appendingPathComponent("unknown.jpg"))
        let schema = Schema(versionedSchema: LocalSchemaV2.self)
        let configuration = ModelConfiguration(schema: schema,
            url: directory.appendingPathComponent("wardrobe.store"), cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let today = StoredTodayConfiguration(TodayConfiguration(ownerID: UUID()))
        if layout == 5 {
            context.insert(today)
            context.insert(StoredPhotoCleanup(photoID: UUID()))
        } else {
            today.kindIDs = ["unknown"]
            context.insert(today)
        }
        try context.save()
        return (container, context)
    }

    private func withExtendedOwnerLifetime(
        _ container: ModelContainer, _ context: ModelContext,
        operation: () async throws -> Void
    ) async rethrows {
        // Standard withExtendedLifetime has a synchronous body. Its deferred
        // use guarantees BOTH values stay alive throughout the awaited body,
        // including snapshot, refusal/no-op delay and final byte assertions.
        defer { withExtendedLifetime((container, context)) {} }
        try await operation()
    }

    private func observe(directory: URL, attemptRefusal: Bool, detail: String) async throws {
        let before = try snapshot(directory: directory)
        try #require(before["wardrobe.store"] != nil, "\(detail) missing fixture DB")
        try #require(before["media/unknown.jpg"] != nil, "\(detail) missing fixture media")
        try #require(before["schema-version"] == nil, "\(detail) fixture unexpectedly marked")
        if attemptRefusal {
            #expect(throws: (any Error).self, "\(detail) expected actual PieceStore refusal") {
                try PieceStore(directory: directory)
            }
        }
        // Identical bounded scheduling window for refusal and no-op controls;
        // unlike a blocking sleep, this permits native teardown to progress.
        try await Task.sleep(for: .milliseconds(20))
        let after = try snapshot(directory: directory)
        #expect(Set(after.keys) == Set(before.keys), "\(detail) file set changed (SHM alone excluded)")
        for filename in Set(before.keys).union(after.keys).sorted() {
            #expect(after[filename] == before[filename], "\(detail) changed \(filename)")
        }
    }

    private func snapshot(directory: URL) throws -> [String: Data] {
        var bytes: [String: Data] = [:]
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for file in files {
            if file.lastPathComponent == "media" {
                for media in try FileManager.default.contentsOfDirectory(at: file, includingPropertiesForKeys: nil) {
                    bytes["media/\(media.lastPathComponent)"] = try Data(contentsOf: media)
                }
            } else if !file.lastPathComponent.hasSuffix("-shm") {
                // Include DB, WAL, marker and every other source file, including
                // additions/removals. Only SQLite's volatile SHM is excluded.
                bytes[file.lastPathComponent] = try Data(contentsOf: file)
            }
        }
        return bytes
    }
}
