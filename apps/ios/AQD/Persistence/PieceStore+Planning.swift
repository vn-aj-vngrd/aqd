import AQDCore
import CoreData
import CryptoKit
import Darwin
import Foundation
import SwiftData

extension PieceStore {
    func planEntries() throws -> [OutfitPlanEntry] {
        let owner = try todayConfiguration().ownerID
        let values = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitPlanEntry>()).map { try $0.value() }
        guard values.allSatisfy({ $0.ownerID == owner }) else { throw StoreError.invalidRecord }
        return values.sorted {
            if $0.day.key != $1.day.key { return $0.day.key < $1.day.key }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    func planDraft() throws -> OutfitPlanDraft? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitPlanDraft>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let value = try records.first?.value() else { return nil }
        guard value.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        return value
    }

    func savePlanDraft(_ draft: OutfitPlanDraft) throws {
        guard allowsSave, draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        _ = try draft.day.date()
        guard try savedPlan(for: draft) == nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredOutfitPlanDraft>())
        guard records.count <= 1, records.first.map({ $0.id == draft.id }) ?? true else { throw StoreError.operationConflict }
        if let record = records.first { record.payload = try JSONEncoder().encode(draft) }
        else { context.insert(try StoredOutfitPlanDraft(draft)) }
        try commit(context)
    }

    func savedPlan(for draft: OutfitPlanDraft) throws -> OutfitPlanEntry? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitPlanSave>()).filter { $0.id == draft.operationID }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let receipt = records.first else { return nil }
        guard try JSONDecoder().decode(OutfitPlanDraft.self, from: receipt.draft) == draft else { throw StoreError.operationConflict }
        let saved = try JSONDecoder().decode(OutfitPlanEntry.self, from: receipt.snapshot)
        try saved.validated()
        guard saved.id == draft.entryID, saved.ownerID == draft.ownerID else { throw StoreError.invalidRecord }
        return saved
    }

    func savePlan(_ draft: OutfitPlanDraft) throws -> OutfitPlanEntry {
        if let saved = try savedPlan(for: draft) { return saved }
        guard allowsSave, draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        try draft.validatedForSave(outfits: outfits())
        let namedPlan = try planDefinitions().first { $0.id == draft.planID }
        if draft.parentPlanID != nil && namedPlan == nil { throw StoreError.staleRevision }
        if let namedPlan {
            guard namedPlan.ownerID == draft.ownerID, draft.day.timeZoneID == namedPlan.start.timeZoneID,
                  draft.day.key >= namedPlan.start.key,
                  draft.day.key <= namedPlan.end.key else { throw PlanValidationError.invalidDay }
        }
        let overlaps = try planEntries().contains {
            $0.id != draft.entryID && $0.day == draft.day && $0.occasion.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == draft.occasion.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        guard !overlaps || draft.allowsOverlap == true else { throw PlanValidationError.overlap }
        guard try planDraft() == draft else { throw StoreError.staleDraft }
        if let outfit = draft.outfit {
            let active = Set(try pieces().filter { $0.availability == .available }.map(\.id))
            guard Set(outfit.pieceIDs).isSubset(of: active) else { throw StoreError.staleRevision }
        }
        let saved = OutfitPlanEntry(id: draft.entryID, planID: draft.planID, ownerID: draft.ownerID, day: draft.day,
                                    occasion: draft.occasion, outfitID: draft.outfit?.id, outfitRevision: draft.outfit?.revision,
                                    state: draft.outfit == nil ? .unassigned : .planned, revision: (draft.baseEntry?.revision ?? 0) + 1)
        try saved.validated()
        let context = ModelContext(container)
        let existing = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()).first { $0.id == draft.entryID }
        if let base = draft.baseEntry {
            guard let existing, try existing.value() == base else { throw StoreError.staleRevision }
            existing.payload = try JSONEncoder().encode(saved)
        } else {
            guard existing == nil else { throw StoreError.operationConflict }
            context.insert(try StoredOutfitPlanEntry(saved))
        }
        context.insert(try StoredOutfitPlanSave(draft: draft, saved: saved))
        try prunePackingChecks(in: context)
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
        return saved
    }

    func finishPlanDraft(_ draft: OutfitPlanDraft, discarding: Bool = false) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let saved = try savedPlan(for: draft)
        guard discarding ? saved == nil : saved != nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredOutfitPlanDraft>())
        guard records.count == 1, let record = records.first, try record.value() == draft else { throw StoreError.staleDraft }
        context.delete(record); try commit(context)
    }
}

