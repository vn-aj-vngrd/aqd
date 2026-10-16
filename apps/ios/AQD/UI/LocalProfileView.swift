import AQDCore
import SwiftUI

struct LocalProfileView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        @Bindable var state = state
        NavigationStack {
            Group {
                if state.fitMemories.isEmpty && state.fitError == nil {
                    VStack(alignment: .leading, spacing: 16) {
                        identityHeader.padding(.horizontal, 20)
                        if let error = state.identityError {
                            SemanticFeedback(role: .danger, message: error).padding(.horizontal, 20)
                            Button("Retry profile") { state.reloadIdentity() }.padding(.horizontal, 20)
                        }
                        EmptyStatePage(title: "A little space for your style", systemImage: "photo.stack",
                                       description: Text("Keep a photo or outfit here. Your fit memories stay private.")) {
                            PrimaryAction(title: "Add fit") { state.openFit() }
                        }.accessibilityIdentifier("profile.fits.empty")
                    }.padding(.top, 20)
                } else {
            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    identityHeader
                    FitJournalGrid()
                    if let error = state.identityError { SemanticFeedback(role: .danger, message: error); Button("Retry profile") { state.reloadIdentity() } }
                }.padding(20)
            }.onChange(of: state.fitAnchor) { _, id in if let id { proxy.scrollTo(id) } }
            }
                }
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
    private var identityHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 16) {
                        Button { state.openIdentity() } label: {
                            LocalIdentityAvatar(photoID: state.localIdentity?.photoID, recipe: state.localIdentity?.photoRecipe ?? .fitOriginal)
                                .frame(width: 64, height: 64)
                        }.buttonStyle(.plain).accessibilityLabel("Edit profile photo")
                            .accessibilityIdentifier("profile.avatar.edit")
                        VStack(alignment: .leading, spacing: 4) {
                            Text(state.localIdentity?.name ?? "Your profile").font(.title.weight(.medium))
                            let caption = state.localIdentity?.caption ?? LocalProfileIdentity.defaultCaption
                            if !caption.isEmpty {
                                Text(caption).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }.accessibilityIdentifier("profile.identity")
        }
    }
}
