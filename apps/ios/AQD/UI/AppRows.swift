import SwiftUI

/// Navigation affordance, not an immediate command or replacement for Menu.
struct DisclosureRow: View {
    enum Placement { case standalone, grouped }
    let title: String
    var value: String? = nil
    var placement: Placement = .standalone
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.medium) {
                Group {
                    if typeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) { labels }
                    } else {
                        HStack(spacing: AppSpacing.medium) { labels }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.forward")
                    .font(.system(size: AppControlMetrics.disclosureLane))
                    .frame(width: AppControlMetrics.disclosureLane)
                    .foregroundStyle(AppTheme.secondary)
                    .accessibilityHidden(true)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, AppControlMetrics.fieldPadding)
            .padding(.vertical, AppSpacing.small)
            .frame(maxWidth: .infinity, minHeight: AppControlMetrics.rowHeight, alignment: .leading)
            .background(placement == .standalone ? AppTheme.surface : .clear,
                        in: RoundedRectangle(cornerRadius: AppRadius.group))
            .overlay {
                if contrast == .increased && placement == .standalone {
                    RoundedRectangle(cornerRadius: AppRadius.group)
                        .stroke(AppTheme.controlBoundary, lineWidth: 1).accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value ?? "")
    }

    @ViewBuilder private var labels: some View {
        Text(title).font(AppTypography.body)
            .foregroundStyle(isEnabled ? AppTheme.ink : AppTheme.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        if let value {
            Text(value).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                .multilineTextAlignment(typeSize.isAccessibilitySize ? .leading : .trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Caller supplies uniquely identified related rows. The group alone owns
/// separators: zero for one row, none after the last. Native List/Form already
/// own their grouping and should not be wrapped again.
struct SurfaceGroup<Data: RandomAccessCollection, ID: Hashable, Row: View>: View {
    let data: Data
    let id: KeyPath<Data.Element, ID>
    var separators = true
    var separatorInsets: EdgeInsets
    @ViewBuilder let row: (Data.Element) -> Row

    init(_ data: Data, id: KeyPath<Data.Element, ID>, separators: Bool = true,
         separatorInsets: EdgeInsets = EdgeInsets(top: 0, leading: AppControlMetrics.fieldPadding,
                                                 bottom: 0, trailing: AppControlMetrics.fieldPadding),
         @ViewBuilder row: @escaping (Data.Element) -> Row) {
        self.data = data
        self.id = id
        self.separators = separators
        self.separatorInsets = separatorInsets
        self.row = row
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(data, id: id) { element in
                row(element)
                if separators && element[keyPath: id] != data.last.map({ $0[keyPath: id] }) {
                    Rectangle().fill(AppTheme.divider).frame(height: 1)
                        .padding(separatorInsets)
                        .accessibilityHidden(true)
                }
            }
        }
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.group))
    }
}