extension PieceStore {
    func deletePlanEntry(_ request: PlanEntryDeletionRequest) throws {
        guard request.expectedRevision > 0 else { throw StoreError.invalidRecord }
        let context = ModelContext(container)
        if let receipt = try context.fetch(FetchDescriptor<StoredPlanEntryDeletion>()).first(where: { $0.id == request.operationID }) {
            guard try JSONDecoder().decode(PlanEntryDeletionRequest.self, from: receipt.request) == request else { throw StoreError.operationConflict }
            return
        }
        guard allowsSave else { throw StoreError.corruptStore }
        guard let record = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()).first(where: { $0.id == request.entryID }) else { throw StoreError.staleRevision }
        let entry = try record.value()
        guard entry.ownerID == (try todayConfiguration().ownerID), entry.revision == request.expectedRevision,
              entry.state == .planned || entry.state == .unassigned else { throw StoreError.staleRevision }
        context.delete(record); context.insert(try StoredPlanEntryDeletion(request))
        try prunePackingChecks(in: context)
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
}

extension PieceStore {
    func planDefinitions() throws -> [PlanDefinition] {
        let owner = try todayConfiguration().ownerID
        let values = try ModelContext(container).fetch(FetchDescriptor<StoredPlanDefinition>()).map { try $0.value() }
        guard values.allSatisfy({ $0.ownerID == owner }) else { throw StoreError.invalidRecord }
        return values.sorted { $0.start.key == $1.start.key ? $0.id.uuidString < $1.id.uuidString : $0.start.key < $1.start.key }
    }
    func planAuthoringDraft() throws -> PlanAuthoringDraft? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredPlanAuthoringDraft>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let value = try records.first?.value() else { return nil }
        guard value.plan.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        return value
    }
    func savePlanAuthoringDraft(_ draft: PlanAuthoringDraft) throws {
        guard allowsSave, draft.plan.ownerID == (try todayConfiguration().ownerID), try savedPlanAuthoring(draft) == nil else { throw StoreError.operationConflict }
        _ = try draft.plan.start.date(); _ = try draft.plan.end.date()
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredPlanAuthoringDraft>())
        guard records.count <= 1, records.first.map({ $0.id == draft.id }) ?? true else { throw StoreError.operationConflict }
        if let record = records.first { record.payload = try encode(draft) }
        else { context.insert(try StoredPlanAuthoringDraft(draft)) }
        try commit(context)
    }
    func savedPlanAuthoring(_ draft: PlanAuthoringDraft) throws -> PlanAuthoringReceipt? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredPlanAuthoringSave>()).filter { $0.id == draft.operationID }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let proof = records.first else { return nil }
        guard try JSONDecoder().decode(PlanAuthoringDraft.self, from: proof.request) == draft else { throw StoreError.operationConflict }
        let result = try JSONDecoder().decode(PlanAuthoringReceipt.self, from: proof.result)
        try result.plan.validated()
        var expectedPlan = draft.plan; expectedPlan.revision = (draft.basePlan?.revision ?? 0) + 1
        guard result.plan == expectedPlan, Set(result.entries.map(\.id)).count == result.entries.count,
              Set(result.entries.map(\.id)) == Set(draft.slots.map(\.id)), result.entries.count == draft.slots.count else { throw StoreError.invalidRecord }
        for entry in result.entries {
            try entry.validated()
            guard let slot = draft.slots.first(where: { $0.id == entry.id }),
                  entry.ownerID == result.plan.ownerID, entry.planID == result.plan.id, entry.day == slot.day,
                  entry.occasion == slot.occasion, entry.outfitID == slot.outfit?.id,
                  entry.outfitRevision == slot.outfit?.revision,
                  entry.revision == (draft.editableBaseEntries.first(where: { $0.id == entry.id })?.revision ?? 0) + 1,
                  entry.state == (slot.outfit == nil ? .unassigned : .planned), !entry.requiresReview else { throw StoreError.invalidRecord }
        }
        return result
    }
    func savePlanAuthoring(_ draft: PlanAuthoringDraft) throws -> PlanAuthoringReceipt {
        if let saved = try savedPlanAuthoring(draft) { return saved }
        guard allowsSave, draft.plan.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        let existing = try planEntries()
        try draft.validatedForSave(outfits: outfits(), existing: existing)
        guard try planAuthoringDraft() == draft else { throw StoreError.staleDraft }
        let active = Set(try pieces().filter { $0.availability == .available }.map(\.id))
        guard draft.slots.allSatisfy({ $0.outfit.map { Set($0.pieceIDs).isSubset(of: active) } ?? true }) else { throw PlanValidationError.unavailablePieces }
        let baseEntries = Dictionary(uniqueKeysWithValues: draft.editableBaseEntries.map { ($0.id, $0) })
        var savedPlan = draft.plan; savedPlan.revision = (draft.basePlan?.revision ?? 0) + 1; try savedPlan.validated()
        let entries = draft.slots.map { slot in
            OutfitPlanEntry(id: slot.id, planID: draft.plan.id, ownerID: draft.plan.ownerID, day: slot.day,
                occasion: slot.occasion, outfitID: slot.outfit?.id, outfitRevision: slot.outfit?.revision,
                state: slot.outfit == nil ? .unassigned : .planned, revision: (baseEntries[slot.id]?.revision ?? 0) + 1)
        }
        for entry in entries { try entry.validated() }
        let context = ModelContext(container)
        let definitions = try context.fetch(FetchDescriptor<StoredPlanDefinition>())
        let record = definitions.first { $0.id == draft.plan.id }
        if let base = draft.basePlan {
            guard let record, try record.value() == base else { throw StoreError.staleRevision }
            let current = existing.filter { $0.planID == base.id }
            let reviewed = draft.baseEntries ?? []
            guard current.count == reviewed.count, current.allSatisfy({ reviewed.contains($0) }) else { throw StoreError.staleRevision }
            record.payload = try encode(savedPlan)
        } else {
            guard record == nil else { throw StoreError.operationConflict }
            context.insert(try StoredPlanDefinition(savedPlan))
        }
        let editableIDs = Set(baseEntries.keys)
        let newIDs = Set(entries.map(\.id))
        guard newIDs.isDisjoint(with: existing.filter { !editableIDs.contains($0.id) }.map(\.id)) else { throw StoreError.operationConflict }
        let replacing = Set(draft.resolutions.filter { $0.choice == .replace }.map { $0.existing.id })
            .union(editableIDs.subtracting(newIDs))
        let entryRecords = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>())
        for record in entryRecords where replacing.contains(record.id) { context.delete(record) }
        for entry in entries {
            if let record = entryRecords.first(where: { $0.id == entry.id }) { record.payload = try encode(entry) }
            else { context.insert(try StoredOutfitPlanEntry(entry)) }
        }
        let result = PlanAuthoringReceipt(plan: savedPlan, entries: entries)
        context.insert(try StoredPlanAuthoringSave(draft: draft, saved: result))
        try prunePackingChecks(in: context)
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
        return result
    }
    func finishPlanAuthoring(_ draft: PlanAuthoringDraft, discarding: Bool = false) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let receipt = try savedPlanAuthoring(draft)
        guard discarding ? receipt == nil : receipt != nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredPlanAuthoringDraft>())
        guard records.count == 1, let record = records.first, try record.value() == draft else { throw StoreError.staleDraft }
        context.delete(record); try commit(context)
    }
}

