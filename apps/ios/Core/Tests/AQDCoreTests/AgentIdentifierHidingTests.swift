import Testing
@testable import AQDCore

struct AgentIdentifierHidingTests {
    @Test func idLabelsAndBareUUIDsAreRemovedFromDisplayedReplies() {
        let text = "• ID 48B6CB14-FB2F-4BE6-8A3F-6B4267EF5D00 – Saturday look includes the Cream midi dress (ID: 48B6CB14-FB2F-4BE6-8A3F-6B4267EF5D01)."
        let shown = AgentMarkdownPolicy.conversationalText(text)
        #expect(!shown.contains("48B6CB14") && shown.contains("Saturday look") && shown.contains("Cream midi dress"))
    }
    @Test func replyWithoutIdentifiersIsUnchanged() {
        #expect(AgentMarkdownPolicy.hidingIdentifiers("Cream midi dress with tan crossbody") == "Cream midi dress with tan crossbody")
    }
}
