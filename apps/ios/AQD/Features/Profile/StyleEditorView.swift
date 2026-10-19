import AQDCore
import SwiftUI

struct StyleEditorView: View {
    @Bindable var model: StyleEditorModel
    @State private var confirmsDiscard = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Saved-screen entrance: 0 hidden, 1 mark, 2 look, 3 words, 4 actions.
    @State private var savedStage = 0
    /// Set when Next is tapped on an unanswered step; cleared by answering or changing step.
    @State private var showsNeed = false
    @State private var needTaps = 0
    /// Direction of the last step change, so questions slide forward on Next and back on Back.
    @State private var forward = true
    private var page: Int { model.draft.page }
    private let questions = ["What would you like help with?", "What do you dress for?", "What feels like you?", "How do you like clothes to fit?", "Body details, only if you want", "Colors and patterns you enjoy"]
    private let hints = ["Choose up to two, or No preference. Your answers stay private.", "Choose any, or No preference. We won’t infer your schedule.", "Choose any styles you enjoy, or No preference.", "Choose any, or No preference. Suggestions are not a size or try-on guarantee.", "Add optional details, choose Not sure, or decline.", "Choose colors and patterns, or No preference. Your choices stay private."]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let error = model.error {
                        VStack(alignment: .leading, spacing: 8) {
                            SemanticFeedback(role: model.unknown ? .warning : .danger, message: error, contained: true)
                            if page != 6 && model.saved == nil { Button("Retry saving draft") { model.persist() }.frame(minHeight: 44) }
                        }.accessibilityIdentifier("style.error")
                    }
                    if model.saved != nil {
                        savedContent
                            .transition(.opacity)
                            .task { await revealSaved() }
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Step \(page + 1) of 7").font(.subheadline).foregroundStyle(AppTheme.secondary)
                                .accessibilityIdentifier("style.progress")
                            HStack(spacing: 4) {
                                ForEach(0..<7, id: \.self) { index in
                                    Capsule().fill(index <= page ? AppTheme.ink : AppTheme.divider).frame(height: 4)
                                }
                            }.accessibilityHidden(true)
                        }
                        Group {
                        if page == 6 { review }
                        else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(questions[page]).font(AppTypography.section)
                                Text(hints[page]).foregroundStyle(AppTheme.secondary)
                                if showsNeed {
                                    Label(needMessage, systemImage: "exclamationmark.circle")
                                        .font(AppTypography.supporting).foregroundStyle(AppTheme.warning)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                        .accessibilityIdentifier("style.need")
                                }
                            }
                            question
                        }
                        }
                        .id(page)
                        .transition(stepTransition)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
                    .animation(reduceMotion ? nil : .smooth(duration: 0.4), value: model.saved != nil)
            }
            .background(AppTheme.canvas)
            .navigationTitle(model.saved == nil ? StylePreferences.titles[page] : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(model.saved == nil ? .visible : .hidden, for: .navigationBar)
            .toolbar {
                if model.saved == nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if page > 0 {
                                forward = model.draft.editingFromReview
                                withAnimation(stepAnimation) { model.update { $0.page = $0.editingFromReview ? 6 : $0.page - 1; $0.editingFromReview = false } }
                            } else if model.hasUnsavedChanges { confirmsDiscard = true }
                            else { model.discard() }
                        } label: { Label("Back", systemImage: "chevron.backward") }
                        .disabled(model.pending || model.unknown)
                        .accessibilityIdentifier("style.back").tint(AppTheme.ink)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if model.saved != nil {
                        EmptyView()
                    } else if page == 6 {
                        ToolbarSaveAction(title: model.unknown ? "Check save" : "Save", isPending: model.pending) { Task { await model.save() } }
                            .disabled(model.pending || (!model.unknown && (!model.draft.isComplete || (model.draft.baseRevision > 0 && !model.hasUnsavedChanges)))).accessibilityLabel(model.unknown ? "Check save" : "Save preferences")
                    } else {
                        ToolbarForwardAction(title: model.draft.editingFromReview ? "Review preferences" : "Next question", usesGlass: true) { advance() }
                            .disabled(model.pending || model.unknown || model.error != nil)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if model.saved != nil {
                    // The same bottom stack as Welcome: one prominent glass action, one quiet one, one line of reassurance.
                    VStack(spacing: AppSpacing.small) {
                        Button { model.finish() } label: { GlassActionLabel(title: savedContinueTitle, prominent: true) }
                            .buttonStyle(.plain).accessibilityIdentifier("style.saved.continue")
                        Button { model.finish(openCloset: true) } label: {
                            GlassActionLabel(title: model.draft.source == .onboarding ? "Skip the tour" : "Open my closet")
                        }.buttonStyle(.plain).accessibilityIdentifier("style.saved.closet")
                        Text("Change these anytime in Profile → Style.")
                            .font(.footnote).foregroundStyle(AppTheme.secondary).padding(.top, AppSpacing.xSmall)
                    }
                    .padding(.horizontal, AppSpacing.screen).padding(.top, AppSpacing.small).padding(.bottom, AppSpacing.small)
                    .opacity(savedStage >= 4 ? 1 : 0).offset(y: savedStage >= 4 ? 0 : 18)
                }
            }
            .draftDiscardConfirmation(isPresented: $confirmsDiscard, title: "Discard this preference draft?",
                                  message: "Only this draft will be removed. Your saved preferences stay unchanged.") {
                    confirmsDiscard = false
                    model.discard()
                }
            .onChange(of: model.draft.isAnswered(page)) { _, answered in if answered { hideNeed() } }
            .onChange(of: page) { hideNeed() }
            .sensoryFeedback(.warning, trigger: needTaps)
            .interactiveDismissDisabled()
        }.tint(AppTheme.ink)
    }

    /// Next stays tappable. An unanswered step explains what it needs instead of leaving a dimmed button with no reason.
    private func advance() {
        guard model.draft.isAnswered(page) else {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) { showsNeed = true }
            needTaps += 1
            AccessibilityNotification.Announcement(needMessage).post()
            return
        }
        forward = true
        withAnimation(stepAnimation) { model.next() }
    }
    /// Questions slide in from the side they are heading to and fade, like turning a page; Reduce Motion keeps only the fade.
    private var stepTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                           removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity))
    }
    private var stepAnimation: Animation { reduceMotion ? .easeInOut(duration: 0.2) : .smooth(duration: 0.38) }
    private func hideNeed() { withAnimation(reduceMotion ? nil : .smooth(duration: 0.2)) { showsNeed = false } }
    private var needMessage: String {
        switch page {
        case 4: "Fix the details above, or choose Not sure, to continue."
        case 5: "Choose a color or pattern, or tap No color or pattern preference."
        default: "Pick at least one, or choose No preference, to continue."
        }
    }

    private var savedContinueTitle: String {
        switch model.draft.source {
        case .onboarding: "Show me around"
        case .profile: "Back to Profile"
        case .settings: "Back to Settings"
        }
    }
    private var savedContent: some View {
        VStack(spacing: AppSpacing.section) {
            AQDMark(size: 56)
                .scaleEffect(savedStage >= 1 ? 1 : 0.85).opacity(savedStage >= 1 ? 1 : 0).blur(radius: savedStage >= 1 ? 0 : 6)
            EntryIllustration(kind: .ready)
                .frame(maxWidth: 300)
                .scaleEffect(savedStage >= 2 ? 1 : 0.94).opacity(savedStage >= 2 ? 1 : 0)
            VStack(spacing: AppSpacing.small) {
                Label(model.draft.source == .onboarding ? "You’re all set" : "Preferences saved", systemImage: "checkmark.circle")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    .symbolEffect(.bounce, value: savedStage >= 3)
                Text("A closet that feels\nmore like you.")
                    .font(.largeTitle.weight(.medium)).tracking(-0.8).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                Text(model.draft.source == .onboarding
                     ? "Your choices stay on this iPhone.\nTake a one-minute look around, or skip it."
                     : "Your choices stay on this iPhone.\nSuggestions now lean toward what feels like you.")
                    .font(AppTypography.body).foregroundStyle(AppTheme.secondary).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(savedStage >= 3 ? 1 : 0).offset(y: savedStage >= 3 ? 0 : 14)
        }
        .frame(maxWidth: .infinity).padding(.top, AppSpacing.large)
        .accessibilityIdentifier("style.saved.receipt")
    }
    /// The questions fade away, then the receipt builds in the same order as Welcome: mark, look, words, actions.
    private func revealSaved() async {
        guard !reduceMotion else { savedStage = 4; return }
        do {
            for stage in 1...4 {
                try await Task.sleep(for: .milliseconds(stage == 1 ? 120 : 220))
                withAnimation(.smooth(duration: 0.55)) { savedStage = stage }
            }
        } catch { savedStage = 4 }
    }

    @ViewBuilder private var question: some View {
        if page < 4 {
            let step = page
            VStack(spacing: 0) {
                ForEach(StylePreferences.options[step], id: \.self) { option in
                    let selected = model.draft.answers.choices(at: step).contains(option)
                    Button {
                        model.update { $0.answers.choose(option, at: step) }
                    } label: {
                        HStack(spacing: 12) {
                            Text(option).foregroundStyle(AppTheme.ink)
                            Spacer(minLength: 8)
                            Image(systemName: selected ? "checkmark.square.fill" : "square")
                                .foregroundStyle(selected ? AppTheme.ink : AppTheme.secondary)
                        }.padding(16).frame(maxWidth: .infinity, minHeight: 56).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel(option).accessibilityValue(selected ? "Selected" : "Not selected")
                        .disabled(model.pending || model.unknown)
                    if option != StylePreferences.options[step].last { Divider().padding(.leading, 16) }
                }
            }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
            if page == 3 {
                LabeledField(title: "Comfort preferences", text: answerBinding(\.comfort), prompt: "Fabrics, coverage or anything to avoid")
            }
        } else if page == 4 { bodyDetails }
        else { colorDetails }
    }

    private var bodyDetails: some View { BodyDetailsView(model: model) }

    private var colorDetails: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                ForEach(StyleColorField.allCases, id: \.self) { field in
                    NavigationLink {
                        StyleColorSelectionView(model: model, field: field).secondaryPage()
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(field.rawValue).foregroundStyle(AppTheme.ink)
                                let value = model.draft.answers.colors[keyPath: field.keyPath]
                                Text(value.isEmpty ? "Not selected" : value)
                                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.forward").font(AppTypography.disclosure)
                                .foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                        }.padding(16).frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    if field != StyleColorField.allCases.last { Divider().padding(.leading, 16) }
                }
            }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
            Button {
                model.update { $0.answers.colors = ColorPreferences(); $0.answers.colors.declined = true }
            } label: {
                HStack(spacing: 12) {
                    Text("No color or pattern preference").foregroundStyle(AppTheme.ink)
                    Spacer(minLength: 8)
                    Image(systemName: model.draft.answers.colors.declined ? "checkmark.square.fill" : "square")
                        .foregroundStyle(model.draft.answers.colors.declined ? AppTheme.ink : AppTheme.secondary).accessibilityHidden(true)
                }.padding(16).frame(maxWidth: .infinity, minHeight: 56).contentShape(Rectangle())
            }.buttonStyle(.plain).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                .accessibilityValue(model.draft.answers.colors.declined ? "Selected" : "Not selected")
        }.disabled(model.pending || model.unknown)
    }

    private var review: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("\(model.draft.answeredCount) of 6 questions answered\(model.draft.answers.allDeclined ? ", all declined" : "")").font(.subheadline)
            ForEach([Array(0..<3), Array(3..<6)], id: \.self) { group in
                VStack(spacing: 0) {
                    ForEach(group, id: \.self) { step in
                        Button {
                            forward = false
                            withAnimation(stepAnimation) { model.update { $0.page = step; $0.editingFromReview = true } }
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(["Goals", "Occasions", "Style", "Fit & comfort", "Body details", "Colors & patterns"][step]).font(.body.weight(.medium))
                                    Text(model.draft.answers.summary(at: step)).font(.subheadline).foregroundStyle(AppTheme.secondary)
                                    if step == 4 { Text("Use for suggestions: \(model.draft.answers.body.useForSuggestions ? "On" : "Off")").font(.footnote).foregroundStyle(AppTheme.secondary) }
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.forward").font(AppTypography.disclosure).frame(width: 22).foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                            }.padding(14).frame(maxWidth: .infinity, minHeight: 80, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.plain).foregroundStyle(AppTheme.ink).accessibilityIdentifier("style.review.\(step)")
                            .disabled(model.pending || model.unknown)
                    }
                }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
            }
            Text("Your answers stay private on this iPhone. Body details are optional and used for suggestions only when you allow it. No size or virtual try-on guarantee.")
                .font(.footnote).foregroundStyle(AppTheme.secondary)
        }
    }

    private func answerBinding(_ key: WritableKeyPath<StylePreferences, String>) -> Binding<String> {
        Binding(get: { model.draft.answers[keyPath: key] }, set: { value in model.update { $0.answers[keyPath: key] = value } })
    }
}

