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
            .scrollContentBackground(.hidden)
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
                Label(title, systemImage: symbol)
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

/// A short source choice anchored to its row, including on compact iPhones.
struct PhotoSourcePopover: View {
    let photos: () -> Void
    let camera: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: photos) { Label("Choose from Photos", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity, minHeight: 44, alignment: .leading) }
            Divider()
            Button(action: camera) { Label("Take photo", systemImage: "camera").frame(maxWidth: .infinity, minHeight: 44, alignment: .leading) }
            Text("Selected photos are copied into AQD on this device. iCloud Photos may download your selection. Originals stay in Photos.")
                .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).padding(.top, 12)
        }.buttonStyle(.plain).foregroundStyle(AppTheme.ink).padding(16).frame(width: 280)
            .presentationCompactAdaptation(.popover)
    }
}
