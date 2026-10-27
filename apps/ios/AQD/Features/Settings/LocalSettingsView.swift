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
    @State private var seedSamples = false
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
                    SettingsRow(title: "Weather", symbol: "cloud.sun", value: state.weatherClient?.local?.enabled == true ? state.weatherClient?.local?.place?.name.split(separator: ",").first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? "Place unavailable" : "Off", valueLineLimit: 1, disclosure: true)
                }
            }.listRowInsets(EdgeInsets(top: AppSpacing.xSmall, leading: AppSpacing.large, bottom: AppSpacing.xSmall, trailing: AppSpacing.large))
                .listRowBackground(AppTheme.surface)
            Section("AI") {
                NavigationLink { AgentSettingsView().secondaryPage() } label: { SettingsRow(title: "AI settings", symbol: "sparkles") }
                NavigationLink { LocalAssistanceSettingsView().secondaryPage() } label: { SettingsRow(title: "About Agent", symbol: "sparkle") }
                NavigationLink { DeviceSupportView().secondaryPage() } label: { SettingsRow(title: "Device support", symbol: "iphone") }
                NavigationLink { AgentFeedbackView().secondaryPage() } label: { SettingsRow(title: "Feedback", symbol: "bubble.left") }
            }.listRowInsets(EdgeInsets(top: AppSpacing.xSmall, leading: AppSpacing.large, bottom: AppSpacing.xSmall, trailing: AppSpacing.large))
                .listRowBackground(AppTheme.surface)
            Section("Help") {
                NavigationLink { LocalPrivacySettingsView().secondaryPage() } label: { SettingsRow(title: "Help & privacy", symbol: "hand.raised") }
                Button { state.beginTour(from: .settings) } label: { SettingsRow(title: "App tour", symbol: "play.rectangle", disclosure: true) }
            }.listRowInsets(EdgeInsets(top: AppSpacing.xSmall, leading: AppSpacing.large, bottom: AppSpacing.xSmall, trailing: AppSpacing.large))
                .listRowBackground(AppTheme.surface)
            Section {
                NavigationLink { ArchivedPiecesView().secondaryPage() } label: { SettingsRow(title: "Archived pieces", symbol: "archivebox") }
                NavigationLink { LocalExportView().secondaryPage() } label: { SettingsRow(title: "Export closet", symbol: "square.and.arrow.up") }
                Button { state.openRestore(inSettings: true) } label: { SettingsRow(title: "Restore closet", symbol: "arrow.counterclockwise", disclosure: true) }
                Button(role: .destructive) { state.openErase(inSettings: true) } label: { SettingsRow(title: "Reset data", symbol: "trash", disclosure: true, destructive: true) }
                    .accessibilityIdentifier("aqd.settings.reset-data")
            } header: { Text("Your data") } footer: {
                Text("Stored on this iPhone with no account or automatic cloud backup. Export a copy to protect against device loss or deleting AQD.")
            }.listRowInsets(EdgeInsets(top: AppSpacing.xSmall, leading: AppSpacing.large, bottom: AppSpacing.xSmall, trailing: AppSpacing.large))
                .listRowBackground(AppTheme.surface)
            if state.localDataCleanupError != nil || state.photoCleanupError != nil {
                Section {
                    if state.localDataCleanupError != nil {
                        Button { state.openRestore(inSettings: true) } label: { SettingsRow(title: "Review data operation", symbol: "arrow.counterclockwise", disclosure: true) }
                        Button { state.retryLocalDataCleanup() } label: { SettingsRow(title: "Retry cleanup", symbol: "arrow.clockwise") }
                    }
                    SettingsPhotoRecoveryView()
                } header: { Text("Data recovery") } footer: {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        if let recovery = state.localDataCleanupError { Text(recovery) }
                    }
                }
                .listRowInsets(EdgeInsets(top: AppSpacing.xSmall, leading: AppSpacing.large,
                                         bottom: AppSpacing.xSmall, trailing: AppSpacing.large))
                .listRowBackground(AppTheme.surface)
            }
            #if DEBUG
            Section {
                Button { previewWelcome = true } label: { SettingsRow(title: "Preview welcome screen", symbol: "hand.wave", disclosure: true) }
                    .accessibilityIdentifier("aqd.development.welcome")
                Button { previewSplash = true } label: { SettingsRow(title: "Preview splash screen", symbol: "arrow.clockwise", disclosure: true) }
                    .accessibilityIdentifier("aqd.development.splash")
                Button { seedSamples = true } label: { SettingsRow(title: "Seed sample data", symbol: "square.stack.3d.up", disclosure: true) }
                    .accessibilityIdentifier("aqd.development.seed-data")
            } header: { Text("Development") } footer: { Text("Previews preserve your setup. Close and reopen AQD to test the system launch screen.") }
                .listRowInsets(EdgeInsets(top: AppSpacing.xSmall, leading: AppSpacing.large, bottom: AppSpacing.xSmall, trailing: AppSpacing.large))
                .listRowBackground(AppTheme.surface)
            #endif
        }
        .listStyle(.insetGrouped).listSectionSpacing(AppSpacing.large).navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
        .contentMargins(.top, AppSpacing.small, for: .scrollContent).scrollContentBackground(.hidden).background(AppTheme.canvas).tint(AppTheme.ink)
        .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
        .navigationDestination(isPresented: Binding(get: { state.restoreModel != nil && state.restoreInSettings },
                                                    set: { if !$0 { state.closeSettingsDataOperation() } })) {
            if let model = state.restoreModel {
                if model.kind == .erase {
                    LocalEraseView(model: model, onCancel: { state.closeSettingsDataOperation() },
                                   onInstall: state.finishSettingsDataOperation, embedded: true).secondaryPage()
                } else {
                    LocalRestoreView(model: model, onCancel: { state.closeSettingsDataOperation() },
                                     onInstall: state.finishSettingsDataOperation, embedded: true).secondaryPage()
                }
            }
        }
        .onAppear { state.reloadSettings() }
        .navigationDestination(isPresented: $weather) { if let client = state.weatherClient { WeatherContextView(client: client, persistsPreference: true) { _ in true }.secondaryPage() } }
        #if DEBUG
        .fullScreenCover(isPresented: $previewWelcome, onDismiss: {
            if tourAfterWelcome { tourAfterWelcome = false; state.beginTour(from: .settings) }
        }) { WelcomeView(previewDismiss: { tour in tourAfterWelcome = tour; previewWelcome = false }).background(AppTheme.canvas) }
        .fullScreenCover(isPresented: $previewSplash) { DevelopmentSplashPreview() }
        .navigationDestination(isPresented: $seedSamples) { DevelopmentSeedView().secondaryPage() }
        #endif
    }
    private var appearanceTitle: String { state.appearance == .system ? "Automatic" : state.appearance.rawValue.capitalized }
}

