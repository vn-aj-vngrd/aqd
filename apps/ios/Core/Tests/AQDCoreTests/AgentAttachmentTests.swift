import Foundation
import Testing
@testable import AQDCore

struct AgentAttachmentTests {
    private func image() -> AgentAttachment { AgentAttachment(kind: .image, name: "Photo", preview: Data([1, 2, 3]), text: "Navy coat", method: "Image reference") }
    @Test func attachmentOnlyDraftMovesOnceAndSurvivesRetryAndDecode() throws {
        var chat = AgentConversation(ownerID: UUID()); let photo = image()
        chat.draftAttachments = [photo]
        #expect(chat.title == "New conversation")
        let attempt = try chat.beginAttempt()
        #expect(chat.draftAttachments == nil && chat.messages[0].source.isEmpty)
        #expect(chat.messages[0].attachments == [photo])
        #expect(chat.messages[0].promptText.contains("Navy coat") && !chat.messages[0].promptText.contains("AQID"))
        #expect(chat.title == "Photo")
        try chat.append("A navy look", attemptID: attempt); try chat.complete(attemptID: attempt)
        _ = try chat.retry(messageID: chat.messages.last!.id)
        let decoded = try JSONDecoder().decode(AgentConversation.self, from: JSONEncoder().encode(chat))
        #expect(decoded.messages[0].attachments == [photo] && decoded.messages.count == 2)
        try decoded.validated()
    }
    @Test func invalidAttachmentsCannotClearADraft() throws {
        var chat = AgentConversation(ownerID: UUID()); chat.draft = "Keep me"
        chat.draftAttachments = (0..<5).map { _ in image() }
        #expect(throws: (any Error).self) { try chat.beginAttempt() }
        #expect(chat.draft == "Keep me" && chat.messages.isEmpty && chat.draftAttachments?.count == 5)
        var oversized = image(); oversized.preview = Data(repeating: 0, count: AgentAttachment.maximumPreviewBytes + 1)
        #expect(throws: (any Error).self) { try oversized.validated() }
        let document = AgentAttachment(kind: .document, name: "notes.txt", text: "", method: "Document text")
        #expect(throws: (any Error).self) { try document.validated() }
    }
    @Test func oldMessagesAndDraftsDecodeWithoutAttachments() throws {
        let chat = AgentConversation(ownerID: UUID())
        let decoded = try JSONDecoder().decode(AgentConversation.self, from: JSONEncoder().encode(chat))
        #expect(decoded.draftAttachments == nil)
        let message = AgentMessage(role: .user, source: "Hello", status: .complete)
        let old = try JSONDecoder().decode(AgentMessage.self, from: JSONEncoder().encode(message))
        #expect(old.attachments == nil && old.promptText == "Hello")
    }
}
