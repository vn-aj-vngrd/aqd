import Foundation

public enum TodayAction: String, CaseIterable, Codable, Sendable {
    case addPiece, buildOutfit, planner, recordWear, addFit, openCloset
    public var title: String {
        switch self {
        case .addPiece: "Add piece"
        case .buildOutfit: "Build outfit"
        case .planner: "Planner"
        case .recordWear: "Record wear"
        case .addFit: "Add fit"
        case .openCloset: "Open Closet"
        }
    }
    /// Four commands lay out as a clean two by two. Cards that saved their own actions keep them.
    public static let defaults: [Self] = [.addPiece, .buildOutfit, .planner, .recordWear]
}
public enum TodayLayoutError: Error, Equatable {
    case invalidContent, invalidPeriod, selectionRequired, minimumOne, invalidOwner, staleRevision
}
public struct TodayPersonalCard: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let ownerID: UUID
    public let kind: TodayWidgetKind
    public var title: String
    public var text: String
    public var photoID: UUID?
    public var photoRecipe: PhotoEditRecipe
    public var revision: Int
    public init(id: UUID = UUID(), ownerID: UUID, kind: TodayWidgetKind, title: String = "", text: String = "", photoID: UUID? = nil, photoRecipe: PhotoEditRecipe = .fitOriginal, revision: Int = 1) {
        self.id = id; self.ownerID = ownerID; self.kind = kind; self.title = title; self.text = text
        self.photoID = photoID; self.photoRecipe = photoRecipe; self.revision = revision
    }
    public func validated(requireContent: Bool = true) throws {
        guard kind == .personalNote || kind == .personalPhoto, revision > 0, revision < Int.max else { throw TodayLayoutError.invalidContent }
        try photoRecipe.validated()
        if requireContent {
            guard kind == .personalNote ? !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : photoID != nil else { throw TodayLayoutError.invalidContent }
        }
        guard kind != .personalNote || photoID == nil else { throw TodayLayoutError.invalidContent }
    }
    public func independentCopy() -> Self {
        Self(ownerID: ownerID, kind: kind, title: title, text: text, photoID: photoID, photoRecipe: photoRecipe)
    }
}
public struct TodayWidgetOptions: Codable, Equatable, Sendable {
    public var pinnedID: UUID?
    public var period: LocalPlanDay?
    public var upcomingDays: Int?
    public var actions: [TodayAction]?
    public var personal: TodayPersonalCard?
    public var insights: WearInsightsOptions?
    public init(pinnedID: UUID? = nil, period: LocalPlanDay? = nil, upcomingDays: Int? = nil, actions: [TodayAction]? = nil, personal: TodayPersonalCard? = nil, insights: WearInsightsOptions? = nil) {
        self.pinnedID = pinnedID; self.period = period; self.upcomingDays = upcomingDays; self.actions = actions; self.personal = personal; self.insights = insights
    }
}
public extension TodayWidgetInstance {
    func validatedContent(ownerID: UUID, today: LocalPlanDay = LocalPlanDay(), requireContent: Bool = true) throws {
        let options = options ?? TodayWidgetOptions()
        if requireContent, let period = options.period {
            _ = try period.date()
            if kind == .closetInUse {
                guard String(period.key.prefix(7)) < String(today.key.prefix(7)) else { throw TodayLayoutError.invalidPeriod }
            } else if kind == .weekInWear {
                guard period.key <= today.key else { throw TodayLayoutError.invalidPeriod }
            } else { throw TodayLayoutError.invalidPeriod }
        }
        if let insights = options.insights {
            guard kind == .wearInsights else { throw TodayLayoutError.invalidContent }
            try insights.validated()
        }
        if let days = options.upcomingDays { guard kind == .upcomingPlans, days == 7 || days == 14 else { throw TodayLayoutError.invalidContent } }
        if requireContent, let actions = options.actions {
            guard kind == .quickActions, !actions.isEmpty, Set(actions).count == actions.count else { throw TodayLayoutError.invalidContent }
        }
        if requireContent && kind == .theme && options.pinnedID == nil { throw TodayLayoutError.selectionRequired }
        if kind == .personalNote || kind == .personalPhoto {
            if let personal = options.personal {
                guard personal.ownerID == ownerID, personal.kind == kind else { throw TodayLayoutError.invalidOwner }
                try personal.validated(requireContent: requireContent)
            } else if requireContent { throw TodayLayoutError.invalidContent }
        } else if options.personal != nil { throw TodayLayoutError.invalidContent }
    }
    func independentCopy() -> Self {
        var options = options
        let copied = options?.personal?.independentCopy()
        options?.personal = copied
        return Self(kind: kind, options: options, isVisible: isVisible)
    }
}
public struct TodayLayoutDraft: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let operationID: UUID
    public let base: TodayConfiguration
    public var value: TodayConfiguration
    public var defaultsUndo: TodayConfiguration?
    public var nested: TodayWidgetInstance?
    public var nestedBase: TodayWidgetInstance?
    public init(base: TodayConfiguration) { id = UUID(); operationID = UUID(); self.base = base; value = base }
    public var hasChanges: Bool { value != base || nested != nil }
    public mutating func remove(_ id: UUID) throws {
        guard value.instances.count > 1 else { throw TodayLayoutError.minimumOne }
        value.instances.removeAll { $0.id == id }
    }
    public mutating func restoreDefaults() {
        defaultsUndo = value
        value.instances = TodayConfiguration(ownerID: base.ownerID).instances
    }
    public mutating func undoDefaults() { if let defaultsUndo { value = defaultsUndo; self.defaultsUndo = nil } }
    public func validated(requireContent: Bool = false) throws {
        try base.validated(); try value.validated()
        guard base.ownerID == value.ownerID, base.revision == value.revision, base.revision < Int.max else { throw TodayLayoutError.invalidOwner }
        for instance in value.instances { try instance.validatedContent(ownerID: base.ownerID, requireContent: requireContent && instance.options != nil) }
        let personalIDs = value.instances.compactMap { $0.options?.personal?.id }
        guard Set(personalIDs).count == personalIDs.count else { throw TodayLayoutError.invalidContent }
        if let nested { try nested.validatedContent(ownerID: base.ownerID, requireContent: false) }
        if requireContent, nested != nil { throw TodayLayoutError.invalidContent }
    }
    public func result() throws -> TodayConfiguration {
        try validated(requireContent: true)
        var result = value; result.revision = base.revision + 1; return result
    }
}
public struct TodayLayoutUndo: Codable, Equatable, Sendable {
    public let previous: TodayConfiguration
    public let current: TodayConfiguration
    public init(previous: TodayConfiguration, current: TodayConfiguration) { self.previous = previous; self.current = current }
}
