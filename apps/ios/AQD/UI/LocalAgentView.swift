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
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var context = false
    @State private var tools = false
    @State private var voice = false
    @State private var details: AgentMessage?
    @State private var copied: UUID?
    @State private var followsLatest = true
    @State private var didFocus = false
    @FocusState private var focused: Bool
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
                    ForEach(model.conversation.messages) { message in
                        messageRow(message).id(message.id)
                    }
                    ForEach(model.conversation.proposals ?? []) { proposal in
                        NavigationLink { AgentActionReviewView(model: model, id: proposal.id).secondaryPage() } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(proposal.action.title)
                                Text(proposal.status == .succeeded ? "Saved receipt available" : proposal.status.rawValue.capitalized + " · Review required").font(.footnote).foregroundStyle(AppTheme.secondary)
                            }.frame(minHeight: 44)
                        }
                    }
                    if !model.supportsGeneration {
                        AgentAvailabilityContent(availability: model.availability, recheck: model.recheckAvailability,
                                                 showsActions: false)
                        if !model.conversation.draft.isEmpty { Text("Your retained draft").font(AppTypography.section); Text(model.conversation.draft).textSelection(.enabled) }
                    }
                    Color.clear.frame(height: 1).id("latest").onAppear { followsLatest = true }.onDisappear { followsLatest = false }
                }.padding(20).disabled(voice)
            }.onChange(of: model.conversation.messages.last?.source) { _, _ in if followsLatest { proxy.scrollTo("latest", anchor: .bottom) } }
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
                ToolbarItem(placement: .topBarLeading) { Button { if !model.active && model.persist() { close() } } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Back").disabled(model.active || voice) }
                if model.supportsGeneration {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { model.newConversation(); focused = true } label: { Image(systemName: "square.and.pencil") }
                            .accessibilityLabel("New conversation").disabled(model.active || model.hasPendingOperation || voice)
                    }
                }
                if model.supportsGeneration || !model.history.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Section("Conversation") {
                                if !model.history.isEmpty {
                                    AccessoryButton("Conversations", systemImage: "bubble.left.and.bubble.right") { model.reloadHistory(); history = true }.disabled(model.active)
                                }
                                if model.conversation.revision > 0 {
                                    AccessoryButton(model.conversation.isPinned ? "Unpin conversation" : "Pin conversation", systemImage: model.conversation.isPinned ? "pin.slash" : "pin") {
                                        model.setOrganization(model.conversation, pinned: !model.conversation.isPinned)
                                    }.disabled(model.active || model.hasPendingOperation)
                                    AccessoryButton(model.conversation.isArchived ? "Restore conversation" : "Archive conversation", systemImage: "archivebox") {
                                        model.setOrganization(model.conversation, archived: !model.conversation.isArchived)
                                    }.disabled(model.active || model.hasPendingOperation)
                                    Button(role: .destructive) {
                                        if model.persist() { deletingConversation = model.conversation }
                                    } label: { Label("Delete conversation", systemImage: "trash").foregroundStyle(AppTheme.error) }
                                        .disabled(model.active || model.hasPendingOperation)
                                }
                            }
                            if model.supportsGeneration {
                                Section("Tools") {
                                    AccessoryButton("Manage context", systemImage: "tshirt") { context = true }
                                    AccessoryButton("Local tools", systemImage: "slider.horizontal.3") { state.reloadPieces(); state.reloadOutfits(); state.reloadThemes(); state.reloadPlanEntries(); tools = true }.disabled(model.active || model.hasPendingOperation)
                                }
                            }
                        } label: { Label("More", systemImage: "ellipsis") }.disabled(voice)
                    }
                }
            }.navigationDestination(isPresented: $history) { AgentHistoryView(model: model) { value in if value.revision > 0 { model.open(value.id) }; history = false } }
            .sheet(isPresented: $tools) { AgentActionComposerView(model: model).environment(state).appAppearance(state.appearance) }
            .sheet(isPresented: $context) { AgentContextView(model: model).environment(state).appAppearance(state.appearance) }
            .sheet(item: $details) { message in NavigationStack { Form {
                Group {
                LabeledContent("Runtime", value: "On-device")
                LabeledContent("Received", value: message.createdAt.formatted())
                LabeledContent("Response time", value: message.elapsedSeconds.map { String(format: "%.1f s", $0) } ?? "Unavailable")
                LabeledContent("First text", value: message.firstTextSeconds.map { String(format: "%.1f s", $0) } ?? "Unavailable")
                Text(message.contextSummary ?? "Context measurements unavailable")
                Text("Generated text cannot change your records. Only an explicit review and saved receipt can do that.")
                }.listRowBackground(AppTheme.surface)
            }.contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden).background(AppTheme.canvas).navigationTitle("Response details").toolbar { ToolbarItem(placement: .confirmationAction) { ToolbarSaveAction(title: "Done") { details = nil } } } }.appAppearance(state.appearance) }
            .alert("Delete this conversation?", isPresented: Binding(get: { deletingConversation != nil }, set: { if !$0 { deletingConversation = nil } })) {
                Button("Cancel", role: .cancel) { deletingConversation = nil }
                Button("Delete conversation", role: .destructive) {
                    if let value = deletingConversation { model.delete(value) }; deletingConversation = nil
                }
            } message: { Text("Deletes its messages and draft on this iPhone. Saved pieces, outfits and plans stay.") }
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
                Text(message.source).textSelection(.enabled)
                    .padding(.horizontal, AppSpacing.large).padding(.vertical, AppSpacing.medium)
                    .background(AppTheme.messageBubble, in: RoundedRectangle(cornerRadius: AppRadius.composer))
                    .accessibilityLabel("You: " + message.source)
            }.frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                AgentMarkdownBody(source: AgentMarkdownPolicy.conversationalText(message.source))
                if message.isActive {
                    HStack(spacing: AppSpacing.small) {
                        ProgressView()
                        if message.status == .stopping { Text("Stopping…") }
                        else if model.slow { Text("Still working…") }
                    }.font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(message.status == .stopping ? "Stopping response" : "Generating response")
                } else {
                    if message.status != .complete {
                        Text("Incomplete response").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }
                    if let reason = message.failureReason { Text(reason).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                    responseActions(message)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func responseActions(_ message: AgentMessage) -> some View {
        HStack(spacing: 0) {
            Button { copy(message, markdown: false) } label: {
                responseIcon(copied == message.id ? "checkmark" : "doc.on.doc")
            }.accessibilityLabel(copied == message.id ? "Response copied" : "Copy response")
            if message.id == model.conversation.messages.last?.id && model.canGenerate {
                Button { model.send(retrying: message.id) } label: { responseIcon("arrow.clockwise") }
                    .accessibilityLabel("Try response again")
            }
            Menu {
                AccessoryButton("Copy Markdown", systemImage: "doc.on.doc") { copy(message, markdown: true) }
                AccessoryButton("Response details", systemImage: "info.circle") { details = message }
            } label: { responseIcon("ellipsis") }.accessibilityLabel("Response options")
        }.buttonStyle(.plain)
    }

    private func responseIcon(_ name: String) -> some View {
        Image(systemName: name).font(AppTypography.supporting).foregroundStyle(AppTheme.controlIcon)
            .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
            .contentShape(Rectangle())
    }

    private var canSend: Bool {
        model.canGenerate && !model.conversation.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            if voice {
                AgentVoiceView(model: model, isPresented: $voice)
            } else {
            TextField("Ask Agent…", text: Binding(get: { model.conversation.draft }, set: model.updateDraft), axis: .vertical)
                .lineLimit(1...6).focused($focused).padding(.horizontal, AppSpacing.xSmall)
                .accessibilityLabel("Message Agent")
            HStack(spacing: AppSpacing.small) {
                Menu {
                    AccessoryButton("Context: " + (model.conversation.context.scope == .general ? "Without closet" : model.conversation.context.scope == .selected ? "Selected pieces" : "My closet"), systemImage: "tshirt") { context = true }
                    AccessoryButton("Local tools", systemImage: "slider.horizontal.3") { tools = true }
                        .disabled(model.active || model.hasPendingOperation)
                } label: { Image(systemName: "plus").frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget) }
                    .accessibilityLabel("Context and tools")
                Spacer(minLength: AppSpacing.small)
                if AgentVoiceModel.isSupported {
                    Button { focused = false; voice = true } label: { Image(systemName: "mic").frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget) }.accessibilityLabel("Voice input").disabled(model.active || model.hasPendingOperation)
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
            .background { composerBackground }
            .padding(.horizontal, AppSpacing.large).padding(.bottom, AppSpacing.small)
    }
    @ViewBuilder private var composerBackground: some View {
        if #available(iOS 26, *), !reduceTransparency, contrast != .increased {
            RoundedRectangle(cornerRadius: AppRadius.composer).fill(.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.composer))
        } else {
            RoundedRectangle(cornerRadius: AppRadius.composer).fill(AppTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: AppRadius.composer).stroke(contrast == .increased ? AppTheme.controlBoundary : AppTheme.divider, lineWidth: 1))
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
    private var conversations: [AgentConversation] { filter.conversations(in: model.history) }
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
                    HStack(spacing: AppSpacing.medium) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(value.title).foregroundStyle(AppTheme.ink)
                            Text(value.updatedAt, style: .date).font(.footnote).foregroundStyle(AppTheme.secondary)
                        }
                        Spacer(minLength: 8)
                        if value.isArchived { Image(systemName: "archivebox").foregroundStyle(AppTheme.controlIcon).accessibilityLabel("Archived") }
                        if value.isPinned { Image(systemName: "pin.fill").foregroundStyle(AppTheme.controlIcon).accessibilityLabel("Pinned") }
                    }
                }
                    .disabled(model.hasPendingOperation)
                    .contextMenu {
                        AccessoryButton("Open conversation", systemImage: "bubble.left") { open(value) }.disabled(model.active || model.hasPendingOperation)
                        AccessoryButton(value.isPinned ? "Unpin" : "Pin", systemImage: value.isPinned ? "pin.slash" : "pin") { model.setOrganization(value, pinned: !value.isPinned) }.disabled(model.active || model.hasPendingOperation)
                        AccessoryButton(value.isArchived ? "Restore" : "Archive", systemImage: "archivebox") { model.setOrganization(value, archived: !value.isArchived) }.disabled(model.active || model.hasPendingOperation)
                        Button(role: .destructive) { selected = value } label: { Label("Delete conversation", systemImage: "trash").foregroundStyle(AppTheme.error) }.disabled(model.active || model.hasPendingOperation)
                    } preview: {
                        VStack(alignment: .leading, spacing: AppSpacing.medium) {
                            Text(value.title).font(AppTypography.section)
                            Text(value.messages.last?.source ?? "No messages yet").font(AppTypography.supporting).lineLimit(6)
                        }.padding(AppSpacing.screen).frame(width: 280, alignment: .leading).background(AppTheme.surface)
                    }
                    .swipeActions(allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) { selected = value }
                        Button(value.isArchived ? "Restore" : "Archive", systemImage: "archivebox") { model.setOrganization(value, archived: !value.isArchived) }.tint(AppTheme.secondary)
                    }.disabled(model.active || model.hasPendingOperation)
            }
        }.contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden).background(AppTheme.canvas).navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Show conversations", selection: $filter) {
                            ForEach(AgentHistoryFilter.allCases, id: \.self) { option in Text(option.rawValue).tag(option) }
                        }
                    } label: { Image(systemName: filter == .active ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill") }
                        .accessibilityLabel("Filter conversations").accessibilityValue(filter.rawValue)
                }
                ToolbarItem(placement: .topBarTrailing) { Button { model.newConversation(); open(model.conversation) } label: { Image(systemName: "square.and.pencil") }.accessibilityLabel("New conversation").disabled(model.active || model.hasPendingOperation) }
            }
            .alert("Delete this conversation?", isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } })) {
                Button("Cancel", role: .cancel) { selected = nil }
                Button("Delete conversation", role: .destructive) { if let selected { model.delete(selected) }; selected = nil }
            } message: { Text("Deletes this conversation, its draft and responses on this iPhone. Saved pieces, outfits and plans stay.") }
    }
}
