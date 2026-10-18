import AQDCore
import CoreData
import CryptoKit
import Darwin
import Foundation
import SwiftData

extension PieceStore {
    func todayDraft() throws -> TodayLayoutDraft? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredTodayDraft>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let value = try records.first?.value() else { return nil }
        guard value.base.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }; return value
    }
    func todayPersonalCards() throws -> [TodayPersonalCard] {
        let owner = try todayConfiguration().ownerID
        let cards = try ModelContext(container).fetch(FetchDescriptor<StoredTodayPersonalCard>()).map { try $0.value() }
        guard cards.allSatisfy({ $0.ownerID == owner }) else { throw StoreError.invalidRecord }
        return cards.sorted { $0.id.uuidString < $1.id.uuidString }
    }
    func todayUndo() throws -> TodayLayoutUndo? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredTodayUndo>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let value = try records.first?.value() else { return nil }
        guard value.current == (try todayConfiguration()) else { throw StoreError.staleRevision }; return value
    }
    func saveTodayDraft(_ draft: TodayLayoutDraft) throws {
        try draft.validated()
        guard allowsSave, draft.base.ownerID == (try todayConfiguration().ownerID), try savedTodayLayout(draft) == nil else { throw StoreError.operationConflict }
        let context = ModelContext(container), records = try context.fetch(FetchDescriptor<StoredTodayDraft>())
        guard records.count <= 1, records.first.map({ $0.id == draft.id }) ?? true else { throw StoreError.operationConflict }
        if let record = records.first { try queueTodayPhotos(record.value(), context: context); record.payload = try encode(draft) }
        else { context.insert(try StoredTodayDraft(draft)) }
        try commit(context)
    }
    func savedTodayLayout(_ draft: TodayLayoutDraft) throws -> TodayConfiguration? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredTodaySave>()).filter { $0.id == draft.operationID }
        guard let receipt = records.first else { return nil }
        if let acknowledgment = try? JSONDecoder().decode(ArchiveOperationDigest.self, from: receipt.request) {
            guard records.count == 1, acknowledgment.digest == digest(try encode(draft)) else { throw StoreError.operationConflict }; return try draft.result()
        }
        guard records.count == 1, try JSONDecoder().decode(TodayLayoutDraft.self, from: receipt.request) == draft else { throw StoreError.operationConflict }
        let result = try JSONDecoder().decode(TodayConfiguration.self, from: receipt.result)
        guard result == (try draft.result()) else { throw StoreError.invalidRecord }; return result
    }
    func saveTodayLayout(_ draft: TodayLayoutDraft) throws -> TodayConfiguration {
        if let result = try savedTodayLayout(draft) { return result }
        guard allowsSave, try todayDraft() == draft, try todayConfiguration() == draft.base else { throw StoreError.staleDraft }
        let result = try draft.result(), context = ModelContext(container)
        let existing = try todayPersonalCards()
        for instance in result.instances {
            try instance.validatedContent(ownerID: result.ownerID, requireContent: instance.options != nil)
            if instance.isVisible, let pin = instance.options?.pinnedID,
               draft.base.instances.first(where: { $0.id == instance.id })?.options?.pinnedID != pin {
                let available: Bool
                switch instance.kind {
                case .todayLook: available = try planEntries().contains { $0.id == pin }
                case .upcomingPlans: available = try planDefinitions().contains { $0.id == pin }
                case .wearAgain: available = try pieces().contains { $0.id == pin && $0.availability == .available }
                case .favoriteOutfits: available = try outfits().contains { $0.id == pin }
                case .theme: available = try themes().contains { $0.id == pin }
                case .fitJournal: available = try fitMemories().contains { $0.id == pin }
                default: available = false
                }
                guard available else { throw TodayLayoutError.selectionRequired }
            }
            if let card = instance.options?.personal {
                let previous = existing.first { $0.id == card.id }
                guard previous == card || previous.map({ card.revision == $0.revision + 1 }) ?? (card.revision == 1) else { throw StoreError.staleRevision }
                if let id = card.photoID, card.photoID != previous?.photoID || card.photoRecipe != previous?.photoRecipe {
                    _ = try photoRendition(id: id, recipe: card.photoRecipe); _ = try photoThumbnail(id: id, recipe: card.photoRecipe)
                }
                if let record = try context.fetch(FetchDescriptor<StoredTodayPersonalCard>()).first(where: { $0.id == card.id }) {
                    if let previous { try queueTodayPhotos([previous], context: context) }
                    record.payload = try encode(card)
                } else { context.insert(try StoredTodayPersonalCard(card)) }
            }
        }
        guard let layout = try context.fetch(FetchDescriptor<StoredTodayLayout>()).first else { throw StoreError.invalidRecord }
        layout.payload = try encode(result)
        for old in try context.fetch(FetchDescriptor<StoredTodayUndo>()) {
            try queueTodayPhotos(old.value().previous.instances.compactMap { $0.options?.personal }, context: context); context.delete(old)
        }
        context.insert(try StoredTodayUndo(TodayLayoutUndo(previous: draft.base, current: result)))
        context.insert(try StoredTodaySave(draft, result: result))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave(); return result
    }
    func finishTodayDraft(_ draft: TodayLayoutDraft, discarding: Bool = false) throws {
        let result = try savedTodayLayout(draft)
        guard discarding ? result == nil : result != nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        guard let record = try context.fetch(FetchDescriptor<StoredTodayDraft>()).first, try record.value() == draft else { throw StoreError.staleDraft }
        try queueTodayPhotos(draft, context: context); context.delete(record); try commit(context)
    }
    func queueTodayPhotos(_ cards: [TodayPersonalCard], context: ModelContext) throws {
        for card in cards { if let id = card.photoID { try queueCleanup(photoID: id, recipeDigest: try cleanupRecipeDigest(card.photoRecipe), context: context) } }
    }
    func queueTodayPhotos(_ draft: TodayLayoutDraft, context: ModelContext) throws {
        let layouts = [draft.base, draft.value] + [draft.defaultsUndo].compactMap { $0 }
        let cards = layouts.flatMap { $0.instances.compactMap { $0.options?.personal } } + [draft.nested?.options?.personal, draft.nestedBase?.options?.personal].compactMap { $0 }
        try queueTodayPhotos(cards, context: context)
    }
    func todayPhotoOwners(in context: ModelContext) throws -> [(id: UUID, recipe: PhotoEditRecipe)] {
        var cards = try context.fetch(FetchDescriptor<StoredTodayPersonalCard>()).map { try $0.value() }
        for record in try context.fetch(FetchDescriptor<StoredTodayLayout>()) { cards += try record.value().instances.compactMap { $0.options?.personal } }
        for record in try context.fetch(FetchDescriptor<StoredTodayUndo>()) { cards += try record.value().previous.instances.compactMap { $0.options?.personal } }
        for record in try context.fetch(FetchDescriptor<StoredTodayDraft>()) {
            let draft = try record.value()
            cards += ([draft.base, draft.value] + [draft.defaultsUndo].compactMap { $0 }).flatMap { $0.instances.compactMap { $0.options?.personal } }
            cards += [draft.nested?.options?.personal, draft.nestedBase?.options?.personal].compactMap { $0 }
        }
        return cards.compactMap { card in card.photoID.map { ($0, card.photoRecipe) } }
    }
}

