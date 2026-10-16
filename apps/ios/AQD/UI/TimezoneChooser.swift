import SwiftUI

/// Selection applies to the caller's retained draft, never to saved records.
struct TimezoneChooser: View {
    let current: String
    let select: (String) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    private var zones: [String] {
        let all = [current] + TimeZone.knownTimeZoneIdentifiers.filter { $0 != current }
        return all.filter { query.isEmpty || $0.localizedCaseInsensitiveContains(query) }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Selecting a zone changes this draft only. Its calendar dates stay the same.")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                if zones.isEmpty { AppEmptyState("No matching timezones", systemImage: "globe") }
                LazyVStack(spacing: 0) {
                    ForEach(zones, id: \.self) { zone in
                        Button { if select(zone) { dismiss() } } label: {
                            HStack(spacing: 12) {
                                Text(zone).frame(maxWidth: .infinity, alignment: .leading)
                                if zone == current { Image(systemName: "checkmark").foregroundStyle(AppTheme.actionText) }
                            }.foregroundStyle(AppTheme.ink).frame(minHeight: 54).padding(.horizontal, 14)
                        }.buttonStyle(.plain).accessibilityValue(zone == current ? "Selected" : "Not selected")
                    }
                }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Timezone").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search timezones").tint(AppTheme.ink)
    }
}
