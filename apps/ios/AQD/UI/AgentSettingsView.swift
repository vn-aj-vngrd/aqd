import AQDCore
import SwiftUI

struct AgentSettingsView: View {
    @Environment(AppState.self) private var state
    @State private var controls: AgentControlsModel?
    @State private var error: String?
    var body: some View {
        Group {
            if let controls { AgentSettingsForm(controls: controls) }
            else if error == nil { ProgressView("Loading…") }
            else {
                AppEmptyState("AI settings couldn’t load", systemImage: "sparkle", description: Text(error ?? "Your saved data stays on this iPhone."))
                    .overlay(alignment: .bottom) { Button("Try again", action: load).padding(AppSpacing.screen) }
            }
        }.navigationTitle("AI settings").navigationBarTitleDisplayMode(.inline).background(AppTheme.canvas).task { load() }
    }
    private func load() {
        do { guard let store = state.store else { throw PieceStore.StoreError.corruptStore }; if state.agentControlsModel == nil { state.agentControlsModel = try AgentControlsModel(store: store) }; controls = state.agentControlsModel; state.agentModel?.controls = controls; controls?.reload(); error = nil }
        catch { self.error = "Your saved choices are retained. Try again." }
    }
}

private struct AgentSettingsForm: View {
    @Environment(AppState.self) private var state
    @Bindable var controls: AgentControlsModel
    @State private var weather = false
    private var preferences: AgentPreferences { controls.settings.agentPreferences ?? AgentPreferences() }
    var body: some View {
        List {
            if let error = controls.error {
                Section {
                    SemanticFeedback(role: .danger, message: error)
                    Button(controls.hasPending ? "Retry save" : "Reload settings") { if controls.hasPending { _ = controls.retry() } else { controls.reload() }; state.reloadSettings() }
                }.listRowBackground(AppTheme.surface)
            }
            Section {
                ForEach([AgentDataSource.pieces, .outfits, .themes], id: \.self) { source in sourceToggle(source) }
            } header: { Text("Your wardrobe") } footer: { Text("Agent selects relevant saved records for each reply. Large collections are summarized, with coverage shown in response details.") }
                .listRowBackground(AppTheme.surface)
            Section {
                ForEach([AgentDataSource.style, .profile, .notes], id: \.self) { source in sourceToggle(source) }
                NavigationLink { LocalStyleSettingsView().secondaryPage() } label: { AccessoryLabel("Style preferences", systemImage: "slider.horizontal.3") }
            } header: { Text("Personalization") } footer: { Text("Only saved text is used. Photo contents aren’t analyzed. Body details keep their separate use permission in Style preferences. Private notes means piece, theme, fit and Today notes.") }
                .listRowBackground(AppTheme.surface)
            Section {
                ForEach([AgentDataSource.wear, .journal, .today, .planner, .pastChats, .feedback], id: \.self) { source in sourceToggle(source) }
            } header: { Text("History & feedback") } footer: { Text("Wear insights use recorded wear, not plans or fit photos. Past chats supply user topics, not verified facts from earlier AI replies. Ratings do not train Apple’s model.") }
                .listRowBackground(AppTheme.surface)
            Section {
                sourceToggle(.weather)
                Button { weather = true } label: { AccessoryLabel("Weather preferences", systemImage: "cloud.sun") }
            } footer: { Text("Weather must be enabled separately. Only fresh data for the saved place and matching date can inform a reply; missing weather never blocks outfit advice.") }
                .listRowBackground(AppTheme.surface)
            if let agent = state.agentModel, agent.conversation.context.automatic != true || agent.conversation.context.scope != .closet {
                Section {
                    Button("Use automatic context in this chat") {
                        agent.conversation.context.automatic = true; agent.conversation.context.scope = .closet
                        agent.conversation.context.selected = []
                        _ = agent.persist()
                    }.disabled(agent.active || agent.hasPendingOperation)
                    if let error = agent.error { SemanticFeedback(role: .danger, message: error) }
                    if agent.hasPendingOperation { Button("Retry chat save") { agent.retryPending() } }
                } footer: { Text("This older chat keeps its previous context limits until you change them. Your AI data choices above still apply.") }
                    .listRowBackground(AppTheme.surface)
            }
            Section {
                NavigationLink { AgentFeedbackView().secondaryPage() } label: { AccessoryLabel("Feedback", systemImage: "bubble.left.and.exclamationmark.bubble.right") }
            } footer: { Text("Likes, dislikes and reports stay on this iPhone. Review and export a report when you choose. Nothing is sent automatically.") }
                .listRowBackground(AppTheme.surface)
            #if DEBUG
            Section("Development") {
                NavigationLink { AgentEvaluationView().secondaryPage() } label: { AccessoryLabel("Agent evaluations", systemImage: "checkmark.seal") }
            }.listRowBackground(AppTheme.surface)
            #endif
        }.listStyle(.insetGrouped).listSectionSpacing(AppSpacing.large)
            .contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden).background(AppTheme.canvas).tint(AppTheme.ink)
            .disabled(controls.hasPending)
            .overlay(alignment: .bottom) {
                if controls.hasPending { Button("Retry AI settings save") { if controls.retry() { state.reloadSettings() } }.padding(AppSpacing.medium).background(AppTheme.surface, in: Capsule()).padding(AppSpacing.screen) }
            }
            .sheet(isPresented: $weather) { if let client = state.weatherClient { WeatherContextView(client: client, persistsPreference: true) { _ in true }.appAppearance(state.appearance) } }
    }
    private func sourceToggle(_ source: AgentDataSource) -> some View {
        Toggle(isOn: Binding(get: { preferences.allows(source) }, set: { enabled in
            var next = preferences; next.set(source, enabled: enabled)
            if controls.save(preferences: next) { state.reloadSettings() }
        })) { Text(source.title) }
    }
}
