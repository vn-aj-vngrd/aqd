import Foundation

/// User-perceived character limits for editable multiline content.
public enum TextAreaLimits {
    public static let caption = 160
    public static let note = 2_000
    public static let fitNote = 500

    public static func editedText(_ proposed: String, current: String, limit: Int) -> String {
        // Recovered or older text is never truncated just by opening its editor.
        // Permit gradual shortening while preventing further over-limit growth.
        if current.count > limit { return proposed.count < current.count ? proposed : current }
        return String(proposed.prefix(limit))
    }
}
