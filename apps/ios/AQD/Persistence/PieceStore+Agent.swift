import AQDCore
import CoreData
import CryptoKit
import Darwin
import Foundation
import SwiftData

struct AgentSaveAcknowledgment: Codable {
    let revision: Int
    let updatedAt: Date
}

extension PieceStore {
    func agentConversations() throws -> [AgentConversation] {
        let owner = try todayConfiguration().ownerID
        return try ModelContext(container).fetch(FetchDescriptor<StoredAgentConversation>()).map {
            let value = try $0.value()
            guard value.ownerID == owner else { throw StoreError.invalidRecord }; return value
        }.sorted { $0.updatedAt == $1.updatedAt ? $0.id.uuidString < $1.id.uuidString : $0.updatedAt > $1.updatedAt }
    }
    @discardableResult func saveAgentConversation(_ value: AgentConversation, operationID: UUID) throws -> AgentConversation {
        try value.validated()
        guard value.ownerID == (try todayConfiguration().ownerID) else { throw StoreError.invalidRecord }
        let context = ModelContext(container), checksum = digest(try encode(value))
        if let receipt = try context.fetch(FetchDescriptor<StoredAgentOperation>()).first(where: { $0.id == operationID }) {
            guard receipt.conversationID == value.id, receipt.digest == checksum, let result = receipt.result else { throw StoreError.operationConflict }
            if let acknowledgment = try? JSONDecoder().decode(AgentSaveAcknowledgment.self, from: result) {
                var saved = value; saved.revision = acknowledgment.revision; saved.updatedAt = acknowledgment.updatedAt; return saved
            }
            return try JSONDecoder().decode(AgentConversation.self, from: result)
        }
        guard !(try context.fetch(FetchDescriptor<StoredAgentOperation>())).contains(where: { $0.conversationID == value.id && $0.result == nil }) else { throw StoreError.deletedPiece }
        let stored = try context.fetch(FetchDescriptor<StoredAgentConversation>()).first { $0.id == value.id }
        guard try stored?.value().revision ?? 0 == value.revision else { throw StoreError.staleRevision }
        var saved = value; saved.revision += 1; saved.updatedAt = Date()
        try beforeOutfitSave()
        if let stored { stored.payload = try encode(saved) } else { context.insert(try StoredAgentConversation(saved)) }
        context.insert(StoredAgentOperation(id: operationID, conversationID: value.id, digest: checksum, result: try encode(AgentSaveAcknowledgment(revision: saved.revision, updatedAt: saved.updatedAt))))
        try commit(context); try afterOutfitSave(); return saved
    }
    func deleteAgentConversation(id: UUID, expectedRevision: Int, operationID: UUID) throws {
        let context = ModelContext(container), checksum = "delete:\(id):\(expectedRevision)"
        if let receipt = try context.fetch(FetchDescriptor<StoredAgentOperation>()).first(where: { $0.id == operationID }) {
            guard receipt.conversationID == id, receipt.digest == checksum, receipt.result == nil else { throw StoreError.operationConflict }; return
        }
        guard let stored = try context.fetch(FetchDescriptor<StoredAgentConversation>()).first(where: { $0.id == id }),
              try stored.value().revision == expectedRevision,
              try stored.value().ownerID == todayConfiguration().ownerID else { throw StoreError.staleRevision }
        guard try !(stored.value().proposals ?? []).contains(where: { $0.status == .executing }) else { throw StoreError.operationConflict }
        try beforeOutfitSave(); context.delete(stored)
        // Superseded save acknowledgments no longer retain deleted conversation text.
        for receipt in try context.fetch(FetchDescriptor<StoredAgentOperation>()) where receipt.conversationID == id { context.delete(receipt) }
        context.insert(StoredAgentOperation(id: operationID, conversationID: id, digest: checksum, result: nil))
        try commit(context); try afterOutfitSave()
    }
}
