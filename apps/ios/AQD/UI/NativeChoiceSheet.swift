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

/// A short source choice anchored to its row, including on compact iPhones.
struct PhotoSourcePopover: View {
    let photos: () -> Void
    let camera: () -> Void
    var edit: (() -> Void)? = nil
    var removeBackground: (() -> Void)? = nil
    var remove: (() -> Void)? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            choice("Choose from Photos", symbol: "photo.on.rectangle", action: photos)
            Divider()
            choice("Take photo", symbol: "camera", action: camera)
            if let edit { Divider(); choice("Edit photo", symbol: "crop", action: edit) }
            if let removeBackground { Divider(); choice("Remove background", symbol: "person.crop.rectangle", action: removeBackground) }
            if let remove { Divider(); choice("Remove photo", symbol: "trash", role: .destructive, action: remove) }
        }.padding(AppSpacing.large).frame(width: 280)
            .presentationCompactAdaptation(.popover)
            .accessibilityHint("Selected photos are copied into AQD on this device. Originals stay in Photos.")
    }

    private func choice(_ title: String, symbol: String, role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: symbol)
                    .foregroundStyle(role == .destructive ? AppTheme.error : AppTheme.controlIcon)
                    .frame(width: AppControlMetrics.disclosureLane).accessibilityHidden(true)
                Text(title).foregroundStyle(role == .destructive ? AppTheme.error : AppTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.font(AppTypography.body)
                .frame(maxWidth: .infinity, minHeight: AppControlMetrics.minimumTarget, alignment: .leading)
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}
