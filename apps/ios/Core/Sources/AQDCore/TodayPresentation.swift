import Foundation

/// What Today's look should offer, decided once so the card can show a single primary action.
public enum TodayPresentation {
    public enum LookAction: Equatable, Sendable {
        case recordWear, reviewPlan, chooseOutfit, buildOutfit, addPiece
    }

    public struct Look: Equatable, Sendable {
        public let primary: LookAction?
        public let status: String
    }

    /// `outfitRevision` is the saved outfit's current revision, or nil when the outfit no longer exists.
    public static func look(entry: OutfitPlanEntry?, outfitRevision: Int?, hasPieces: Bool) -> Look {
        guard let entry else {
            return hasPieces ? Look(primary: .buildOutfit, status: "Nothing planned for today")
                             : Look(primary: .addPiece, status: "Start with a photo of a piece you love")
        }
        switch entry.state {
        case .worn: return Look(primary: nil, status: "Recorded wear")
        case .skipped: return Look(primary: nil, status: "Skipped")
        case .planned, .unassigned:
            guard entry.outfitID != nil, let current = outfitRevision else {
                return Look(primary: .chooseOutfit, status: "No outfit chosen yet")
            }
            if entry.requiresReview || current != entry.outfitRevision {
                return Look(primary: .reviewPlan, status: "This outfit changed. Review the plan before recording wear")
            }
            return Look(primary: .recordWear, status: "Planned, not recorded as worn")
        }
    }

    public enum RelativeDay: Equatable, Sendable { case yesterday, today, tomorrow, other }

    /// Whole calendar days from `today`, so "Tomorrow" never depends on the hour.
    public static func relativeDay(_ day: LocalPlanDay, to today: LocalPlanDay) -> RelativeDay {
        guard let target = try? day.date(), let origin = try? today.date(),
              let zone = TimeZone(identifier: today.timeZoneID) else { return .other }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
        let start = calendar.startOfDay(for: origin), end = calendar.startOfDay(for: target)
        switch calendar.dateComponents([.day], from: start, to: end).day {
        case -1: return .yesterday
        case 0: return .today
        case 1: return .tomorrow
        default: return .other
        }
    }

    /// Entries for the Upcoming card, leaving out today's when Today's look already shows them.
    public static func upcoming(_ entries: [OutfitPlanEntry], today: LocalPlanDay, hidingToday: Bool) -> [OutfitPlanEntry] {
        hidingToday ? entries.filter { $0.day.key != today.key } : entries
    }

    /// A card's header: an optional small label above one title.
    public struct Header: Equatable, Sendable {
        public let eyebrow: String?
        public let title: String
    }

    /// The title is the content's own name when it has one, otherwise the kind label. The eyebrow adds
    /// context (a range, a month, "Theme") and is dropped when it would only repeat the title or says nothing.
    /// Personal notes and photos never get an eyebrow: their own title stands alone.
    public static func header(kind: String, contentTitle: String?, context: String?, personal: Bool = false) -> Header {
        func clean(_ value: String?) -> String? {
            let text = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return text.isEmpty ? nil : text
        }
        let own = clean(contentTitle)
        let title = own ?? kind
        if personal { return Header(eyebrow: nil, title: title) }
        let candidate = clean(context) ?? (own == nil ? nil : kind)
        guard let candidate, candidate.caseInsensitiveCompare(title) != .orderedSame else { return Header(eyebrow: nil, title: title) }
        return Header(eyebrow: candidate, title: title)
    }

    /// Kept for callers that only need the single title.
    public static func title(kind: String, contentTitle: String?) -> String {
        header(kind: kind, contentTitle: contentTitle, context: nil).title
    }
}
