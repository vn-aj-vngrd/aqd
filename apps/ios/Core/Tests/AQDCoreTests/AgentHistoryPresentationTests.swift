import Foundation
import Testing
@testable import AQDCore

struct AgentHistoryPresentationTests {
    @Test func statusTracksLatestReplyAndPreservesDraftPriority() throws {
        var value = AgentConversation(ownerID: UUID())
        #expect(AgentHistoryPresentation.status(value) == .empty)
        value.draft = "A look"; #expect(AgentHistoryPresentation.status(value) == .draft)
        let attempt = try value.beginAttempt(); #expect(AgentHistoryPresentation.status(value) == .loading)
        try value.append("**Blue shirt** 👕", attemptID: attempt); try value.complete(attemptID: attempt)
        #expect(AgentHistoryPresentation.status(value) == .complete)
        _ = try value.retry(messageID: value.messages.last!.id); value.interruptActiveAttempt()
        #expect(AgentHistoryPresentation.status(value) == .incomplete)
    }
    @Test func historyUsesLocalDayAndTime() throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_792_166_400)
        let today = calendar.startOfDay(for: now)
        let locale = Locale(identifier: "en_US")
        #expect(AgentHistoryPresentation.time(today, relativeTo: today.addingTimeInterval(3600), calendar: calendar, locale: locale).contains("12:00"))
        #expect(AgentHistoryPresentation.time(today.addingTimeInterval(-1), relativeTo: today, calendar: calendar, locale: locale) == "Yesterday")
        #expect(!AgentHistoryPresentation.time(today.addingTimeInterval(-86400 * 10), relativeTo: today, calendar: calendar, locale: locale).isEmpty)
    }
    @Test func attachmentRequiresReviewedBoundedContent() throws {
        let text = try AgentAttachmentPolicy.draftText(name: "look.png", method: "Image summary", text: "Navy coat")
        #expect(text.contains("untrusted") && text.contains("Navy coat"))
        #expect(throws: PlanValidationError.self) { try AgentAttachmentPolicy.draftText(name: "x", method: "Text", text: " ") }
        #expect(throws: PlanValidationError.self) { try AgentAttachmentPolicy.draftText(name: "x", method: "Text", text: String(repeating: "a", count: 2401)) }
    }
}
