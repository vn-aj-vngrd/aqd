import AQDCore
import SwiftUI

/// Which iPhones can run the Agent, what else it needs, and whether this iPhone is ready. Closet and Planner never depend on it.
struct DeviceSupportView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var availability = OutfitSuggestions.modelAvailability()
    private let machine = DeviceSupportView.machineIdentifier()

    private var status: (title: String, detail: String, ready: Bool) {
        switch availability {
        case .available: ("Ready on this iPhone", "Agent runs on this iPhone with Apple Intelligence.", true)
        case .unsupported: ("Not supported on this iPhone", "Agent needs an Apple Intelligence iPhone. Your closet, Planner and every manual path still work.", false)
        case .intelligenceOff: ("Apple Intelligence is off", "Turn it on in iPhone Settings, then check again.", false)
        case .preparing: ("Getting ready", "Apple Intelligence is still downloading its model. This can take a while on Wi-Fi.", false)
        case .localeUnavailable: ("Language not supported", "Choose a supported language for the iPhone and Siri in iPhone Settings.", false)
        case .awaitingQualification: ("Not enabled in this build", "Your closet, Planner and every manual path still work.", false)
        }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: AppSpacing.medium) {
                    Image(systemName: status.ready ? "checkmark.circle" : "info.circle").foregroundStyle(AppTheme.controlIcon).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text(status.title).font(AppTypography.fieldLabel).foregroundStyle(AppTheme.ink)
                        Text(status.detail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Button { availability = OutfitSuggestions.modelAvailability() } label: {
                        Image(systemName: "arrow.clockwise").frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
                    }.buttonStyle(.plain).foregroundStyle(AppTheme.ink).accessibilityLabel("Check again")
                }
            } header: { Text("This iPhone") } footer: {
                Text(AppleIntelligenceSupport.isEligible(machine: machine) ? "This iPhone model supports Apple Intelligence." : "This iPhone model isn’t on Apple’s Apple Intelligence list.")
            }.listRowBackground(AppTheme.surface)
            ForEach(AppleIntelligenceSupport.families, id: \.self) { family in
                Section(family) {
                    ForEach(AppleIntelligenceSupport.phones(in: family)) { phone in
                        Text(phone.name).foregroundStyle(AppTheme.ink)
                    }
                }.listRowBackground(AppTheme.surface)
            }
            Section("Also needed") {
                requirement("Software", AppleIntelligenceSupport.minimumSystem + " with Apple Intelligence turned on in iPhone Settings.")
                requirement("Storage", AppleIntelligenceSupport.storage)
                requirement("Region", AppleIntelligenceSupport.region)
                requirement("Language", "The iPhone and Siri language must be one of: " + AppleIntelligenceSupport.languages.joined(separator: ", ") + ".")
            }.listRowBackground(AppTheme.surface)
            Section {
                Text("Agent runs on the iPhone with Apple’s on-device model, so your closet never leaves it. On any other iPhone running iOS 18 or later, Closet, Planner, Today and Profile work fully by hand.")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            } header: { Text("Everything else") }.listRowBackground(AppTheme.surface)
        }.listStyle(.insetGrouped).listSectionSpacing(AppSpacing.large)
            .contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden).background(AppTheme.canvas)
            .navigationTitle("Device support").navigationBarTitleDisplayMode(.inline)
            .onChange(of: scenePhase) { _, phase in if phase == .active { availability = OutfitSuggestions.modelAvailability() } }
    }

    private func requirement(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(title).font(AppTypography.fieldLabel).foregroundStyle(AppTheme.ink)
            Text(detail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).accessibilityElement(children: .combine)
    }

    /// The hardware identifier, such as `iPhone18,2`. A simulator reports the model it stands in for.
    private static func machineIdentifier() -> String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulated }
        var system = utsname(); uname(&system)
        return withUnsafePointer(to: &system.machine) { $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { String(cString: $0) } }
    }
}