private enum StyleColorField: String, CaseIterable {
    case preferredColors = "Preferred colors", avoidedColors = "Colors to avoid"
    case preferredPatterns = "Preferred patterns", avoidedPatterns = "Patterns to avoid"
    var keyPath: WritableKeyPath<ColorPreferences, String> {
        switch self {
        case .preferredColors: \.preferredColors
        case .avoidedColors: \.avoidedColors
        case .preferredPatterns: \.preferredPatterns
        case .avoidedPatterns: \.avoidedPatterns
        }
    }
    var options: [String] {
        switch self {
        case .preferredColors, .avoidedColors:
            ["Black", "White", "Cream", "Beige", "Gray", "Brown", "Navy", "Blue", "Green", "Red", "Pink", "Purple", "Yellow", "Orange", "Gold", "Silver"]
        case .preferredPatterns, .avoidedPatterns:
            ["Solid", "Stripes", "Checks", "Plaid", "Florals", "Polka dots", "Animal print", "Geometric", "Abstract", "Graphic"]
        }
    }
}

/// A pushed choice page with the app's editor pattern: changes stay on this page until Save, and Back leaves them behind.
private struct StyleColorSelectionView: View {
    @Bindable var model: StyleEditorModel
    let field: StyleColorField
    @Environment(\.dismiss) private var dismiss
    @State private var working: String?
    @State private var addingCustom = false
    @State private var custom = ""
    private var saved: String { model.draft.answers.colors[keyPath: field.keyPath] }
    private var value: String { working ?? saved }
    private var selected: [String] { ColorPreferences.selections(in: value) }
    private var options: [String] {
        field.options + selected.filter { item in
            !field.options.contains { $0.caseInsensitiveCompare(item) == .orderedSame }
        }.reduce(into: [String]()) { result, item in
            if !result.contains(where: { $0.caseInsensitiveCompare(item) == .orderedSame }) { result.append(item) }
        }
    }
    private var changed: Bool { ColorPreferences.selections(in: value) != ColorPreferences.selections(in: saved) }
    private var locked: Bool { model.pending || model.unknown }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                if let error = model.error {
                    SemanticFeedback(role: model.unknown ? .warning : .danger, message: error, contained: true)
                    Button("Retry saving draft") { model.persist() }.frame(minHeight: 44).disabled(locked)
                }
                Text("Choose any. Nothing changes until you tap Save.")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                VStack(spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        let isSelected = selected.contains { $0.caseInsensitiveCompare(option) == .orderedSame }
                        Button { toggle(option) } label: {
                            HStack(spacing: 12) {
                                Text(option).foregroundStyle(AppTheme.ink)
                                Spacer(minLength: 8)
                                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(isSelected ? AppTheme.ink : AppTheme.secondary).accessibilityHidden(true)
                            }.padding(.horizontal, 16).frame(maxWidth: .infinity, minHeight: 52).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityLabel(option).accessibilityValue(isSelected ? "Selected" : "Not selected")
                            .disabled(locked)
                        Divider().padding(.leading, 16)
                    }
                    Button { custom = ""; addingCustom = true } label: {
                        Label("Add your own", systemImage: "plus").foregroundStyle(AppTheme.ink)
                            .padding(.horizontal, 16).frame(maxWidth: .infinity, minHeight: 52, alignment: .leading).contentShape(Rectangle())
                    }.buttonStyle(.plain).disabled(locked)
                }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
            }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.top, AppSpacing.small).padding(.bottom, 24)
        }
        .background(AppTheme.canvas.ignoresSafeArea())
        .navigationTitle(field.rawValue).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                ToolbarSaveAction(title: "Save") { save() }.disabled(!changed || locked)
                    .accessibilityIdentifier("style.colors.save")
            }
        }
        .sensoryFeedback(.selection, trigger: selected)
        .appConfirmation("Add your own", isPresented: $addingCustom) {
            Button("Add") {
                var current = value
                for item in ColorPreferences.selections(in: custom)
                where !ColorPreferences.selections(in: current).contains(where: { $0.caseInsensitiveCompare(item) == .orderedSame }) {
                    current = ColorPreferences.toggling(item, in: current)
                }
                working = current
            }.disabled(ColorPreferences.selections(in: custom).isEmpty || locked)
            Button("Cancel", role: .cancel) {}
        } message: {
            TextField("Your preference", text: $custom)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Your preference")
        }
    }
    private func toggle(_ option: String) { working = ColorPreferences.toggling(option, in: value) }
    private func save() {
        let result = value
        model.update {
            $0.answers.colors[keyPath: field.keyPath] = result
            $0.answers.colors.declined = false
        }
        dismiss()
    }
}
