import AQDCore
import SwiftUI

struct LocalProfileView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        @Bindable var state = state
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Your closet, privately").font(AppTypography.section)
                    Text("Your pieces and style preferences stay on this iPhone.").foregroundStyle(AppTheme.secondary)
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
        }.tint(AppTheme.actionText)
    }
}

struct LocalSettingsView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DisclosureRow(title: "Style", value: "Edit preferences") { state.openStyle(source: .settings) }
                Text("Your preferences stay private on this iPhone. No account is needed.")
                    .font(.footnote).foregroundStyle(AppTheme.secondary)
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
    }
}