private struct SettingsRow: View {
    let title: String
    let symbol: String
    var value: String? = nil
    var valueLineLimit: Int? = nil
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
                    if let value { Text(value).lineLimit(valueLineLimit).truncationMode(.tail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                }
                Spacer(minLength: 0)
            } else {
                Text(title).foregroundStyle(destructive ? AppTheme.error : AppTheme.ink).layoutPriority(1)
                Spacer(minLength: 8)
                if let value { Text(value).lineLimit(valueLineLimit).truncationMode(.tail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).multilineTextAlignment(.trailing) }
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
                    Button("Retry appearance save") { state.retryAppearanceSave() }.tint(AppTheme.ink)
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
                        }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
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
    private var statusTitle: String {
        switch availability {
        case .available: "Ready on this iPhone"
        case .unsupported: "Not supported on this iPhone"
        case .intelligenceOff: "Apple Intelligence is off"
        case .preparing: "Getting ready"
        case .localeUnavailable: "Language not supported"
        case .awaitingQualification: "Not enabled in this build"
        }
    }
    private var statusDetail: String {
        switch availability {
        case .available: "Powered by Apple Intelligence"
        case .unsupported: "Your saved conversations and wardrobe stay available."
        case .intelligenceOff: "Enable Apple Intelligence in iPhone Settings, then check again."
        case .preparing: "Apple Intelligence is preparing its model. Check again shortly."
        case .localeUnavailable: "Choose a supported Apple Intelligence language in iPhone Settings."
        case .awaitingQualification: "Your saved conversations and wardrobe stay available."
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Image(systemName: "sparkle").font(.system(size: 28, weight: .regular))
                        .foregroundStyle(AppTheme.controlIcon).accessibilityHidden(true)
                    Text("More from what you own.").font(AppTypography.section)
                        .foregroundStyle(AppTheme.ink).accessibilityAddTraits(.isHeader)
                    Text("Find outfit ideas, rediscover pieces and explore your wardrobe with Agent.")
                        .font(AppTypography.body).foregroundStyle(AppTheme.secondary)
                }
                HStack(alignment: .center, spacing: AppSpacing.medium) {
                    Image(systemName: availability == .available ? "checkmark.circle" : "info.circle")
                        .foregroundStyle(AppTheme.controlIcon).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text(statusTitle).font(AppTypography.fieldLabel).foregroundStyle(AppTheme.ink)
                        Text(statusDetail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Button { availability = OutfitSuggestions.modelAvailability() } label: {
                        Image(systemName: "arrow.clockwise").frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
                    }.buttonStyle(.plain).foregroundStyle(AppTheme.ink).accessibilityLabel("Check Agent availability again")
                }.padding(AppSpacing.large)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    aboutRow("Your wardrobe, in context", symbol: "tshirt", detail: "Uses relevant saved pieces, preferences and recorded wear. Choose what Agent can use in AI settings.")
                    aboutRow("On this iPhone", symbol: "iphone", detail: "Replies are generated on-device. Your conversations aren't sent to an AQD server.")
                    aboutRow("You're in control", symbol: "checkmark.shield", detail: "A reply doesn't change your records. Review suggestions and decide what to keep.")
                }
                NavigationLink { DeviceSupportView().secondaryPage() } label: {
                    HStack(spacing: AppSpacing.medium) {
                        Image(systemName: "iphone").foregroundStyle(AppTheme.controlIcon)
                        Text("Device support").foregroundStyle(AppTheme.ink)
                        Spacer(minLength: AppSpacing.small)
                        Image(systemName: "chevron.forward").font(AppTypography.disclosure).foregroundStyle(AppTheme.controlIcon).accessibilityHidden(true)
                    }.font(AppTypography.body).padding(.horizontal, AppSpacing.large).frame(minHeight: AppControlMetrics.rowHeight)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                }.buttonStyle(.plain)
                NavigationLink { AgentSettingsView().secondaryPage() } label: {
                    HStack(spacing: AppSpacing.medium) {
                        Image(systemName: "slider.horizontal.3").foregroundStyle(AppTheme.controlIcon)
                        Text("AI settings").foregroundStyle(AppTheme.ink)
                        Spacer(minLength: AppSpacing.small)
                        Image(systemName: "chevron.forward").font(AppTypography.disclosure).foregroundStyle(AppTheme.controlIcon).accessibilityHidden(true)
                    }.font(AppTypography.body).padding(.horizontal, AppSpacing.large).frame(minHeight: AppControlMetrics.rowHeight)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                }.buttonStyle(.plain)
                Text("AI can make mistakes. Check details that matter to you.")
                    .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.screen).padding(.top, AppSpacing.headerGap).padding(.bottom, AppSpacing.section)
        }.background(AppTheme.canvas).navigationTitle("About Agent").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ActionFooter {
                    PrimaryAction(title: "Open Agent") { state.agentLaunchID = UUID() }
                }
            }
            .onChange(of: scenePhase) { _, phase in if phase == .active { availability = OutfitSuggestions.modelAvailability() } }
    }
    private func aboutRow(_ title: String, symbol: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: symbol).font(.body).foregroundStyle(AppTheme.controlIcon)
                .frame(width: AppControlMetrics.disclosureLane, height: 24).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(title).font(AppTypography.fieldLabel).foregroundStyle(AppTheme.ink)
                Text(detail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
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
            Text("Restore replaces local data after review. Reset data clears AQD-owned records and files and returns to Welcome; original Photos and previous exported copies stay outside AQD.")
        }.padding(20) }.background(AppTheme.canvas).navigationTitle("Help and privacy").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ActionFooter {
                    Button { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } } label: {
                        GlassActionLabel(title: "Open iPhone Settings", systemImage: "gearshape")
                    }.buttonStyle(.plain)
                }
            }
    }
}

#if DEBUG
private struct DevelopmentSplashPreview: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exiting = false
    var body: some View {
        LaunchSplash(exiting: exiting).accessibilityLabel("AQD").task {
            do {
                try await Task.sleep(for: .seconds(1.15))
                withAnimation(.easeIn(duration: 0.4)) { exiting = true }
                try await Task.sleep(for: .seconds(0.45)); dismiss()
            } catch { }
        }
    }
}
#endif

/// Background photo recovery is displayed only inside Settings.
struct SettingsPhotoRecoveryView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        if let recovery = state.photoCleanupError {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(recovery).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                Button { state.retryPhotoCleanup() } label: {
                    SettingsRow(title: "Retry photo cleanup", symbol: "photo")
                }
            }
        }
    }
}
