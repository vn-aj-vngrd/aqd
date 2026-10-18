import AQDCore
import SwiftUI

/// Chat input: attachments, a + menu (Camera, Photos, Files) and one send/stop button.
struct AgentComposerView: View {
    @Environment(AppState.self) private var state
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Bindable var model: AgentModel
    @State private var addOpen = false
    @Bindable var importer: AgentAttachmentImporter
    @Binding var attachmentSource: AgentAttachmentSource?
    var focused: FocusState<Bool>.Binding

    private var canSend: Bool {
        model.canGenerate && (!model.conversation.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !(model.conversation.draftAttachments ?? []).isEmpty)
    }

    /// The text after a leading "/" while the draft is a single slash command.
    private var slashQuery: String? {
        let draft = model.conversation.draft
        guard draft.hasPrefix("/"), !draft.contains("\n"), model.supportsGeneration, !model.active else { return nil }
        return String(draft.dropFirst())
    }

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            if addOpen && slashQuery == nil {
                AgentAddMenu { choice in
                    addOpen = false
                    switch choice {
                    case .source(let source): focused.wrappedValue = false; attachmentSource = source
                    case .tools: model.updateDraft("/"); focused.wrappedValue = true
                    }
                }.transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .bottomLeading)))
            }
            if let query = slashQuery {
                AgentSlashMenu(query: query) { model.updateDraft($0.prompt); focused.wrappedValue = true }
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .bottom)))
            }
            surface
        }.padding(.horizontal, AppSpacing.large).padding(.bottom, AppSpacing.small)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: slashQuery != nil)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: addOpen)
            .onChange(of: model.conversation.draft) { _, _ in addOpen = false }
    }

    /// One quiet line until the owner engages: tapping, typing, attaching or a running reply opens the full composer.
    private var expanded: Bool {
        focused.wrappedValue || addOpen || model.active || !model.conversation.draft.isEmpty
            || !(model.conversation.draftAttachments ?? []).isEmpty || !importer.pending.isEmpty
    }

    private var content: some View {
        let open = expanded
        return VStack(alignment: .leading, spacing: 0) {
            if !(model.conversation.draftAttachments ?? []).isEmpty || !importer.pending.isEmpty {
                AgentAttachmentStrip(attachments: model.conversation.draftAttachments ?? [], pending: importer.pending, order: importer.order,
                                     remove: model.removeAttachment, cancelImport: importer.remove, locked: model.active || model.hasPendingOperation)
                    .padding(.bottom, AppSpacing.small)
            }
            // The field never changes place, so focus survives opening; the buttons slide around it.
            TextField("Ask Agent, or type / for tools", text: Binding(get: { model.conversation.draft }, set: model.updateDraft), axis: .vertical)
                .lineLimit(1...6).focused(focused)
                .padding(.leading, open ? AppSpacing.xSmall : AppControlMetrics.minimumTarget)
                .padding(.trailing, open ? AppSpacing.xSmall : AppControlMetrics.minimumTarget)
                .frame(minHeight: AppControlMetrics.minimumTarget, alignment: .leading)
                .accessibilityLabel("Message Agent")
            if open { Color.clear.frame(height: AppControlMetrics.minimumTarget) }
        }
        .overlay(alignment: open ? .bottom : .center) {
            HStack(spacing: AppSpacing.small) {
                addMenu
                Spacer(minLength: AppSpacing.small)
                sendButton
            }
        }
        .padding(.horizontal, open ? AppSpacing.medium : AppSpacing.small)
        .padding(.vertical, open ? AppSpacing.medium : AppSpacing.xSmall)
        .contentShape(Rectangle())
        .onTapGesture { if !open { focused.wrappedValue = true } }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: open)
    }

    private var addMenu: some View {
        Button { addOpen.toggle() } label: {
            Image(systemName: "plus").rotationEffect(.degrees(addOpen ? 45 : 0)).padding(.leading, AppSpacing.xSmall)
                .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget, alignment: .leading)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).foregroundStyle(AppTheme.ink).accessibilityLabel("Add photos, files or tools").accessibilityValue(addOpen ? "Open" : "Closed")
            .disabled(!model.supportsGeneration || model.active || model.hasPendingOperation || importer.count >= AgentAttachment.maximumCount || state.agentControlsModel?.hasPending == true)
    }

    private var sendButton: some View {
        Button { if model.active { model.stop() } else { model.send() } } label: {
            Image(systemName: model.active ? "stop.fill" : "arrow.up")
                .font(.body.weight(.semibold))
                .foregroundStyle(model.active || canSend ? AppTheme.onPrimary : AppTheme.secondary)
                .frame(width: 32, height: 32)
                .background(model.active || canSend ? AppTheme.primaryFill : AppTheme.divider, in: Circle())
                .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(model.active ? "Stop response" : "Send to Agent")
            .disabled(!model.active && !canSend)
    }

    @ViewBuilder private var surface: some View {
        if #available(iOS 26, *), !reduceTransparency, contrast != .increased {
            content.glassEffect(.regular.interactive(!reduceMotion), in: RoundedRectangle(cornerRadius: AppRadius.composer))
        } else {
            content.background {
                RoundedRectangle(cornerRadius: AppRadius.composer).fill(AppTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.composer).stroke(contrast == .increased ? AppTheme.controlBoundary : AppTheme.divider, lineWidth: 1))
            }
        }
    }
}
