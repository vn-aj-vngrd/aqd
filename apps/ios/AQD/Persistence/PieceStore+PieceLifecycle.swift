import AQDCore
import CoreData
import CryptoKit
import Darwin
import Foundation
import SwiftData

extension PieceStore {
    struct AvailabilityRequest: Encodable {
        let id: UUID
        let value: PieceAvailability
        let expectedRevision: Int
    }

    @discardableResult
    func setAvailability(id: UUID, value: PieceAvailability, expectedRevision: Int, operationID: UUID) throws -> WardrobePiece {
        let context = ModelContext(container)
        let digest = "availability:" + digest(try encode(AvailabilityRequest(id: id, value: value, expectedRevision: expectedRevision)))
        if let receipt = try context.fetch(FetchDescriptor<StoredPieceSave>(predicate: #Predicate { $0.id == operationID })).first {
            guard receipt.draftDigest == digest else { throw StoreError.operationConflict }
            return try JSONDecoder().decode(WardrobePiece.self, from: receipt.snapshot)
        }
        guard allowsSave else { throw StoreError.corruptStore }
        try ensureUnusedDeletionOperation(operationID, context: context)
        guard try context.fetch(FetchDescriptor<StoredPieceDraft>(predicate: #Predicate { $0.operationID == operationID })).isEmpty else {
            throw StoreError.operationConflict
        }
        guard let stored = try context.fetch(FetchDescriptor<StoredPiece>(predicate: #Predicate { $0.id == id })).first,
              stored.revision == expectedRevision else { throw StoreError.staleRevision }
        if value != .available { try flagFuturePlans(using: id, context: context) }
        stored.availability = value.rawValue; stored.revision += 1; stored.updatedAt = Date()
        let result = try stored.value()
        context.insert(StoredPieceSave(id: operationID, itemID: id, draftDigest: digest, snapshot: try encode(result)))
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
        return result
    }

    func flagFuturePlans(using pieceID: UUID, context: ModelContext) throws {
        let affected = Set(try context.fetch(FetchDescriptor<StoredOutfit>()).map { try $0.value() }
            .filter { $0.pieceIDs.contains(pieceID) }.map(\.id))
        try flagFuturePlans(outfitIDs: affected, context: context)
    }

    func flagFuturePlans(outfitIDs: Set<UUID>, context: ModelContext) throws {
        let owner = try todayConfiguration().ownerID
        for record in try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()) {
            var plan = try record.value()
            guard plan.ownerID == owner else { throw StoreError.invalidRecord }
            let zone = TimeZone(identifier: plan.day.timeZoneID) ?? .current
            guard plan.state == .planned, plan.day.key >= LocalPlanDay(timeZone: zone).key,
                  let outfitID = plan.outfitID, outfitIDs.contains(outfitID), !plan.requiresReview else { continue }
            plan.requiresReview = true; plan.revision += 1; try plan.validated()
            record.payload = try encode(plan)
        }
    }
}

extension PieceStore {
    func pieceDeletionImpact(id: UUID) throws -> PieceDeletionImpact {
        guard let piece = try piece(id: id) else { throw StoreError.staleRevision }
        let affected = try outfits().filter { $0.pieceIDs.contains(id) }
        let ids = Set(affected.map(\.id))
        let themes = try themes().filter { !ids.isDisjoint(with: $0.outfitIDs) }
        let plans = try planEntries().filter { entry in
            let zone = TimeZone(identifier: entry.day.timeZoneID) ?? .current
            return entry.state == .planned && entry.day.key >= LocalPlanDay(timeZone: zone).key
                && entry.outfitID.map { ids.contains($0) } == true
        }
        return PieceDeletionImpact(pieceID: id, pieceRevision: piece.revision,
            outfitRevisions: Dictionary(uniqueKeysWithValues: affected.map { ($0.id, $0.revision) }),
            themeRevisions: Dictionary(uniqueKeysWithValues: themes.map { ($0.id, $0.revision) }),
            futurePlanRevisions: Dictionary(uniqueKeysWithValues: plans.map { ($0.id, $0.revision) }))
    }

    func applyPieceDeletionImpact(_ impact: PieceDeletionImpact, context: ModelContext) throws {
        var emptyOutfits = Set<UUID>()
        for record in try context.fetch(FetchDescriptor<StoredOutfit>()) {
            var outfit = try record.value()
            guard impact.outfitRevisions[outfit.id] != nil else { continue }
            outfit.pieceIDs.removeAll { $0 == impact.pieceID }
            if outfit.pieceIDs.isEmpty { emptyOutfits.insert(outfit.id); context.delete(record) }
            else {
                outfit.revision += 1; outfit.updatedAt = Date(); try outfit.validated()
                record.payload = try encode(outfit)
            }
        }
        for record in try context.fetch(FetchDescriptor<StoredOutfitTheme>()) {
            var theme = try record.value()
            guard !emptyOutfits.isDisjoint(with: theme.outfitIDs) else { continue }
            theme.outfitIDs.removeAll { emptyOutfits.contains($0) }; theme.revision += 1
            try theme.validated(); record.payload = try encode(theme)
        }
        for record in try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>()) {
            var plan = try record.value()
            guard impact.futurePlanRevisions[plan.id] != nil else { continue }
            plan.outfitID = nil; plan.outfitRevision = nil; plan.requiresReview = true; plan.state = .unassigned
            plan.revision += 1; try plan.validated(); record.payload = try encode(plan)
        }
    }
}
