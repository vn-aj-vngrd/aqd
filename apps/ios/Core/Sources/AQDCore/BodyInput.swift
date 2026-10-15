import Foundation

/// Keeps invalid editing text without ever replacing a saved measurement.
/// Unit changes reformat the canonical value, rather than round-tripping it.
public struct HeightInput: Codable, Equatable, Sendable {
    public enum Field: Sendable { case centimeters, feet, inches }
    public private(set) var units: BodyPreferences.Units
    public private(set) var cmText = ""
    public private(set) var feetText = ""
    public private(set) var inchesText = ""
    public private(set) var centimeters: Double?
    public init(body: BodyPreferences) {
        units = body.units; centimeters = body.heightCM
        format()
    }
    public var isValid: Bool {
        if units == .cm {
            if cmText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return centimeters == nil }
            guard let value = Self.number(cmText), value > 0 else { return false }
        } else {
            let feet = feetText.trimmingCharacters(in: .whitespacesAndNewlines)
            let inches = inchesText.trimmingCharacters(in: .whitespacesAndNewlines)
            if feet.isEmpty && inches.isEmpty { return centimeters == nil }
            guard let f = Self.number(feet.isEmpty ? "0" : feet), f >= 0, f.rounded(.down) == f,
                  let i = Self.number(inches.isEmpty ? "0" : inches), i >= 0, i < 12,
                  (f * 12 + i) > 0, ((f * 12 + i) * 2.54).isFinite else { return false }
        }
        return centimeters.map { $0.isFinite && $0 > 0 } ?? false
    }
    public mutating func edit(_ field: Field, text: String) {
        switch field { case .centimeters: cmText = text; case .feet: feetText = text; case .inches: inchesText = text }
        if units == .cm {
            centimeters = Self.number(cmText).flatMap { $0 > 0 ? $0 : nil }
        } else {
            let feet = feetText.trimmingCharacters(in: .whitespacesAndNewlines)
            let inches = inchesText.trimmingCharacters(in: .whitespacesAndNewlines)
            if feet.isEmpty && inches.isEmpty { centimeters = nil; return }
            guard let f = Self.number(feet.isEmpty ? "0" : feet), f >= 0, f.rounded(.down) == f,
                  let i = Self.number(inches.isEmpty ? "0" : inches), i >= 0, i < 12 else { centimeters = nil; return }
            let value = (f * 12 + i) * 2.54
            centimeters = value > 0 && value.isFinite ? value : nil
        }
    }
    public mutating func switchUnits(to value: BodyPreferences.Units) {
        guard isValid, value != units else { return }
        units = value; format()
    }
    public var summary: String? {
        guard centimeters != nil else { return nil }
        return units == .cm ? "\(cmText) cm" : "\(feetText) ft \(inchesText) in"
    }
    private mutating func format() {
        guard let value = centimeters else { cmText = ""; feetText = ""; inchesText = ""; return }
        cmText = Self.text(value)
        let total = value / 2.54
        let feet = (total / 12).rounded(.down)
        let inches = Self.text(total - feet * 12)
        // Display rounding can carry the remainder into the next foot.
        feetText = Self.text(inches == "12" ? feet + 1 : feet)
        inchesText = inches == "12" ? "0" : inches
    }
    private static func number(_ text: String) -> Double? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value.isFinite else { return nil }
        return value
    }
    private static func text(_ value: Double) -> String {
        value.formatted(.number.locale(Locale(identifier: "en_US_POSIX")).grouping(.never).precision(.fractionLength(0...10)))
    }
}

/// Pending picker and nested custom draft are separate from preference answers.
public struct BodyShapeDraft: Codable, Equatable, Sendable {
    public enum ValidationError: Error { case invalidDescription }
    public var selection: String?
    public var customText: String
    public var isEditingCustom = false
    public init(current: String?) {
        selection = current
        customText = current.flatMap { BodyPreferences.shapes.contains($0) ? nil : $0 } ?? ""
    }
    public var canUseDescription: Bool {
        !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && customText.count <= 160
    }
    public mutating func useDescription() throws {
        guard canUseDescription else { throw ValidationError.invalidDescription }
        selection = customText; isEditingCustom = false
    }
    public mutating func cancelDescription() { isEditingCustom = false }
}

public extension StylePreferenceDraft {
    func isAnswered(_ step: Int) -> Bool {
        answers.isAnswered(step) && (step != 4 || (heightInput?.isValid ?? true) && bodyShapePicker == nil)
    }
    var answeredCount: Int { (0..<6).filter(isAnswered).count }
    var isComplete: Bool { answeredCount == 6 }
    func validatedForSave() throws {
        try validated()
        guard isComplete else { throw StylePreferences.ValidationError.incomplete }
        try answers.validated()
    }
    mutating func editHeight(_ field: HeightInput.Field, text: String) {
        var input = heightInput ?? HeightInput(body: answers.body)
        input.edit(field, text: text)
        applyHeight(input)
    }
    mutating func switchHeightUnits(to units: BodyPreferences.Units) {
        var input = heightInput ?? HeightInput(body: answers.body)
        input.switchUnits(to: units)
        applyHeight(input)
    }
    private mutating func applyHeight(_ input: HeightInput) {
        heightInput = input; answers.body.heightCM = input.centimeters; answers.body.units = input.units
        answers.body.response = .provided
    }
    mutating func openBodyShapePicker() {
        guard bodyShapePicker == nil else { return }
        bodyShapePicker = BodyShapeDraft(current: answers.body.shape)
    }
    mutating func cancelBodyShapePicker() { bodyShapePicker = nil }
    mutating func finishBodyShapePicker() {
        guard let picker = bodyShapePicker, !picker.isEditingCustom else { return }
        answers.body.shape = picker.selection
        answers.body.response = .provided
        bodyShapePicker = nil
    }
    mutating func declineBody() {
        answers.body.decline(); heightInput = nil; bodyShapePicker = nil
    }
}
