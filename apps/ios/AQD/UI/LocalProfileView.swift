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
                        Button { state.openFit() } label: { Label("Add fit", systemImage: "plus") }
                            .accessibilityIdentifier("profile.addFit")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { state.openIdentity() } label: { Label("Edit profile", systemImage: "square.and.pencil") }
                            .accessibilityIdentifier("profile.edit")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
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
