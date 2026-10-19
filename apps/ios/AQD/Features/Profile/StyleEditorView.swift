import AQDCore
import SwiftUI

struct StyleEditorView: View {
    @Bindable var model: StyleEditorModel
    @State private var confirmsDiscard = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var savedArrived = false
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
                            .opacity(savedArrived ? 1 : 0)
                            .offset(y: savedArrived || reduceMotion ? 0 : 12)
                            .task { withAnimation(reduceMotion ? nil : .smooth(duration: 0.35)) { savedArrived = true } }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Step \(page + 1) of 7").font(.subheadline).foregroundStyle(AppTheme.secondary)
                                .accessibilityIdentifier("style.progress")
                            ProgressView(value: Double(page + 1), total: 7).accessibilityHidden(true)
                        }
                        if page == 6 { review }
                        else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(questions[page]).font(AppTypography.section)
                                Text(hints[page]).foregroundStyle(AppTheme.secondary)
                            }
                            question
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
            }
            .background(AppTheme.canvas)
            .navigationTitle(model.saved == nil ? StylePreferences.titles[page] : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                if model.saved == nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if page > 0 {
                                model.update { $0.page = $0.editingFromReview ? 6 : $0.page - 1; $0.editingFromReview = false }
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
                        if model.draft.source == .onboarding {
                            ToolbarForwardAction(title: savedContinueTitle, usesGlass: true) { model.finish() }
                                .accessibilityIdentifier("style.saved.continue")
                        } else {
                            ToolbarSaveAction(title: "Done") { model.finish() }
                                .accessibilityLabel(savedContinueTitle).accessibilityIdentifier("style.saved.continue")
                        }
                    } else if page == 6 {
                        ToolbarSaveAction(title: model.unknown ? "Check save" : "Save", isPending: model.pending) { Task { await model.save() } }
                            .disabled(model.pending || (!model.unknown && (!model.draft.isComplete || (model.draft.baseRevision > 0 && !model.hasUnsavedChanges)))).accessibilityLabel(model.unknown ? "Check save" : "Save preferences")
                    } else {
                        ToolbarForwardAction(title: model.draft.editingFromReview ? "Review preferences" : "Next question", usesGlass: true) { model.next() }
                            .disabled(!model.draft.isAnswered(page) || model.pending || model.unknown || model.error != nil)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if model.saved != nil {
                    ActionFooter {
                        SecondaryAction(title: "Open my closet") { model.finish(openCloset: true) }
                            .accessibilityIdentifier("style.saved.closet")
                        Text("You can edit your preferences from Profile → Style.")
                            .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                    }
                }
            }
            .draftDiscardConfirmation(isPresented: $confirmsDiscard, title: "Discard this preference draft?",
                                  message: "Only this draft will be removed. Your saved preferences stay unchanged.") {
                    confirmsDiscard = false
                    model.discard()
                }
            .interactiveDismissDisabled()
        }.tint(AppTheme.ink)
    }

    private var savedContinueTitle: String {
        switch model.draft.source {
        case .onboarding: "Take the tour"
        case .profile: "Back to Profile"
        case .settings: "Back to Settings"
        }
    }
    private var savedContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.section) {
            AQDMark()
            EntryIllustration(kind: .ready)
            VStack(alignment: .leading, spacing: 16) {
                Label("Preferences saved", systemImage: "checkmark.circle")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.ink)
                Text("A closet that feels\nmore like you.")
                    .font(.largeTitle).tracking(-0.64).fixedSize(horizontal: false, vertical: true)
                Text(model.draft.source == .onboarding
                     ? "Your choices are saved on this iPhone.\nNext, take a quick look around."
                     : "Your choices are saved on this iPhone.\nKeep exploring your closet, your way.")
                    .foregroundStyle(AppTheme.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }.accessibilityIdentifier("style.saved.receipt")
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
                            model.update { $0.page = step; $0.editingFromReview = true }
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

private struct StyleColorSelectionView: View {
    @Bindable var model: StyleEditorModel
    let field: StyleColorField
    @State private var addingCustom = false
    @State private var custom = ""
    private var value: String { model.draft.answers.colors[keyPath: field.keyPath] }
    private var selected: [String] { ColorPreferences.selections(in: value) }
    private var options: [String] {
        field.options + selected.filter { item in
            !field.options.contains { $0.caseInsensitiveCompare(item) == .orderedSame }
        }.reduce(into: [String]()) { result, item in
            if !result.contains(where: { $0.caseInsensitiveCompare(item) == .orderedSame }) { result.append(item) }
        }
    }
    var body: some View {
        List {
            if let error = model.error {
                Section {
                    SemanticFeedback(role: model.unknown ? .warning : .danger, message: error)
                    Button("Retry saving draft") { model.persist() }.disabled(model.pending || model.unknown)
                }
            }
            Section {
                ForEach(options, id: \.self) { option in
                    let isSelected = selected.contains { $0.caseInsensitiveCompare(option) == .orderedSame }
                    Button { toggle(option) } label: {
                        HStack(spacing: 12) {
                            Text(option).foregroundStyle(AppTheme.ink)
                            Spacer(minLength: 8)
                            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                .foregroundStyle(isSelected ? AppTheme.ink : AppTheme.secondary).accessibilityHidden(true)
                        }.frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityValue(isSelected ? "Selected" : "Not selected")
                        .disabled(model.pending || model.unknown)
                }
                Button { custom = ""; addingCustom = true } label: {
                    Label("Add custom preference", systemImage: "plus").frame(minHeight: 44)
                }.disabled(model.pending || model.unknown)
            } footer: { Text("Choose any. Changes stay in your draft until you save preferences.") }
        }.scrollContentBackground(.hidden).background(AppTheme.canvas)
            .navigationTitle(field.rawValue).navigationBarTitleDisplayMode(.inline)
            .appConfirmation("Add preference", isPresented: $addingCustom) {
                Button("Add") {
                    let items = ColorPreferences.selections(in: custom)
                    model.update { draft in
                        for item in items {
                            let current = draft.answers.colors[keyPath: field.keyPath]
                            if !ColorPreferences.selections(in: current).contains(where: { $0.caseInsensitiveCompare(item) == .orderedSame }) {
                                draft.answers.colors[keyPath: field.keyPath] = ColorPreferences.toggling(item, in: current)
                            }
                        }
                        draft.answers.colors.declined = false
                    }
                }.disabled(ColorPreferences.selections(in: custom).isEmpty || model.pending || model.unknown)
                Button("Cancel", role: .cancel) {}
            } message: {
                TextField("Your preference", text: $custom)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Your preference")
            }
    }
    private func toggle(_ option: String) {
        model.update {
            $0.answers.colors[keyPath: field.keyPath] = ColorPreferences.toggling(option, in: value)
            $0.answers.colors.declined = false
        }
    }
}
