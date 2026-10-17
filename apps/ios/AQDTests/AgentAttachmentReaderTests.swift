import AQDCore
import Foundation
import Testing
@testable import AQD

struct AgentAttachmentReaderTests {
    @Test func documentsExposeBoundedReviewedTextAndRejectEmptyData() async throws {
        let text = String(repeating: "A wardrobe note. ", count: 200)
        let result = try await AgentAttachmentReader.read(data: Data(text.utf8), name: "notes.md", image: false)
        #expect(result.partial && result.text.count == AgentAttachmentPolicy.maximumCharacters)
        #expect(result.method == "Document text")
        await #expect(throws: AgentAttachmentReader.Failure.self) { try await AgentAttachmentReader.read(data: Data(), name: "empty.txt", image: false) }
    }
    @Test func canceledPreparationCannotDeliverAReference() async throws {
        let task = Task {
            try await AgentAttachmentReader.perform {
                try await Task.sleep(for: .seconds(30))
                return try await AgentAttachmentReader.read(data: Data("Text".utf8), name: "test.txt", image: false)
            }
        }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
    }
}
