import AQDCore
import Foundation

@MainActor extension AgentModel {
    /// The names and trusted totals a reply about the owner's closet may use, from enabled sources only.
    func nameCatalog() -> AgentNameCatalog {
        var catalog = AgentNameCatalog()
        guard let preferences = try? store.localSettings().agentPreferences ?? AgentPreferences() else { return catalog }
        let all = preferences.allows(.pieces) ? ((try? store.pieces()) ?? []) + ((try? store.pieces(archived: true)) ?? []) : []
        let active = all.filter { !$0.isArchived }
        catalog.pieces = active.map { AgentNameCatalog.Piece(name: $0.displayName, color: $0.details.color, category: $0.category.rawValue) }
        if preferences.allows(.pieces) {
            catalog.counts["pieces"] = [active.count, all.count - active.count, active.filter { $0.availability == .available }.count, all.count]
            for category in PieceCategory.allCases { catalog.counts[category.rawValue.lowercased()] = [active.filter { $0.category == category }.count] }
        }
        if preferences.allows(.outfits), let outfits = try? store.outfits() { catalog.outfits = outfits.map(\.displayName); catalog.counts["outfits"] = [outfits.count] }
        if preferences.allows(.themes), let themes = try? store.themes() { catalog.themes = themes.map(\.displayName); catalog.counts["themes"] = [themes.count] }
        if preferences.allows(.planner), let plans = try? store.planDefinitions() { catalog.plans = plans.map(\.name); catalog.counts["plans"] = [plans.count] }
        if preferences.allows(.wear), let records = try? store.wearRecords() {
            var wears: Set<Int> = [0, records.count]
            var perPiece: [UUID: Int] = [:]
            for record in records { for piece in record.pieces { perPiece[piece.id, default: 0] += 1 } }
            wears.formUnion(perPiece.values)
            let today = LocalPlanDay()
            for month in [today, LocalPlanDay(date: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date())] {
                if let period = try? WearPeriodSummary(month: month, pieces: all, records: records.filter { $0.day.key <= today.key }) {
                    wears.insert(period.occasions); wears.formUnion(period.counts.values)
                }
            }
            catalog.counts["wears"] = wears
        }
        catalog.proposed = (conversation.proposals ?? []).flatMap { proposal -> [String] in
            switch proposal.action {
            case .outfit(let draft): [draft.name]
            case .theme(let draft): [draft.name]
            case .plan(let draft): [draft.plan.name]
            case .trip(let draft): [draft.name, draft.theme.name] + draft.days.map { $0.outfit.name }
            case .piece(let change): [change.draft.name]
            case .wear, .availability, .profile: []
            }
        }
        return catalog
    }
}
