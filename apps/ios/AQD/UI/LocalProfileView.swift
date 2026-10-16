import AQDCore
import SwiftUI

struct LocalProfileView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        @Bindable var state = state
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .center, spacing: 16) {
                        LocalIdentityAvatar(photoID: state.localIdentity?.photoID).frame(width: 64, height: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(state.localIdentity?.name ?? "Your profile").font(.title.weight(.medium))
                            Text("Your private style and fit memories")
                                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }
                    }.accessibilityIdentifier("profile.identity")
                    Label("Private on this iPhone", systemImage: "lock")
                        .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your fits").font(AppTypography.section)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("A little space for your style").font(AppTypography.detailTitle)
                            Text("Your saved fit memories will appear here.")
                                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.group))
                    }.accessibilityIdentifier("profile.fits.empty")
                    if let error = state.identityError { SemanticFeedback(role: .danger, message: error); Button("Retry profile") { state.reloadIdentity() } }
                }.padding(20)
            }.background(AppTheme.canvas).navigationTitle("Profile").onAppear { state.reloadIdentity() }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
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
