import AQDCore
import Foundation
import ImageIO
import PDFKit
import Vision
import UniformTypeIdentifiers

/// Retains bounded image references and excerpts. Original full-resolution files are ephemeral.
enum AgentAttachmentReader {
    struct Result: Sendable { let name: String; let method: String; let text: String; let partial: Bool }
    enum Failure: LocalizedError {
        case tooLarge, unsupported, unreadable, empty, timeout
        var errorDescription: String? {
            switch self {
            case .tooLarge: "Choose a file smaller than 20 MB. Your draft is unchanged."
            case .unsupported: "Choose an image, PDF, plain text or Markdown file."
            case .unreadable: "This attachment couldn’t be read. Choose another file or try again."
            case .empty: "No readable text was found. For a scanned document, attach its pages as photos instead."
            case .timeout: "Attachment processing timed out. Your draft is unchanged. Try again."
            }
        }
    }
    static func perform<Value: Sendable>(_ operation: @escaping @Sendable () async throws -> Value) async throws -> Value {
        let worker = Task.detached(priority: .userInitiated, operation: operation)
        return try await withTaskCancellationHandler(operation: { try await worker.value }, onCancel: { worker.cancel() })
    }
    static func prepare(data: Data, name: String, image: Bool, pdf: Bool = false) async throws -> AgentAttachment {
        guard data.count <= 20 * 1024 * 1024 else { throw Failure.tooLarge }
        let name = String(name.prefix(120))
        if image {
            let preview = try normalizedImage(data)
            var text = ""
            do { text = try await read(data: preview, name: name, image: true).text }
            catch Failure.empty { /* A photo without text remains a usable image attachment. */ }
            try Task.checkCancellation()
            return AgentAttachment(kind: .image, name: name, preview: preview, text: String(text.prefix(AgentAttachment.maximumTextCharacters)), method: "Selected image; OCR is supplemental. Visual input requires a supported on-device model.", partial: text.count > AgentAttachment.maximumTextCharacters)
        }
        let value = try await read(data: data, name: name, image: false, pdf: pdf)
        return AgentAttachment(kind: .document, name: name, text: String(value.text.prefix(AgentAttachment.maximumTextCharacters)), method: value.method, partial: value.partial || value.text.count > AgentAttachment.maximumTextCharacters)
    }
    private static func normalizedImage(_ data: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { throw Failure.unreadable }
        for size in [1024, 640] {
            guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: size, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else { throw Failure.unreadable }
            for quality in [0.75, 0.5, 0.3] {
                let output = NSMutableData()
                guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else { throw Failure.unreadable }
                CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
                if CGImageDestinationFinalize(destination), output.length <= AgentAttachment.maximumPreviewBytes { return output as Data }
            }
        }
        throw Failure.tooLarge
    }
    static func read(data: Data, name: String, image: Bool, pdf: Bool = false) async throws -> Result {
        guard data.count <= 20 * 1024 * 1024 else { throw Failure.tooLarge }
        try Task.checkCancellation()
        if image {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 1024, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else { throw Failure.unreadable }
            let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate; request.usesLanguageCorrection = true
            try VNImageRequestHandler(cgImage: thumbnail).perform([request])
            try Task.checkCancellation()
            let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            return try result(name: name, method: "Image text only. Visual appearance was not analyzed.", text: text)
        }
        if pdf {
            guard let document = PDFDocument(data: data), !document.isLocked else { throw Failure.unreadable }
            var parts: [String] = [], count = 0, pagesRead = 0
            for index in 0..<min(document.pageCount, 20) {
                try Task.checkCancellation()
                let page = document.page(at: index)?.string ?? ""
                parts.append(page); count += page.count; pagesRead += 1
                if count > AgentAttachmentPolicy.maximumCharacters { break }
            }
            return try result(name: name, method: "PDF text. Layout and images were not analyzed.", text: parts.joined(separator: "\n"), partial: pagesRead < document.pageCount)
        }
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) else { throw Failure.unreadable }
        return try result(name: name, method: "Document text", text: text)
    }
    private static func result(name: String, method: String, text: String, partial: Bool = false) throws -> Result {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw Failure.empty }
        return Result(name: name, method: method, text: String(text.prefix(AgentAttachmentPolicy.maximumCharacters)), partial: partial || text.count > AgentAttachmentPolicy.maximumCharacters)
    }
}
