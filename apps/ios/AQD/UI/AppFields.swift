import AQDCore
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
            Text(title).font(AppTypography.fieldLabel).foregroundStyle(AppTheme.secondary)
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
    var prompt: String? = nil
    var multiline = false
    var characterLimit: Int? = nil
    var helper: String? = nil
    var validation: String? = nil
    var accessibilityID: String = ""
    var editingFocus: FocusState<Bool>.Binding? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            LabeledControl(title: title, helper: helper, validation: validation) {
                if let editingFocus {
                    editor.focused(editingFocus)
                } else {
                    editor
                }
            }
            if multiline { TextAreaCounter(text: text, limit: characterLimit ?? TextAreaLimits.note) }
        }
    }

    private var editor: some View {
        TextField(title, text: multiline ? $text.limited(to: characterLimit ?? TextAreaLimits.note) : $text,
                  prompt: Text(prompt ?? title).foregroundStyle(AppTheme.secondary),
                  axis: multiline ? .vertical : .horizontal)
            .lineLimit(multiline ? 3...8 : 1...1)
            .textFieldStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityIdentifier(accessibilityID)
    }
}

/// Metadata with native font/color accessibility attributes. The compact audit
/// comparator exposed UIKit labels where equivalent SwiftUI footnotes failed.
struct MetadataText: UIViewRepresentable {
    let text: String

    init(_ text: String) { self.text = text }

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.backgroundColor = .clear
        configure(label, environment: context.environment)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        configure(label, environment: context.environment)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        uiView.sizeThatFits(CGSize(width: proposal.width ?? .greatestFiniteMagnitude,
                                  height: proposal.height ?? .greatestFiniteMagnitude))
    }

    private func configure(_ label: UILabel, environment: EnvironmentValues) {
        label.text = text
        label.isAccessibilityElement = true
        label.accessibilityTraits = .staticText
        label.overrideUserInterfaceStyle = environment.colorScheme == .dark ? .dark : .light
        label.textColor = UIColor(cgColor: AppTheme.secondary.resolve(in: environment).cgColor)
        let rtl = environment.layoutDirection == .rightToLeft
        label.textAlignment = rtl ? .right : .left
        label.semanticContentAttribute = rtl ? .forceRightToLeft : .forceLeftToRight
        let traits = UITraitCollection(preferredContentSizeCategory: contentCategory(environment.dynamicTypeSize))
        label.font = UIFont.preferredFont(forTextStyle: .footnote, compatibleWith: traits)
    }

    private func contentCategory(_ size: DynamicTypeSize) -> UIContentSizeCategory {
        switch size {
        case .xSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .extraLarge
        case .xxLarge: .extraExtraLarge
        case .xxxLarge: .extraExtraExtraLarge
        case .accessibility1: .accessibilityMedium
        case .accessibility2: .accessibilityLarge
        case .accessibility3: .accessibilityExtraLarge
        case .accessibility4: .accessibilityExtraExtraLarge
        case .accessibility5: .accessibilityExtraExtraExtraLarge
        default: .large
        }
    }
}

/// Full-width neutral menu selection; the Picker retains selected-option semantics.
struct MenuSelectionLabel: View {
    let title: String
    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Text(title).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: AppSpacing.small)
            Image(systemName: "chevron.up.chevron.down").font(.footnote.weight(.medium))
                .foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
        }
        .font(AppTypography.body).foregroundStyle(AppTheme.ink)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
    }
}

extension Binding where Value == String {
    func limited(to limit: Int) -> Binding<String> {
        Binding(get: { wrappedValue }, set: { proposed in
            wrappedValue = TextAreaLimits.editedText(proposed, current: wrappedValue, limit: limit)
        })
    }
}

struct TextAreaCounter: View {
    let text: String
    let limit: Int
    var body: some View {
        Text("\(text.count) / \(limit)").font(AppTypography.metadata)
            .foregroundStyle(text.count > limit ? AppTheme.error : AppTheme.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityLabel("\(text.count) of \(limit) characters")
    }
}

/// A theme-owned date chip presenting the native calendar, preserving caller timezone.
struct ThemedDatePicker: View {
    let title: String
    @Binding var selection: Date
    var lowerBound = Date.distantPast
    var upperBound = Date.distantFuture
    var showsTitle = true
    @Environment(\.timeZone) private var timeZone
    @Environment(\.locale) private var locale
    @State private var presented = false
    init(_ title: String, selection: Binding<Date>, displayedComponents: DatePickerComponents = .date, showsTitle: Bool = true) {
        self.title = title; _selection = selection; self.showsTitle = showsTitle
    }
    init(_ title: String, selection: Binding<Date>, in range: PartialRangeThrough<Date>, displayedComponents: DatePickerComponents = .date, showsTitle: Bool = true) {
        self.title = title; _selection = selection; upperBound = range.upperBound; self.showsTitle = showsTitle
    }
    init(_ title: String, selection: Binding<Date>, in range: ClosedRange<Date>, displayedComponents: DatePickerComponents = .date, showsTitle: Bool = true) {
        self.title = title; _selection = selection; lowerBound = range.lowerBound; upperBound = range.upperBound; self.showsTitle = showsTitle
    }
    var body: some View {
        HStack {
            if showsTitle { Text(title) }
            Spacer(minLength: 12)
            Button { presented = true } label: {
                Text(dateLabel).padding(.horizontal, 12).padding(.vertical, 6)
                    .background(AppTheme.imageGround, in: Capsule()).frame(minHeight: 44).contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityLabel(title).accessibilityValue(dateLabel)
                .popover(isPresented: $presented) {
                    DatePicker(title, selection: $selection, in: lowerBound...upperBound, displayedComponents: .date)
                        .datePickerStyle(.graphical).labelsHidden().tint(AppTheme.ink)
                        .padding(16).frame(width: 320).background(AppTheme.surface)
                        .presentationCompactAdaptation(.popover)
                }
        }.foregroundStyle(AppTheme.ink)
    }
    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = locale; formatter.timeZone = timeZone; formatter.dateStyle = .medium
        return formatter.string(from: selection)
    }
}

struct AppSegmentedControl: View {
    @Binding var selection: String
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Namespace private var selectedSegment
    let options: [String]
    let accessibilityTitle: String
    var identifierPrefix = "segment"

    var body: some View {
        Group {
            if #available(iOS 26, *), !reduceTransparency, contrast != .increased {
                segments.glassEffect(.regular, in: Capsule())
            } else {
                segments.background(AppTheme.surface, in: Capsule())
                    .overlay(Capsule().stroke(contrast == .increased ? AppTheme.controlBoundary : AppTheme.divider, lineWidth: 1))
            }
        }.accessibilityElement(children: .contain).accessibilityLabel(accessibilityTitle)
    }
    private var segments: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { scope in
                Button { selection = scope } label: {
                    Text(scope).font(AppTypography.supporting).fontWeight(selection == scope ? .semibold : .regular)
                        .foregroundStyle(AppTheme.ink).frame(maxWidth: .infinity, minHeight: 44)
                        .background {
                            if selection == scope {
                                Capsule().fill(AppTheme.segmentSelection)
                                    .matchedGeometryEffect(id: "selected", in: selectedSegment)
                            }
                        }.contentShape(Capsule())
                }.buttonStyle(.plain)
                    .accessibilityAddTraits(selection == scope ? [.isSelected] : [])
                    .accessibilityIdentifier("\(identifierPrefix).\(scope.lowercased())")
            }
        }.padding(4).animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: selection)
    }
}
