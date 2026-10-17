import AQDCore
import CoreData
import CryptoKit
import Darwin
import Foundation
import SwiftData

extension PieceStore {
    func outfits() throws -> [Outfit] {
        let owner = try todayConfiguration().ownerID
        return try ModelContext(container).fetch(FetchDescriptor<StoredOutfit>()).map {
            let value = try $0.value()
            guard value.ownerID == owner else { throw StoreError.invalidRecord }
            return value
        }.sorted {
            if $0.updatedAt != $1.updatedAt { return $0.updatedAt > $1.updatedAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    func outfit(id: UUID) throws -> Outfit? { try outfits().first { $0.id == id } }

    func outfitDraft() throws -> OutfitDraft? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitDraft>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let value = try records.first?.value() else { return nil }
        guard value.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        return value
    }

    func saveOutfitDraft(_ draft: OutfitDraft) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        try draft.validated()
        guard draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        let context = ModelContext(container)
        let receipts = try context.fetch(FetchDescriptor<StoredOutfitSave>())
        // An acknowledged operation is immutable until the receipt is dismissed.
        guard !receipts.contains(where: { $0.id == draft.operationID }) else { throw StoreError.operationConflict }
        let records = try context.fetch(FetchDescriptor<StoredOutfitDraft>())
        guard records.count <= 1, records.first.map({ $0.id == draft.id }) ?? true else { throw StoreError.operationConflict }
        if let record = records.first { record.payload = try JSONEncoder().encode(draft) }
        else { context.insert(try StoredOutfitDraft(draft)) }
        try commit(context)
    }

    func discardOutfitDraft(id: UUID) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredOutfitDraft>())
        guard records.count == 1, let record = records.first, record.id == id else { throw StoreError.staleDraft }
        let draft = try record.value()
        let operation = draft.operationID
        guard try !context.fetch(FetchDescriptor<StoredOutfitSave>()).contains(where: { $0.id == operation }) else {
            throw StoreError.operationConflict
        }
        context.delete(record)
        try commit(context)
    }

    func savedOutfit(for draft: OutfitDraft) throws -> Outfit? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitSave>()).filter { $0.id == draft.operationID }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let receipt = records.first else { return nil }
        guard try JSONDecoder().decode(OutfitDraft.self, from: receipt.draft) == draft else { throw StoreError.operationConflict }
        let value = try JSONDecoder().decode(Outfit.self, from: receipt.snapshot)
        try value.validated()
        guard value.ownerID == draft.ownerID, value.id == draft.outfitID else { throw StoreError.invalidRecord }
        return value
    }

    func saveOutfit(_ draft: OutfitDraft) throws -> Outfit {
        // Read the immutable receipt first. A retry still acknowledges a past
        // successful save if a selected piece has subsequently been archived.
        if let saved = try savedOutfit(for: draft) { return saved }
        guard allowsSave else { throw StoreError.corruptStore }
        try draft.validatedForSave(pieces: pieces())
        guard draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        guard try outfitDraft() == draft else { throw StoreError.staleDraft }
        let context = ModelContext(container)
        let existing = try context.fetch(FetchDescriptor<StoredOutfit>()).first { $0.id == draft.outfitID }
        let previous = try existing?.value()
        guard (previous == nil || previous?.ownerID == draft.ownerID), (previous?.revision ?? 0) == draft.baseRevision else { throw StoreError.staleRevision }
        let saved = Outfit(id: draft.outfitID, ownerID: draft.ownerID, name: draft.trimmedName,
                           pieceIDs: draft.pieceIDs, mood: draft.mood, occasion: draft.occasion, isFavorite: previous?.isFavorite ?? false,
                           revision: draft.baseRevision + 1, createdAt: previous?.createdAt ?? Date())
        try saved.validated()
        if let existing {
            existing.payload = try JSONEncoder().encode(saved)
            try flagFuturePlans(outfitIDs: [saved.id], context: context)
        } else { context.insert(try StoredOutfit(saved)) }
        let themeRecords = try context.fetch(FetchDescriptor<StoredOutfitTheme>())
        let selectedThemes = Set(draft.themeIDs ?? [])
        let existingThemes = try themeRecords.map { try $0.value() }
        guard existingThemes.allSatisfy({ $0.ownerID == draft.ownerID }), selectedThemes.isSubset(of: Set(existingThemes.filter { $0.ownerID == draft.ownerID }.map(\.id))) else {
            throw StoreError.staleRevision
        }
        for record in themeRecords {
            var theme = try record.value()
            let hadMembership = theme.outfitIDs.contains(saved.id)
            let wantsMembership = selectedThemes.contains(theme.id)
            if hadMembership != wantsMembership {
                if wantsMembership { theme.outfitIDs.append(saved.id) }
                else { theme.outfitIDs.removeAll { $0 == saved.id } }
                theme.revision += 1
                record.payload = try JSONEncoder().encode(theme)
            }
        }
        context.insert(try StoredOutfitSave(draft: draft, saved: saved))
        try prunePackingChecks(in: context)
        try beforeOutfitSave()
        try commit(context)
        try afterOutfitSave()
        return saved
    }

    func acknowledgeOutfitReceipt(_ draft: OutfitDraft) throws {
        guard allowsSave, try savedOutfit(for: draft) != nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredOutfitDraft>())
        guard records.count == 1, let record = records.first, try record.value() == draft else { throw StoreError.staleDraft }
        context.delete(record)
        try commit(context)
    }
}

