import Testing
@testable import AQDCore

struct TextAreaLimitsTests {
    @Test func editsBoundPastesAtCharacterBoundaries() {
        let emoji = "👨‍👩‍👧‍👦"
        #expect(TextAreaLimits.editedText(String(repeating: emoji, count: 161), current: "", limit: TextAreaLimits.caption) == String(repeating: emoji, count: 160))
        #expect(TextAreaLimits.editedText("abc", current: "ab", limit: 3) == "abc")
        #expect(TextAreaLimits.editedText("abcd", current: "abc", limit: 3) == "abc")
    }
    @Test func olderLongTextIsPreservedAndCanBeShortened() {
        #expect(TextAreaLimits.editedText("abcdef", current: "abcdef", limit: 3) == "abcdef")
        #expect(TextAreaLimits.editedText("abcdefg", current: "abcdef", limit: 3) == "abcdef")
        #expect(TextAreaLimits.editedText("abcde", current: "abcdef", limit: 3) == "abcde")
        #expect(TextAreaLimits.editedText("", current: "abcdef", limit: 3).isEmpty)
    }
}
