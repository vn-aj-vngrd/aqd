import AQDCore
import SwiftUI
import UIKit

struct LocalAgentView: View {
    @Environment(AppState.self) private var state
    @Environment(\.scenePhase) private var scenePhase
    let close: () -> Void
    var body: some View {
        NavigationStack {
            if let model = state.agentModel {
                AgentConversationView(model: model, close: close)
            } else {
                CenteredPageContent {
                    AppEmptyState("Conversations couldn’t open", systemImage: "exclamationmark.bubble", description: Text("Your local records are retained."), fillsAvailableSpace: false)
                    Button(action: open) { Text("Try again").frame(minHeight: 44).contentShape(Rectangle()) }
                }.toolbar { ToolbarItem(placement: .topBarLeading) {
                    Button(action: close) { Image(systemName: "chevron.backward") }.accessibilityLabel("Back")
                } }
            }
        }.appAppearance(state.appearance).background(AppTheme.canvas.ignoresSafeArea()).tint(AppTheme.ink).task { open() }.onDisappear { state.agentModel?.suspend() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { state.agentModel?.recheckAvailability() }
                else { state.agentModel?.suspend() }
            }
    }
    private func open() {
        guard state.agentModel == nil, let store = state.store else { return }
        state.agentModel = try? AgentModel(store: store)
        state.agentModel?.weatherClient = state.weatherClient
        state.agentModel?.controls = state.agentControlsModel
    }
}

