import AQDCore
import CoreData
import CryptoKit
import Darwin
import Foundation
import SwiftData

extension PieceStore {
    func themes() throws -> [OutfitTheme] {
        let owner = try todayConfiguration().ownerID
        let values = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitTheme>()).map { try $0.value() }
        guard values.allSatisfy({ $0.ownerID == owner }), Set(values.map { OutfitTheme.nameKey($0.name) }).count == values.count else {
            throw StoreError.invalidRecord
        }
        return values.sorted {
            let comparison = $0.name.localizedStandardCompare($1.name)
            return comparison == .orderedSame ? $0.id.uuidString < $1.id.uuidString : comparison == .orderedAscending
        }
    }

    func themeDraft() throws -> ThemeDraft? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredThemeDraft>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let draft = try records.first?.value() else { return nil }
        guard draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        return draft
    }

    func saveThemeDraft(_ draft: ThemeDraft) throws {
        guard allowsSave, draft.ownerID == (try todayConfiguration().ownerID), draft.baseRevision >= 0,
              Set(draft.outfitIDs).count == draft.outfitIDs.count else { throw StoreError.invalidRecord }
        guard try savedTheme(for: draft) == nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredThemeDraft>())
        guard records.count <= 1, records.first.map({ $0.id == draft.id }) ?? true else { throw StoreError.operationConflict }
        if let record = records.first { record.payload = try JSONEncoder().encode(draft) }
        else { context.insert(try StoredThemeDraft(draft)) }
        try commit(context)
    }

    func savedTheme(for draft: ThemeDraft) throws -> OutfitTheme? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredThemeSave>()).filter { $0.id == draft.operationID }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let receipt = records.first else { return nil }
        guard try JSONDecoder().decode(ThemeDraft.self, from: receipt.draft) == draft else { throw StoreError.operationConflict }
        let value = try JSONDecoder().decode(OutfitTheme.self, from: receipt.snapshot)
        try value.validated()
        guard value.id == draft.themeID, value.ownerID == draft.ownerID else { throw StoreError.invalidRecord }
        return value
    }

    func saveTheme(_ draft: ThemeDraft) throws -> OutfitTheme {
        if let saved = try savedTheme(for: draft) { return saved }
        guard allowsSave, draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.corruptStore }
        try draft.validatedForSave(themes: themes(), outfits: outfits())
        guard try themeDraft() == draft else { throw StoreError.staleDraft }
        let context = ModelContext(container)
        let record = try context.fetch(FetchDescriptor<StoredOutfitTheme>()).first { $0.id == draft.themeID }
        let previous = try record?.value()
        guard (previous == nil || previous?.ownerID == draft.ownerID), (previous?.revision ?? 0) == draft.baseRevision else { throw StoreError.staleRevision }
        let saved = OutfitTheme(id: draft.themeID, ownerID: draft.ownerID,
                               name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines), description: draft.description,
                               outfitIDs: draft.outfitIDs, revision: draft.baseRevision + 1)
        if let record { record.payload = try JSONEncoder().encode(saved) }
        else { context.insert(try StoredOutfitTheme(saved)) }
        context.insert(try StoredThemeSave(draft: draft, saved: saved))
        try beforeOutfitSave()
        try commit(context)
        try afterOutfitSave()
        return saved
    }

    func finishThemeDraft(_ draft: ThemeDraft, discarding: Bool = false) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let saved = try savedTheme(for: draft)
        guard discarding ? saved == nil : saved != nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredThemeDraft>())
        guard records.count == 1, let record = records.first, try record.value() == draft else { throw StoreError.staleDraft }
        context.delete(record)
        try commit(context)
    }
}

extension PieceStore {
    func isThemeDeletionAcknowledged(_ request: ThemeDeletionRequest) throws -> Bool {
        guard request.expectedRevision > 0 else { throw StoreError.invalidRecord }
        let context = ModelContext(container)
        let receipts = try context.fetch(FetchDescriptor<StoredThemeDeletion>()).filter { $0.id == request.operationID }
        guard receipts.count <= 1 else { throw StoreError.invalidRecord }
        guard let receipt = receipts.first else { return false }
        guard try JSONDecoder().decode(ThemeDeletionRequest.self, from: receipt.request) == request else { throw StoreError.operationConflict }
        guard try context.fetch(FetchDescriptor<StoredOutfitTheme>()).allSatisfy({ $0.id != request.themeID }) else { throw StoreError.invalidRecord }
        return true
    }

    func deleteTheme(_ request: ThemeDeletionRequest) throws {
        if try isThemeDeletionAcknowledged(request) { return }
        guard allowsSave else { throw StoreError.corruptStore }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredOutfitTheme>())
        guard let record = records.first(where: { $0.id == request.themeID }) else { throw StoreError.staleRevision }
        let theme = try record.value()
        guard theme.ownerID == (try todayConfiguration().ownerID), theme.revision == request.expectedRevision else { throw StoreError.staleRevision }
        // Memberships belong to this theme alone. Outfit identity, other themes,
        // favorites, plans, pieces and historical wear are independent owners.
        context.delete(record); context.insert(try StoredThemeDeletion(request))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
}
