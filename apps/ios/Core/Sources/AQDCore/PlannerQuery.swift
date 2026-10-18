import Foundation

/// Local filter and sort options for the Planner root, shared by the day list and the plans list.
public struct PlannerQuery: Hashable, Sendable {
    public enum Status: String, CaseIterable, Sendable {
        case all = "All entries", open = "Still open", toChoose = "Open without an outfit", needsReview = "Needs review", worn = "Worn", skipped = "Skipped"
    }
    public enum Kind: String, CaseIterable, Sendable {
        case all = "All plans", plans = "Plans", routines = "Routines", trips = "Trips"
    }
    public enum Sort: String, CaseIterable, Sendable {
        case soonest = "Soonest first", latest = "Latest first", name = "Name A–Z"
    }
    public var status: Status
    public var kind: Kind
    public var sort: Sort
    public var text: String
    public init(status: Status = .all, kind: Kind = .all, sort: Sort = .soonest, text: String = "") {
        self.status = status; self.kind = kind; self.sort = sort; self.text = text
    }
    public var searchTerm: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    public var isSearching: Bool { !searchTerm.isEmpty }

    private func matches(_ values: [String?]) -> Bool {
        guard isSearching else { return true }
        return values.contains { $0?.range(of: searchTerm, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }
    public var isFiltering: Bool { status != .all || kind != .all }
    public var isDefault: Bool { status == .all && kind == .all && sort == .soonest }

    public func apply(to entries: [OutfitPlanEntry], outfitRevisions: [UUID: Int] = [:], outfitNames: [UUID: String] = [:]) -> [OutfitPlanEntry] {
        entries.filter { matches([$0.occasion, $0.outfitID.flatMap { outfitNames[$0] }]) }.filter {
            switch status {
            case .all: true
            case .open: $0.state == .planned || $0.state == .unassigned
            case .toChoose: $0.state == .unassigned
            case .needsReview: ($0.state == .planned || $0.state == .unassigned) && PlannerPresentation.isStale($0, outfitRevisions: outfitRevisions)
            case .worn: $0.state == .worn
            case .skipped: $0.state == .skipped
            }
        }
    }

    public func apply(to plans: [PlanDefinition]) -> [PlanDefinition] {
        plans.filter { matches([$0.name, $0.trip?.destination, $0.routine?.occasion] + ($0.trip?.activities ?? [])) }.filter {
            switch kind {
            case .all: true
            case .plans: PlannerPresentation.kind(of: $0) == .plan
            case .routines: PlannerPresentation.kind(of: $0) == .routine
            case .trips: PlannerPresentation.kind(of: $0) == .trip
            }
        }.sorted {
            switch sort {
            case .soonest where $0.start.key != $1.start.key: return $0.start.key < $1.start.key
            case .latest where $0.start.key != $1.start.key: return $0.start.key > $1.start.key
            case .name:
                let order = $0.name.localizedStandardCompare($1.name)
                if order != .orderedSame { return order == .orderedAscending }
            default: break
            }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}
