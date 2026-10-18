import SwiftUI

/// Readable impact rows shared by export, restore and erase reviews.
struct LocalDataSummaryView: View {
    let summary: LocalArchiveSummary
    private func count(_ value: Int, _ singular: String, _ plural: String) -> String {
        "\(value) \(value == 1 ? singular : plural)"
    }
    private var rows: [(String, String, String)] {
        [("Closet", "tshirt", [count(summary.pieces, "piece", "pieces"), count(summary.outfits, "outfit", "outfits"), count(summary.themes, "theme", "themes")].joined(separator: ", ")),
         ("Planner", "calendar", [count(summary.plans, "plan", "plans"), count(summary.entries, "planned date", "planned dates")].joined(separator: ", ")),
         ("Memories & wear", "photo.stack", [count(summary.fits, "fit memory", "fit memories"), count(summary.wear, "wear record", "wear records")].joined(separator: ", ")),
         ("Personal content", "text.bubble", [count(summary.conversations, "conversation", "conversations"), count(summary.personalCards, "personal card", "personal cards"), count(summary.drafts, "draft", "drafts")].joined(separator: ", "))]
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: row.1).font(.system(size: 18, weight: .regular)).foregroundStyle(AppTheme.secondary).frame(width: 24).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.0).font(AppTypography.supporting).foregroundStyle(AppTheme.ink)
                        Text(row.2).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }.padding(14).accessibilityElement(children: .combine)
                if index < rows.count - 1 { Divider().padding(.leading, 50) }
            }
        }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}