extension PieceStore {
    func outfitDeletionReview(id: UUID) throws -> OutfitMutationRequest {
        guard let outfit = try outfit(id: id) else { throw StoreError.staleRevision }
        let dependencies = OutfitDeletionDependencies(
            themeRevisions: Dictionary(uniqueKeysWithValues: try themes().filter { $0.outfitIDs.contains(id) }.map { ($0.id, $0.revision) }),
            planRevisions: Dictionary(uniqueKeysWithValues: try planEntries().filter { $0.outfitID == id }.map { ($0.id, $0.revision) }))
        return OutfitMutationRequest(outfit: outfit, action: .delete(dependencies))
    }

    func outfitMutationReceipt(for request: OutfitMutationRequest) throws -> OutfitMutationReceipt? {
        try request.outfit.validated()
        let context = ModelContext(container)
        let proofs = try context.fetch(FetchDescriptor<StoredOutfitMutation>()).filter { $0.id == request.operationID }
        guard proofs.count <= 1 else { throw StoreError.invalidRecord }
        if let proof = proofs.first {
            guard try JSONDecoder().decode(OutfitMutationRequest.self, from: proof.request) == request else { throw StoreError.operationConflict }
            let receipt = try JSONDecoder().decode(OutfitMutationReceipt.self, from: proof.result)
            switch (request.action, receipt) {
            case (.favorite(let flag), .saved(let saved)):
                try saved.validated()
                guard saved.id == request.outfit.id, saved.ownerID == request.outfit.ownerID,
                      saved.isFavorite == flag, saved.revision == request.outfit.revision + 1 else { throw StoreError.invalidRecord }
            case (.delete, .deleted(let id)):
                guard id == request.outfit.id else { throw StoreError.invalidRecord }
            default: throw StoreError.invalidRecord
            }
            return receipt
        }
        return nil
    }

    func applyOutfitMutation(_ request: OutfitMutationRequest) throws -> OutfitMutationReceipt {
        try request.outfit.validated()
        let context = ModelContext(container)
        if let receipt = try outfitMutationReceipt(for: request) { return receipt }
        guard allowsSave, request.outfit.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        let records = try context.fetch(FetchDescriptor<StoredOutfit>())
        guard let record = records.first(where: { $0.id == request.outfit.id }), try record.value() == request.outfit else {
            throw StoreError.staleRevision
        }
        let result: OutfitMutationReceipt
        switch request.action {
        case .favorite(let flag):
            var value = request.outfit
            value.isFavorite = flag; value.revision += 1; value.updatedAt = Date()
            try value.validated()
            record.payload = try JSONEncoder().encode(value)
            result = .saved(value)
        case .delete(let dependencies):
            let current = try outfitDeletionReview(id: request.outfit.id)
            guard current.outfit == request.outfit, current.action == .delete(dependencies) else { throw StoreError.staleRevision }
            let themes = try context.fetch(FetchDescriptor<StoredOutfitTheme>())
            for themeRecord in themes {
                var theme = try themeRecord.value()
                if theme.outfitIDs.contains(request.outfit.id) {
                    theme.outfitIDs.removeAll { $0 == request.outfit.id }; theme.revision += 1
                    try theme.validated(); themeRecord.payload = try JSONEncoder().encode(theme)
                }
            }
            let plans = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>())
            for planRecord in plans {
                var plan = try planRecord.value()
                if plan.outfitID == request.outfit.id {
                    plan.outfitID = nil; plan.outfitRevision = nil; plan.requiresReview = true
                    if plan.state == .planned { plan.state = .unassigned }
                    plan.revision += 1; try plan.validated()
                    planRecord.payload = try JSONEncoder().encode(plan)
                }
            }
            context.delete(record)
            result = .deleted(request.outfit.id)
        }
        context.insert(try StoredOutfitMutation(request: request, result: result))
        try prunePackingChecks(in: context)
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
        return result
    }
}

extension PieceStore {
    func searchCloset(query: String, scope: ClosetSearchScope, favoritesOnly: Bool = false, themeID: UUID? = nil) throws -> ClosetSearchResults {
        let query = Self.searchText(query.trimmingCharacters(in: .whitespacesAndNewlines))
        switch scope {
        case .pieces:
            // Dedicated Pieces search is independent of browse filters. Archived
            // matches are explicit records, never hidden active constraints.
            return .pieces(try (pieces(query: query) + pieces(query: query, archived: true)).sorted {
                let order = $0.name.localizedStandardCompare($1.name)
                return order == .orderedSame ? $0.id.uuidString < $1.id.uuidString : order == .orderedAscending
            })
        case .outfits:
            let themes = try themes()
            let matching = try outfits().filter { outfit in
                guard !favoritesOnly || outfit.isFavorite else { return false }
                guard themeID == nil || themes.contains(where: { $0.id == themeID && $0.outfitIDs.contains(outfit.id) }) else { return false }
                let memberships = themes.filter { $0.outfitIDs.contains(outfit.id) }.map(\.name)
                let terms = [outfit.name, outfit.mood ?? "", outfit.occasion ?? ""] + memberships
                return query.isEmpty || Self.searchText(terms.joined(separator: " ")).contains(query)
            }
            return .outfits(matching)
        case .themes:
            return .themes(try themes().filter { query.isEmpty || Self.searchText($0.name + " " + $0.description).contains(query) })
        }
    }
    func closetIsEmpty() throws -> Bool {
        try pieces().isEmpty && pieces(archived: true).isEmpty && outfits().isEmpty && themes().isEmpty
    }
}
