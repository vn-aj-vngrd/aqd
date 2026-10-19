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
        state.openFit(source: .outfit)
        state.planEntries = [OutfitPlanEntry(id: UUID(), planID: fixture.plan.id, ownerID: owner, day: LocalPlanDay(),
                                             occasion: "", outfitID: fixture.outfit.id, outfitRevision: fixture.outfit.revision, state: .planned)]
        let editor = try #require(state.fitEditor)
        #expect(editor.plannedOutfit?.id == fixture.outfit.id)
        #expect(editor.guidance == .needsContent)
        #expect(editor.link(fixture.outfit))
        #expect(editor.plannedOutfit == nil, "nothing to offer once it is linked")
        #expect(editor.guidance == .ready)
    }

    @Test func postingAFitWithAnOutfitCountsItAsWornOnce() async throws {
        let (state, fixture) = try await loaded()
        let existing = state.fitMemories.count
        let before = try fixture.store.wearRecords().count
        state.openFit(source: .outfit)
        let editor = try #require(state.fitEditor)
        #expect(editor.recordWearNext, "a new post counts as worn by default")
        #expect(editor.link(fixture.outfit))
        await editor.save()
        #expect(editor.error == nil, "\(String(describing: editor.error))")
        #expect(state.fitEditor == nil)
        #expect(state.fitMemories.count == existing + 1)
        #expect(state.pendingFitWear == nil, "recorded in the same step, no second screen")
        #expect(try fixture.store.wearRecords().count == before + 1)

        state.openFit(source: .outfit)
        let again = try #require(state.fitEditor)
        #expect(again.link(fixture.outfit))
        await again.save()
        #expect(try fixture.store.wearRecords().count == before + 1, "the same outfit and day is never counted twice")
    }

    @Test func savingWithoutTheToggleQueuesNoWear() async throws {
        let (state, fixture) = try await loaded()
        let existing = state.fitMemories.count
        state.openFit(source: .outfit)
        let editor = try #require(state.fitEditor)
        #expect(editor.link(fixture.outfit))
        editor.recordWearNext = false
        await editor.save()
        #expect(editor.error == nil, "\(String(describing: editor.error))")
        #expect(state.fitMemories.count == existing + 1)
        #expect(state.pendingFitWear == nil)
        state.openPendingFitWear()
        #expect(state.wearEditor == nil)
    }
}
