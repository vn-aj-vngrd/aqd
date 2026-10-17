import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct LocalSettingsPersistenceTests {
    @Test func tourReadsCurrentDataWithoutChangingNavigationDraftsOrInterruptedConversations() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try PieceStore(directory: directory)
        try store.saveEntryState(PrivateEntryState(alreadyEntered: true))
        let state = AppState(store: store)
        let owner = try store.todayConfiguration().ownerID
        var identity = LocalIdentityDraft(ownerID: owner)
        identity.name = "Current profile"; identity.caption = "Current caption"
        try store.saveIdentityDraft(identity); _ = try store.saveIdentity(identity); try store.finishIdentityDraft(identity)
        var retained = LocalIdentityDraft(ownerID: owner, base: try store.localIdentity())
        retained.name = "Unfinished edit"; try store.saveIdentityDraft(retained)
        var conversation = AgentConversation(ownerID: owner)
        conversation.draft = "A retained request"; _ = try conversation.beginAttempt()
        let savedConversation = try store.saveAgentConversation(conversation, operationID: UUID())
        state.selection = 4; state.profileSettings = true; state.closetScope = "Themes"
        state.closetSearchActive = true; state.closetSearchQuery = "Personal search"
        state.beginTour(from: .settings)
        let entry = try store.localExperience().entryState
        let stamp = try store.mutationStamp()
        let preview = state.makeTourReadState()
        #expect(preview !== state && preview.store === store)
        #expect(preview.localIdentity?.name == "Current profile")
        #expect(preview.localIdentity?.caption == "Current caption")
        #expect(preview.today == (try store.todayConfiguration()))
        #expect(preview.profileSettings == false && preview.closetSearchActive == false && preview.closetScope == "Pieces")
        #expect(preview.identityEditor == nil && preview.capture == nil && preview.styleEditor == nil)
        #expect(preview.agentModel?.conversation.id == savedConversation.id)
        #expect(preview.agentModel?.conversation.messages.contains(where: \.isActive) == false)
        #expect(try store.agentConversations().first == savedConversation)
        #expect(try store.identityDraft() == retained)
        #expect(try store.mutationStamp() == stamp && store.localExperience().entryState == entry)
        preview.selection = 1; preview.closetScope = "Outfits"
        #expect(state.selection == 4 && state.profileSettings && state.closetScope == "Themes")
        #expect(state.closetSearchActive && state.closetSearchQuery == "Personal search")
        preview.store = nil; state.store = nil
    }

    @Test(arguments: [false, true], [false, true]) func newAppearanceChoiceSurvivesPendingSaveReconciliation(lostAcknowledgment: Bool, recoverBeforeSecondChoice: Bool) throws {
        var before = false, after = false
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            beforeOutfitSave: { if before { throw CocoaError(.fileWriteNoPermission) } },
            afterOutfitSave: { if after { throw CocoaError(.fileReadUnknown) } })
        let state = AppState(store: store)
        before = !lostAcknowledgment; after = lostAcknowledgment
        state.saveAppearance(.dark)
        #expect(state.settingsError != nil)
        if recoverBeforeSecondChoice { before = false; after = false }
        state.saveAppearance(.light)
        if !recoverBeforeSecondChoice {
            #expect(state.settingsError != nil)
            before = false; after = false
            state.retryAppearanceSave()
        }
        #expect(state.appearance == .light && state.settingsError == nil)
        #expect(try store.localSettings().appearance == .light)
        #expect(try store.localSettings().revision == 2)
        after = true; state.saveAppearance(.dark); after = false
        state.retryAppearanceSave()
        #expect(state.appearance == .dark && state.settingsError == nil)
        #expect(try store.localSettings().revision == 3)
        state.store = nil
    }
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
