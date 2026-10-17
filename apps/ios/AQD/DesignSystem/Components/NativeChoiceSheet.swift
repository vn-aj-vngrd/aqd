import SwiftUI

/// Simple task choices use native inset-grouped rows and native sheet chrome.
struct NativeChoiceSheet<Content: View>: View {
    let title: String
    var footer: String? = nil
    @ViewBuilder let content: () -> Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section { content().listRowBackground(AppTheme.surface) } footer: {
                    if let footer { Text(footer).font(AppTypography.metadata) }
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, 56)
            .contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden)
            .background(AppTheme.canvas)
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                if #available(iOS 26.0, *) {
                    Button(role: .close) { dismiss() }.accessibilityLabel("Close")
                } else {
                    Button { dismiss() } label: { Label("Close", systemImage: "xmark") }
                }
            } }
        }
        .tint(AppTheme.ink)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct NativeChoiceRow: View {
    let title: String
    let symbol: String
    var disclosure = true
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AccessoryLabel(title, systemImage: symbol)
                Spacer(minLength: 12)
                if disclosure {
                    Image(systemName: "chevron.forward").font(AppTypography.disclosure)
                        .foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                }
            }
            .font(AppTypography.body).foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
        }
    }
}
