import AQDCore
import SwiftUI
import UIKit

/// Remote images and HTML are never loaded. Links require a complete allowed URL.
struct AgentMarkdownBody: View {
    let source: String
    private struct Block: Identifiable { let id: Int; let text: String; let code: Bool; let language: String }
    private var blocks: [Block] {
        var result: [Block] = [], buffer: [String] = [], code = false, language = ""
        func flush() { if !buffer.isEmpty { result.append(Block(id: result.count, text: buffer.joined(separator: "\n"), code: code, language: language)); buffer = [] } }
        for line in source.components(separatedBy: "\n") {
            if line.hasPrefix("```") { flush(); code.toggle(); language = code ? String(line.dropFirst(3)) : "" }
            else if line.isEmpty && !code { flush() }
            else { buffer.append(line) }
        }
        flush(); return result
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(blocks) { block in
                if block.code {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack { Text(block.language.isEmpty ? "Code" : block.language).font(.footnote); Spacer(); Button("Copy code") { UIPasteboard.general.string = block.text }.frame(minHeight: 44) }
                        ScrollView(.horizontal) { Text(block.text).font(.body.monospaced()).textSelection(.enabled) }
                    }.padding(12).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                } else {
                    ForEach(Array(block.text.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                        lineView(line)
                    }
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    @ViewBuilder private func lineView(_ line: String) -> some View {
        if line.hasPrefix("#") && line.contains(" ") {
            let hashes = line.prefix(while: { $0 == "#" }).count
            Text(attributed(String(line.dropFirst(hashes)).trimmingCharacters(in: .whitespaces)))
                .font(hashes == 1 ? .title2.weight(.medium) : .headline).accessibilityAddTraits(.isHeader).textSelection(.enabled)
        } else if line.hasPrefix("> ") {
            HStack(alignment: .top, spacing: 12) { Rectangle().fill(AppTheme.divider).frame(width: 2); Text(attributed(String(line.dropFirst(2)))).textSelection(.enabled) }
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.range(of: #"^\d+\. "#, options: .regularExpression) != nil {
            let parts = line.split(separator: " ", maxSplits: 1)
            HStack(alignment: .top, spacing: 8) { Text(line.hasPrefix("- ") || line.hasPrefix("* ") ? "•" : String(parts[0])).frame(width: 28, alignment: .leading); Text(attributed(parts.count > 1 ? String(parts[1]) : line)).textSelection(.enabled) }
        } else if line.contains("|") {
            ScrollView(.horizontal) { Text(attributed(line)).font(.body.monospaced()).textSelection(.enabled) }
        } else { Text(attributed(line)).textSelection(.enabled) }
    }
    private func attributed(_ line: String) -> AttributedString {
        var result = (try? AttributedString(markdown: line, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(line)
        for run in result.runs {
            if let link = run.link {
                if !AgentMarkdownPolicy.allowsLink(link.absoluteString) { result[run.range].link = nil }
                else { result[run.range].underlineStyle = .single }
            }
        }
        return result
    }
}
