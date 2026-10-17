import Foundation

/// What one calendar day holds, so the calendar can show state instead of a bare count.
public struct PlannerDayMarker: Equatable, Sendable {
    public var planned = 0
    public var worn = 0
    public var skipped = 0
    public var gaps = 0
    public var needsReview = 0
    public var total: Int { planned + worn + skipped + gaps }
    public var isEmpty: Bool { total == 0 }
    /// Open items still need a decision; a day with only worn or skipped entries is settled.
    public var hasOpenItems: Bool { planned + gaps > 0 }
}

public enum PlannerPresentation {
    public static func markers(for entries: [OutfitPlanEntry], outfitRevisions: [UUID: Int] = [:]) -> [String: PlannerDayMarker] {
        var result: [String: PlannerDayMarker] = [:]
        for entry in entries {
            var marker = result[entry.day.key, default: PlannerDayMarker()]
            switch entry.state {
            case .planned: marker.planned += 1
            case .worn: marker.worn += 1
            case .skipped: marker.skipped += 1
            case .unassigned: marker.gaps += 1
            }
            if entry.state == .planned || entry.state == .unassigned, isStale(entry, outfitRevisions: outfitRevisions) {
                marker.needsReview += 1
            }
            result[entry.day.key] = marker
        }
        return result
    }

    /// An entry needs review when flagged, or when its outfit changed after planning.
    public static func isStale(_ entry: OutfitPlanEntry, outfitRevisions: [UUID: Int]) -> Bool {
        if entry.requiresReview { return true }
        guard let id = entry.outfitID, let current = outfitRevisions[id] else { return false }
        return current != entry.outfitRevision
    }

    public enum Kind: String, Sendable { case plan, routine, trip }

    public struct PlanSummary: Identifiable, Equatable, Sendable {
        public let id: UUID
        public let kind: Kind
        public let entryCount: Int
        public let gaps: Int
        public let needsReview: Int
        public let worn: Int
        public let isPast: Bool
    }

    public static func kind(of plan: PlanDefinition) -> Kind {
        plan.trip != nil ? .trip : plan.routine != nil ? .routine : .plan
    }

    /// Summarises each plan against `today` (a plan is past once its last day is before today).
    public static func summaries(plans: [PlanDefinition], entries: [OutfitPlanEntry], today: LocalPlanDay,
                                 outfitRevisions: [UUID: Int] = [:]) -> [PlanSummary] {
        let byPlan = Dictionary(grouping: entries, by: \.planID)
        return plans.map { plan in
            let own = byPlan[plan.id] ?? []
            let open = own.filter { $0.state == .planned || $0.state == .unassigned }
            return PlanSummary(
                id: plan.id, kind: kind(of: plan), entryCount: own.count,
                gaps: own.filter { $0.state == .unassigned }.count,
                needsReview: open.filter { isStale($0, outfitRevisions: outfitRevisions) }.count,
                worn: own.filter { $0.state == .worn }.count,
                isPast: plan.end.key < today.key)
        }
    }

    /// Plans that touch the visible days, soonest first, then the rest as upcoming or past.
    public struct PlanGroups: Equatable, Sendable {
        public var inRange: [PlanDefinition] = []
        public var upcoming: [PlanDefinition] = []
        public var past: [PlanDefinition] = []
    }

    public static func group(_ plans: [PlanDefinition], visible: [LocalPlanDay], today: LocalPlanDay) -> PlanGroups {
        guard let first = visible.map(\.key).min(), let last = visible.map(\.key).max() else {
            return PlanGroups(inRange: [], upcoming: plans.filter { $0.end.key >= today.key }.sorted { $0.start.key < $1.start.key },
                              past: plans.filter { $0.end.key < today.key }.sorted { $0.end.key > $1.end.key })
        }
        var groups = PlanGroups()
        for plan in plans {
            if plan.start.key <= last && plan.end.key >= first { groups.inRange.append(plan) }
            else if plan.end.key < today.key { groups.past.append(plan) }
            else { groups.upcoming.append(plan) }
        }
        groups.inRange.sort { $0.start.key < $1.start.key }
        groups.upcoming.sort { $0.start.key < $1.start.key }
        groups.past.sort { $0.end.key > $1.end.key }
        return groups
    }
}
