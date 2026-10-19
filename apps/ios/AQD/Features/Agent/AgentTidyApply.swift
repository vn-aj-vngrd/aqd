import AQDCore
import Foundation

/// Applying a reviewed tidy, and putting an approved change back. Both use the same store operations as the manual Closet screens.
@MainActor extension AgentModel {
    /// The piece as it is now, as the draft that would restore it. Read before the first apply, so undo has something to return to.
    func priorPieceDraft(_ id: UUID) throws -> PieceDraft? {
        guard let piece = try store.pieces().first(where: { $0.id == id }) else { return nil }
        return PieceDraft(itemID: piece.id, name: piece.name, category: piece.category, photoID: piece.photoID, baseRevision: piece.revision,
                          details: piece.details, availability: piece.availability, photoRecipe: piece.photoRecipe)
    }

    /// Applies the ticked pieces only. Every piece is checked against the revision that was reviewed before the first write, and an archive
    /// that fails part-way is rolled back, so a tidy is applied whole or not at all. A delete cannot be rolled back, which is why it is checked first.
    func applyTidy(_ change: AgentTidyChange) throws -> AgentActionReceipt {
        let chosen = change.selectedItems
        guard let first = chosen.first else { throw PlanValidationError.invalidRecord }
        let current = try store.pieces() + store.pieces(archived: true)
        for item in chosen {
            let piece = current.first { $0.id == item.id }
            switch change.op {
            case .archive, .unarchive:
                // A retry after an unconfirmed save finds the piece already one revision on, in the state this tidy wanted.
                let applied = piece.map { $0.revision == item.expectedRevision + 1 && $0.isArchived == (change.op == .archive) } ?? false
                guard piece?.revision == item.expectedRevision || applied else { throw PieceStore.StoreError.staleRevision }
            case .delete:
                if let piece, piece.revision != item.expectedRevision { throw PieceStore.StoreError.staleRevision }
                if piece != nil, item.impact != (try store.pieceDeletionImpact(id: item.id)) { throw PieceStore.StoreError.staleRevision }
            }
        }
        var undo: [AgentUndo.Item] = []
        switch change.op {
        case .archive, .unarchive:
            let target = change.op == .archive
            do {
                for item in chosen {
                    let updated = try store.setArchived(id: item.id, archived: target, expectedRevision: item.expectedRevision, operationID: item.operationID)
                    undo.append(.init(pieceID: item.id, wasArchived: !target, appliedRevision: updated.revision))
                }
            } catch {
                // Put back what this attempt changed. An unconfirmed save stays unconfirmed for the owner to check.
                if error as? PieceStore.StoreError != .operationConflict {
                    for done in undo.reversed() { _ = try? store.setArchived(id: done.pieceID, archived: done.wasArchived, expectedRevision: done.appliedRevision, operationID: UUID()) }
                }
                throw error
            }
        case .delete:
            for item in chosen { try store.deletePiece(id: item.id, expectedRevision: item.expectedRevision, operationID: item.operationID, impact: item.impact) }
        }
        return AgentActionReceipt(recordID: first.id, kind: "tidy", count: chosen.count, undo: undo.isEmpty ? nil : .archive(undo))
    }

    /// Ticks or unticks one piece of a tidy review. Only an open review can change.
    func setTidySelection(_ proposalID: UUID, item: UUID, selected: Bool) {
        guard !hasPendingOperation, let i = conversation.proposals?.firstIndex(where: { $0.id == proposalID }),
              conversation.proposals?[i].status == .proposed, case .tidy(var change) = conversation.proposals?[i].action else { return }
        change.setSelected(item, selected)
        conversation.proposals?[i].action = .tidy(change)
        _ = persist()
    }

    /// Cancels a review and, when the owner says why, asks the Agent to revise it from that reason.
    func rejectProposal(_ id: UUID, reason: String) {
        cancelProposal(id)
        let text = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, conversation.proposals?.first(where: { $0.id == id })?.status == .cancelled else { return }
        updateDraft("I didn’t approve that. " + String(text.prefix(200)))
        send()
    }

    /// Leaves one day of a plan review out, or puts it back. At least one assigned day always stays in.
    func setPlanDay(_ proposalID: UUID, day: String, included: Bool) {
        guard !hasPendingOperation, let i = conversation.proposals?.firstIndex(where: { $0.id == proposalID }),
              conversation.proposals?[i].status == .proposed, case .plan(let draft) = conversation.proposals?[i].action,
              draft.assignedDayKeys.contains(day) else { return }
        var left = Set(conversation.proposals?[i].leftOutDays ?? [])
        if included { left.remove(day) } else {
            guard left.count + 1 < draft.assignedDayKeys.count else { return }
            left.insert(day)
        }
        conversation.proposals?[i].leftOutDays = left.isEmpty ? nil : left.sorted()
        _ = persist()
    }
}
