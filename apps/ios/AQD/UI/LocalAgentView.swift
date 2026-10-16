import AQDCore
import SwiftUI

struct LocalAgentView: View {
    @Environment(AppState.self) private var state
    @Environment(\.scenePhase) private var scenePhase
    let close: () -> Void
    var body: some View {
        NavigationStack {
            if let model = state.agentModel {
                AgentConversationView(model: model, close: close)
            } else {
                ContentUnavailableView {
                    Label("Conversations couldn’t open", systemImage: "exclamationmark.bubble")
                } description: { Text("Your local records are retained.") } actions: {
                    Button("Try again") { open() }
                    Button("Back", action: close)
                }
            }
        }.tint(AppTheme.ink).task { open() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { state.agentModel?.recheckAvailability() }
                else { _ = state.agentModel?.persist() }
            }
    }
    private func open() {
        guard state.agentModel == nil, let store = state.store else { return }
        state.agentModel = try? AgentModel(store: store)
    }
}

struct AgentConversationView: View {
    @Environment(AppState.self) private var state
    @Bindable var model: AgentModel
    let close: () -> Void
    @State private var history = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let error = model.error {
                    SemanticFeedback(role: .danger, message: error)
                    Button("Retry operation") { model.retryPending() }.frame(minHeight: 44)
                }
                if !model.conversation.messages.isEmpty {
                    ForEach(model.conversation.messages) { message in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(message.role == .user ? "You" : "Agent").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            Text(message.source).textSelection(.enabled)
                            if message.status != .complete { Text(message.status.rawValue.capitalized + " · Incomplete response").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary) }
                        }.frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
                    }
                }
                AgentAvailabilityContent(availability: model.availability, recheck: model.recheckAvailability) {
                    if model.persist() { state.selection = 1; close() }
                }
                if !model.conversation.draft.isEmpty {
                    Text("Your retained draft").font(AppTypography.section)
                    Text(model.conversation.draft).textSelection(.enabled)
                }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Agent").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { if model.persist() { close() } } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.accessibilityLabel("Back") }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("New conversation") { model.newConversation() }
                        Button("Conversations") { model.reloadHistory(); history = true }
                    } label: { Label("More", systemImage: "ellipsis") }
                }
            }.navigationDestination(isPresented: $history) {
                AgentHistoryView(model: model) { value in if value.revision > 0 { model.open(value.id) }; history = false }
            }
    }
}
struct AgentAvailabilityContent: View {
    let availability: OutfitSuggestionAvailability
    let recheck: () -> Void
    let openCloset: () -> Void
    @State private var about = false
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
        VStack(spacing: 20) {
            Image(systemName: "sparkle").font(.largeTitle).accessibilityHidden(true)
            Text(title).font(.title2).multilineTextAlignment(.center)
            Text(availability.message).foregroundStyle(AppTheme.secondary).multilineTextAlignment(.center)
            PrimaryAction(title: availability == .preparing ? "Check again" : "Open Closet", action: availability == .preparing ? recheck : openCloset)
            if availability == .preparing { SecondaryAction(title: "Open Closet", action: openCloset) }
            else { SecondaryAction(title: availability == .intelligenceOff ? "How to enable it" : "About Agent") { about = true } }
        }.frame(maxWidth: .infinity).padding(.vertical, 40)
            .navigationDestination(isPresented: $about) {
                ScrollView { VStack(alignment: .leading, spacing: 20) {
                    Text("Private on-device assistance").font(AppTypography.section)
                    Text("AQD uses Apple Intelligence on supported iPhones. In iPhone Settings, open Apple Intelligence & Siri to check whether Apple Intelligence is enabled and ready.")
                    Text("This build keeps generation disabled until on-device quality and performance checks are complete. Your conversations remain readable. Closet, manual outfits and planning work without it.")
                    Button("Check availability again", action: recheck).frame(minHeight: 44)
                }.padding(20) }.navigationTitle("About Agent")
            }
    }
}
struct AgentHistoryView: View {
    @Bindable var model: AgentModel
    let open: (AgentConversation) -> Void
    @State private var selected: AgentConversation?
    var body: some View {
        List {
            if let error = model.error { Text(error).foregroundStyle(AppTheme.error); Button("Try again") { model.reloadHistory() } }
            if model.history.isEmpty { ContentUnavailableView("No conversations yet", systemImage: "bubble.left", description: Text("Conversations stay on this iPhone.")) }
            ForEach(model.history) { value in
                Button { open(value) } label: { VStack(alignment: .leading, spacing: 4) { Text(value.title).foregroundStyle(AppTheme.ink); Text(value.updatedAt, style: .date).font(.footnote).foregroundStyle(AppTheme.secondary) } }
                    .contextMenu { Button("Delete conversation", role: .destructive) { selected = value } }
                    .swipeActions { Button("Delete", role: .destructive) { selected = value } }
            }
        }.navigationTitle("Conversations")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { model.newConversation(); open(model.conversation) } label: { Image(systemName: "square.and.pencil").frame(width: 44, height: 44) }.accessibilityLabel("New conversation") } }
            .alert("Delete this conversation?", isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } })) {
                Button("Cancel", role: .cancel) { selected = nil }
                Button("Delete conversation", role: .destructive) { if let selected { model.delete(selected) }; selected = nil }
            } message: { Text("Deletes this conversation, its draft and responses on this iPhone. Saved pieces, outfits and plans stay.") }
    }
}
