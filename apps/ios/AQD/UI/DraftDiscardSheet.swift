import SwiftUI

/// Native sheet and button styles, with explicit safe and destructive actions.
struct DraftDiscardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    let title: String
    let message: String
    let discard: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title).font(AppTypography.section).accessibilityAddTraits(.isHeader)
                Text(message).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                VStack(spacing: 12) {
                    Button(role: .cancel) { dismiss() } label: {
                        Text("Keep editing").foregroundStyle(AppTheme.onAccent).frame(maxWidth: .infinity, minHeight: 26)
                    }.tint(AppTheme.accent).keyboardShortcut(.cancelAction)
                    Button(role: .destructive, action: discard) {
                        Text("Discard draft").foregroundStyle(AppTheme.onAccent).frame(maxWidth: .infinity, minHeight: 26)
                    }.tint(AppTheme.dangerFill)
                }.buttonStyle(.borderedProminent).buttonBorderShape(.capsule).controlSize(.large)
            }.padding(24)
        }
        .background(AppTheme.canvas)
        .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.height(320), .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("draft.discard.confirmation")
    }
}