struct AgentConversationView: View {
    @Environment(AppState.self) private var state
    @Bindable var model: AgentModel
    let close: () -> Void
    var automaticallyFocusComposer = true
    @State private var history = false
    @State private var deletingConversation: AgentConversation?
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var attachmentSource: AgentAttachmentSource?
    @State private var attachmentPickerPresented = false
    @State private var attachmentImporter: AgentAttachmentImporter
    @State private var aiSettings = false
    @State private var feedbackEditing: AgentFeedback?
    @State private var feedbackLibrary: AgentFeedbackLibrary?
    @State private var voice = false
    @State private var readAloud = AgentReadAloud()
    @Environment(\.scenePhase) private var scenePhase
    @State private var details: AgentMessage?
    @State private var copied: UUID?
    @State private var followsLatest = true
    @State private var didFocus = false
    @FocusState private var focused: Bool
    init(model: AgentModel, close: @escaping () -> Void, automaticallyFocusComposer: Bool = true) {
        self.model = model; self.close = close; self.automaticallyFocusComposer = automaticallyFocusComposer
        _attachmentImporter = State(initialValue: AgentAttachmentImporter(model: model))
    }
    private var emptyUnavailable: Bool {
        !model.supportsGeneration && model.conversation.messages.isEmpty && (model.conversation.proposals ?? []).isEmpty
    }
    var body: some View {
        Group {
            if emptyUnavailable {
                VStack(spacing: 0) {
                    if let error = model.error { SemanticFeedback(role: .danger, message: error).padding(20) }
                    if model.hasPendingOperation || model.error != nil {
                        Button("Retry operation") { model.retryPending() }.frame(minHeight: 44)
                    }
                    if let attachments = model.conversation.draftAttachments, !attachments.isEmpty {
                        AgentAttachmentStrip(attachments: attachments, remove: model.removeAttachment, locked: model.hasPendingOperation).padding(.horizontal, AppSpacing.screen)
                    }
                    AgentAvailabilityContent(availability: model.availability, recheck: model.recheckAvailability,
                                             fillsPage: true, retainedDraft: model.conversation.draft)
                }
            } else if isNewConversation {
                emptyChat
            } else {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    if let error = model.error {
                        SemanticFeedback(role: .danger, message: error)
                    }
                    if model.hasPendingOperation || model.error != nil {
                        Button("Retry operation") { model.retryPending() }.frame(minHeight: 44)
                    }
                    ForEach(Array(model.conversation.messages.enumerated()), id: \.element.id) { index, message in
                        if AgentChatTimestamp.startsGroup(message.createdAt, after: index > 0 ? model.conversation.messages[index - 1].createdAt : nil) {
                            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                                Text(AgentChatTimestamp.label(for: message.createdAt, relativeTo: timeline.date))
                                    .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                                    .frame(maxWidth: .infinity).padding(.vertical, AppSpacing.xSmall)
                            }
                        }
                        messageRow(message).id(message.id)
                    }
                    ForEach(model.conversation.proposals ?? []) { proposal in
                        NavigationLink { AgentActionReviewView(model: model, id: proposal.id).secondaryPage() } label: {
                            HStack(spacing: AppSpacing.medium) {
                                Image(systemName: proposal.status == .succeeded ? "checkmark.circle" : "square.and.pencil")
                                    .foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                    Text(proposal.action.title).foregroundStyle(AppTheme.ink)
                                    Text(proposal.status == .succeeded ? "Saved locally" : proposal.status == .cancelled ? "Cancelled" : proposal.status == .executing ? "Check save result" : "Not saved · Tap to review")
                                        .font(.footnote).foregroundStyle(AppTheme.secondary)
                                }
                                Spacer(minLength: AppSpacing.small)
                                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                            }.frame(minHeight: AppControlMetrics.minimumTarget)
                                .padding(AppSpacing.medium).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
                        }
                    }
                    if !model.supportsGeneration {
                        AgentAvailabilityContent(availability: model.availability, recheck: model.recheckAvailability,
                                                 showsActions: false)
                        if !model.conversation.draft.isEmpty { Text("Your retained draft").font(AppTypography.section); Text(model.conversation.draft).textSelection(.enabled) }
                    }
                    Color.clear.frame(height: 1).id("latest").onAppear { followsLatest = true }.onDisappear { followsLatest = false }
                }.padding(20).disabled(voice)
            }.defaultScrollAnchor(.bottom, for: .initialOffset)
                .id(model.conversation.id)
                .onAppear { followsLatest = true; proxy.scrollTo("latest", anchor: .bottom) }
                .onChange(of: model.conversation.messages.last?.source) { _, _ in if followsLatest { proxy.scrollTo("latest", anchor: .bottom) } }
                .overlay(alignment: .bottomTrailing) { if !followsLatest { Button { followsLatest = true; proxy.scrollTo("latest", anchor: .bottom) } label: {
                    Image(systemName: "arrow.down").frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
                        .background(AppTheme.surface, in: Circle())
                }.accessibilityLabel("Jump to latest").padding(AppSpacing.large) } }
        }
            }
        }.background(AppTheme.canvas).navigationTitle("Agent").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                if model.supportsGeneration || voice {
                    VStack(spacing: AppSpacing.small) {
                        if isNewConversation && !voice { suggestions }
                        composer
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { if !model.active && model.persist() { close() } } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Back").disabled(model.active || voice || model.attachmentImportCount > 0) }
                if model.supportsGeneration {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { model.newConversation(); focused = true } label: { Image(systemName: "square.and.pencil") }
                            .accessibilityLabel("New conversation").disabled(model.active || model.hasPendingOperation || voice || model.attachmentImportCount > 0)
                    }
                }
                if model.supportsGeneration || !model.history.isEmpty || state.store != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            if !model.history.isEmpty {
                                Section {
                                    AccessoryButton("Conversations", systemImage: "arrow.right") { model.reloadHistory(); history = true }
                                        .disabled(model.hasPendingOperation)
                                }
                            }
                            if model.conversation.revision > 0 {
                                Section("Current conversation") {
                                    AccessoryButton(model.conversation.isPinned ? "Unpin" : "Pin", systemImage: model.conversation.isPinned ? "pin.slash" : "pin") {
                                        model.setOrganization(model.conversation, pinned: !model.conversation.isPinned)
                                    }.disabled(model.active || model.hasPendingOperation)
                                    AccessoryButton(model.conversation.isArchived ? "Restore" : "Archive", systemImage: "archivebox") {
                                        model.setOrganization(model.conversation, archived: !model.conversation.isArchived)
                                    }.disabled(model.active || model.hasPendingOperation)
                                    Button(role: .destructive) {
                                        if model.persist() { deletingConversation = model.conversation }
                                    } label: { AccessoryLabel("Delete", systemImage: "trash", destructive: true) }
                                        .disabled(model.active || model.hasPendingOperation)
                                }
                            }
                            Section {
                                AccessoryButton("AI settings", systemImage: "sparkles") { readAloud.stop(); aiSettings = true }
                                    .disabled(model.active || model.hasPendingOperation)
                            }
                        } label: { Label("More", systemImage: "ellipsis") }.disabled(voice || model.attachmentImportCount > 0)
                    }
                }
            }.navigationDestination(isPresented: $history) { AgentHistoryView(model: model) { value in if value.revision > 0 { model.open(value.id) }; history = false } }
            .modifier(AgentAttachmentPicker(model: model, importer: attachmentImporter, source: $attachmentSource, presented: $attachmentPickerPresented))
            .sheet(isPresented: $aiSettings) {
                NavigationStack { AgentSettingsView().toolbar { ToolbarItem(placement: .cancellationAction) {
                    Button { aiSettings = false } label: { Image(systemName: "xmark") }.accessibilityLabel("Close AI settings")
                        .disabled(model.hasPendingOperation || state.agentControlsModel?.hasPending == true)
                } } }.environment(state).appAppearance(state.appearance)
                    .interactiveDismissDisabled(model.hasPendingOperation || state.agentControlsModel?.hasPending == true)
            }
            .sheet(item: $feedbackEditing) { value in
                if let feedbackLibrary {
                    NavigationStack { AgentFeedbackEditor(library: feedbackLibrary, feedback: value) }.environment(state).appAppearance(state.appearance)
                }
            }
            .sheet(item: $details) { message in NavigationStack { Form {
                Group {
                LabeledContent("Runtime", value: "On-device")
                LabeledContent("Received", value: message.createdAt.formatted())
                LabeledContent("Response time", value: message.elapsedSeconds.map { String(format: "%.1f s", $0) } ?? "Unavailable")
                LabeledContent("First text", value: message.firstTextSeconds.map { String(format: "%.1f s", $0) } ?? "Unavailable")
                Text(message.contextSummary ?? "Context measurements unavailable")
                if let diagnostics = message.diagnostics {
                    LabeledContent("Records included", value: String(diagnostics.included))
                    LabeledContent("Records not included", value: String(diagnostics.omitted))
                    if !diagnostics.unavailable.isEmpty { Text("Unavailable: " + diagnostics.unavailable.map(\.title).joined(separator: ", ")) }
                    if let failure = diagnostics.failure { LabeledContent("Result", value: failure.title) }
                    DisclosureGroup("Diagnostics") {
                        LabeledContent("Prompt version", value: diagnostics.promptVersion)
                        LabeledContent("Retrieval version", value: diagnostics.retrievalVersion)
                        LabeledContent("Input characters", value: String(diagnostics.inputCharacters))
                    }
                }
                Text("Generated text cannot change your records. Only an explicit review and saved receipt can do that.")
                }.listRowBackground(AppTheme.surface)
            }.contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden).background(AppTheme.canvas).navigationTitle("Response details").toolbar { ToolbarItem(placement: .confirmationAction) { ToolbarSaveAction(title: "Done") { details = nil } } } }.appAppearance(state.appearance) }
            .alert("Delete this conversation?", isPresented: Binding(get: { deletingConversation != nil }, set: { if !$0 { deletingConversation = nil } })) {
                Button("Cancel", role: .cancel) { deletingConversation = nil }
                Button("Delete conversation", role: .destructive) {
                    if let value = deletingConversation { model.delete(value) }; deletingConversation = nil
                }
            } message: { Text("Deletes its messages and draft on this iPhone. Saved pieces, outfits and plans stay.") }
            .onDisappear { readAloud.stop(); if !attachmentPickerPresented { attachmentImporter.cancel() } }
            .onChange(of: scenePhase) { _, phase in if phase != .active { readAloud.stop() }; if phase == .background { attachmentImporter.cancel() } }
            .onChange(of: model.conversation.id) { _, _ in readAloud.stop() }
            .onChange(of: model.active) { _, active in if active { readAloud.stop() } }
            .onChange(of: voice) { _, recording in if recording { readAloud.stop() } }
            .onAppear { if automaticallyFocusComposer && model.supportsGeneration && model.conversation.messages.isEmpty && !didFocus { didFocus = true; focused = true } }
    }
    private var isNewConversation: Bool {
        model.supportsGeneration && model.conversation.messages.isEmpty && (model.conversation.proposals ?? []).isEmpty
    }

    private var emptyChat: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: AppSpacing.section) {
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                    if model.hasPendingOperation || model.error != nil {
                        Button("Retry operation") { model.retryPending() }.frame(minHeight: AppControlMetrics.minimumTarget)
                    }
                    Text("What would you like to wear?").font(.title2.weight(.medium))
                        .multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
                }.padding(.horizontal, AppSpacing.screen)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }.scrollIndicators(.hidden)
        }
    }

    private var suggestions: some View {
        VStack(spacing: AppSpacing.xSmall) {
            suggestion("Tonight’s look", symbol: "moon.stars")
            suggestion("Plan my week", symbol: "calendar")
            suggestion("Rediscover unworn pieces", symbol: "sparkles")
        }.padding(.horizontal, AppSpacing.section)
    }

    private func suggestion(_ title: String, symbol: String) -> some View {
        Button { model.updateDraft(title); focused = true } label: {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: symbol).foregroundStyle(AppTheme.controlIcon)
                    .frame(width: AppControlMetrics.disclosureLane).accessibilityHidden(true)
                Text(title).foregroundStyle(AppTheme.ink).multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }.font(AppTypography.body).frame(maxWidth: .infinity, minHeight: AppControlMetrics.minimumTarget)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(!model.canGenerate)
    }

    @ViewBuilder private func messageRow(_ message: AgentMessage) -> some View {
        if message.role == .user {
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
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                AgentMarkdownBody(source: AgentMarkdownPolicy.conversationalText(message.source))
                if message.isActive {
                    AgentWorkingIndicator(
                        title: message.status == .stopping ? "Stopping…" : model.slow ? "Still working…" : message.source.isEmpty ? "Thinking…" : "Writing…",
                        animates: message.status != .stopping)
                } else {
                    if message.status != .complete {
                        Text("Incomplete response").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }
                    if let reason = message.failureReason { Text(reason).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                    responseActions(message)
                    if readAloud.errorMessageID == message.id, let error = readAloud.error {
                        Text(error).font(AppTypography.supporting).foregroundStyle(AppTheme.error)
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func responseActions(_ message: AgentMessage) -> some View {
        let reading = readAloud.messageID == message.id
        let hasText = !message.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return HStack(spacing: 0) {
            Button { copy(message, markdown: false) } label: {
                responseIcon(copied == message.id ? "checkmark" : "square.on.square")
            }.accessibilityLabel(copied == message.id ? "Response copied" : "Copy response").disabled(!hasText)
            Button { rate(message, rating: .helpful) } label: {
                responseIcon(reaction(message)?.rating == .helpful ? "hand.thumbsup.fill" : "hand.thumbsup")
            }.accessibilityLabel("Helpful response").accessibilityValue(reaction(message)?.rating == .helpful ? "Selected" : "Not selected")
                .disabled(!hasText || model.active || model.hasPendingOperation)
            Button { rate(message, rating: .notHelpful) } label: {
                responseIcon(reaction(message)?.rating == .notHelpful ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }.accessibilityLabel("Not helpful").accessibilityValue(reaction(message)?.rating == .notHelpful ? "Selected" : "Not selected")
                .disabled(!hasText || model.active || model.hasPendingOperation)
            Button { readAloud.toggle(message) } label: {
                responseIcon(reading ? "stop.circle" : "speaker.wave.2")
            }.accessibilityLabel(reading ? "Stop reading" : "Read aloud").disabled(!hasText)
            Menu {
                Section(AgentChatTimestamp.label(for: message.createdAt)) {
                    AccessoryButton(reading ? "Stop reading" : "Read aloud", systemImage: reading ? "stop.circle" : "speaker.wave.2") { readAloud.toggle(message) }.disabled(!hasText)
                    AccessoryButton("Copy Markdown", systemImage: "doc.text") { copy(message, markdown: true) }.disabled(!hasText)
                }
                Section("Response") {
                    if message.id == model.conversation.messages.last?.id {
                        AccessoryButton("Try again", systemImage: "arrow.clockwise") { readAloud.stop(); model.send(retrying: message.id) }.disabled(!model.canGenerate)
                    }
                    AccessoryButton("Report a problem", systemImage: "flag") { editFeedback(message, report: true) }
                        .disabled(model.active || model.hasPendingOperation)
                    AccessoryButton("Response details", systemImage: "info.circle") { readAloud.stop(); details = message }
                }
            } label: { responseIcon("ellipsis") }.accessibilityLabel("Response options")
        }.buttonStyle(.plain).padding(.leading, -AppSpacing.medium)
    }

    private func reaction(_ message: AgentMessage) -> AgentFeedback? {
        message.feedback?.first { $0.attemptID == message.attemptID }
    }
    private func feedbackValue(_ message: AgentMessage) -> AgentFeedback {
        reaction(message) ?? AgentFeedback(conversationID: model.conversation.id, messageID: message.id, attemptID: message.attemptID, diagnostics: message.diagnostics)
    }
    private func rate(_ message: AgentMessage, rating: AgentFeedbackRating) {
        var value = feedbackValue(message)
        if value.rating == rating {
            if !value.isReport && value.comment.isEmpty && value.reasons.isEmpty { _ = model.saveFeedback(value, removing: true); return }
            value.rating = nil
        } else { value.rating = rating }
        value.updatedAt = Date()
        if model.saveFeedback(value), rating == .notHelpful, value.rating != nil { editFeedback(message, report: false) }
    }
    private func editFeedback(_ message: AgentMessage, report: Bool) {
        do {
            readAloud.stop()
            let library = try AgentFeedbackLibrary(agent: model, controls: state.agentControlsModel)
            var value = feedbackValue(model.conversation.messages.first { $0.id == message.id } ?? message)
            if report { value.isReport = true }
            feedbackLibrary = library; feedbackEditing = value
        } catch { model.error = "Feedback couldn’t load. Your response is retained. Try again." }
    }

    private func responseIcon(_ name: String) -> some View {
        Image(systemName: name).font(.system(size: 16, weight: .regular)).foregroundStyle(AppTheme.controlIcon)
            .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
            .contentShape(Rectangle())
    }

    private var canSend: Bool {
        model.canGenerate && (!model.conversation.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !(model.conversation.draftAttachments ?? []).isEmpty)
    }

    private var composer: some View {
        composerSurface
            .padding(.horizontal, AppSpacing.large).padding(.bottom, AppSpacing.small)
    }

    private var composerContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            if voice {
                AgentVoiceView(model: model, isPresented: $voice)
            } else {
            if !(model.conversation.draftAttachments ?? []).isEmpty || !attachmentImporter.pending.isEmpty {
                AgentAttachmentStrip(attachments: model.conversation.draftAttachments ?? [], pending: attachmentImporter.pending, order: attachmentImporter.order,
                                     remove: model.removeAttachment, cancelImport: attachmentImporter.remove, locked: model.active || model.hasPendingOperation)
            }
            TextField("Ask Agent…", text: Binding(get: { model.conversation.draft }, set: model.updateDraft), axis: .vertical)
                .lineLimit(1...6).focused($focused).padding(.horizontal, AppSpacing.xSmall)
                .accessibilityLabel("Message Agent")
            HStack(spacing: AppSpacing.small) {
                Menu {
                    ForEach(AgentAttachmentSource.allCases) { source in
                        AccessoryButton(source.rawValue, systemImage: source.icon) {
                            readAloud.stop(); focused = false; attachmentSource = source
                        }
                    }
                } label: { Image(systemName: "plus").frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget) }
                    .accessibilityLabel("Add camera, photo or file").disabled(!model.supportsGeneration || model.active || model.hasPendingOperation || attachmentImporter.count >= AgentAttachment.maximumCount || state.agentControlsModel?.hasPending == true)
                Spacer(minLength: AppSpacing.small)
                if AgentVoiceModel.isSupported {
                    Button { readAloud.stop(); focused = false; voice = true } label: { Image(systemName: "mic").frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget) }.accessibilityLabel("Voice input").disabled(model.active || model.hasPendingOperation || model.attachmentImportCount > 0)
                }
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
            }
        }.padding(AppSpacing.medium)
    }
    @ViewBuilder private var composerSurface: some View {
        if #available(iOS 26, *), !reduceTransparency, contrast != .increased {
            composerContent
                .glassEffect(.regular.interactive(!reduceMotion), in: RoundedRectangle(cornerRadius: AppRadius.composer))
        } else {
            composerContent.background {
                RoundedRectangle(cornerRadius: AppRadius.composer).fill(AppTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.composer).stroke(contrast == .increased ? AppTheme.controlBoundary : AppTheme.divider, lineWidth: 1))
            }
        }
    }

    private func copy(_ message: AgentMessage, markdown: Bool) {
        let source = AgentMarkdownPolicy.conversationalText(message.source)
        let value = markdown ? (message.status == .complete ? "" : "Incomplete response\n\n") + source : AgentMarkdownPolicy.plainText(source, incomplete: message.status != .complete)
        UIPasteboard.general.string = value
        if UIPasteboard.general.string == value { copied = message.id; UIAccessibility.post(notification: .announcement, argument: "Response copied") }
    }
}
struct AgentAvailabilityContent: View {
    let availability: OutfitSuggestionAvailability
    let recheck: () -> Void
    var fillsPage = false
    var showsActions = true
    var retainedDraft = ""
    private var title: String {
        switch availability {
        case .unsupported: "Agent isn’t supported on this iPhone"
        case .intelligenceOff: "Turn on Apple Intelligence"
        case .preparing: "Agent isn’t ready yet"
        case .localeUnavailable: "Agent isn’t available in this language"
        case .awaitingQualification, .available: "On-device Agent isn’t enabled yet"
        }
    }
    var body: some View {
        if fillsPage {
            if availability == .preparing {
                CenteredPageContent {
                    AppEmptyState(LocalizedStringKey(title), systemImage: "sparkle", description: Text(availability.message), fillsAvailableSpace: false)
                    if !retainedDraft.isEmpty { Text(retainedDraft).textSelection(.enabled) }
                    Button(action: recheck) { Text("Check again").frame(minHeight: 44).contentShape(Rectangle()) }
                }
            } else {
                EmptyStatePage(title: LocalizedStringKey(title), systemImage: "sparkle",
                               description: Text(availability.message), detail: retainedDraft.isEmpty ? nil : retainedDraft)
            }
        } else {
            VStack(spacing: 20) {
                AppEmptyState(LocalizedStringKey(title), systemImage: "sparkle", description: Text(availability.message), fillsAvailableSpace: false)
                if showsActions && availability == .preparing { Button(action: recheck) { Text("Check again").frame(minHeight: 44).contentShape(Rectangle()) } }
            }
        }
    }
}

