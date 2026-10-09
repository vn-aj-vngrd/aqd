import Foundation

public enum TodayWidgetKind: String, CaseIterable, Codable, Sendable {
    case todayLook, weekInWear, closetInUse, upcomingPlans, wearAgain, favoriteOutfits
    case theme, fitJournal, weatherContext, quickActions, personalNote, personalPhoto

    public var title: String {
        switch self {
        case .todayLook: "Today’s look"
        case .weekInWear: "Your week in wear"
        case .closetInUse: "Closet in use"
        case .upcomingPlans: "Upcoming plans"
        case .wearAgain: "Wear again"
        case .favoriteOutfits: "Favorite outfits"
        case .theme: "Theme"
        case .fitJournal: "Fit journal"
        case .weatherContext: "Weather"
        case .quickActions: "Quick actions"
        case .personalNote: "Note"
        case .personalPhoto: "Photo"
        }
    }
}

public struct TodayWidgetInstance: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var kind: TodayWidgetKind

    public init(id: UUID = UUID(), kind: TodayWidgetKind) {
        self.id = id
        self.kind = kind
    }
}

/// Structural presentation identity, not duplicated wardrobe/history data.
/// Kind-specific content/configuration validation belongs to the full Today slice.
public struct TodayConfiguration: Codable, Equatable, Sendable {
    public enum ValidationError: Error, Equatable { case unsupportedSchema, invalidRevision, emptyLayout, duplicateInstance }

    public let ownerID: UUID
    public var schemaVersion: Int
    public var revision: Int
    public var instances: [TodayWidgetInstance]

    public init(ownerID: UUID) {
        self.ownerID = ownerID
        schemaVersion = 1
        revision = 1
        instances = [.todayLook, .weekInWear, .closetInUse].map { TodayWidgetInstance(kind: $0) }
    }

    public func validated() throws {
        guard schemaVersion == 1 else { throw ValidationError.unsupportedSchema }
        guard revision > 0 else { throw ValidationError.invalidRevision }
        guard !instances.isEmpty else { throw ValidationError.emptyLayout }
        guard Set(instances.map(\.id)).count == instances.count else { throw ValidationError.duplicateInstance }
    }
}
