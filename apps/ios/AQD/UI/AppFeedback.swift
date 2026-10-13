import SwiftUI

/// App-owned messages only, never inserted into native alerts/dialogs.
struct SemanticFeedback: View {
    enum Role: CaseIterable {
        case neutral, information, success, warning, danger

        var symbol: String {
            switch self {
            case .neutral, .information: "info.circle"
            case .success: "checkmark.circle"
            case .warning: "exclamationmark.triangle"
            case .danger: "exclamationmark.octagon"
            }
        }
        var foreground: Color {
            switch self {
            case .neutral: AppTheme.secondary
            case .information: AppTheme.information
            case .success: AppTheme.success
            case .warning: AppTheme.warning
            case .danger: AppTheme.error
            }
        }
        var ground: Color {
            switch self {
            case .neutral: AppTheme.surface
            case .information: AppTheme.informationSurface
            case .success: AppTheme.successSurface
            case .warning: AppTheme.warningSurface
            case .danger: AppTheme.errorSurface
            }
        }
    }

    let role: Role
    let message: String
    var contained = false

    var body: some View {
        Label {
            Text(message).font(AppTypography.supporting)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: role.symbol)
                .font(.system(size: AppControlMetrics.feedbackSymbol))
                .foregroundStyle(role.foreground)
                .frame(width: AppControlMetrics.feedbackSymbol)
                .accessibilityHidden(true)
        }
        .labelStyle(FeedbackLabelStyle())
        .padding(.vertical, contained ? AppControlMetrics.fieldPadding : 0)
        .padding(.horizontal, contained ? AppSpacing.large : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(contained ? role.ground : .clear, in: RoundedRectangle(cornerRadius: AppRadius.group))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.isStaticText)
    }
}

private struct FeedbackLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
            configuration.icon
            configuration.title
        }
    }
}

/// One native indeterminate spinner and a truthful operation label. Use either
/// this inline component OR PrimaryAction.isPending for the same operation.
struct OperationProgress: View {
    let title: String
    var body: some View {
        HStack(spacing: AppSpacing.small) {
            ProgressView().tint(AppTheme.accent).accessibilityHidden(true)
            Text(title).font(AppTypography.supporting).foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }
}
