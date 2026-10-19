import Foundation

/// Local filter, sort and search for the fit journal grid.
public struct FitJournalQuery: Hashable, Sendable {
    public enum Content: String, CaseIterable, Sendable {
        case all = "All fits", photos = "With a photo", outfitOnly = "Outfit only"
    }
    public enum Sort: String, CaseIterable, Sendable { case newest = "Newest first", oldest = "Oldest first" }
    public var content: Content
    public var sort: Sort
    public var text: String
    public init(content: Content = .all, sort: Sort = .newest, text: String = "") {
        self.content = content; self.sort = sort; self.text = text
    }
    public var searchTerm: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    public var isSearching: Bool { !searchTerm.isEmpty }
    public var isFiltering: Bool { content != .all }
    public var isDefault: Bool { content == .all && sort == .newest }

    public func apply(to memories: [FitMemory]) -> [FitMemory] {
        memories.filter { memory in
            switch content {
            case .all: break
            case .photos: if memory.photoID == nil { return false }
            case .outfitOnly: if memory.photoID != nil { return false }
            }
            guard isSearching else { return true }
            return [memory.note, memory.outfit?.name].contains {
                $0?.range(of: searchTerm, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
        }.sorted {
            if $0.day.key != $1.day.key { return sort == .newest ? $0.day.key > $1.day.key : $0.day.key < $1.day.key }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}

public struct FitMonthSection: Identifiable, Equatable, Sendable {
    public let year: Int
    public let month: Int
    public let memories: [FitMemory]
    public var id: String { String(format: "%04d-%02d", year, month) }
}

public enum FitJournalPresentation {
    /// Fits posted in the same calendar month as `today`.
    public static func monthCount(_ memories: [FitMemory], today: LocalPlanDay) -> Int {
        memories.filter { $0.day.year == today.year && $0.day.month == today.month }.count
    }

    /// Consecutive calendar days with at least one fit, ending today, or yesterday when nothing is posted yet today.
    public static func streak(_ memories: [FitMemory], today: LocalPlanDay) -> Int {
        let posted = Set(memories.map(\.day.key))
        guard let zone = TimeZone(identifier: today.timeZoneID), var cursor = try? today.date() else { return 0 }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
        if !posted.contains(today.key) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var count = 0
        while posted.contains(LocalPlanDay(date: cursor, timeZone: zone).key) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    /// Groups an already ordered list into consecutive calendar months, keeping its order.
    public static func sections(_ memories: [FitMemory]) -> [FitMonthSection] {
        var result: [FitMonthSection] = []
        for memory in memories {
            let year = memory.day.year, month = memory.day.month
            if let last = result.last, last.year == year, last.month == month {
                result[result.count - 1] = FitMonthSection(year: year, month: month, memories: last.memories + [memory])
            } else {
                result.append(FitMonthSection(year: year, month: month, memories: [memory]))
            }
        }
        return result
    }

    /// The outfit already planned for a day, so Add fit can offer it in one tap. Skipped entries and gaps never count;
    /// a still-planned entry wins over one already worn.
    public static func plannedOutfitID(on day: LocalPlanDay, entries: [OutfitPlanEntry]) -> UUID? {
        let onDay = entries.filter { $0.day.key == day.key && $0.outfitID != nil }
        return (onDay.first { $0.state == .planned } ?? onDay.first { $0.state == .worn })?.outfitID
    }

    public enum SaveGuidance: Equatable, Sendable { case ready, needsContent, noteTooLong }

    /// One plain line for what a draft still needs before it can be saved.
    public static func guidance(for memory: FitMemory) -> SaveGuidance {
        if memory.note.count > 500 { return .noteTooLong }
        if memory.photoID == nil && memory.outfit == nil { return .needsContent }
        return .ready
    }
}
