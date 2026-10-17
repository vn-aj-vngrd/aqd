import AQDCore
import Foundation
import Testing
@testable import AQD

@Suite(.serialized) @MainActor struct FitCaptureTests {
    private func loaded() async throws -> (AppState, LocalDataFixture) {
        let fixture = try await LocalDataFixture()
        let state = AppState(store: fixture.store)
        if let draft = try fixture.store.fitDraft() { try fixture.store.finishFitDraft(draft, discarding: true) }
        state.reloadPieces(); state.reloadOutfits(); state.reloadFits()
        state.activeEditor = nil
        return (state, fixture)
    }

    @Test func choosingCameraOrPhotosOpensTheEditorOnThatSourceAndOutfitDoesNot() async throws {
        for (source, expected) in [(FitCaptureSource.camera, PhotoSourceLaunch.camera), (.photos, .photos)] {
            let (state, _) = try await loaded()
            state.openFit(source: source)
            #expect(state.fitEditor?.launch == expected)
        }
        let (state, _) = try await loaded()
        state.openFit(source: .outfit)
        #expect(state.fitEditor != nil && state.fitEditor?.launch == nil)
    }

    @Test func aRetainedDraftReopensWithoutReplayingTheSource() async throws {
        let (state, fixture) = try await loaded()
        var draft = FitDraft(ownerID: try fixture.store.todayConfiguration().ownerID)
        draft.value.note = "kept"
        try fixture.store.saveFitDraft(draft)
        state.openFit(source: .camera)
        let editor = try #require(state.fitEditor)
        #expect(editor.draft.value.note == "kept", "the retained draft wins")
        #expect(editor.draft.base == nil)
    }

    @Test func plannedOutfitIsOfferedUntilLinked() async throws {
        let (state, fixture) = try await loaded()
        let owner = try fixture.store.todayConfiguration().ownerID
        state.planEntries = [OutfitPlanEntry(id: UUID(), planID: fixture.plan.id, ownerID: owner, day: LocalPlanDay(),
                                             occasion: "", outfitID: fixture.outfit.id, outfitRevision: fixture.outfit.revision, state: .planned)]
        state.openFit(source: .outfit)
        let editor = try #require(state.fitEditor)
        #expect(editor.plannedOutfit?.id == fixture.outfit.id)
        #expect(editor.guidance == .needsContent)
        #expect(editor.link(fixture.outfit))
        #expect(editor.plannedOutfit == nil, "nothing to offer once it is linked")
        #expect(editor.guidance == .ready)
    }

    @Test func savingWithRecordWearNextQueuesWearButNeverRecordsIt() async throws {
        let (state, fixture) = try await loaded()
        state.openFit(source: .outfit)
        let editor = try #require(state.fitEditor)
        #expect(editor.link(fixture.outfit))
        editor.recordWearNext = true
        await editor.save()
        #expect(state.fitEditor == nil && state.fitMemories.count == 1)
        let pending = try #require(state.pendingFitWear)
        #expect(pending.outfitID == fixture.outfit.id)
        let before = try fixture.store.wearRecords().count
        state.openPendingFitWear()
        #expect(state.pendingFitWear == nil)
        #expect(state.wearEditor != nil, "Record wear opens for confirmation")
        #expect(try fixture.store.wearRecords().count == before, "opening it records nothing")
    }

    @Test func savingWithoutTheToggleQueuesNoWear() async throws {
        let (state, fixture) = try await loaded()
        state.openFit(source: .outfit)
        let editor = try #require(state.fitEditor)
        #expect(editor.link(fixture.outfit))
        await editor.save()
        #expect(state.fitMemories.count == 1 && state.pendingFitWear == nil)
        state.openPendingFitWear()
        #expect(state.wearEditor == nil)
    }
}