extension PieceStore {
    func todayCardUsage(_ id: UUID) throws -> TodayCardUsage {
        func contains(_ configuration: TodayConfiguration) -> Bool { configuration.instances.contains { $0.options?.personal?.id == id } }
        let draft = try todayDraft()
        let inDraft = draft.map { value in
            contains(value.base) || contains(value.value) || value.defaultsUndo.map(contains) == true
                || value.nested?.options?.personal?.id == id || value.nestedBase?.options?.personal?.id == id
        } ?? false
        return TodayCardUsage(active: contains(try todayConfiguration()), draft: inDraft, undo: try todayUndo().map { contains($0.previous) } ?? false)
    }
    func reviewTodayCardDeletion(_ card: TodayPersonalCard) throws -> TodayCardDeletion {
        guard try pendingTodayCardDeletion() == nil, try todayPersonalCards().contains(card) else { throw StoreError.staleRevision }
        let usage = try todayCardUsage(card.id)
        guard !usage.active, !usage.draft else { throw StoreError.operationConflict }
        if let draft = try todayDraft(), try savedTodayLayout(draft) != nil { throw StoreError.operationConflict }
        return TodayCardDeletion(card: card, undo: usage.undo ? try todayUndo() : nil)
    }
    func pendingTodayCardDeletion() throws -> TodayCardDeletion? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredTodayCardDeletion>()).filter { !$0.acknowledged }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        let value = try records.first?.value()
        if let value { guard value.card.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord } }
        return value
    }
    func todayCardDeletionApplied(_ request: TodayCardDeletion) throws -> Bool {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredTodayCardDeletion>()).filter { $0.id == request.operationID }
        guard let record = records.first else { return false }
        if let acknowledgment = try? JSONDecoder().decode(ArchiveOperationDigest.self, from: record.payload) {
            guard records.count == 1, record.acknowledged, acknowledgment.digest == digest(try encode(request)) else { throw StoreError.operationConflict }; return record.applied
        }
        guard records.count == 1, try record.value() == request else { throw StoreError.operationConflict }; return record.applied
    }
    func deleteTodayCard(_ request: TodayCardDeletion) throws {
        if try todayCardDeletionApplied(request) { return }
        guard allowsSave, request.card.ownerID == (try todayConfiguration().ownerID), try todayPersonalCards().contains(request.card) else { throw StoreError.staleRevision }
        let usage = try todayCardUsage(request.card.id), undo = try todayUndo()
        let releasesUndo = undo.map { $0.previous.instances.contains { $0.options?.personal?.id == request.card.id } } ?? false
        guard !usage.active, !usage.draft, releasesUndo == (request.undo != nil),
              request.undo == nil || undo == request.undo else { throw StoreError.operationConflict }
        if let draft = try todayDraft(), try savedTodayLayout(draft) != nil { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let tasks = try context.fetch(FetchDescriptor<StoredTodayCardDeletion>())
        guard !tasks.contains(where: { $0.id == request.operationID && $0.acknowledged && !$0.applied }) else { throw StoreError.operationConflict }
        let pending = tasks.filter { !$0.acknowledged }
        guard pending.count <= 1, pending.first.map({ $0.id == request.operationID }) ?? true else { throw StoreError.operationConflict }
        let task: StoredTodayCardDeletion
        if let retained = pending.first { guard try retained.value() == request else { throw StoreError.operationConflict }; task = retained }
        else { task = try StoredTodayCardDeletion(request); context.insert(task); try commit(context) }
        guard let card = try context.fetch(FetchDescriptor<StoredTodayPersonalCard>()).first(where: { $0.id == request.card.id }), try card.value() == request.card else { throw StoreError.staleRevision }
        if request.undo != nil {
            for undo in try context.fetch(FetchDescriptor<StoredTodayUndo>()) {
                try queueTodayPhotos(undo.value().previous.instances.compactMap { $0.options?.personal }, context: context); context.delete(undo)
            }
        }
        try queueTodayPhotos([request.card], context: context)
        context.delete(card); task.applied = true
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
    func finishTodayCardDeletion(_ request: TodayCardDeletion, cancelling: Bool = false) throws {
        let context = ModelContext(container)
        guard let task = try context.fetch(FetchDescriptor<StoredTodayCardDeletion>()).first(where: { $0.id == request.operationID }),
              task.applied || cancelling else { throw StoreError.operationConflict }
        if let acknowledgment = try? JSONDecoder().decode(ArchiveOperationDigest.self, from: task.payload) {
            guard task.acknowledged, acknowledgment.digest == digest(try encode(request)) else { throw StoreError.operationConflict }; return
        }
        guard try task.value() == request else { throw StoreError.operationConflict }
        task.acknowledged = true; try commit(context)
    }
}
