import AQDCore
import SwiftUI
import UIKit

struct LocalSettingsView: View {
    @Environment(AppState.self) private var state
    @State private var weather = false
    var body: some View {
        List {
            Section {
                Text("Your closet is on this iPhone.").font(.title2)
                Text("No account or automatic cloud backup. Device loss or deleting AQD can lose these records.").foregroundStyle(AppTheme.secondary)
            }
            Section("Personal settings") {
                NavigationLink("Style") { LocalStyleSettingsView() }
                NavigationLink { LocalAppearanceSettingsView() } label: { HStack { Text("Appearance"); Spacer(); Text(state.appearance.rawValue.capitalized).foregroundStyle(AppTheme.secondary) } }
                NavigationLink("On-device assistance") { LocalAssistanceSettingsView() }
                NavigationLink("Help and privacy") { LocalPrivacySettingsView() }
                Button("Take the tour") { state.beginTour(from: .settings) }
                Button { weather = true } label: { HStack { Text("Weather"); Spacer(); Text(state.weatherClient?.local?.enabled == true ? state.weatherClient?.local?.place?.name ?? "Place unavailable" : "Off").foregroundStyle(AppTheme.secondary) } }
            }
        }.navigationTitle("Settings").navigationBarTitleDisplayMode(.inline).scrollContentBackground(.hidden).background(AppTheme.canvas)
            .onAppear { state.reloadSettings() }
            .sheet(isPresented: $weather) { if let client = state.weatherClient { WeatherContextView(client: client, persistsPreference: true) { _ in true } } }
    }
}
struct LocalAppearanceSettingsView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        List {
            Text("System follows your device; Light or Dark stays fixed.").foregroundStyle(AppTheme.secondary)
            if let error = state.settingsError { Text(error).foregroundStyle(AppTheme.error); Button("Retry appearance save") { state.saveAppearance(state.settings?.appearance ?? .system) } }
            ForEach(LocalAppearance.allCases, id: \.self) { value in
                Button { state.saveAppearance(value) } label: { HStack { Text(value.rawValue.capitalized).foregroundStyle(AppTheme.ink); Spacer(); if state.settings?.appearance == value || (state.settings == nil && value == .system) { Image(systemName: "checkmark").foregroundStyle(AppTheme.actionText) } }.frame(minHeight: 44) }
                    .accessibilityValue(state.settings?.appearance == value ? "Selected" : "Not selected")
            }
        }.navigationTitle("Appearance").navigationBarTitleDisplayMode(.inline)
    }
}
struct LocalStyleSettingsView: View {
    @Environment(AppState.self) private var state
    @State private var answers: StylePreferences?
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 20) {
            Text("Answer six questions, then review. No preference is valid.").font(AppTypography.section)
            if let answers { ForEach(0..<6, id: \.self) { index in VStack(alignment: .leading, spacing: 4) { Text(StylePreferences.titles[index]).font(.headline); Text(answers.summary(at: index)).foregroundStyle(AppTheme.secondary) } } }
            else { Text("No preferences added yet.") }
            PrimaryAction(title: "Edit preferences") { state.openStyle(source: .settings) }
            Text("Saved on this iPhone. Allowed Style context requires an explicit choice in Agent. Body-use permission starts off and remains separately controlled.").font(.footnote).foregroundStyle(AppTheme.secondary)
        }.padding(20) }.background(AppTheme.canvas).navigationTitle("Style").navigationBarTitleDisplayMode(.inline)
            .onAppear { answers = try? state.store?.localExperience().style?.answers }
    }
}
struct LocalAssistanceSettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.scenePhase) private var scenePhase
    @State private var availability = OutfitSuggestions.availability()
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 20) {
            Text("Apple Intelligence").font(AppTypography.section)
            Text(availability.message)
            SecondaryAction(title: "Check availability again") { availability = OutfitSuggestions.availability() }
            Text("Quick rules and manual tools").font(AppTypography.section)
            Text("Agent explains actual availability. Your closet, manual outfits and planning remain usable. No cloud model is used.")
            Text("Review before saving").font(AppTypography.section)
            Text("Suggestions are drafts. Approve exact reviewed changes; a receipt follows successful local saving.")
            PrimaryAction(title: "Open Agent") { state.agentLaunchID = UUID() }
        }.padding(20) }.background(AppTheme.canvas).navigationTitle("On-device assistance").navigationBarTitleDisplayMode(.inline)
            .onChange(of: scenePhase) { _, phase in if phase == .active { availability = OutfitSuggestions.availability() } }
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
            SecondaryAction(title: "Open iPhone Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
            Text("Restore replaces local data after review. Erase clears AQD-owned records and files; original Photos and previous exported copies stay outside AQD.")
        }.padding(20) }.background(AppTheme.canvas).navigationTitle("Help and privacy").navigationBarTitleDisplayMode(.inline)
    }
}
