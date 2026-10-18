import Foundation
import Testing
@testable import AQDCore
struct LocalSettingsTests {
    @Test func appearanceIsARevisionBoundLocalPreference() throws {
        let base = LocalSettings(ownerID: UUID())
        let request = LocalSettingsRequest(base: base, appearance: .dark)
        let saved = try request.result()
        #expect(saved.appearance == .dark && saved.revision == 1 && saved.ownerID == base.ownerID)
        #expect(base.appearance == .system && base.revision == 0)
    }
}
