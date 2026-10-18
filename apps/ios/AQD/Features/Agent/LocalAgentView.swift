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
                else if phase == .background { state.agentModel?.suspend() }
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
    @State private var reviewingID: UUID?
    @Environment(\.scenePhase) private var scenePhase
    @State private var details: AgentMessage?
    @State private var capabilities = false
    @State private var feedbackEditing: AgentFeedback?
    @State private var feedbackLibrary: AgentFeedbackLibrary?
    @State private var readAloud = AgentReadAloud()
    @State private var followsLatest = true
    @State private var pinnedTurn: UUID?
    @State private var chatScrollPhase = ScrollPhase.idle
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
        GeometryReader { geometry in
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.section) {
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                    if model.hasPendingOperation || model.error != nil {
                        Button("Retry operation") { model.retryPending() }.frame(minHeight: AppControlMetrics.minimumTarget)
                    }
                    messageRows(in: 0..<(latestUserIndex ?? 0))
                    if let index = latestUserIndex, model.conversation.messages.indices.contains(index) {
                        timestamp(for: model.conversation.messages[index], after: index > 0 ? model.conversation.messages[index - 1].createdAt : nil)
                    }
                    VStack(alignment: .leading, spacing: AppSpacing.section) {
                        if let index = latestUserIndex {
                            messageBlock(model.conversation.messages[index])
                            messageRows(in: (index + 1)..<model.conversation.messages.count)
                        } else { messageRows(in: 0..<model.conversation.messages.count) }
                        unlinkedProposalRows
                        if !model.supportsGeneration {
                            AgentAvailabilityContent(availability: model.availability, recheck: model.recheckAvailability,
                                                     showsActions: false)
                            if !model.conversation.draft.isEmpty { Text("Your retained draft").font(AppTypography.section); Text(model.conversation.draft).textSelection(.enabled) }
                        }
                        Color.clear.frame(height: 1).id("latest")
                            .onGeometryChange(for: Bool.self) { marker in
                                let frame = marker.frame(in: .named("agent-message-viewport"))
                                return frame.maxY >= 0 && frame.minY <= geometry.size.height
                            } action: { visible in followsLatest = visible }
                    }
                    .frame(maxWidth: .infinity, minHeight: max(0, geometry.size.height - 2 * AppSpacing.screen), alignment: .top)
                    .id(latestUserIndex.map { model.conversation.messages[$0].id } ?? model.conversation.id)
                }.padding(AppSpacing.screen)
            }.coordinateSpace(name: "agent-message-viewport")
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture { focused = false }
                .defaultScrollAnchor(.bottom, for: .initialOffset)
                .modifier(AgentChatScrollEdges())
                .id(model.conversation.id)
                .onAppear {
                    followsLatest = true
                    if model.active, let index = latestUserIndex {
                        let id = model.conversation.messages[index].id
                        pinnedTurn = id; proxy.scrollTo(id, anchor: .top)
                    } else { pinnedTurn = nil; proxy.scrollTo("latest", anchor: .bottom) }
                }
                .onChange(of: model.conversation.messages.last?.attemptID) { _, _ in
                    // Sending scrolls the new question to the top once; the reply then streams below it without moving it.
                    guard model.active, let index = latestUserIndex else { return }
                    let id = model.conversation.messages[index].id
                    pinnedTurn = id
                    withAnimation(reduceMotion ? nil : AQDMotion.reflow) { proxy.scrollTo(id, anchor: .top) }
                }
                .onChange(of: model.conversation.messages.last?.toolSteps?.count) { _, _ in
                    if pinnedTurn == nil && followsLatest && chatScrollPhase == .idle { proxy.scrollTo("latest", anchor: .bottom) }
                }
                .onChange(of: model.conversation.messages.last?.source) { _, _ in
                    if pinnedTurn == nil && followsLatest && chatScrollPhase == .idle { proxy.scrollTo("latest", anchor: .bottom) }
                }
                .onScrollPhaseChange { _, phase in
                    chatScrollPhase = phase
                    if phase == .interacting { pinnedTurn = nil }
                }
        }
        }
            }
        }.background(AppTheme.canvas).navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                if model.supportsGeneration {
                    VStack(spacing: AppSpacing.small) {
                        if isNewConversation && model.conversation.draft.isEmpty && (model.conversation.draftAttachments ?? []).isEmpty {
                            AgentSuggestionStrip(titles: suggestionTitles, enabled: model.canGenerate, send: sendSuggestion)
                        }
                        AgentComposerView(model: model, importer: attachmentImporter, attachmentSource: $attachmentSource, focused: $focused)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { if !model.active && model.persist() { close() } } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Back").disabled(model.active || model.attachmentImportCount > 0) }
                if model.supportsGeneration {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { model.newConversation(); focused = true } label: { Image(systemName: "square.and.pencil") }
                            .accessibilityLabel("New conversation").disabled(model.active || model.hasPendingOperation || model.attachmentImportCount > 0)
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
                                }
                                Section {
                                    DestructiveMenuButton("Delete") { if model.persist() { deletingConversation = model.conversation } }
                                        .disabled(model.active || model.hasPendingOperation)
                                }
                            }
                            Section {
                                AccessoryButton("Settings", systemImage: "gearshape") { aiSettings = true }
                                    .disabled(model.active || model.hasPendingOperation)
                                AccessoryButton("Help", systemImage: "questionmark.circle") { capabilities = true }
                            }
                        } label: { Label("More", systemImage: "ellipsis") }.disabled(model.attachmentImportCount > 0)
                    }
                }
            }.navigationDestination(isPresented: $history) { AgentHistoryView(model: model) { value in if value.revision > 0 { model.open(value.id) }; history = false } }
            .modifier(AgentAttachmentPicker(model: model, importer: attachmentImporter, source: $attachmentSource, presented: $attachmentPickerPresented))
            .sheet(isPresented: $aiSettings) {
                NavigationStack { AgentSettingsView().toolbar { ToolbarItem(placement: .cancellationAction) {
                    Button { aiSettings = false } label: { Image(systemName: "xmark") }.accessibilityLabel("Close settings")
                        .disabled(model.hasPendingOperation || state.agentControlsModel?.hasPending == true)
                } } }.environment(state).appAppearance(state.appearance)
                    .interactiveDismissDisabled(model.hasPendingOperation || state.agentControlsModel?.hasPending == true)
            }
                        .sheet(isPresented: Binding(get: { reviewingID != nil }, set: { if !$0 { reviewingID = nil } })) {
                if let id = reviewingID {
                    NavigationStack {
                        AgentActionReviewView(model: model, id: id).toolbar { ToolbarItem(placement: .cancellationAction) {
                            Button { reviewingID = nil } label: { Image(systemName: "xmark") }.accessibilityLabel("Close review")
                        } }
                    }.environment(state).appAppearance(state.appearance).tint(AppTheme.ink)
                        .interactiveDismissDisabled(model.hasPendingOperation)
                }
            }
            .sheet(isPresented: $capabilities) {
                AgentCapabilitiesSheet(enabled: model.canGenerate, choose: { capabilities = false; sendSuggestion($0.prompt) }, close: { capabilities = false })
                    .environment(state).appAppearance(state.appearance)
            }
            .sheet(item: $feedbackEditing) { value in
                if let feedbackLibrary {
                    NavigationStack { AgentFeedbackEditor(library: feedbackLibrary, feedback: value) }.environment(state).appAppearance(state.appearance)
                }
            }
            .sheet(item: $details) { message in NavigationStack { Form {
                Group {
                if let reason = message.failureReason { Text(reason).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).textSelection(.enabled) }
                LabeledContent("Runtime", value: "On-device")
                LabeledContent("Received", value: message.createdAt.displayTimestamp())
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
            .deleteConfirmation("conversation", isPresented: Binding(get: { deletingConversation != nil }, set: { if !$0 { deletingConversation = nil } }),
                                message: "Deletes its messages and draft on this iPhone. Saved pieces, outfits and plans stay.",
                                cancel: { deletingConversation = nil }) {
                if let value = deletingConversation { model.delete(value) }; deletingConversation = nil
            }
            .onDisappear { if !attachmentPickerPresented { attachmentImporter.cancel() } }
            .onChange(of: scenePhase) { _, phase in if phase == .background { attachmentImporter.cancel() } }
            .onChange(of: model.conversation.messages.last?.status) { _, _ in if !history { model.markCurrentRead() } }
            .onChange(of: model.conversation.id) { _, _ in if !history { model.markCurrentRead() } }
            .onChange(of: history) { _, showing in if !showing { model.markCurrentRead() } }
            .onAppear { model.markCurrentRead(); if automaticallyFocusComposer && model.supportsGeneration && model.conversation.messages.isEmpty && !didFocus { didFocus = true; focused = true } }
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
                    VStack(spacing: AppSpacing.xSmall) {
                        Text(greeting).font(.title.weight(.semibold))
                        Text("Ready when you are.").font(.title3).foregroundStyle(AppTheme.secondary)
                    }.multilineTextAlignment(.center).accessibilityElement(children: .combine).accessibilityAddTraits(.isHeader)
                }.padding(.horizontal, AppSpacing.screen)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }.scrollIndicators(.hidden).scrollDismissesKeyboard(.interactively).onTapGesture { focused = false }
        }
    }

    /// Time-of-day welcome by first name; the name never leaves the device.
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let salutation = hour < 5 ? "Hello" : hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
        let first = state.localIdentity?.name?.split(separator: " ").first.map(String.init)
        return first.map { "\(salutation), \($0)" } ?? salutation
    }

    private var suggestionTitles: [String] {
        guard !state.ownedPieces.isEmpty else { return ["How do I start my closet?", "What can you help with?"] }
        var titles = [Calendar.current.component(.hour, from: Date()) >= 16 ? "Tonight’s look" : "What should I wear today?"]
        if !state.outfits.isEmpty { titles += ["Plan my week", "Make a theme from my outfits"] }
        return titles + ["Rediscover unworn pieces"]
    }

    /// A new piece from a photo is reviewed in the Closet editor; every other proposal opens the review sheet.
    private func openReview(_ proposal: AgentActionProposal) {
        if case .piece(let change) = proposal.action, change.isNewPiece, proposal.status == .proposed { model.openAddedPieceEditor(proposal, in: state) }
        else { reviewingID = proposal.id }
    }

    private func sendSuggestion(_ title: String) {
        guard model.canGenerate else { return }
        model.updateDraft(title); model.send()
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

    /// Turns a suggested look into an outfit draft the owner reviews and applies like any other Agent change.
    private func saveLook(_ pieceIDs: [UUID], message: AgentMessage) {
        let request = AgentMutationRequest(kind: .createOutfit, name: "Suggested look", pieceIDs: pieceIDs)
        guard let action = try? request.prepare(ownerID: model.conversation.ownerID, pieces: state.ownedPieces) else {
            model.error = "That look can’t be saved right now. Some pieces may be unavailable."; return
        }
        model.propose(action, attemptID: message.attemptID)
    }

    private func canRegenerate(_ message: AgentMessage) -> Bool {
        message.role == .assistant && message.id == model.conversation.messages.last?.id && model.canGenerate
    }

    private func messageBlock(_ message: AgentMessage) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            AgentMessageRow(message: message, slow: model.slow, canRegenerate: canRegenerate(message),
                            rating: reaction(message)?.rating, reading: readAloud.messageID == message.id, canRate: !model.active && !model.hasPendingOperation,
                            retry: { readAloud.stop(); model.send(retrying: message.id) }, showDetails: { readAloud.stop(); details = message },
                            rate: { rate(message, rating: $0) }, toggleRead: { readAloud.toggle(message) }, report: { editFeedback(message, report: true) },
                            saveLook: model.canGenerate ? { saveLook($0, message: message) } : nil,
                            iterate: model.canGenerate && message.id == model.conversation.messages.last?.id ? { sendSuggestion($0) } : nil)
            ForEach(model.conversation.proposals(for: message)) { proposal in
                AgentProposalCard(proposal: proposal, locked: model.hasPendingOperation, pieces: state.ownedPieces, review: { openReview(proposal) }, dismiss: { model.cancelProposal(proposal.id) },
                                 tryAnother: model.canGenerate && message.id == model.conversation.messages.last?.id ? { sendSuggestion("Show me a different option") } : nil)
            }
        }
    }

    private var latestUserIndex: Int? { model.conversation.messages.lastIndex { $0.role == .user } }

    @ViewBuilder private func timestamp(for message: AgentMessage, after previous: Date?) -> some View {
        if AgentChatTimestamp.startsGroup(message.createdAt, after: previous) {
            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                Text(AgentChatTimestamp.label(for: message.createdAt, relativeTo: timeline.date))
                    .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, AppSpacing.xSmall)
            }
        }
    }
    private func messageRows(in range: Range<Int>) -> some View {
        let messages = model.conversation.messages
        return ForEach(Array(messages.enumerated()).filter { range.contains($0.offset) }, id: \.element.id) { index, message in
            timestamp(for: message, after: index > 0 ? messages[index - 1].createdAt : nil)
            messageBlock(message).id(message.id)
        }
    }
    private var unlinkedProposalRows: some View {
        ForEach(model.conversation.unlinkedProposals) { proposal in
            AgentProposalCard(proposal: proposal, locked: model.hasPendingOperation, pieces: state.ownedPieces, review: { openReview(proposal) }, dismiss: { model.cancelProposal(proposal.id) })
        }
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
        case .complete:
            Circle().fill(model.isUnread(value) ? AppTheme.unreadIndicator : AppTheme.secondary.opacity(0.35)).frame(width: 7, height: 7).frame(width: 12)
                .accessibilityLabel(model.isUnread(value) ? "Unread response" : "Read")
        case .empty: Color.clear.frame(width: 12, height: 7).accessibilityHidden(true)
        case .incomplete: Image(systemName: "exclamationmark.circle").font(.footnote).foregroundStyle(AppTheme.error).frame(width: 12).accessibilityLabel("Response incomplete")
        case .draft: Image(systemName: AppSymbols.edit).font(.footnote).foregroundStyle(AppTheme.controlIcon).frame(width: 12).accessibilityLabel("Draft")
        }
    }
    var body: some View {
        List {
            if let error = model.error { Text(error).foregroundStyle(AppTheme.error).listRowSeparator(.hidden) }
            if model.hasPendingOperation || model.error != nil {
                Button(model.hasPendingOperation ? "Retry operation" : "Try again") {
                    if model.hasPendingOperation { model.retryPending() } else { model.reloadHistory() }
                }.listRowSeparator(.hidden)
            }
            if filter != .active && !conversations.isEmpty { Text(filter.rawValue).font(.subheadline).foregroundStyle(AppTheme.secondary).listRowBackground(Color.clear).listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: AppSpacing.screen, bottom: 4, trailing: AppSpacing.screen)) }
            ForEach(conversations) { value in
                Button { open(value) } label: {
                    HStack(spacing: AppSpacing.small) {
                        status(value)
                        Text(value.title).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                            .truncated().frame(maxWidth: .infinity, alignment: .leading)
                        if value.isPinned { Image(systemName: "pin.fill").font(.footnote).foregroundStyle(AppTheme.controlIcon).accessibilityLabel("Pinned") }
                        if value.isArchived { Image(systemName: "archivebox").font(.footnote).foregroundStyle(AppTheme.controlIcon).accessibilityLabel("Archived") }
                        TimelineView(.periodic(from: .now, by: 60)) { timeline in
                            Text(AgentHistoryPresentation.time(value.updatedAt, relativeTo: timeline.date))
                                .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).fixedSize()
                        }
                        Image(systemName: "chevron.forward").font(AppTypography.disclosure).foregroundStyle(AppTheme.controlIcon).accessibilityHidden(true)
                    }.padding(.horizontal, AppSpacing.large).padding(.vertical, AppSpacing.medium)
                        .frame(minHeight: 60).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                }
                    .disabled(model.hasPendingOperation)
                    .contextMenu {
                        AccessoryButton("Open conversation", systemImage: "bubble.left") { open(value) }.disabled(model.active || model.hasPendingOperation)
                        AccessoryButton(value.isPinned ? "Unpin" : "Pin", systemImage: value.isPinned ? "pin.slash" : "pin") { model.setOrganization(value, pinned: !value.isPinned) }.disabled(model.active || model.hasPendingOperation)
                        AccessoryButton(value.isArchived ? "Restore" : "Archive", systemImage: "archivebox") { model.setOrganization(value, archived: !value.isArchived) }.disabled(model.active || model.hasPendingOperation)
                        Section { DestructiveMenuButton("Delete") { selected = value }.disabled(model.active || model.hasPendingOperation) }
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
                        // Same icon-and-label treatment for both; delete is the only red.
                        Button(role: .destructive) { selected = value } label: { Label("Delete", systemImage: "trash") }.tint(AppTheme.dangerFill)
                        Button { model.setOrganization(value, archived: !value.isArchived) } label: {
                            Label(value.isArchived ? "Restore" : "Archive", systemImage: value.isArchived ? "tray.and.arrow.up" : "archivebox")
                        }.tint(AppTheme.controlIcon)
                    }.disabled(model.active || model.hasPendingOperation)
            }
        }.listStyle(.plain).listRowSeparator(.hidden).listSectionSeparator(.hidden).contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden).background(AppTheme.canvas)
            .overlay {
                if conversations.isEmpty {
                    AppEmptyState(filter == .active ? "No active conversations" : filter == .pinned ? "No pinned conversations" : filter == .archived ? "No archived conversations" : "No conversations yet",
                                  systemImage: filter == .pinned ? "pin" : filter == .archived ? "archivebox" : "bubble.left",
                                  description: Text(filter == .pinned ? "Pin a conversation from its options to keep it close." : filter == .archived ? "Archive a conversation to tuck it away here." : "Conversations stay on this iPhone."))
                }
            }.navigationTitle("Conversations")
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
            .deleteConfirmation("conversation", isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } }),
                                message: "Deletes its messages and draft on this iPhone. Saved pieces, outfits and plans stay.",
                                cancel: { selected = nil }) { if let selected { model.delete(selected) }; selected = nil }
    }
}

/// Fade messages under the toolbar so its controls stay readable while the chat scrolls.
private struct AgentChatScrollEdges: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26, *) { content.scrollEdgeEffectStyle(.soft, for: .top) }
        else { content }
    }
}
