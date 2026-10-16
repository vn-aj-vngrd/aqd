import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct LocalSettingsPersistenceTests {
    @Test func failedAndUnknownAppearanceWritesPreserveOtherDataAndReconcileWithoutRewindingNewerSettings() throws {
        var fail = false, unknown = false
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory,
            beforeOutfitSave: { if fail { throw CocoaError(.fileWriteNoPermission) } },
            afterOutfitSave: { if unknown { throw CocoaError(.fileReadUnknown) } })
        let base = try store.localSettings(), stamp = try store.mutationStamp()
        let dark = LocalSettingsRequest(base: base, appearance: .dark)
        fail = true
        #expect(throws: (any Error).self) { try store.saveLocalSettings(dark) }
        #expect(try store.localSettings() == base && store.mutationStamp() == stamp)
        fail = false; unknown = true
        #expect(throws: (any Error).self) { try store.saveLocalSettings(dark) }
        let saved = try store.saveLocalSettings(dark)
        #expect(saved.appearance == .dark && saved.revision == 1)
        #expect(try store.mutationStamp() != stamp)
        unknown = false
        let light = LocalSettingsRequest(base: saved, appearance: .light)
        let latest = try store.saveLocalSettings(light)
        #expect(try store.saveLocalSettings(dark) == saved)
        #expect(try PieceStore(directory: directory).localSettings() == latest)
        let state = AppState(store: store)
        #expect(state.appearance == .light)
        #expect(try store.pieces().isEmpty && store.planEntries().isEmpty)
        state.store = nil
    }
    @Test func sharedStyleAndWeatherReturnsDoNotEnableUnrelatedConsent() throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        try store.saveEntryState(PrivateEntryState(alreadyEntered: true))
        let state = AppState(store: store)
        state.selection = 4; state.profileSettings = true
        state.beginTour(from: .settings)
        #expect(state.entry.tour?.source == .settings)
        #expect(try store.weatherState().enabled == false)
        #expect(try store.localExperience().style == nil)
        state.store = nil
    }
}
