import AQDCore
import CoreData
import CryptoKit
import Darwin
import Foundation
import SwiftData

extension PieceStore {
    func ownedPiecesForWear() throws -> [WardrobePiece] { try pieces() + pieces(archived: true) }

    func wearRecords() throws -> [OutfitWearRecord] {
        let owner = try todayConfiguration().ownerID
        let values = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitWear>()).map { try $0.value() }
        guard values.allSatisfy({ $0.ownerID == owner }), Set(values.map(\.duplicateKey)).count == values.count else {
            throw StoreError.invalidRecord
        }
        return values.sorted {
            if $0.day.key != $1.day.key { return $0.day.key > $1.day.key }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
    func wearDraft() throws -> OutfitWearDraft? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitWearDraft>())
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let draft = try records.first?.value() else { return nil }
        guard draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        return draft
    }
    func saveWearDraft(_ draft: OutfitWearDraft) throws {
        guard allowsSave, draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        _ = try draft.day.date()
        guard Set(draft.pieceIDs).count == draft.pieceIDs.count else { throw StoreError.invalidRecord }
        guard try savedWear(for: draft) == nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredOutfitWearDraft>())
        guard records.count <= 1, records.first.map({ $0.id == draft.id }) ?? true else { throw StoreError.operationConflict }
        if let record = records.first { record.payload = try JSONEncoder().encode(draft) }
        else { context.insert(try StoredOutfitWearDraft(draft)) }
        try commit(context)
    }
    func matchingWear(for draft: OutfitWearDraft) throws -> OutfitWearRecord? {
        try wearRecords().first { $0.duplicateKey == draft.duplicateKey && $0.id != draft.baseRecord?.id }
    }
    func savedWear(for draft: OutfitWearDraft) throws -> OutfitWearRecord? {
        let records = try ModelContext(container).fetch(FetchDescriptor<StoredOutfitWearSave>()).filter { $0.id == draft.operationID }
        guard records.count <= 1 else { throw StoreError.invalidRecord }
        guard let receipt = records.first else { return nil }
        guard try JSONDecoder().decode(OutfitWearDraft.self, from: receipt.draft) == draft else { throw StoreError.operationConflict }
        let saved = try JSONDecoder().decode(OutfitWearRecord.self, from: receipt.snapshot)
        try saved.validated()
        guard saved.ownerID == draft.ownerID, saved.duplicateKey == draft.duplicateKey,
              saved.id == draft.wearID || saved.id == draft.acceptedDuplicateID else { throw StoreError.invalidRecord }
        return saved
    }
    func saveWear(_ draft: OutfitWearDraft) throws -> OutfitWearRecord {
        if let saved = try savedWear(for: draft) { return saved }
        guard allowsSave, draft.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        let pieces = try ownedPiecesForWear()
        try draft.validatedForSave(pieces: pieces)
        guard try wearDraft() == draft else { throw StoreError.staleDraft }
        if draft.baseRecord == nil, let id = draft.outfitID, try outfit(id: id) == nil { throw StoreError.staleRevision }
        let context = ModelContext(container)
        var editedRecord: StoredOutfitWear?
        if let base = draft.baseRecord {
            editedRecord = try context.fetch(FetchDescriptor<StoredOutfitWear>()).first { $0.id == base.id }
            guard let editedRecord, try editedRecord.value() == base else { throw StoreError.staleRevision }
        }
        var linkedRecord: StoredOutfitPlanEntry?
        if let reviewed = draft.planEntry {
            linkedRecord = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()).first { $0.id == reviewed.id }
            guard let linkedRecord, try linkedRecord.value() == reviewed else { throw StoreError.staleRevision }
        }
        let saved: OutfitWearRecord
        if let existing = try matchingWear(for: draft) {
            guard draft.baseRecord == nil, draft.acceptedDuplicateID == existing.id else { throw WearValidationError.alreadyRecorded }
            saved = existing
        } else {
            guard draft.acceptedDuplicateID == nil else { throw StoreError.staleRevision }
            let snapshots = try draft.pieceIDs.map { id -> WearPieceSnapshot in
                if let previous = draft.baseRecord?.pieces.first(where: { $0.id == id }) { return previous }
                guard let piece = pieces.first(where: { $0.id == id }) else { throw StoreError.staleRevision }
                return WearPieceSnapshot(piece)
            }
            saved = OutfitWearRecord(id: draft.wearID, ownerID: draft.ownerID, day: draft.day,
                                     outfitID: draft.outfitID, pieces: snapshots, revision: (draft.baseRecord?.revision ?? 0) + 1,
                                     planEntryID: draft.planEntry?.id ?? draft.baseRecord?.planEntryID)
            try saved.validated()
            if let editedRecord {
                editedRecord.payload = try encode(saved)
                if draft.baseRecord?.day != saved.day || draft.baseRecord?.duplicateKey != saved.duplicateKey {
                    try resetWearLinks(saved.id, in: context)
                }
            } else { context.insert(try StoredOutfitWear(saved)) }
        }
        if let linkedRecord, var entry = draft.planEntry {
            entry.state = .worn; entry.wearRecordID = saved.id; entry.revision += 1
            linkedRecord.payload = try encode(entry)
        }
        context.insert(try StoredOutfitWearSave(draft: draft, saved: saved))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
        return saved
    }
    func finishWearDraft(_ draft: OutfitWearDraft, discarding: Bool = false) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let saved = try savedWear(for: draft)
        guard discarding ? saved == nil : saved != nil else { throw StoreError.operationConflict }
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<StoredOutfitWearDraft>())
        guard records.count == 1, let record = records.first, try record.value() == draft else { throw StoreError.staleDraft }
        context.delete(record); try commit(context)
    }
}