extension PieceStore {
    func packingState(planID: UUID) throws -> PackingState {
        guard try planDefinitions().contains(where: { $0.id == planID && $0.trip != nil }) else { throw StoreError.staleRevision }
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredPackingState>()).filter { $0.id == planID }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        return try records.first?.value() ?? PackingState(planID: planID)
    }
    func packingSummary(planID: UUID) throws -> TripPackingSummary {
        guard let plan = try planDefinitions().first(where: { $0.id == planID }) else { throw StoreError.staleRevision }
        return try TripPackingSummary(plan: plan, entries: planEntries(), outfits: outfits(), pieces: ownedPiecesForWear(), checkedIDs: packingState(planID: planID).checkedIDs)
    }
    func setPackingCheck(_ request: PackingCheckRequest) throws -> PackingState {
        guard request.expectedRevision >= 0, request.expectedRevision < Int.max - 1 else { throw StoreError.invalidRecord }
        let context = ModelContext(container)
        if let proof = try context.fetch(FetchDescriptor<StoredPackingCheck>()).first(where: { $0.id == request.operationID }) {
            guard try JSONDecoder().decode(PackingCheckRequest.self, from: proof.request) == request else { throw StoreError.operationConflict }
            let value = try JSONDecoder().decode(PackingState.self, from: proof.result)
            guard value.planID == request.planID, value.revision == request.expectedRevision + 1,
                  value.checkedIDs.contains(request.pieceID) == request.checked else { throw StoreError.invalidRecord }
            return value
        }
        guard allowsSave else { throw StoreError.corruptStore }
        let summary = try packingSummary(planID: request.planID)
        guard summary.items.contains(where: { $0.id == request.pieceID }) else { throw StoreError.staleRevision }
        var state = try packingState(planID: request.planID)
        guard state.revision == request.expectedRevision else { throw StoreError.staleRevision }
        state.checkedIDs.formIntersection(summary.items.map(\.id))
        if request.checked { state.checkedIDs.insert(request.pieceID) } else { state.checkedIDs.remove(request.pieceID) }
        state.revision += 1
        if let record = try context.fetch(FetchDescriptor<StoredPackingState>()).first(where: { $0.id == request.planID }) { record.payload = try encode(state) }
        else { context.insert(try StoredPackingState(state)) }
        context.insert(try StoredPackingCheck(request: request, result: state))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
        return state
    }
    func prunePackingChecks(in context: ModelContext) throws {
        let records = try context.fetch(FetchDescriptor<StoredPackingState>())
        guard !records.isEmpty else { return }
        let definitions = try context.fetch(FetchDescriptor<StoredPlanDefinition>()).map { try $0.value() }
        let owner = try todayConfiguration().ownerID
        guard definitions.allSatisfy({ $0.ownerID == owner }) else { throw StoreError.invalidRecord }
        let entries = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()).map { try $0.value() }
        let outfits = try context.fetch(FetchDescriptor<StoredOutfit>()).map { try $0.value() }
        let pieces = try context.fetch(FetchDescriptor<StoredPiece>()).map { try $0.value() }
        guard entries.allSatisfy({ $0.ownerID == owner }), outfits.allSatisfy({ $0.ownerID == owner }) else { throw StoreError.invalidRecord }
        for record in records {
            var state = try record.value()
            guard let plan = definitions.first(where: { $0.id == state.planID }), plan.trip != nil else { throw StoreError.invalidRecord }
            let summary = try TripPackingSummary(plan: plan, entries: entries, outfits: outfits, pieces: pieces, checkedIDs: state.checkedIDs)
            let retained = state.checkedIDs.intersection(summary.items.map(\.id))
            if retained != state.checkedIDs {
                state.checkedIDs = retained; state.revision += 1
                guard state.revision < Int.max else { throw StoreError.invalidRecord }
                record.payload = try encode(state)
            }
        }
    }
}
