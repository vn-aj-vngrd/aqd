import AQDCore
import SwiftUI

struct LocalProfileView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        @Bindable var state = state
        NavigationStack {
            Group {
                if state.fitMemories.isEmpty && state.fitError == nil {
                    GeometryReader { geometry in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                identityHeader
                                if let error = state.identityError {
                                    SemanticFeedback(role: .danger, message: error)
                                    Button("Retry profile") { state.reloadIdentity() }.frame(minHeight: 44)
                                }
                                Spacer(minLength: 0)
                                AppEmptyState("A little space for your style", systemImage: "photo.stack",
                                              description: Text("Keep a photo or outfit here. Your fit memories stay private."), fillsAvailableSpace: false)
                                    .frame(maxWidth: .infinity)
                                Spacer(minLength: 0)
                            }.frame(minHeight: max(0, geometry.size.height - 40)).padding(20)
                        }
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        ActionFooter { PrimaryAction(title: "Add fit") { state.openFit() } }
                    }.accessibilityIdentifier("profile.fits.empty")
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
            }.background(AppTheme.canvas).navigationTitle("Profile").onAppear { state.reloadIdentity(); state.reloadFits(); state.reloadOutfits(); state.reloadPieces() }
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
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 16) {
                    profileAvatar
                    identityDetails
                    profileStats
                }
            } else {
                HStack(alignment: .top, spacing: 24) {
                    profileAvatar
                    VStack(alignment: .leading, spacing: 16) {
                        identityDetails
                        profileStats
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }.accessibilityIdentifier("profile.identity")
    }
    private var identityDetails: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(state.localIdentity?.name ?? "Your profile").font(AppTypography.detailTitle).lineLimit(2)
            let caption = state.localIdentity?.caption ?? LocalProfileIdentity.defaultCaption
            if !caption.isEmpty {
                Text(caption).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    .lineLimit(3).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    private var profileAvatar: some View {
        Button { state.openIdentity() } label: {
            LocalIdentityAvatar(photoID: state.localIdentity?.photoID, recipe: state.localIdentity?.photoRecipe ?? .fitOriginal)
                .frame(width: 88, height: 88)
        }.buttonStyle(.plain).accessibilityLabel("Edit profile photo")
            .accessibilityIdentifier("profile.avatar.edit")
    }
    private var profileStats: some View {
        HStack(alignment: .top, spacing: 12) {
            profileStat("Fits", count: state.fitError == nil ? state.fitMemories.count : nil)
            profileStat("Outfits", count: state.outfitError == nil ? state.outfits.count : nil)
            profileStat("Pieces", count: state.pieceReadError == nil ? state.pieces.count : nil)
        }.frame(maxWidth: .infinity)
    }
    private func profileStat(_ title: String, count: Int?) -> some View {
        VStack(spacing: 4) {
            Text(count.map(String.init) ?? "—").font(.title3.weight(.semibold)).monospacedDigit()
            Text(title).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
        }.frame(maxWidth: .infinity).accessibilityElement(children: .ignore)
            .accessibilityLabel(count.map { "\($0) \(title.lowercased())" } ?? "\(title) unavailable")
    }
}