extension PieceStore {
    func applyHistoryMutation(_ request: HistoryMutation) throws {
        let context = ModelContext(container)
        if let receipt = try context.fetch(FetchDescriptor<StoredHistoryMutation>()).first(where: { $0.id == request.operationID }) {
            guard try JSONDecoder().decode(HistoryMutation.self, from: receipt.request) == request else { throw StoreError.operationConflict }
            return
        }
        guard allowsSave else { throw StoreError.corruptStore }
        let owner = try todayConfiguration().ownerID
        let entries = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>())
        switch request.action {
        case .undoWear(let base):
            guard base.ownerID == owner,
                  let record = try context.fetch(FetchDescriptor<StoredOutfitWear>()).first(where: { $0.id == base.id }),
                  try record.value() == base else { throw StoreError.staleRevision }
            try resetWearLinks(base.id, in: context)
            context.delete(record)
        case .skip(let base):
            guard base.ownerID == owner, base.state == .planned || base.state == .unassigned,
                  let record = entries.first(where: { $0.id == base.id }), try record.value() == base else { throw StoreError.staleRevision }
            var updated = base; updated.state = .skipped; updated.revision += 1
            try updated.validated(); record.payload = try encode(updated)
        case .deletePlan(let base, let reviewed):
            guard base.ownerID == owner,
                  let record = try context.fetch(FetchDescriptor<StoredPlanDefinition>()).first(where: { $0.id == base.id }),
                  try record.value() == base else { throw StoreError.staleRevision }
            let affected = try entries.filter { try $0.value().planID == base.id }
            let current = try affected.map { try $0.value() }
            guard Set(current.map(\.id)) == Set(reviewed.map(\.id)), current.count == reviewed.count,
                  current.allSatisfy({ reviewed.contains($0) }) else { throw StoreError.staleRevision }
            affected.forEach { context.delete($0) }; context.delete(record)
            for packing in try context.fetch(FetchDescriptor<StoredPackingState>()) where packing.id == base.id { context.delete(packing) }
        }
        context.insert(try StoredHistoryMutation(request))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
}

extension PieceStore {
    func resetWearLinks(_ wearID: UUID, in context: ModelContext) throws {
        for record in try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()) {
            var entry = try record.value()
            guard entry.wearRecordID == wearID else { continue }
            entry.wearRecordID = nil; entry.state = entry.outfitID == nil ? .unassigned : .planned; entry.revision += 1
            try entry.validated(); record.payload = try encode(entry)
        }
    }
}
