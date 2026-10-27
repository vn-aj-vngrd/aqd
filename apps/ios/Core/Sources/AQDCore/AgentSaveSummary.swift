import Foundation

public extension AgentReviewedAction {
    /// Exactly what saving this review will do, in one sentence. Shown on the card before the owner opens it.
    var savesSummary: String {
        func quoted(_ name: String) -> String { "“\(name.trimmingCharacters(in: .whitespacesAndNewlines))”" }
        func count(_ n: Int, _ noun: String) -> String { "\(n) \(noun)" + (n == 1 ? "" : "s") }
        switch self {
        case .outfit(let draft):
            return draft.baseRevision == 0 ? "Saves a new outfit \(quoted(draft.name)) with \(count(draft.pieceIDs.count, "piece"))." : "Changes the saved outfit \(quoted(draft.name))."
        case .theme(let draft):
            return draft.baseRevision == 0 ? "Saves a new theme \(quoted(draft.name)) with \(count(draft.outfitIDs.count, "outfit"))." : "Changes the saved theme \(quoted(draft.name))."
        case .plan(let draft):
            if draft.basePlan != nil { return "Changes the plan \(quoted(draft.plan.name))." }
            return "Saves a plan \(quoted(draft.plan.name)) over \(count(draft.slots.count, "day")) with \(count(draft.slots.filter { $0.outfit != nil }.count, "outfit")) placed."
        case .wear(let draft):
            return "Records that you wore \(count(draft.pieceIDs.count, "piece")) on \(draft.day.display(.standard))."
        case .availability(let change):
            return "Marks \(quoted(change.pieceName)) as \(change.value.rawValue)."
        case .profile(let draft):
            var fields: [String] = []
            if draft.name != (draft.base?.name ?? "") { fields.append("name") }
            if (draft.caption ?? "") != (draft.base?.caption ?? "") { fields.append("bio") }
            return "Updates your profile " + (fields.isEmpty ? "details" : fields.joined(separator: " and ")) + "."
        case .piece(let change):
            return change.isNewPiece ? "Opens the Closet editor with a new piece \(quoted(change.draft.name)); it is saved when you add its photo and save." : "Changes the piece \(quoted(change.draft.name))."
        case .trip(let draft):
            var parts = [count(draft.days.count, "new outfit")]
            if draft.includeTheme { parts.append("a theme \(quoted(draft.theme.name))") }
            if draft.canPlan && draft.includePlan { parts.append("a Planner trip") }
            return "Saves " + (parts.count > 1 ? parts.dropLast().joined(separator: ", ") + " and " + (parts.last ?? "") : parts.first ?? "") + "."
        case .tidy(let change):
            let n = change.selectedItems.count
            switch change.op {
            case .archive: return "Archives \(count(n, "piece")). They leave your closet but can be restored, and you can undo this."
            case .unarchive: return "Restores \(count(n, "piece")) to your closet."
            case .delete: return "Permanently deletes \(count(n, "piece")). This can’t be undone."
            }
        }
    }
}
