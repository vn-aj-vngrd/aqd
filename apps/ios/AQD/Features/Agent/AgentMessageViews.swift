import AQDCore
import SwiftUI
import UIKit

/// One chat turn: a right-aligned bubble for the user, unboxed streaming Markdown for the assistant.
struct AgentMessageRow: View {
    let message: AgentMessage
    let slow: Bool
    let canRegenerate: Bool
    let retry: () -> Void
    let showDetails: () -> Void
    @State private var copied = false

    var body: some View {
        if message.role == .user { userRow } else { assistantRow }
    }

    private var userRow: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer(minLength: AppControlMetrics.minimumTarget)
            VStack(alignment: .trailing, spacing: AppSpacing.small) {
                if let attachments = message.attachments, !attachments.isEmpty { AgentAttachmentStrip(attachments: attachments) }
                if !message.source.isEmpty {
                    Text(message.source).textSelection(.enabled)
                        .padding(.horizontal, AppSpacing.large).padding(.vertical, AppSpacing.medium)
                        .background(AppTheme.messageBubble, in: RoundedRectangle(cornerRadius: AppRadius.composer))
                        .accessibilityLabel("You: " + message.source)
                }
            }
        }.frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var hasText: Bool { !message.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var didFail: Bool { message.status == .failed || message.status == .interrupted }

    private var assistantRow: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            if hasText { AgentMarkdownBody(source: AgentMarkdownPolicy.conversationalText(message.source)) }
            if message.isActive {
                AgentWorkingIndicator(
                    title: message.status == .stopping ? "Stopping…" : slow ? "Still working…" : message.source.isEmpty ? "Thinking…" : "Writing…",
                    animates: message.status != .stopping)
            } else if didFail {
                failureBubble
            } else {
                if message.status == .stopped { Text("Stopped").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                actions
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var failureBubble: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Label(message.failureReason ?? "The response didn’t finish.", systemImage: "exclamationmark.circle")
                .font(AppTypography.supporting).foregroundStyle(AppTheme.ink)
            if canRegenerate {
                Button(action: retry) { Label("Retry", systemImage: "arrow.clockwise").frame(minHeight: AppControlMetrics.minimumTarget).contentShape(Rectangle()) }
                    .buttonStyle(.plain).foregroundStyle(AppTheme.ink)
            }
        }.padding(AppSpacing.medium).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
            .accessibilityElement(children: .contain)
    }

    private var actions: some View {
        HStack(spacing: 0) {
            Button { copy(markdown: false) } label: { icon(copied ? "checkmark" : "square.on.square") }
                .accessibilityLabel(copied ? "Response copied" : "Copy response").disabled(!hasText)
            if canRegenerate {
                Button(action: retry) { icon("arrow.clockwise") }.accessibilityLabel("Regenerate response")
            }
            Menu {
                Section(AgentChatTimestamp.label(for: message.createdAt)) {
                    AccessoryButton("Copy Markdown", systemImage: "doc.text") { copy(markdown: true) }.disabled(!hasText)
                    AccessoryButton("Response details", systemImage: "info.circle", action: showDetails)
                }
            } label: { icon("ellipsis") }.accessibilityLabel("Response options")
        }.buttonStyle(.plain).padding(.leading, -AppSpacing.medium)
    }

    private func icon(_ name: String) -> some View {
        Image(systemName: name).font(.system(size: 16, weight: .regular)).foregroundStyle(AppTheme.controlIcon)
            .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
            .contentShape(Rectangle())
    }

    private func copy(markdown: Bool) {
        let source = AgentMarkdownPolicy.conversationalText(message.source)
        let value = markdown ? (message.status == .complete ? "" : "Incomplete response\n\n") + source : AgentMarkdownPolicy.plainText(source, incomplete: message.status != .complete)
        UIPasteboard.general.string = value
        if UIPasteboard.general.string == value { copied = true; UIAccessibility.post(notification: .announcement, argument: "Response copied") }
    }
}

/// Contextual prompts shown on an empty chat; tapping one sends it.
struct AgentSuggestionStrip: View {
    let titles: [String]
    let enabled: Bool
    let send: (String) -> Void
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: AppSpacing.small) {
                ForEach(titles, id: \.self) { title in AppChip(title: title, isSelected: false) { send(title) } }
            }.padding(.horizontal, AppSpacing.large)
        }.scrollIndicators(.hidden).disabled(!enabled)
    }
}
