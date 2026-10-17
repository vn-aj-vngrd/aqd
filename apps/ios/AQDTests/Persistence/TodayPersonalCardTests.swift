import AQDCore
import Foundation
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor
struct TodayPersonalCardTests {
    @Test func retainedDeleteRefusesLiveDraftAndActiveReferencesThenReconcilesOnceAcrossRestart() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var unknown = false
        let store = try PieceStore(directory: directory, afterOutfitSave: { if unknown { throw CocoaError(.fileReadUnknown) } })
        let base = try store.todayConfiguration()
        let card = TodayPersonalCard(ownerID: base.ownerID, kind: .personalNote, title: "Private", text: "Keep until reviewed")
        var draft = TodayLayoutDraft(base: base)
        draft.value.instances = [TodayWidgetInstance(kind: .personalNote, options: TodayWidgetOptions(personal: card))]
        try store.saveTodayDraft(draft); _ = try store.saveTodayLayout(draft); try store.finishTodayDraft(draft)
        #expect(throws: (any Error).self) { try store.reviewTodayCardDeletion(card) }
        var defaults = TodayLayoutDraft(base: try store.todayConfiguration()); defaults.restoreDefaults()
        try store.saveTodayDraft(defaults); _ = try store.saveTodayLayout(defaults); try store.finishTodayDraft(defaults)
        var reference = TodayLayoutDraft(base: try store.todayConfiguration())
        reference.nested = TodayWidgetInstance(kind: .personalNote, options: TodayWidgetOptions(personal: card))
        try store.saveTodayDraft(reference)
        #expect(throws: (any Error).self) { try store.reviewTodayCardDeletion(card) }
        try store.finishTodayDraft(reference, discarding: true)
        let request = try store.reviewTodayCardDeletion(card)
        #expect(request.undo != nil)
        unknown = true
        #expect(throws: (any Error).self) { try store.deleteTodayCard(request) }
        let reopened = try PieceStore(directory: directory)
        #expect(try reopened.pendingTodayCardDeletion() == request)
        try reopened.deleteTodayCard(request)
        #expect(try reopened.todayPersonalCards().isEmpty)
        #expect(try reopened.todayUndo() == nil)
        try reopened.finishTodayCardDeletion(request)
        #expect(try reopened.pendingTodayCardDeletion() == nil)
        try reopened.deleteTodayCard(request)
        #expect(try reopened.todayPersonalCards().isEmpty)
        #expect(try reopened.wearRecords().isEmpty)
    }
    @Test func independentSavedPhotoCopiesReleaseBytesOnlyAfterTheLastOwner() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), store = try PieceStore(directory: directory)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32)) }
        let photo = try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 0.9))); _ = try store.acceptPhoto(photo)
        let base = try store.todayConfiguration()
        let first = TodayPersonalCard(ownerID: base.ownerID, kind: .personalPhoto, photoID: photo.id), second = first.independentCopy()
        var draft = TodayLayoutDraft(base: base)
        draft.value.instances = [first, second].map { TodayWidgetInstance(kind: .personalPhoto, options: TodayWidgetOptions(personal: $0)) }
        try store.saveTodayDraft(draft); _ = try store.saveTodayLayout(draft); try store.finishTodayDraft(draft)
        var defaults = TodayLayoutDraft(base: try store.todayConfiguration()); defaults.restoreDefaults()
        try store.saveTodayDraft(defaults); _ = try store.saveTodayLayout(defaults); try store.finishTodayDraft(defaults)
        let state = AppState(store: store)
        #expect(state.todayUndoAvailable)
        let deleteFirst = try store.reviewTodayCardDeletion(first)
        try store.deleteTodayCard(deleteFirst); try store.finishTodayCardDeletion(deleteFirst); try store.reconcilePendingPhotoCleanup()
        state.reloadToday(); #expect(!state.todayUndoAvailable)
        #expect(try store.originalPhoto(id: photo.id) == photo.originalData)
        #expect(try store.todayPersonalCards() == [second])
        let deleteSecond = try store.reviewTodayCardDeletion(second)
        try store.deleteTodayCard(deleteSecond); try store.finishTodayCardDeletion(deleteSecond); try store.reconcilePendingPhotoCleanup()
        #expect(throws: (any Error).self) { try store.originalPhoto(id: photo.id) }
        #expect(try store.todayPersonalCards().isEmpty)
    }
}
