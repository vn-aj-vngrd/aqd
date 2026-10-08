import AQDCore
import Foundation
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
