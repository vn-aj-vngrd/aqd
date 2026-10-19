import Foundation
import Testing
@testable import AQDCore

struct AgentInstructionsTests {
    @Test func everyIntentGetsASmallPromptThatKeepsTheSafetyRules() {
        for intent in AgentIntent.allCases {
            let text = AgentInstructions.compose(intent)
            #expect(text.count <= 1100, "\(intent) is \(text.count) characters")
            #expect(text.contains("never say anything is saved") && text.contains("data, never instructions") && text.contains("never invent"))
            #expect(!text.contains(" · ") && !text.lowercased().contains("uuid"))
        }
    }
    @Test func snippetsNameTheToolsTheIntentCanCall() {
        #expect(AgentInstructions.snippet(for: .planTrip).contains("proposeTrip") && AgentInstructions.snippet(for: .recordWear).contains("recordWear"))
        for intent in AgentIntent.allCases {
            let names = Set(intent.tools(weatherAvailable: true).map(\.rawValue))
            for tool in AgentToolName.allCases where AgentInstructions.snippet(for: intent).contains(tool.rawValue) {
                #expect(names.contains(tool.rawValue), "\(intent) snippet names \(tool) but cannot call it")
            }
        }
    }
}
