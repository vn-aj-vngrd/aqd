import AQDCore
import SwiftUI
import UIKit

struct LocalSettingsView: View {
    @Environment(AppState.self) private var state
    @State private var weather = false
    #if DEBUG
    @State private var previewWelcome = false
    @State private var tourAfterWelcome = false
    @State private var previewSplash = false
    #endif
    var body: some View {
        List {
            Section("Personalize") {
                NavigationLink { WardrobeCategorySettingsView().secondaryPage() } label: { SettingsRow(title: "Categories", symbol: "square.grid.2x2") }
                NavigationLink { LocalStyleSettingsView().secondaryPage() } label: { SettingsRow(title: "Style preferences", symbol: "slider.horizontal.3") }
                NavigationLink { LocalAppearanceSettingsView().secondaryPage() } label: {
                    SettingsRow(title: "Appearance", symbol: "circle.lefthalf.filled", value: appearanceTitle)
                }
                Button { weather = true } label: {
                    SettingsRow(title: "Weather", symbol: "cloud.sun", value: state.weatherClient?.local?.enabled == true ? state.weatherClient?.local?.place?.name ?? "Place unavailable" : "Off", disclosure: true)
                }
            }.listRowBackground(AppTheme.surface)
            Section("Assistance & help") {
                NavigationLink { LocalAssistanceSettingsView().secondaryPage() } label: { SettingsRow(title: "About Agent", symbol: "sparkle") }
                NavigationLink { LocalPrivacySettingsView().secondaryPage() } label: { SettingsRow(title: "Help & privacy", symbol: "hand.raised") }
                Button { state.beginTour(from: .settings) } label: { SettingsRow(title: "App tour", symbol: "play.rectangle", disclosure: true) }
            }.listRowBackground(AppTheme.surface)
            Section {
                NavigationLink { ArchivedPiecesView().secondaryPage() } label: { SettingsRow(title: "Archived pieces", symbol: "archivebox") }
                NavigationLink { LocalExportView().secondaryPage() } label: { SettingsRow(title: "Export closet", symbol: "square.and.arrow.up") }
                Button { state.openRestore() } label: { SettingsRow(title: "Restore closet", symbol: "arrow.counterclockwise", disclosure: true) }
                Button(role: .destructive) { state.openErase() } label: { SettingsRow(title: "Erase closet", symbol: "trash", disclosure: true, destructive: true) }
            } header: { Text("Your data") } footer: {
                Text("Stored on this iPhone with no account or automatic cloud backup. Export a copy to protect against device loss or deleting AQD.")
            }.listRowBackground(AppTheme.surface)
            #if DEBUG
            Section {
                Button { previewWelcome = true } label: { SettingsRow(title: "Preview welcome screen", symbol: "hand.wave", disclosure: true) }
                    .accessibilityIdentifier("aqd.development.welcome")
                Button { previewSplash = true } label: { SettingsRow(title: "Preview splash screen", symbol: "arrow.clockwise", disclosure: true) }
                    .accessibilityIdentifier("aqd.development.splash")
            } header: { Text("Development") } footer: { Text("Previews preserve your setup. Close and reopen AQD to test the system launch screen.") }
                .listRowBackground(AppTheme.surface)
            #endif
        }
        .listStyle(.insetGrouped).navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
        .contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden).background(AppTheme.canvas).tint(AppTheme.ink)
        .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
        .onAppear { state.reloadSettings() }
        .sheet(isPresented: $weather) { if let client = state.weatherClient { WeatherContextView(client: client, persistsPreference: true) { _ in true } } }
        #if DEBUG
        .fullScreenCover(isPresented: $previewWelcome, onDismiss: {
            if tourAfterWelcome { tourAfterWelcome = false; state.beginTour(from: .settings) }
        }) { WelcomeView(previewDismiss: { tour in tourAfterWelcome = tour; previewWelcome = false }).background(AppTheme.canvas) }
        .fullScreenCover(isPresented: $previewSplash) { DevelopmentSplashPreview() }
        #endif
    }
    private var appearanceTitle: String { state.appearance == .system ? "Automatic" : state.appearance.rawValue.capitalized }
}

private struct SettingsRow: View {
    let title: String
    let symbol: String
    var value: String? = nil
    var disclosure = false
    var destructive = false
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 19, weight: .regular)).frame(width: 24)
                .foregroundStyle(destructive ? AppTheme.error : AppTheme.controlIcon).accessibilityHidden(true)
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).foregroundStyle(destructive ? AppTheme.error : AppTheme.ink)
                    if let value { Text(value).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                }
                Spacer(minLength: 0)
            } else {
                Text(title).foregroundStyle(destructive ? AppTheme.error : AppTheme.ink)
                Spacer(minLength: 8)
                if let value { Text(value).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).multilineTextAlignment(.trailing) }
            }
            if disclosure { Image(systemName: "chevron.forward").font(AppTypography.disclosure).foregroundStyle(AppTheme.secondary).accessibilityHidden(true) }
        }.font(AppTypography.body).frame(minHeight: 44).contentShape(Rectangle())
    }
}

