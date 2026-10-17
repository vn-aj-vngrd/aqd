import AQDCore
import CoreData
import CryptoKit
import Darwin
import Foundation
import SwiftData

#if DEBUG
extension PieceStore {
    /// Compare-and-swap the exact legacy seed text, never any user-edited fields.
    func replacePreviewSampleContexts(plans: [(before: OutfitPlanEntry, after: OutfitPlanEntry)], fits: [(before: FitMemory, after: FitMemory)]) throws {
        guard allowsSave, Set(plans.map { $0.before.id }).count == plans.count,
              Set(fits.map { $0.before.id }).count == fits.count else { throw StoreError.invalidRecord }
        let owner = try todayConfiguration().ownerID
        let context = ModelContext(container)
        for change in plans {
            let before = change.before, id = before.id
            guard let index = (0..<7).first(where: { PreviewSampleContent.id(301 + $0) == id }),
                  before.ownerID == owner, before.revision == 1, before.occasion == PreviewSampleContent.legacyPlanOccasion(index),
                  before.state == .planned, !before.requiresReview,
                  let record = try context.fetch(FetchDescriptor<StoredOutfitPlanEntry>(predicate: #Predicate { $0.id == id })).first,
                  try record.value() == before else { throw StoreError.staleRevision }
            var expected = before; expected.occasion = PreviewSampleContent.planContexts[index]; expected.revision += 1
            guard expected == change.after else { throw StoreError.invalidRecord }
            try expected.validated(); record.payload = try JSONEncoder().encode(expected)
        }
        for change in fits {
            let before = change.before, id = before.id
            guard let index = (0..<8).first(where: { PreviewSampleContent.id(401 + $0) == id }),
                  before.ownerID == owner, before.revision == 1, before.note == PreviewSampleContent.legacyFitNote,
                  let record = try context.fetch(FetchDescriptor<StoredFitMemory>(predicate: #Predicate { $0.id == id })).first,
                  try record.value() == before else { throw StoreError.staleRevision }
            var expected = before; expected.note = PreviewSampleContent.fitNotes[index]; expected.revision += 1
            guard expected == change.after else { throw StoreError.invalidRecord }
            try expected.validated(); record.payload = try JSONEncoder().encode(expected)
        }
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
    func replacePreviewSamplePhotos(_ replacements: [(piece: WardrobePiece, photoID: UUID)]) throws {
        guard allowsSave, Set(replacements.map { $0.piece.id }).count == replacements.count else { throw StoreError.invalidRecord }
        let context = ModelContext(container)
        for replacement in replacements {
            let piece = replacement.piece, id = piece.id
            guard PreviewSampleContent.sampleIDs["pieces", default: []].contains(id), piece.revision == 1,
                  piece.photoRecipe == .fitOriginal,
                  let record = try context.fetch(FetchDescriptor<StoredPiece>(predicate: #Predicate { $0.id == id })).first,
                  try record.value() == piece else { throw StoreError.staleRevision }
            _ = try originalPhoto(id: replacement.photoID); _ = try thumbnailPhoto(id: replacement.photoID)
            let result = WardrobePiece(id: id, name: piece.name, category: piece.category, photoID: replacement.photoID,
                details: piece.details, availability: piece.availability, revision: piece.revision + 1,
                isArchived: piece.isArchived, createdAt: piece.createdAt, updatedAt: Date(), photoRecipe: .fitOriginal)
            try queueCleanup(photoID: piece.photoID, context: context)
            record.apply(result)
        }
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
    /// Owner-requested sample population. All graph records commit together;
    /// existing records/drafts and actual wear remain unchanged.
    func insertPreviewSamples(_ samples: PreviewSampleContent.Bundle) throws {
        guard allowsSave else { throw StoreError.corruptStore }
        let owner = try todayConfiguration().ownerID
        let existing = try PreviewSampleContent.existingIDs(in: self)
        guard existing.values.allSatisfy(\.isEmpty) else { throw StoreError.operationConflict }
        let pieceIDs = Set(samples.pieces.map(\.id))
        let availableIDs = Set(samples.pieces.filter { $0.availability == .available }.map(\.id))
        let outfitIDs = Set(samples.outfits.map(\.id))
        guard pieceIDs.count == samples.pieces.count, outfitIDs.count == samples.outfits.count,
              pieceIDs == Set(PreviewSampleContent.sampleIDs["pieces", default: []]),
              outfitIDs == Set(PreviewSampleContent.sampleIDs["outfits", default: []]),
              Set(samples.themes.map(\.id)) == Set(PreviewSampleContent.sampleIDs["themes", default: []]),
              Set(samples.plans.map(\.id)) == Set(PreviewSampleContent.sampleIDs["plans", default: []]),
              Set(samples.fits.map(\.id)) == Set(PreviewSampleContent.sampleIDs["fits", default: []]) else { throw StoreError.invalidRecord }
        for piece in samples.pieces {
            try PieceDraft(name: piece.name, category: piece.category, photoID: piece.photoID, details: piece.details).validated()
            try piece.photoRecipe.validated()
            _ = try photoRendition(id: piece.photoID, recipe: piece.photoRecipe)
        }
        for outfit in samples.outfits {
            try outfit.validated()
            guard outfit.ownerID == owner, Set(outfit.pieceIDs).isSubset(of: availableIDs) else { throw StoreError.invalidRecord }
        }
        var names = Set(try themes().map { OutfitTheme.nameKey($0.name) })
        for theme in samples.themes {
            try theme.validated()
            guard theme.ownerID == owner, Set(theme.outfitIDs).isSubset(of: outfitIDs),
                  names.insert(OutfitTheme.nameKey(theme.name)).inserted else { throw StoreError.invalidRecord }
        }
        let existingPlans = try planEntries()
        for plan in samples.plans {
            try plan.validated()
            guard plan.ownerID == owner, plan.state == .planned,
                  samples.outfits.contains(where: { $0.id == plan.outfitID && $0.revision == plan.outfitRevision }),
                  !existingPlans.contains(where: { $0.day == plan.day && $0.occasion == plan.occasion }) else { throw StoreError.invalidRecord }
        }
        for fit in samples.fits {
            try fit.validated()
            guard fit.ownerID == owner, let snapshot = fit.outfit,
                  let outfit = samples.outfits.first(where: { $0.id == snapshot.id }),
                  try FitOutfitSnapshot(outfit: outfit, pieces: samples.pieces) == snapshot else { throw StoreError.invalidRecord }
            if let photo = fit.photoID { _ = try photoRendition(id: photo, recipe: fit.photoRecipe) }
        }
        let context = ModelContext(container)
        for value in samples.pieces { context.insert(StoredPiece(value)) }
        for value in samples.outfits { context.insert(try StoredOutfit(value)) }
        for value in samples.themes { context.insert(try StoredOutfitTheme(value)) }
        for value in samples.plans { context.insert(try StoredOutfitPlanEntry(value)) }
        for value in samples.fits { context.insert(try StoredFitMemory(value)) }
        try beforeOutfitSave(); try commit(context); try afterOutfitSave()
    }
}
#endif
