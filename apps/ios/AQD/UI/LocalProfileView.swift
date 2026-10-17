import AQDCore
import SwiftUI

struct LocalProfileView: View {
    @Environment(AppState.self) private var state
    @State private var categories = false
    @State private var journalTab: FitJournalTab = .all
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorSchemeContrast) private var contrast
    var body: some View {
        @Bindable var state = state
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.section) {
                        identityHeader.padding(.horizontal, AppSpacing.screen)
                        profileActions.padding(.horizontal, AppSpacing.screen)
                        if let error = state.identityError {
                            VStack(alignment: .leading, spacing: AppSpacing.small) {
                                SemanticFeedback(role: .danger, message: error)
                                Button("Retry profile") { state.reloadIdentity() }.frame(minHeight: 44)
                            }.padding(.horizontal, AppSpacing.screen)
                        }
                        FitJournalGrid(tab: $journalTab)
                    }.padding(.top, AppSpacing.headerGap).padding(.bottom, AppSpacing.screen)
                }.onChange(of: state.fitAnchor) { _, id in
                    if let id { journalTab = .all; DispatchQueue.main.async { proxy.scrollTo(id, anchor: .center) } }
                }
            }.background(AppTheme.canvas).navigationTitle("").navigationBarTitleDisplayMode(.inline).onAppear { state.reloadIdentity(); state.reloadFits(); state.reloadOutfits(); state.reloadPieces() }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if journalTab == .outfits { state.buildOutfit() } else { state.openFit() }
                        } label: { Label(journalTab == .outfits ? "Add outfit" : "Add fit", systemImage: "plus") }
                            .accessibilityIdentifier(journalTab == .outfits ? "profile.addOutfit" : "profile.addFit")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            AccessoryButton("Style", systemImage: "slider.horizontal.3") { state.openStyle(source: .profile) }
                            AccessoryButton("Categories", systemImage: "square.grid.2x2") { categories = true }
                            AccessoryButton("Settings", systemImage: "gearshape") { state.profileSettings = true }
                        } label: { Label("More", systemImage: "ellipsis") }
                    }
                }
                .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
                .navigationDestination(isPresented: $state.profileInsights) { LocalWearInsightsView().secondaryPage() }
                .navigationDestination(isPresented: $state.profileHistory) { LocalWearHistoryView().secondaryPage() }
                .navigationDestination(isPresented: $categories) { WardrobeCategorySettingsView().secondaryPage() }
                .navigationDestination(isPresented: $state.profileSettings) { LocalSettingsView().secondaryPage() }
        }.tint(AppTheme.ink)
    }
    private var profileActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { editProfile; wearInsights }
            VStack(spacing: 8) { editProfile; wearInsights }
        }
    }
    private var editProfile: some View {
        profileAction("Edit profile") { state.openIdentity() }
            .accessibilityIdentifier("profile.edit")
    }
    private var wearInsights: some View {
        profileAction("Wear insights") { state.profileInsights = true }
    }
    private func profileAction(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(AppTypography.fieldLabel).foregroundStyle(AppTheme.ink)
                .frame(maxWidth: .infinity, minHeight: AppControlMetrics.minimumTarget)
                .contentShape(RoundedRectangle(cornerRadius: AppRadius.group))
        }.buttonStyle(.plain)
            .glassControlSurface(RoundedRectangle(cornerRadius: AppRadius.group))
            .overlay {
                if contrast == .increased {
                    RoundedRectangle(cornerRadius: AppRadius.group).stroke(AppTheme.controlBoundary, lineWidth: 1)
                }
            }
    }
    private var identityHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.section) {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 16) {
                    profileAvatar
                    identityName
                    profileStats
                }
            } else {
                HStack(alignment: .top, spacing: 24) {
                    profileAvatar
                    VStack(alignment: .leading, spacing: 16) {
                        identityName
                        profileStats
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            let caption = state.localIdentity?.caption ?? LocalProfileIdentity.defaultCaption
            if !caption.isEmpty {
                Text(caption).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    .lineLimit(3).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }.accessibilityIdentifier("profile.identity")
    }
    private var identityName: some View {
        Text(state.localIdentity?.name ?? "Your profile").font(AppTypography.detailTitle).lineLimit(2)
    }
    private var profileAvatar: some View {
        Button { state.openIdentity() } label: {
            LocalIdentityAvatar(photoID: state.localIdentity?.photoID, recipe: state.localIdentity?.photoRecipe ?? .fitOriginal)
                .frame(width: 88, height: 88)
        }.buttonStyle(.plain).accessibilityLabel("Edit profile photo")
            .accessibilityIdentifier("profile.avatar.edit")
    }
    private var profileStats: some View {
        HStack(alignment: .top, spacing: 0) {
            profileStat("Fits", count: state.fitError == nil ? state.fitMemories.count : nil)
            profileStat("Outfits", count: state.outfitError == nil ? state.outfits.count : nil)
            profileStat("Pieces", count: state.pieceReadError == nil ? state.pieces.count : nil)
        }.frame(maxWidth: .infinity)
    }
    private func profileStat(_ title: String, count: Int?) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(count.map(String.init) ?? "—").font(.title3.weight(.semibold)).monospacedDigit()
            Text(title).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).accessibilityElement(children: .ignore)
            .accessibilityLabel(count.map { "\($0) \(title.lowercased())" } ?? "\(title) unavailable")
    }
}
