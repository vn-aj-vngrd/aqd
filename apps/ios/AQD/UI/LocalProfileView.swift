import AQDCore
import SwiftUI

struct LocalProfileView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        @Bindable var state = state
        NavigationStack {
            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .center, spacing: 16) {
                        LocalIdentityAvatar(photoID: state.localIdentity?.photoID, recipe: state.localIdentity?.photoRecipe ?? .fitOriginal).frame(width: 64, height: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(state.localIdentity?.name ?? "Your profile").font(.title.weight(.medium))
                            Text("Your private style and fit memories")
                                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }
                    }.accessibilityIdentifier("profile.identity")
                    Label("Private on this iPhone", systemImage: "lock")
                        .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    FitJournalGrid()
                    if let error = state.identityError { SemanticFeedback(role: .danger, message: error); Button("Retry profile") { state.reloadIdentity() } }
                }.padding(20)
            }.onChange(of: state.fitAnchor) { _, id in if let id { proxy.scrollTo(id) } }
            }.background(AppTheme.canvas).navigationTitle("Profile").onAppear { state.reloadIdentity(); state.reloadFits() }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Add fit") { state.openFit() }
                            Button("Edit profile") { state.openIdentity() }
                            Button("Style") { state.openStyle(source: .profile) }
                            Button("Wear insights") { state.profileInsights = true }
                            Button("Settings") { state.profileSettings = true }
                        } label: { Label("More", systemImage: "ellipsis") }
                    }
                }
                .navigationDestination(isPresented: $state.profileInsights) { LocalWearInsightsView() }
                .navigationDestination(isPresented: $state.profileHistory) { LocalWearHistoryView() }
                .navigationDestination(isPresented: $state.profileSettings) { LocalSettingsView() }
        }.tint(AppTheme.ink)
    }
}

struct LocalSettingsView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DisclosureRow(title: "Style", value: "Edit preferences") { state.openStyle(source: .settings) }
                DisclosureRow(title: "Take the tour", value: "Preview only") { state.beginTour(from: .settings) }
                Text("Your preferences stay private on this iPhone. No account is needed.")
                    .font(.footnote).foregroundStyle(AppTheme.secondary)
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
    }
}
