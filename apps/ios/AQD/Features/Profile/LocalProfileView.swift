import AQDCore
import SwiftUI

struct LocalProfileView: View {
    @Environment(AppState.self) private var state
    @State private var query = FitJournalQuery()
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var previewingProfile = false
    var body: some View {
        @Bindable var state = state
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.section) {
                        identityHeader.padding(.horizontal, AppSpacing.screen)
                        if let error = state.identityError {
                            VStack(alignment: .leading, spacing: AppSpacing.small) {
                                SemanticFeedback(role: .danger, message: error)
                                Button("Retry profile") { state.reloadIdentity() }.frame(minHeight: 44)
                            }.padding(.horizontal, AppSpacing.screen)
                        }
                        FitJournalGrid(query: $query)
                    }.padding(.top, AppSpacing.headerGap).padding(.bottom, AppSpacing.screen)
                }.onChange(of: state.fitAnchor) { _, id in
                    if let id { DispatchQueue.main.async { proxy.scrollTo(id, anchor: .center) } }
                }
            }.background(AppTheme.canvas).navigationTitle("").navigationBarTitleDisplayMode(.inline).onAppear { state.reloadIdentity(); state.reloadFits(); state.reloadOutfits(); state.reloadPieces() }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        // One job for Profile's +: post what you wore. The photo is optional inside the composer.
                        Button { state.openFit() } label: { Label("Post a fit", systemImage: "plus") }
                            .accessibilityIdentifier("profile.addFit")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        // Only what is about her: who she is, her style answers and the app's settings.
                        Menu {
                            AccessoryButton("Edit profile", systemImage: "person.crop.circle") { state.openIdentity() }
                            AccessoryButton("Style", systemImage: "slider.horizontal.3") { state.openStyle(source: .profile) }
                            AccessoryButton("Settings", systemImage: "gearshape") { state.profileSettings = true }
                        } label: { Label("More", systemImage: "ellipsis") }
                    }
                }
                .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
                .navigationDestination(isPresented: $state.profileInsights) { LocalWearInsightsView().secondaryPage() }
                .navigationDestination(isPresented: $state.profileHistory) { LocalWearHistoryView().secondaryPage() }
                .navigationDestination(isPresented: $state.profileSettings) { LocalSettingsView().secondaryPage() }
        }.tint(AppTheme.ink)
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
        Button { previewingProfile = true } label: {
            LocalIdentityAvatar(photoID: state.localIdentity?.photoID, recipe: state.localIdentity?.photoRecipe ?? .fitOriginal)
                .frame(width: 88, height: 88)
        }.buttonStyle(.plain).accessibilityLabel("Open profile").accessibilityHint("Shows your profile with an edit action")
            .accessibilityIdentifier("profile.avatar.edit")
            .sheet(isPresented: $previewingProfile) {
                ProfilePreviewView { state.openIdentity() }.appAppearance(state.appearance)
            }
    }
    /// Numbers about her fits, not her closet: how many, how many this month, and how many days in a row.
    private var profileStats: some View {
        let fits = state.fitError == nil ? state.fitMemories : nil
        let today = LocalPlanDay()
        // Starts on the name's edge, then the same gap between each number, so the row reads as one line of facts.
        return HStack(alignment: .top, spacing: 28) {
            profileStat("Fits", count: fits?.count, id: "fits")
            profileStat("This month", count: fits.map { FitJournalPresentation.monthCount($0, today: today) }, id: "month")
            profileStat("Day streak", count: fits.map { FitJournalPresentation.streak($0, today: today) }, id: "streak")
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func profileStat(_ title: String, count: Int?, id: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(count.map(String.init) ?? "—").font(.title3.weight(.semibold)).monospacedDigit().truncated()
            Text(title).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).truncated()
        }.frame(minHeight: AppControlMetrics.minimumTarget, alignment: .leading).fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(AppTheme.ink).accessibilityElement(children: .ignore)
            .accessibilityLabel(count.map { "\(title), \($0)" } ?? "\(title) unavailable")
            .accessibilityIdentifier("profile.stat.\(id)")
    }
}
