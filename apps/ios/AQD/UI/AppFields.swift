import SwiftUI
import UIKit

/// Persistent label and one opaque shell around a native control. Validation is
/// supplied by the feature; this presentation never mutates or validates a draft.
struct LabeledControl<Control: View>: View {
    let title: String
    var helper: String? = nil
    var validation: String? = nil
    @ViewBuilder let control: () -> Control
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title).font(AppTypography.supporting).foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            control()
                .font(AppTypography.body)
                .foregroundStyle(isEnabled ? AppTheme.ink : AppTheme.secondary)
                .padding(AppControlMetrics.fieldPadding)
                .frame(maxWidth: .infinity, minHeight: AppControlMetrics.fieldHeight, alignment: .leading)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
                .overlay {
                    if contrast == .increased || validation != nil {
                        RoundedRectangle(cornerRadius: AppRadius.field)
                            .stroke(validation == nil ? AppTheme.controlBoundary : AppTheme.error, lineWidth: 1)
                            .accessibilityHidden(true)
                    }
                }
                // Preserve the native control's name AND selected value.
                // TextField/Picker receive their persistent title at creation;
                // relabelling this shell erases Picker selection semantics.
                .accessibilityHint(validation ?? helper ?? "")
            if let validation {
                SemanticFeedback(role: .danger, message: validation)
            } else if let helper {
                Text(helper).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
            }
        }
        .onChange(of: validation) { oldValue, newValue in
            // Announce real error/recovery transitions once, not each invalid
            // keystroke. Keep the native insertion point and editing focus.
            guard oldValue != newValue, UIAccessibility.isVoiceOverRunning else { return }
            if let newValue, !newValue.isEmpty {
                UIAccessibility.post(notification: .announcement, argument: "\(title). \(newValue)")
            } else if let oldValue, !oldValue.isEmpty {
                UIAccessibility.post(notification: .announcement, argument: "\(title). Error cleared.")
            }
        }
    }
}

struct LabeledField: View {
    let title: String
    @Binding var text: String
    var multiline = false
    var helper: String? = nil
    var validation: String? = nil
    var accessibilityID: String = ""

    var body: some View {
        LabeledControl(title: title, helper: helper, validation: validation) {
            TextField(title, text: $text, axis: multiline ? .vertical : .horizontal)
                .lineLimit(multiline ? 3...8 : 1...1)
                .textFieldStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityIdentifier(accessibilityID)
        }
    }
}
