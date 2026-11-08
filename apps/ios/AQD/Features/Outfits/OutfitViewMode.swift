import SwiftUI

/// How an outfit's pieces are shown. One remembered choice is shared by Outfit detail and Build outfit.
enum OutfitViewMode: String, CaseIterable, Identifiable {
    case collage = "Collage"
    case mannequin = "Mannequin"

    static let storageKey = "outfit.viewMode"
    var id: String { rawValue }
}

struct OutfitViewModePicker: View {
    @Binding var mode: OutfitViewMode

    var body: some View {
        Picker("Outfit view", selection: $mode) {
            ForEach(OutfitViewMode.allCases) { Text($0.rawValue).tag($0) }
        }.pickerStyle(.segmented).accessibilityIdentifier("outfit.viewMode")
    }
}
