import Foundation

/// Private, explicitly supplied preferences. Empty answers never mean refusal.
public struct StylePreferences: Codable, Equatable, Sendable {
    public enum ValidationError: Error { case incomplete, invalidChoice, invalidBody, unsupportedSchema }
    public var goals: [String] = []
    public var occasions: [String] = []
    public var styles: [String] = []
    public var fits: [String] = []
    public var comfort = ""
    public var body = BodyPreferences()
    public var colors = ColorPreferences()
    public init() {}

    public static let titles = ["Your goals", "Your occasions", "Your style", "Fit & comfort", "Body details", "Colors & patterns", "Review preferences"]
    public static let options = [
        ["Wear more of my closet", "Plan outfits faster", "Try new combinations", "No preference"],
        ["Everyday", "Work", "Evenings", "Active", "Travel", "No preference"],
        ["Relaxed", "Minimal", "Classic", "Bold", "Sporty", "No preference"],
        ["Fitted", "Regular", "Relaxed", "Oversized", "No preference"]
    ]

    public func choices(at step: Int) -> [String] {
        switch step { case 0: goals; case 1: occasions; case 2: styles; case 3: fits; default: [] }
    }

    public mutating func choose(_ choice: String, at step: Int) {
        guard Self.options.indices.contains(step), Self.options[step].contains(choice) else { return }
        var selection = choices(at: step)
        if selection.contains(choice) { selection.removeAll { $0 == choice } }
        else if choice == "No preference" { selection = [choice] }
        else {
            selection.removeAll { $0 == "No preference" }
            if step != 0 || selection.count < 2 { selection.append(choice) }
        }
        // Canonical order makes operation payloads deterministic.
        selection = Self.options[step].filter { selection.contains($0) }
        switch step { case 0: goals = selection; case 1: occasions = selection; case 2: styles = selection; case 3: fits = selection; default: break }
    }

    public func isAnswered(_ step: Int) -> Bool {
        switch step {
        case 0..<4:
            let selection = choices(at: step)
            return !selection.isEmpty && Set(selection).count == selection.count
                && selection.allSatisfy(Self.options[step].contains)
                && !(selection.count > 1 && selection.contains("No preference"))
                && (step != 0 || selection.count <= 2)
        case 4: return body.isAnswered
        case 5: return colors.isAnswered
        default: return false
        }
    }

    public var answeredCount: Int { (0..<6).filter(isAnswered).count }
    public var isComplete: Bool { answeredCount == 6 }
    public var allDeclined: Bool {
        (0..<4).allSatisfy { choices(at: $0) == ["No preference"] } && body.response == .declined && colors.declined
    }

    public func validated() throws {
        for step in 0..<4 where !choices(at: step).isEmpty && !isAnswered(step) { throw ValidationError.invalidChoice }
        if body.response != .unanswered && !body.isAnswered { throw ValidationError.invalidBody }
        guard isComplete else { throw ValidationError.incomplete }
    }

    public func summary(at step: Int) -> String {
        switch step {
        case 0..<4: return choices(at: step).isEmpty ? "Not answered" : choices(at: step).joined(separator: ", ")
        case 4: return body.summary
        case 5:
            if colors.declined { return "No preference" }
            return colors.values.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: ", ").nilIfEmpty ?? "Not answered"
        default: return ""
        }
    }
}

public struct BodyPreferences: Codable, Equatable, Sendable {
    public enum Response: String, Codable, Sendable { case unanswered, provided, declined }
    public enum Units: String, Codable, Sendable { case cm, feetInches }
    public var response: Response = .unanswered
    public var heightCM: Double?
    public var units: Units = .cm
    public var shape: String?
    public var useForSuggestions = false
    public init() {}
    public static let shapes = ["Not sure", "Prefer not to say", "Straight", "Rounded", "Hourglass", "Broader shoulders", "Fuller hips"]
    public var isAnswered: Bool {
        if response == .declined { return heightCM == nil && shape == nil && !useForSuggestions }
        guard response == .provided, heightCM != nil || shape != nil else { return false }
        if let heightCM, !heightCM.isFinite || heightCM <= 0 { return false }
        if let shape, shape.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || shape.count > 160 { return false }
        return true
    }
    public var summary: String {
        switch response {
        case .unanswered: return "Not answered"
        case .declined: return "Prefer not to share"
        case .provided:
            return [heightCM.map { "\($0.formatted(.number.precision(.fractionLength(0...1)))) cm" }, shape].compactMap { $0 }.joined(separator: ", ")
        }
    }
    public mutating func decline() {
        response = .declined; heightCM = nil; shape = nil; useForSuggestions = false
    }
    /// No model consumer may use body values without BOTH explicit permissions.
    public func suggestionContext(styleContextEnabled: Bool) -> BodyPreferences? {
        useForSuggestions && styleContextEnabled && response == .provided && isAnswered ? self : nil
    }
}

public struct ColorPreferences: Codable, Equatable, Sendable {
    public var preferredColors = ""
    public var avoidedColors = ""
    public var preferredPatterns = ""
    public var avoidedPatterns = ""
    public var declined = false
    public init() {}
    public var values: [String] { [preferredColors, avoidedColors, preferredPatterns, avoidedPatterns] }
    public var isAnswered: Bool {
        let hasValues = values.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return declined ? !hasValues : hasValues
    }
}

public enum StylePreferenceSource: String, Codable, Sendable { case onboarding, profile, settings }

public struct StylePreferenceDraft: Codable, Equatable, Sendable {
    public let id: UUID
    public let operationID: UUID
    public let source: StylePreferenceSource
    public let baseRevision: Int
    public var answers: StylePreferences
    public var page = 0
    public var editingFromReview = false
    public init(source: StylePreferenceSource, baseRevision: Int = 0, answers: StylePreferences = .init()) {
        id = UUID(); operationID = UUID(); self.source = source
        self.baseRevision = baseRevision; self.answers = answers
    }
    public func validated() throws {
        guard (0...6).contains(page), baseRevision >= 0 else { throw StylePreferences.ValidationError.unsupportedSchema }
    }
}

public struct SavedStylePreferences: Codable, Equatable, Sendable {
    public let answers: StylePreferences
    public let revision: Int
    public let operationID: UUID
    public init(answers: StylePreferences, revision: Int, operationID: UUID) {
        self.answers = answers; self.revision = revision; self.operationID = operationID
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
