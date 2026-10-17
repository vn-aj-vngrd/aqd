import AQDCore
import Foundation
import Testing
import UIKit
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

struct AgentComposerAttachmentReaderTests {
    @Test func documentPreparationRetainsLabelAndMarksBoundedExcerpt() async throws {
        let result = try await AgentAttachmentReader.prepare(data: Data(String(repeating: "Linen notes. ", count: 200).utf8), name: "closet.md", image: false)
        #expect(result.kind == .document && result.name == "closet.md")
        #expect(result.partial && result.text.count == AgentAttachment.maximumTextCharacters)
        try result.validated()
    }
}

@Suite(.serialized) @MainActor struct AgentComposerImageReferenceTests {
    @Test func imageWithoutTextStillBecomesABoundedAttachment() async throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 900))
        let image = renderer.image { context in UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 1200, height: 900)) }
        let data = try #require(image.pngData())
        let prepared = try await AgentAttachmentReader.prepare(data: data, name: "blue.png", image: true)
        #expect(prepared.kind == .image && prepared.preview?.isEmpty == false)
        #expect((prepared.preview?.count ?? Int.max) <= AgentAttachment.maximumPreviewBytes)
        #expect(prepared.preview?.prefix(2) == Data([0xff, 0xd8]))
        try prepared.validated()
    }
    @Test func removingPendingImportCancelsWithoutAppendingToDraft() async throws {
        let store = try PieceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let model = try AgentModel(store: store), importer = AgentAttachmentImporter(model: model)
        model.updateDraft("Keep my question")
        importer.add(name: "notes.txt") {
            try await Task.sleep(for: .seconds(30))
            return AgentAttachment(kind: .document, name: "notes.txt", text: "Text", method: "Document text")
        }
        #expect(model.attachmentImportCount == 1)
        importer.remove(try #require(importer.pending.first?.id))
        await Task.yield()
        #expect(model.attachmentImportCount == 0 && model.conversation.draft == "Keep my question" && model.conversation.draftAttachments == nil)
    }
}
