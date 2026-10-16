#if DEBUG
import AQDCore
import Foundation
import UIKit

/// Explicit owner preview only. No normal launch, tour or Release path calls this.
@MainActor enum PreviewSampleContent {
    struct Bundle {
        var pieces: [WardrobePiece] = []
        var outfits: [Outfit] = []
        var themes: [OutfitTheme] = []
        var plans: [OutfitPlanEntry] = []
        var fits: [FitMemory] = []
    }
    struct Receipt: Codable, Equatable {
        let version: Int
        let added: [String: Int]
        let ids: [String: [UUID]]
        let backup: String?
    }
    struct ContextReceipt: Codable, Equatable {
        let updatedPlans: [UUID]
        let updatedFits: [UUID]
        let skippedPlans: [UUID]
        let skippedFits: [UUID]
        let backup: String?
    }
    static let planContexts = ["Team planning", "Coffee and errands", "Sunday market", "Client meeting", "Lunch by the waterfront", "Dinner with friends", "Project catch-up"]
    static let legacyFitNote = "Sample fit memory for preview only. This does not represent your photo or recorded wear."
    static let fitNotes = [
        "Sample preview · A blue coat adds a little color to a city walk. Illustrative photo, not recorded wear.",
        "Sample preview · Burgundy layers and sunglasses for an afternoon outside. Illustrative photo, not recorded wear.",
        "Sample preview · Cream and tan with sneakers for a relaxed weekend. Not recorded wear.",
        "Sample preview · Navy layers, a cotton shirt and loafers for a cooler morning. Not recorded wear.",
        "Sample preview · A blue shirt with sand linen trousers for a long lunch. Not recorded wear.",
        "Sample preview · A cream dress and navy coat for dinner. Not recorded wear.",
        "Sample preview · Charcoal trousers, a cotton shirt and loafers for the studio. Not recorded wear.",
        "Sample preview · Denim and ivory sneakers for coffee and errands. Not recorded wear."]
    static func legacyPlanOccasion(_ index: Int) -> String {
        "Sample · " + ["Office day", "Coffee run", "Weekend ease", "City layers", "Linen afternoon", "Evening out"][index % 6]
    }
    enum Failure: Error { case partialSamples, missingArtwork, changedStore, invalidGraph }
    static func id(_ number: Int) -> UUID {
        // Closed constants below are the only callers; this namespace is reserved for samples.
        UUID(uuidString: "A0D51000-0000-4000-8000-" + String(format: "%012d", number))!
    }
    static let specs: [(String, String, PieceCategory, String)] = [
            ("shirt", "Blue cotton shirt", .tops, "Blue"), ("knit", "Ivory ribbed knit", .tops, "Ivory"),
            ("coat", "Navy trench coat", .layers, "Navy"), ("overshirt", "Olive overshirt", .layers, "Olive"),
            ("trousers", "Tailored trousers", .bottoms, "Charcoal"), ("linen", "Linen trousers", .bottoms, "Sand"),
            ("dress", "Cream midi dress", .dresses, "Cream"), ("jeans", "Indigo jeans", .bottoms, "Indigo"),
            ("loafers", "Oxblood loafers", .shoes, "Oxblood"), ("sneakers", "Ivory sneakers", .shoes, "Ivory"),
            ("bag", "Tan crossbody", .accessories, "Tan"), ("belt", "Black belt", .accessories, "Black")]
    static var sampleIDs: [String: [UUID]] {
        ["pieces": (1...12).map(id), "outfits": (101...106).map(id), "themes": (201...204).map(id),
         "plans": (301...307).map(id), "fits": (401...408).map(id)]
    }
    static func existingIDs(in store: PieceStore) throws -> [String: [UUID]] {
        let expected = sampleIDs
        return ["pieces": try (store.pieces() + store.pieces(archived: true)).map(\.id).filter { expected["pieces", default: []].contains($0) },
                "outfits": try store.outfits().map(\.id).filter { expected["outfits", default: []].contains($0) },
                "themes": try store.themes().map(\.id).filter { expected["themes", default: []].contains($0) },
                "plans": try store.planEntries().map(\.id).filter { expected["plans", default: []].contains($0) },
                "fits": try store.fitMemories().map(\.id).filter { expected["fits", default: []].contains($0) }]
    }
    static func populate(store: PieceStore, outputDirectory: URL, now: Date = Date(), timeZone: TimeZone = .current, legacyDescriptions: Bool = false) async throws -> Receipt {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let receiptURL = outputDirectory.appendingPathComponent("AQD-preview-samples.json")
        let existing = try existingIDs(in: store)
        if existing.values.contains(where: { !$0.isEmpty }) {
            guard sampleIDs.allSatisfy({ Set(existing[$0.key, default: []]) == Set($0.value) }) else { throw Failure.partialSamples }
            // Preserve any edits/deletions deliberately made after the original population.
            if let data = try? Data(contentsOf: receiptURL), let receipt = try? JSONDecoder().decode(Receipt.self, from: data), receipt.ids == sampleIDs { return receipt }
            let receipt = Receipt(version: 1, added: sampleIDs.mapValues(\.count), ids: sampleIDs, backup: nil)
            try write(try JSONEncoder().encode(receipt), to: receiptURL); return receipt
        }
        let backupName = "AQD-before-samples-\(UUID().uuidString).aqdarchive"
        let backup = try await LocalArchiveService.create(store: store)
        try write(backup.data, to: outputDirectory.appendingPathComponent(backupName))
        var stamp = try store.mutationStamp()
        let preparer = PhotoPreparer()
        func photo(_ data: Data) async throws -> UUID {
            let prepared = try await preparer.prepare(data: data)
            guard try store.mutationStamp() == stamp else { throw Failure.changedStore }
            let photoID = try store.acceptPhoto(prepared)
            stamp = try store.mutationStamp()
            return photoID
        }
        var bundle = Bundle()
        for (index, spec) in specs.enumerated() {
            guard let data = WelcomeGarments.images[spec.0]?.pngData() else { throw Failure.missingArtwork }
            let photoID = try await photo(data)
            let piece = WardrobePiece(id: id(index + 1), name: "Sample · \(spec.1)", category: spec.2, photoID: photoID,
                details: PieceDetails(color: spec.3, notes: "Sample preview artwork. This is not a personal wardrobe upload."),
                availability: index == 1 ? .laundry : index == 3 ? .unavailable : .available,
                createdAt: now.addingTimeInterval(Double(-index) * 86400), updatedAt: now)
            bundle.pieces.append(piece)
        }
        let owner = try store.todayConfiguration().ownerID
        let looks: [(String, [Int])] = [("Office day", [1, 5, 9, 12]), ("Coffee run", [1, 8, 10, 11]),
            ("Weekend ease", [7, 10, 11]), ("City layers", [3, 1, 5, 9]),
            ("Linen afternoon", [1, 6, 9, 12]), ("Evening out", [7, 3, 9])]
        for (index, look) in looks.enumerated() {
            bundle.outfits.append(Outfit(id: id(101 + index), ownerID: owner, name: "Sample · \(look.0)",
                pieceIDs: look.1.map(id), mood: "Sample preview", occasion: look.0, isFavorite: index < 3,
                createdAt: now, updatedAt: now.addingTimeInterval(Double(-index) * 60)))
        }
        let themes: [(String, [Int])] = [("Weekday", [101, 104]), ("Off duty", [102, 103, 105]), ("Evening", [106, 104]), ("Ideas to collect", [])]
        for (index, theme) in themes.enumerated() {
            bundle.themes.append(OutfitTheme(id: id(201 + index), ownerID: owner, name: "Sample · \(theme.0)",
                description: "Sample collection for previewing the app.", outfitIDs: theme.1.map(id)))
        }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = timeZone
        for index in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: index, to: now) else { throw Failure.invalidGraph }
            let outfit = bundle.outfits[index % bundle.outfits.count]
            bundle.plans.append(OutfitPlanEntry(id: id(301 + index), planID: id(501 + index), ownerID: owner,
                day: LocalPlanDay(date: date, timeZone: timeZone), occasion: legacyDescriptions ? legacyPlanOccasion(index) : planContexts[index],
                outfitID: outfit.id, outfitRevision: outfit.revision, state: .planned))
        }
        let offsets = [0, -1, -2, -4, -6, -8, -10, -12]
        for index in 0..<8 {
            guard let date = calendar.date(byAdding: .day, value: offsets[index], to: now) else { throw Failure.invalidGraph }
            var memory = FitMemory(id: id(401 + index), ownerID: owner)
            memory.day = LocalPlanDay(date: date, timeZone: timeZone)
            memory.note = legacyDescriptions ? legacyFitNote : fitNotes[index]
            memory.outfit = try FitOutfitSnapshot(outfit: bundle.outfits[index % bundle.outfits.count], pieces: bundle.pieces)
            if index < 2 {
                let name = index == 0 ? "tour-fit-blue-coat" : "tour-fit-street"
                guard let url = Foundation.Bundle.main.url(forResource: name, withExtension: "jpg") else { throw Failure.missingArtwork }
                memory.photoID = try await photo(Data(contentsOf: url))
            }
            bundle.fits.append(memory)
        }
        guard try store.mutationStamp() == stamp else { throw Failure.changedStore }
        try store.insertPreviewSamples(bundle)
        let persisted = try existingIDs(in: store)
        guard sampleIDs.allSatisfy({ Set(persisted[$0.key, default: []]) == Set($0.value) }) else { throw Failure.invalidGraph }
        let receipt = Receipt(version: 1, added: sampleIDs.mapValues(\.count), ids: sampleIDs, backup: backupName)
        try write(try JSONEncoder().encode(receipt), to: receiptURL)
        return receipt
    }
    struct MediaReceipt: Codable {
        let updated: [UUID]
        let skipped: [UUID]
        let transparent: [UUID]
        let backup: String?
    }
    static func refreshTransparentPhotos(store: PieceStore, outputDirectory: URL) async throws -> MediaReceipt {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let pieces = try store.pieces() + store.pieces(archived: true)
        let allSamples = pieces.filter { sampleIDs["pieces", default: []].contains($0.id) }
        let outfitDraftPieces = Set(try store.outfitDraft()?.pieceIDs ?? [])
        var candidates: [WardrobePiece] = []
        for piece in allSamples where piece.revision == 1 && piece.photoRecipe == .fitOriginal && !outfitDraftPieces.contains(piece.id) {
            if try store.recoverableDraft(itemID: piece.id) == nil { candidates.append(piece) }
        }
        var backupName: String?
        var stamp = try store.mutationStamp()
        if !candidates.isEmpty {
            let backup = try await LocalArchiveService.create(store: store)
            guard try store.mutationStamp() == stamp else { throw Failure.changedStore }
            let name = "AQD-before-transparent-samples-\(UUID().uuidString).aqdarchive"
            try write(backup.data, to: outputDirectory.appendingPathComponent(name)); backupName = name
        }
        let preparer = PhotoPreparer()
        var replacements: [(piece: WardrobePiece, photoID: UUID)] = []
        for piece in candidates {
            guard let index = (1...12).first(where: { id($0) == piece.id }),
                  let data = WelcomeGarments.images[specs[index - 1].0]?.pngData() else { throw Failure.missingArtwork }
            let prepared = try await preparer.prepare(data: data)
            let png: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
            guard prepared.originalData.starts(with: png), prepared.thumbnailData.starts(with: png) else { throw Failure.missingArtwork }
            guard try store.mutationStamp() == stamp else { throw Failure.changedStore }
            replacements.append((piece, try store.acceptPhoto(prepared)))
            stamp = try store.mutationStamp()
        }
        guard try store.mutationStamp() == stamp else { throw Failure.changedStore }
        if !replacements.isEmpty {
            do { try store.replacePreviewSamplePhotos(replacements) }
            catch {
                // A post-commit error must reconcile the exact staged references,
                // never create another update or falsely report unchanged photos.
                let acknowledged = try replacements.allSatisfy { replacement in
                    guard let current = try store.piece(id: replacement.piece.id) else { return false }
                    return current.photoID == replacement.photoID && current.revision == replacement.piece.revision + 1
                }
                guard acknowledged else { throw error }
            }
        }
        let refreshed = try store.pieces() + store.pieces(archived: true)
        let transparent = try refreshed.filter { sampleIDs["pieces", default: []].contains($0.id) }.filter {
            try store.originalPhoto(id: $0.photoID).starts(with: [137, 80, 78, 71, 13, 10, 26, 10])
        }.map(\.id)
        let receipt = MediaReceipt(updated: replacements.map { $0.piece.id },
            skipped: allSamples.map(\.id).filter { id in !replacements.contains { $0.piece.id == id } }, transparent: transparent, backup: backupName)
        try write(try JSONEncoder().encode(receipt), to: outputDirectory.appendingPathComponent("AQD-transparent-samples.json"))
        return receipt
    }
    /// Explicit upgrade of untouched old sample descriptions; never normal startup.
    static func refreshContexts(store: PieceStore, outputDirectory: URL) async throws -> ContextReceipt {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let plans = try store.planEntries(), fits = try store.fitMemories(), outfits = try store.outfits()
        let planDraft = try store.planDraft(), authoring = try store.planAuthoringDraft(), fitDraft = try store.fitDraft()
        var planChanges: [(before: OutfitPlanEntry, after: OutfitPlanEntry)] = []
        var fitChanges: [(before: FitMemory, after: FitMemory)] = []
        for (index, context) in planContexts.enumerated() {
            guard let entry = plans.first(where: { $0.id == id(301 + index) }), entry.revision == 1,
                  entry.occasion == legacyPlanOccasion(index), entry.state == .planned, !entry.requiresReview,
                  outfits.contains(where: { $0.id == entry.outfitID && $0.revision == entry.outfitRevision }),
                  planDraft?.entryID != entry.id, planDraft?.planID != entry.planID,
                  authoring?.plan.id != entry.planID,
                  !(authoring?.baseEntries?.contains(where: { $0.id == entry.id }) ?? false),
                  !(authoring?.slots.contains(where: { $0.id == entry.id }) ?? false) else { continue }
            var result = entry; result.occasion = context; result.revision += 1
            planChanges.append((entry, result))
        }
        for (index, note) in fitNotes.enumerated() {
            guard let fit = fits.first(where: { $0.id == id(401 + index) }), fit.revision == 1, fit.note == legacyFitNote,
                  fitDraft?.value.id != fit.id, fitDraft?.base?.id != fit.id else { continue }
            var result = fit; result.note = note; result.revision += 1
            fitChanges.append((fit, result))
        }
        var backupName: String?
        if !planChanges.isEmpty || !fitChanges.isEmpty {
            let stamp = try store.mutationStamp()
            let backup = try await LocalArchiveService.create(store: store)
            guard try store.mutationStamp() == stamp else { throw Failure.changedStore }
            let name = "AQD-before-sample-contexts-\(UUID().uuidString).aqdarchive"
            try write(backup.data, to: outputDirectory.appendingPathComponent(name)); backupName = name
            do { try store.replacePreviewSampleContexts(plans: planChanges, fits: fitChanges) }
            catch {
                let currentPlans = try store.planEntries(), currentFits = try store.fitMemories()
                guard planChanges.allSatisfy({ change in currentPlans.contains(change.after) }),
                      fitChanges.allSatisfy({ change in currentFits.contains(change.after) }) else { throw error }
            }
        }
        let receipt = ContextReceipt(updatedPlans: planChanges.map { $0.before.id }, updatedFits: fitChanges.map { $0.before.id },
            skippedPlans: plans.map(\.id).filter { sampleIDs["plans", default: []].contains($0) && !planChanges.map({ $0.before.id }).contains($0) },
            skippedFits: fits.map(\.id).filter { sampleIDs["fits", default: []].contains($0) && !fitChanges.map({ $0.before.id }).contains($0) }, backup: backupName)
        try write(try JSONEncoder().encode(receipt), to: outputDirectory.appendingPathComponent("AQD-sample-contexts.json"))
        return receipt
    }
    private static func write(_ data: Data, to url: URL) throws {
        try LocalArchiveIO.write(data, to: url)
    }
}
#endif
