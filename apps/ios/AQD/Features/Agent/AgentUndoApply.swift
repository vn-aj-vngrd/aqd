import AQDCore
import Foundation

/// Putting an approved change back. Every undo is checked against the revision the change produced, so a record the owner
/// edited since is never overwritten, and it uses the same store operations as the manual screens.
@MainActor extension AgentModel {
    /// The current revision of every record this undo touches, reading only the kinds it needs.
    private func currentRevisions(for undo: AgentUndo) throws -> [UUID: Int] {
        var map: [UUID: Int] = [:]
        let records = undo.records
        if records.contains(.piece) { for piece in try store.pieces() + store.pieces(archived: true) { map[piece.id] = piece.revision } }
        if records.contains(.outfit) { for outfit in try store.outfits() { map[outfit.id] = outfit.revision } }
        if records.contains(.theme) { for theme in try store.themes() { map[theme.id] = theme.revision } }
        if records.contains(.plan) { for plan in try store.planDefinitions() { map[plan.id] = plan.revision } }
        if records.contains(.planEntry) { for entry in try store.planEntries() { map[entry.id] = entry.revision } }
        if records.contains(.wear) { for record in try store.wearRecords() { map[record.id] = record.revision } }
        if records.contains(.identity), let identity = try store.localIdentity() { map[identity.ownerID] = identity.revision }
        return map
    }

    /// An outfit made by the Agent can only be removed while nothing else uses it, except the records removed together with it.
    private func outfitsAreFree(in undo: AgentUndo) throws -> Bool {
        var outfits: [UUID] = [], themes = Set<UUID>(), entries = Set<UUID>()
        func collect(_ undo: AgentUndo) {
            switch undo {
            case .outfitCreate(let id, _): outfits.append(id)
            case .themeCreate(let id, _): themes.insert(id)
            case .planCreate(_, _, let list): entries.formUnion(list.map(\.id))
            case .trip(let parts): parts.forEach(collect)
            default: break
            }
        }
        collect(undo)
        for id in outfits {
            guard case .delete(let dependencies) = try store.outfitDeletionReview(id: id).action else { return false }
            guard Set(dependencies.themeRevisions.keys).isSubset(of: themes), Set(dependencies.planRevisions.keys).isSubset(of: entries) else { return false }
        }
        return true
    }

    /// Whether the receipt of this proposal can still be undone: it has an undo, it was not used, and nothing it touched changed since.
    func canUndo(_ proposal: AgentActionProposal) -> Bool {
        guard proposal.status == .succeeded, let receipt = proposal.receipt, receipt.canOfferUndo, let undo = receipt.undo,
              let revisions = try? currentRevisions(for: undo), undo.isEligible(currentRevisions: revisions) else { return false }
        return (try? outfitsAreFree(in: undo)) ?? false
    }

    func undoProposal(_ id: UUID) {
        guard !active, !hasPendingOperation, let i = conversation.proposals?.firstIndex(where: { $0.id == id }),
              let proposal = conversation.proposals?[i], canUndo(proposal), let undo = proposal.receipt?.undo else {
            error = "This change can’t be undone any more because it was edited or used since. Change it by hand."
            return
        }
        do {
            try perform(undo)
            conversation.proposals?[i].receipt?.undoneAt = Date()
            _ = persist()
        } catch {
            self.error = "The undo wasn’t confirmed. Check your closet before trying again."
        }
    }

