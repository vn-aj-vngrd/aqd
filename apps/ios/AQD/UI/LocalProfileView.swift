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
                        Image(systemName: "person.crop.circle.fill")
                            .resizable().scaledToFit().frame(width: 64, height: 64)
                            .foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your profile").font(.title.weight(.medium))
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
                }.padding(20)
            }.background(AppTheme.canvas).navigationTitle("Profile")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Style") { state.openStyle(source: .profile) }
                            Button("Settings") { state.profileSettings = true }
                        } label: { Label("More", systemImage: "ellipsis") }
                    }
                }
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
