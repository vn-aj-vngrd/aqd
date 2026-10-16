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
        }.tint(AppTheme.ink).task { open() }.onDisappear { state.agentModel?.suspend() }
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
    @State private var context = false
    @State private var tools = false
    @State private var voice = false
    @State private var imageHelp = false
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
                    if model.conversation.messages.isEmpty && model.supportsGeneration {
                        Text("What would you like to wear?").font(.title).frame(maxWidth: .infinity).padding(.vertical, 40)
                        ForEach(["Tonight’s look", "Plan my week", "Rediscover unworn pieces", "Start with a piece"], id: \.self) { title in
                            Button(title) { model.updateDraft(title); focused = true }.frame(minHeight: 44)
                        }
                    }
                    ForEach(model.conversation.messages) { message in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(message.role == .user ? "You" : "Agent").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            if message.role == .user { Text(message.source).textSelection(.enabled) }
                            else {
                                AgentMarkdownBody(source: message.source)
                                if message.isActive {
                                    HStack { ProgressView(); Text(message.status == .stopping ? "Stopping…" : (model.slow ? "Still working…" : (message.source.isEmpty ? "Preparing response…" : "Writing response…"))) }.accessibilityElement(children: .combine)
                                } else {
                                    Text(message.status == .complete ? "Response complete · Nothing saved" : "\(message.status.rawValue.capitalized) · Incomplete response · Nothing saved").font(.footnote).foregroundStyle(AppTheme.secondary)
                                    if let reason = message.failureReason { Text(reason).font(.subheadline).foregroundStyle(AppTheme.secondary) }
                                    HStack {
                                        Button(copied == message.id ? "Copied" : "Copy") { copy(message, markdown: false) }.frame(minHeight: 44)
                                        Menu {
                                            Button("Copy Markdown") { copy(message, markdown: true) }
                                            Button("Response details") { details = message }
                                        } label: { Label("More", systemImage: "ellipsis").frame(minHeight: 44) }
                                        if message.id == model.conversation.messages.last?.id && model.canGenerate {
                                            Button("Try again") { model.send(retrying: message.id) }.frame(minHeight: 44)
                                        }
                                    }
                                }
                            }
                        }.id(message.id).frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
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
                }.padding(20)
            }.onChange(of: model.conversation.messages.last?.source) { _, _ in if followsLatest { proxy.scrollTo("latest", anchor: .bottom) } }
                .overlay(alignment: .bottomTrailing) { if !followsLatest { Button("Jump to latest") { followsLatest = true; proxy.scrollTo("latest", anchor: .bottom) }.frame(minHeight: 44).padding(12).background(AppTheme.surface, in: Capsule()).padding() } }
        }
            }
        }.background(AppTheme.canvas).navigationTitle("Agent").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                if model.supportsGeneration { composer }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { if !model.active && model.persist() { close() } } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Back").disabled(model.active) }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("New conversation") { model.newConversation() }.disabled(model.active)
                        Button("Conversations") { model.reloadHistory(); history = true }.disabled(model.active)
                        Button("Manage context") { context = true }
                        Button("Local tools") { state.reloadPieces(); state.reloadOutfits(); state.reloadThemes(); state.reloadPlanEntries(); tools = true }.disabled(model.active || model.hasPendingOperation)
                        Button("Voice input") { voice = true }
                        Button("Photo assistance") { imageHelp = true }
                    } label: { Label("More", systemImage: "ellipsis") }
                }
            }.navigationDestination(isPresented: $history) { AgentHistoryView(model: model) { value in if value.revision > 0 { model.open(value.id) }; history = false } }
            .sheet(isPresented: $tools) { AgentActionComposerView(model: model).environment(state) }
            .sheet(isPresented: $voice) { AgentVoiceView(model: model) }
            .sheet(isPresented: $imageHelp) { NavigationStack { VStack(alignment: .leading, spacing: 20) {
                Text("Photo assistance isn’t enabled").font(AppTypography.section)
                Text("You can describe your photo in a message, select existing closet pieces, or add a piece manually. Your text and selected context stay. Photos are never sent to a cloud model.")
                SecondaryAction(title: "Select closet context") { imageHelp = false; context = true }
            }.padding(20).navigationTitle("Photo assistance").toolbar { ToolbarItem(placement: .confirmationAction) { Button { imageHelp = false } label: { Text("Done") }.accessibilityLabel("Done") } } } }
            .sheet(isPresented: $context) { AgentContextView(model: model).environment(state) }
            .sheet(item: $details) { message in NavigationStack { Form {
                LabeledContent("Runtime", value: "On-device")
                LabeledContent("Received", value: message.createdAt.formatted())
                LabeledContent("Response time", value: message.elapsedSeconds.map { String(format: "%.1f s", $0) } ?? "Unavailable")
                LabeledContent("First text", value: message.firstTextSeconds.map { String(format: "%.1f s", $0) } ?? "Unavailable")
                Text(message.contextSummary ?? "Context measurements unavailable")
                Text("Generated text cannot change your records. Only an explicit review and saved receipt can do that.")
            }.scrollContentBackground(.hidden).background(AppTheme.canvas).navigationTitle("Response details").toolbar { ToolbarItem(placement: .confirmationAction) { Button { details = nil } label: { Text("Done") }.accessibilityLabel("Done") } } } }
            .onAppear { if automaticallyFocusComposer && model.supportsGeneration && model.conversation.messages.isEmpty && !didFocus { didFocus = true; focused = true } }
    }
    private var composer: some View {
        VStack(spacing: 12) {
            TextField("Ask about your closet…", text: Binding(get: { model.conversation.draft }, set: model.updateDraft), axis: .vertical).lineLimit(1...6).focused($focused)
            HStack {
                Menu {
                    Button("Select closet context") { context = true }
                    Button("Photo assistance") { imageHelp = true }
                    Button("Local tools") { tools = true }
                } label: { Image(systemName: "plus").frame(width: 44, height: 44) }.accessibilityLabel("Attach or select context")
                Button { context = true } label: { Label(model.conversation.context.scope == .general ? "General" : "Closet", systemImage: "tshirt") }.frame(minHeight: 44)
                Spacer()
                Button { voice = true } label: { Image(systemName: "mic").frame(width: 44, height: 44) }.accessibilityLabel("Voice input")
                if model.active {
                    Button(action: model.stop) { Image(systemName: "stop.fill").frame(width: 44, height: 44) }.accessibilityLabel("Stop response")
                } else {
                    Button { model.send() } label: { Image(systemName: "arrow.up").frame(width: 44, height: 44) }.accessibilityLabel("Send to Agent").disabled(!model.canGenerate || model.conversation.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }.padding(16).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28)).padding(.horizontal, 20).padding(.bottom, 8)
    }
    private func copy(_ message: AgentMessage, markdown: Bool) {
        let value = markdown ? (message.status == .complete ? "" : "Incomplete response\n\n") + message.source : AgentMarkdownPolicy.plainText(message.source, incomplete: message.status != .complete)
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
    var body: some View {
        List {
            if let error = model.error { Text(error).foregroundStyle(AppTheme.error) }
            if model.hasPendingOperation || model.error != nil {
                Button(model.hasPendingOperation ? "Retry operation" : "Try again") {
                    if model.hasPendingOperation { model.retryPending() } else { model.reloadHistory() }
                }
            }
            if model.history.isEmpty { AppEmptyState("No conversations yet", systemImage: "bubble.left", description: Text("Conversations stay on this iPhone.")) }
            ForEach(model.history) { value in
                Button { open(value) } label: { VStack(alignment: .leading, spacing: 4) { Text(value.title).foregroundStyle(AppTheme.ink); Text(value.updatedAt, style: .date).font(.footnote).foregroundStyle(AppTheme.secondary) } }
                    .disabled(model.hasPendingOperation)
                    .contextMenu { Button("Delete conversation", role: .destructive) { selected = value } }
                    .swipeActions { Button("Delete", role: .destructive) { selected = value } }
            }
        }.scrollContentBackground(.hidden).background(AppTheme.canvas).navigationTitle("Conversations")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { model.newConversation(); open(model.conversation) } label: { Image(systemName: "square.and.pencil") }.accessibilityLabel("New conversation").disabled(model.active || model.hasPendingOperation) } }
            .alert("Delete this conversation?", isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } })) {
                Button("Cancel", role: .cancel) { selected = nil }
                Button("Delete conversation", role: .destructive) { if let selected { model.delete(selected) }; selected = nil }
            } message: { Text("Deletes this conversation, its draft and responses on this iPhone. Saved pieces, outfits and plans stay.") }
    }
}
