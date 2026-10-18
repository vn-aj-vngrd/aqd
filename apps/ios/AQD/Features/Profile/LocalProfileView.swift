import AQDCore
import SwiftUI

struct LocalProfileView: View {
    @Environment(AppState.self) private var state
    @State private var categories = false
    @State private var journalTab: FitJournalTab = .all
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
                        FitJournalGrid(tab: $journalTab, query: $query)
                    }.padding(.top, AppSpacing.headerGap).padding(.bottom, AppSpacing.screen)
                }.onChange(of: state.fitAnchor) { _, id in
                    if let id { journalTab = .all; DispatchQueue.main.async { proxy.scrollTo(id, anchor: .center) } }
                }
            }.background(AppTheme.canvas).navigationTitle("").navigationBarTitleDisplayMode(.inline).onAppear { state.reloadIdentity(); state.reloadFits(); state.reloadOutfits(); state.reloadPieces() }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button("Take photo", systemImage: "camera") { state.openFit(source: .camera) }
                                .accessibilityIdentifier("profile.addFit.camera")
                            Button("Choose from Photos", systemImage: "photo.on.rectangle") { state.openFit(source: .photos) }
                                .accessibilityIdentifier("profile.addFit.photos")
                            Button("From an outfit", systemImage: "hanger") { state.openFit(source: .outfit) }
                                .disabled(state.outfits.isEmpty).accessibilityIdentifier("profile.addFit.outfit")
                            Divider()
                            Button("Build an outfit", systemImage: "square.stack") { state.buildOutfit() }
                                .accessibilityIdentifier("profile.addOutfit")
                        } label: { Label("Add fit", systemImage: "plus") }
                            .accessibilityIdentifier("profile.addFit")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Section("Profile") {
                                AccessoryButton("Edit profile", systemImage: "person.crop.circle") { state.openIdentity() }
                                AccessoryButton("Style", systemImage: "slider.horizontal.3") { state.openStyle(source: .profile) }
                            }
                            Section("Wear") {
                                AccessoryButton("Wear history", systemImage: "clock.arrow.circlepath") { state.profileHistory = true }
                                AccessoryButton("Wear insights", systemImage: "chart.bar") { state.profileInsights = true }
                            }
                            Section("Closet") {
                                AccessoryButton("Categories", systemImage: "square.grid.2x2") { categories = true }
                                AccessoryButton("Settings", systemImage: "gearshape") { state.profileSettings = true }
                            }
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
    private var profileStats: some View {
        HStack(alignment: .top, spacing: 0) {
            profileStat("Fits", count: state.fitError == nil ? state.fitMemories.count : nil) { journalTab = .all }
            profileStat("Outfits", count: state.outfitError == nil ? state.outfits.count : nil) { state.closetScope = "Outfits"; state.selection = 1 }
            profileStat("Pieces", count: state.pieceReadError == nil ? state.pieces.count : nil) { state.selection = 1 }
        }.frame(maxWidth: .infinity)
    }
    private func profileStat(_ title: String, count: Int?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(count.map(String.init) ?? "—").font(.title3.weight(.semibold)).monospacedDigit().truncated()
                Text(title).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).truncated()
            }.frame(maxWidth: .infinity, minHeight: AppControlMetrics.minimumTarget, alignment: .leading).contentShape(Rectangle())
        }.buttonStyle(.plain).foregroundStyle(AppTheme.ink).accessibilityElement(children: .ignore)
            .accessibilityLabel(count.map { "\($0) \(title.lowercased())" } ?? "\(title) unavailable")
            .accessibilityHint(title == "Fits" ? "Shows fits below" : "Opens Closet")
            .accessibilityIdentifier("profile.stat.\(title.lowercased())")
    }
}
