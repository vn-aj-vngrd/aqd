import Foundation
import Testing
@testable import AQDCore
struct AgentActionTests {
    @Test func approvalBindsToAnImmutableVersionAndCancellationCannotBeApproved() throws {
        var theme = ThemeDraft(ownerID: UUID()); theme.name = "Weekend"
        var proposal = AgentActionProposal(action: .theme(theme))
        #expect(throws: (any Error).self) { try proposal.approve(version: 2) }
        try proposal.approve(version: 1)
        #expect(proposal.status == .executing)
        var cancelled = AgentActionProposal(action: .theme(theme)); try cancelled.cancel()
        #expect(throws: (any Error).self) { try cancelled.approve(version: 1) }
    }
}