struct AgentHistoryView: View {
    @Bindable var model: AgentModel
    let open: (AgentConversation) -> Void
    @State private var selected: AgentConversation?
    @State private var filter: AgentHistoryFilter = .active
    private var conversations: [AgentConversation] { filter.conversations(in: model.history.map { $0.id == model.conversation.id ? model.conversation : $0 }) }
    @ViewBuilder private func status(_ value: AgentConversation) -> some View {
        switch AgentHistoryPresentation.status(value) {
        case .loading: ProgressView().controlSize(.mini).frame(width: 12).accessibilityLabel("Responding")
        case .complete: Circle().fill(Color.blue).frame(width: 7, height: 7).frame(width: 12).accessibilityLabel("Response complete")
        case .incomplete: Image(systemName: "exclamationmark.circle").font(.footnote).foregroundStyle(AppTheme.error).frame(width: 12).accessibilityLabel("Response incomplete")
        case .draft: Image(systemName: AppSymbols.edit).font(.footnote).foregroundStyle(AppTheme.controlIcon).frame(width: 12).accessibilityLabel("Draft")
        case .empty: Color.clear.frame(width: 12, height: 7).accessibilityHidden(true)
        }
    }
    var body: some View {
        List {
            if let error = model.error { Text(error).foregroundStyle(AppTheme.error) }
            if model.hasPendingOperation || model.error != nil {
                Button(model.hasPendingOperation ? "Retry operation" : "Try again") {
                    if model.hasPendingOperation { model.retryPending() } else { model.reloadHistory() }
                }
            }
            if conversations.isEmpty {
                AppEmptyState(filter == .active ? "No active conversations" : filter == .pinned ? "No pinned conversations" : filter == .archived ? "No archived conversations" : "No conversations yet",
                              systemImage: filter == .pinned ? "pin" : filter == .archived ? "archivebox" : "bubble.left",
                              description: Text(filter == .pinned ? "Pin a conversation from its options to keep it close." : "Conversations stay on this iPhone."))
            }
            if filter != .active { Text(filter.rawValue).font(.subheadline).foregroundStyle(AppTheme.secondary).listRowBackground(Color.clear) }
            ForEach(conversations) { value in
                Button { open(value) } label: {
                    HStack(spacing: AppSpacing.small) {
                        status(value)
                        Text(value.title).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                            .lineLimit(1).truncationMode(.tail).frame(maxWidth: .infinity, alignment: .leading)
                        if value.isPinned { Image(systemName: "pin.fill").font(.footnote).foregroundStyle(AppTheme.controlIcon).accessibilityLabel("Pinned") }
                        if value.isArchived { Image(systemName: "archivebox").font(.footnote).foregroundStyle(AppTheme.controlIcon).accessibilityLabel("Archived") }
                        TimelineView(.periodic(from: .now, by: 60)) { timeline in
                            Text(AgentHistoryPresentation.time(value.updatedAt, relativeTo: timeline.date))
                                .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).fixedSize()
                        }
                        Image(systemName: "chevron.forward").font(AppTypography.disclosure).foregroundStyle(AppTheme.controlIcon).accessibilityHidden(true)
                    }.padding(.horizontal, AppSpacing.large).padding(.vertical, AppSpacing.medium)
                        .frame(minHeight: 60).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))

                }
                    .disabled(model.hasPendingOperation)
                    .contextMenu {
                        AccessoryButton("Open conversation", systemImage: "bubble.left") { open(value) }.disabled(model.active || model.hasPendingOperation)
                        AccessoryButton(value.isPinned ? "Unpin" : "Pin", systemImage: value.isPinned ? "pin.slash" : "pin") { model.setOrganization(value, pinned: !value.isPinned) }.disabled(model.active || model.hasPendingOperation)
                        AccessoryButton(value.isArchived ? "Restore" : "Archive", systemImage: "archivebox") { model.setOrganization(value, archived: !value.isArchived) }.disabled(model.active || model.hasPendingOperation)
                        Button(role: .destructive) { selected = value } label: { AccessoryLabel("Delete", systemImage: "trash", destructive: true) }.disabled(model.active || model.hasPendingOperation)
                    } preview: {
                        VStack(alignment: .leading, spacing: AppSpacing.medium) {
                            Text(value.title).font(AppTypography.section).lineLimit(2)
                            AgentMarkdownBody(source: AgentMarkdownPolicy.conversationalText(value.messages.last?.source ?? "No messages yet"))
                                .font(AppTypography.supporting).frame(maxHeight: 180, alignment: .top).clipped()
                        }.padding(AppSpacing.screen).frame(width: 280, alignment: .leading).background(AppTheme.surface)
                    }
                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: AppSpacing.screen, bottom: 4, trailing: AppSpacing.screen))
                    .swipeActions(allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) { selected = value }
                        Button(value.isArchived ? "Restore" : "Archive", systemImage: "archivebox") { model.setOrganization(value, archived: !value.isArchived) }.tint(AppTheme.secondary)
                    }.disabled(model.active || model.hasPendingOperation)
            }
        }.listStyle(.plain).contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden).background(AppTheme.canvas).navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button { model.newConversation(); open(model.conversation) } label: { Image(systemName: "square.and.pencil") }.accessibilityLabel("New conversation").disabled(model.active || model.hasPendingOperation) }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Show conversations", selection: $filter) {
                            ForEach(AgentHistoryFilter.allCases, id: \.self) { option in Text(option.rawValue).tag(option) }
                        }
                    } label: { Image(systemName: filter == .active ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill") }
                        .accessibilityLabel("Filter conversations").accessibilityValue(filter.rawValue)
                }

            }
            .alert("Delete this conversation?", isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } })) {
                Button("Cancel", role: .cancel) { selected = nil }
                Button("Delete conversation", role: .destructive) { if let selected { model.delete(selected) }; selected = nil }
            } message: { Text("Deletes this conversation, its draft and responses on this iPhone. Saved pieces, outfits and plans stay.") }
    }
}