struct LocalAppearanceSettingsView: View {
    @Environment(AppState.self) private var state
    private var selected: LocalAppearance { state.settings?.appearance ?? .system }
    var body: some View {
        List {
            Section {
                ForEach(LocalAppearance.allCases, id: \.self) { value in
                    Button { state.saveAppearance(value) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: symbol(value)).font(.system(size: 21, weight: .regular)).frame(width: 26)
                                .foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title(value)).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                                Text(subtitle(value)).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            if selected == value { Image(systemName: "checkmark").font(AppTypography.disclosure).foregroundStyle(AppTheme.ink).accessibilityHidden(true) }
                        }.frame(minHeight: 52).contentShape(Rectangle())
                    }.accessibilityValue(selected == value ? "Selected" : "Not selected")
                        .accessibilityAddTraits(selected == value ? [.isSelected] : [])
                }
            } footer: { Text("Automatic follows the appearance set on your iPhone.") }
                .listRowBackground(AppTheme.surface)
            if let error = state.settingsError {
                Section {
                    SemanticFeedback(role: .danger, message: error)
                    Button("Retry appearance save") { state.retryAppearanceSave() }.tint(AppTheme.actionText)
                }.listRowBackground(AppTheme.surface)
            }
        }.listStyle(.insetGrouped).contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden).background(AppTheme.canvas)
            .navigationTitle("Appearance").navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink)
    }
    private func title(_ value: LocalAppearance) -> String { value == .system ? "Automatic" : value.rawValue.capitalized }
    private func subtitle(_ value: LocalAppearance) -> String {
        switch value { case .system: "Match your iPhone"; case .light: "Always use light appearance"; case .dark: "Always use dark appearance" }
    }
    private func symbol(_ value: LocalAppearance) -> String {
        switch value { case .system: "circle.lefthalf.filled"; case .light: "sun.max"; case .dark: "moon" }
    }
}
struct LocalStyleSettingsView: View {
    @Environment(AppState.self) private var state
    @State private var answers: StylePreferences?
    var body: some View {
        Group {
            if let answers {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(0..<6, id: \.self) { index in
                                VStack(alignment: .leading, spacing: AppSpacing.small) {
                                    Text(StylePreferences.titles[index]).font(AppTypography.fieldLabel)
                                    Text(answers.summary(at: index)).foregroundStyle(AppTheme.secondary)
                                }.frame(maxWidth: .infinity, alignment: .leading).padding(AppSpacing.screen)
                                if index < 5 { Divider().padding(.horizontal, AppSpacing.screen) }
                            }
                        }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
                        stylePrivacy
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
                }
            } else {
                CenteredPageContent {
                    Text("Make it your style").font(AppTypography.section)
                    Text("Answer six short questions, then review your preferences. No preference is always an option.")
                        .foregroundStyle(AppTheme.secondary)
                    stylePrivacy
                }
            }
        }.background(AppTheme.canvas).navigationTitle("Style").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { state.openStyle(source: .settings) }
                    .tint(AppTheme.ink).accessibilityLabel("Edit preferences")
            } }
            .onAppear { answers = try? state.store?.localExperience().style?.answers }
            .onChange(of: state.styleEditor?.id) { _, editorID in
                if editorID == nil { answers = try? state.store?.localExperience().style?.answers }
            }
    }
    private var stylePrivacy: some View {
        Text("Saved on this iPhone. Share Style with Agent only when you choose. Body details have a separate permission.")
            .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
    }
}
struct LocalAssistanceSettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.scenePhase) private var scenePhase
    @State private var availability = OutfitSuggestions.modelAvailability()
    var body: some View {
        CenteredPageContent {
            Image(systemName: "sparkles").font(.system(size: 32, weight: .light)).foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
            VStack(spacing: 8) {
                Text("On-device Agent").font(AppTypography.section)
                Text(availability.message).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }
            VStack(alignment: .leading, spacing: 16) {
                Label("Manual tools stay available", systemImage: "slider.horizontal.3")
                Label("Review every change before saving", systemImage: "checkmark.circle")
                Label("No cloud model", systemImage: "iphone")
            }.font(AppTypography.supporting).frame(maxWidth: .infinity, alignment: .leading)
                .padding(20).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        }.background(AppTheme.canvas).navigationTitle("About Agent").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ActionFooter {
                    ActionStack {
                        PrimaryAction(title: "Open Agent") { state.agentLaunchID = UUID() }
                        SecondaryAction(title: "Check availability again") { availability = OutfitSuggestions.modelAvailability() }
                    }
                }
            }
            .onChange(of: scenePhase) { _, phase in if phase == .active { availability = OutfitSuggestions.modelAvailability() } }
    }
}
struct LocalPrivacySettingsView: View {
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 20) {
            Text("Private on this device").font(AppTypography.section)
            Text("AQD keeps your closet, local profile, conversations and drafts on this iPhone. There is no account, social publishing, AQD backend or automatic cloud backup. AQD-owned files are excluded from device backups.")
            Text("Keep a copy").font(AppTypography.section)
            Text("App deletion or device loss can lose your data. Export a sensitive local archive from Settings. Your chosen Files destination may use cloud storage; protect copies you export.")
            Text("Permissions and optional services").font(AppTypography.section)
            Text("Camera and supported microphone/speech permissions are requested only after an explicit action. Photos uses your selected media. Optional Apple city search sends your city query; qualified weather uses the selected place/date without wardrobe, photos, body details or conversations.")
            Text("Restore replaces local data after review. Erase clears AQD-owned records and files; original Photos and previous exported copies stay outside AQD.")
        }.padding(20) }.background(AppTheme.canvas).navigationTitle("Help and privacy").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ActionFooter {
                    SecondaryAction(title: "Open iPhone Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
                }
            }
    }
}

#if DEBUG
private struct DevelopmentSplashPreview: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            Color("LaunchCanvas").ignoresSafeArea()
            Image("LaunchMark").resizable().scaledToFit().frame(width: 144, height: 144).accessibilityLabel("AQD")
        }.task {
            do { try await Task.sleep(for: .seconds(1.2)); dismiss() } catch { }
        }
    }
}
#endif
