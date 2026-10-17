import AQDCore
import SwiftUI

/// Chat input: attachments, a + menu (Camera, Photos, Files) and one send/stop button.
struct AgentComposerView: View {
    @Environment(AppState.self) private var state
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Bindable var model: AgentModel
    @Bindable var importer: AgentAttachmentImporter
    @Binding var attachmentSource: AgentAttachmentSource?
    var focused: FocusState<Bool>.Binding

    private var canSend: Bool {
        model.canGenerate && (!model.conversation.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !(model.conversation.draftAttachments ?? []).isEmpty)
    }

    var body: some View {
        surface.padding(.horizontal, AppSpacing.large).padding(.bottom, AppSpacing.small)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            if !(model.conversation.draftAttachments ?? []).isEmpty || !importer.pending.isEmpty {
                AgentAttachmentStrip(attachments: model.conversation.draftAttachments ?? [], pending: importer.pending, order: importer.order,
                                     remove: model.removeAttachment, cancelImport: importer.remove, locked: model.active || model.hasPendingOperation)
            }
            TextField("Ask Agent…", text: Binding(get: { model.conversation.draft }, set: model.updateDraft), axis: .vertical)
                .lineLimit(1...6).focused(focused).padding(.horizontal, AppSpacing.xSmall)
                .accessibilityLabel("Message Agent")
            HStack(spacing: AppSpacing.small) {
                addMenu
                Spacer(minLength: AppSpacing.small)
                sendButton
            }
        }.padding(AppSpacing.medium)
    }

    private var addMenu: some View {
        Menu {
            ForEach(AgentAttachmentSource.allCases) { source in
                AccessoryButton(source.rawValue, systemImage: source.icon) { focused.wrappedValue = false; attachmentSource = source }
            }
        } label: {
            Image(systemName: "plus").padding(.leading, AppSpacing.xSmall)
                .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget, alignment: .leading)
                .contentShape(Rectangle())
        }.accessibilityLabel("Add camera, photo or file")
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
