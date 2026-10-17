import Foundation
import SwiftData
import AQDCore

@Model final class StoredAgentConversation {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(_ value: AgentConversation) throws { id = value.id; payload = try JSONEncoder().encode(value) }
    func value() throws -> AgentConversation {
        let result = try JSONDecoder().decode(AgentConversation.self, from: payload)
        try result.validated(); guard result.id == id else { throw PieceStore.StoreError.invalidRecord }; return result
    }
}
@Model final class StoredAgentOperation {
    @Attribute(.unique) var id: UUID
    var conversationID: UUID
    var digest: String
    var result: Data?
    init(id: UUID, conversationID: UUID, digest: String, result: Data?) {
        self.id = id; self.conversationID = conversationID; self.digest = digest; self.result = result
    }
}
