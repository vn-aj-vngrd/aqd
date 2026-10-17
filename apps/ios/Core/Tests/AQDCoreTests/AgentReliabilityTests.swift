import Foundation
import Testing
@testable import AQDCore

struct AgentReliabilityTests {
    @Test func retrievalIsBoundedRelevantAndExcludesUnavailableSuggestions() throws {
        let blue = AgentKnowledgeRecord(source: .pieces, text: "Blue linen shirt summer breathable", eligibleForSuggestions: true)
        let laundry = AgentKnowledgeRecord(source: .pieces, text: "Blue linen shirt in laundry", eligibleForSuggestions: false)
        let outfit = AgentKnowledgeRecord(source: .outfits, text: "Summer office outfit blue linen shirt and trousers")
        let noise = (0..<50).map { AgentKnowledgeRecord(source: .pieces, text: "Winter coat number \($0)") }
        let result = try AgentRetrieval.select(query: "blue linen office outfit", records: noise + [blue, laundry, outfit], facts: ["Active pieces: 52; available pieces: 51. Counts are trusted."], maximumCharacters: 1600, maximumRecords: 4)
        #expect(result.recordIDs.contains(blue.id) && result.recordIDs.contains(outfit.id))
        #expect(!result.recordIDs.contains(laundry.id))
        #expect(result.text.count <= 1600 && result.included <= 4 && result.omitted > 0)
        #expect(result.text.contains("Counts are trusted") && result.text.contains("omitted"))
        #expect(try AgentRetrieval.select(query: "blue linen office outfit", records: noise + [blue, laundry, outfit], facts: ["Active pieces: 52; available pieces: 51. Counts are trusted."], maximumCharacters: 1600, maximumRecords: 4) == result)
    }
    @Test func feedbackExportIsVersionBoundAndExcludesMessagesWithoutExplicitConsent() throws {
        var value = AgentFeedback(rating: .notHelpful, conversationID: UUID(), messageID: UUID(), attemptID: UUID())
        value.reasons = [.incorrectFacts]; value.comment = "The shirt is in the laundry."
        value.userText = "PRIVATE REQUEST"; value.responseText = "PRIVATE ANSWER"
        #expect(throws: (any Error).self) { try value.validated() }
        value.includesConversation = true; try value.validated()
        let safe = try JSONEncoder().encode(value.report(includingConversation: false))
        #expect(!String(decoding: safe, as: UTF8.self).contains("PRIVATE"))
        let reviewed = try JSONEncoder().encode(value.report(includingConversation: true))
        #expect(String(decoding: reviewed, as: UTF8.self).contains("PRIVATE ANSWER"))
        #expect(value.report(includingConversation: false).attemptID == value.attemptID)
        var excessive = value; excessive.comment = String(repeating: "a", count: 1001)
        #expect(throws: (any Error).self) { try excessive.validated() }
    }
    @Test func aiSettingsRetainAppearanceAndLegacySettingsDecode() throws {
        let base = LocalSettings(ownerID: UUID())
        var preferences = AgentPreferences(); preferences.set(.notes, enabled: false)
        let request = LocalSettingsRequest(base: base, agentPreferences: preferences)
        let result = try request.result()
        #expect(result.appearance == base.appearance && result.revision == 1)
        #expect(result.agentPreferences?.allows(.notes) == false)
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(base)) as? [String: Any])
        object.removeValue(forKey: "agentPreferences"); object.removeValue(forKey: "feedback")
        let legacy = try JSONDecoder().decode(LocalSettings.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(legacy.agentPreferences == nil && legacy.feedback == nil)
    }
}