    private func perform(_ undo: AgentUndo) throws {
        switch undo {
        case .availability(let pieceID, let previous, let revision):
            _ = try store.setAvailability(id: pieceID, value: previous, expectedRevision: revision, operationID: UUID())
        case .archive(let items):
            for item in items { try store.setArchived(id: item.pieceID, archived: item.wasArchived, expectedRevision: item.appliedRevision, operationID: UUID()) }
        case .piece(var previous, let revision):
            previous.baseRevision = revision
            _ = try store.savePiece(previous, operationID: UUID())
        case .outfitEdit(let previous, let revision):
            guard let current = try store.outfit(id: previous.id), current.revision == revision else { throw PieceStore.StoreError.staleRevision }
            var draft = OutfitDraft(editing: current)
            draft.name = previous.name; draft.occasion = previous.occasion; draft.mood = previous.mood
            let pieces = try store.pieces()
            try draft.applyManualSelection(previous.pieceIDs, pieces: pieces)
            try draft.validatedForSave(pieces: pieces)
            try store.saveOutfitDraft(draft)
            _ = try store.saveOutfit(draft)
            try store.acknowledgeOutfitReceipt(draft)
        case .outfitCreate(let id, let revision):
            let review = try store.outfitDeletionReview(id: id)
            guard review.outfit.revision == revision else { throw PieceStore.StoreError.staleRevision }
            _ = try store.applyOutfitMutation(review)
        case .themeEdit(let previous, let revision):
            guard let current = try store.themes().first(where: { $0.id == previous.id }), current.revision == revision else { throw PieceStore.StoreError.staleRevision }
            var draft = ThemeDraft(editing: current)
            draft.name = previous.name; draft.description = previous.description; draft.outfitIDs = previous.outfitIDs
            try draft.validatedForSave(themes: try store.themes(), outfits: try store.outfits())
            try store.saveThemeDraft(draft)
            _ = try store.saveTheme(draft)
            try store.finishThemeDraft(draft)
        case .themeCreate(let id, let revision):
            guard let current = try store.themes().first(where: { $0.id == id }), current.revision == revision else { throw PieceStore.StoreError.staleRevision }
            try store.deleteTheme(ThemeDeletionRequest(theme: current))
        case .planCreate(let id, let revision, _):
            guard let plan = try store.planDefinitions().first(where: { $0.id == id }), plan.revision == revision else { throw PieceStore.StoreError.staleRevision }
            try store.applyHistoryMutation(HistoryMutation(action: .deletePlan(plan, try store.planEntries().filter { $0.planID == id })))
        case .planEdit(let id, let previous, let revision, _):
            guard let plan = try store.planDefinitions().first(where: { $0.id == id }), plan.revision == revision else { throw PieceStore.StoreError.staleRevision }
            let outfits = try store.outfits(), entries = try store.planEntries().filter { $0.planID == id }
            var draft = try PlanAuthoringDraft(editing: plan, entries: entries, outfits: outfits, scope: .whole, anchorEntryID: nil)
            draft.plan.name = previous.name
            for index in draft.slots.indices {
                guard let day = previous.days.first(where: { $0.dayKey == draft.slots[index].day.key }) else { continue }
                if let outfitID = day.outfitID {
                    guard let outfit = outfits.first(where: { $0.id == outfitID }) else { throw PieceStore.StoreError.staleRevision }
                    draft.slots[index].outfit = outfit; draft.slots[index].unassignedByChoice = false
                } else { draft.slots[index].outfit = nil; draft.slots[index].unassignedByChoice = true }
            }
            draft.reviewing = true
            try draft.validatedForSave(outfits: outfits, existing: entries)
            try store.savePlanAuthoringDraft(draft)
            _ = try store.savePlanAuthoring(draft)
            try store.finishPlanAuthoring(draft)
        case .wear(let id, let revision):
            guard let record = try store.wearRecords().first(where: { $0.id == id }), record.revision == revision else { throw PieceStore.StoreError.staleRevision }
            try store.applyHistoryMutation(HistoryMutation(action: .undoWear(record)))
        case .profile(let previous, let revision):
            guard let current = try store.localIdentity(), current.revision == revision else { throw PieceStore.StoreError.staleRevision }
            var draft = LocalIdentityDraft(ownerID: current.ownerID, base: current)
            draft.name = previous.name ?? ""; draft.caption = previous.caption
            try store.saveIdentityDraft(draft)
            _ = try store.saveIdentity(draft)
            try store.finishIdentityDraft(draft)
        case .trip(let parts):
            // Newest kind first, so nothing is removed while something that uses it is still there.
            func rank(_ part: AgentUndo) -> Int { if case .planCreate = part { 0 } else if case .themeCreate = part { 1 } else { 2 } }
            for part in parts.sorted(by: { rank($0) < rank($1) }) { try perform(part) }
        }
    }
}
