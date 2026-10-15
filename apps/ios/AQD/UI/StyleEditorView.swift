import AQDCore
import SwiftUI

struct StyleEditorView: View {
    @Bindable var model: StyleEditorModel
    @State private var confirmsDiscard = false
    private var page: Int { model.draft.page }
    private let questions = ["What would you like help with?", "What do you dress for?", "What feels like you?", "How do you like clothes to fit?", "Body details, only if you want", "Colors and patterns you enjoy"]
    private let hints = ["Choose up to two, or No preference. Your answers stay private.", "Choose any, or No preference. We won’t infer your schedule.", "Choose any styles you enjoy, or No preference.", "Choose any, or No preference. Suggestions are not a size or try-on guarantee.", "Add optional details, choose Not sure, or decline.", "Add preferences, or choose No preference. We won’t infer these from photos."]

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
                        Image(systemName: "checkmark.circle").font(.largeTitle).foregroundStyle(AppTheme.accent).accessibilityHidden(true)
                        Text("Preferences saved").font(AppTypography.section)
                        Text("Your private preferences are saved on this iPhone. You can change them from Profile or Settings.")
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
            .navigationTitle(model.saved == nil ? StylePreferences.titles[page] : "Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if model.saved == nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if page > 0 {
                                model.update { $0.page = $0.editingFromReview ? 6 : $0.page - 1; $0.editingFromReview = false }
                            } else { confirmsDiscard = true }
                        } label: { Label("Back", systemImage: "chevron.backward") }
                        .disabled(model.pending || model.unknown)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                ActionFooter {
                    if model.saved != nil { PrimaryAction(title: "Done") { model.finish() } }
                    else if page == 6 {
                        PrimaryAction(title: model.unknown ? "Check save" : model.error != nil ? "Retry save" : "Save preferences", isPending: model.pending) { Task { await model.save() } }
                            .disabled(!model.draft.answers.isComplete)
                    } else {
                        PrimaryAction(title: model.draft.editingFromReview ? "Back to review" : "Continue") { model.next() }
                            .disabled(!model.draft.answers.isAnswered(page) || model.pending || model.unknown || model.error != nil)
                    }
                }
            }
            .confirmationDialog("Discard this preference draft?", isPresented: $confirmsDiscard, titleVisibility: .visible) {
                Button("Discard draft", role: .destructive) { model.discard() }
                Button("Keep editing", role: .cancel) {}
            } message: { Text("Only this draft will be removed. Your saved preferences stay unchanged.") }
            .interactiveDismissDisabled()
        }.tint(AppTheme.actionText)
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
                                .foregroundStyle(selected ? AppTheme.accent : AppTheme.secondary)
                        }.padding(16).frame(maxWidth: .infinity, minHeight: 56).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel(option).accessibilityValue(selected ? "Selected" : "Not selected")
                        .disabled(model.pending || model.unknown)
                    if option != StylePreferences.options[step].last { Divider().padding(.leading, 16) }
                }
            }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            if page == 3 {
                LabeledField(title: "Comfort preferences", text: answerBinding(\.comfort), prompt: "Fabrics, coverage or anything to avoid")
            }
        } else if page == 4 { bodyDetails }
        else { colorDetails }
    }

    private var bodyDetails: some View {
        VStack(alignment: .leading, spacing: 20) {
            LabeledField(title: "Height (cm)", text: Binding(get: {
                model.draft.answers.body.heightCM.map { $0.formatted(.number.grouping(.never)) } ?? ""
            }, set: { text in
                model.update { draft in
                    draft.answers.body.response = .provided
                    draft.answers.body.heightCM = Double(text)
                }
            }), prompt: "Not added")
            Picker("Body shape", selection: Binding(get: { model.draft.answers.body.shape ?? "Not added" }, set: { value in
                model.update { $0.answers.body.shape = value == "Not added" ? nil : value; $0.answers.body.response = .provided }
            })) {
                Text("Not added").tag("Not added")
                ForEach(BodyPreferences.shapes, id: \.self) { Text($0).tag($0) }
            }.frame(minHeight: 44)
            Toggle("Use body details for suggestions", isOn: Binding(get: { model.draft.answers.body.useForSuggestions }, set: { value in
                model.update { $0.answers.body.useForSuggestions = value }
            }))
            Text("Off by default. On allows private suggestions to use these details. Apple Intelligence also needs Style context enabled. No automatic cloud sharing.")
                .font(.footnote).foregroundStyle(AppTheme.secondary)
            Button("Prefer not to share body details") { model.update { $0.answers.body.decline() } }
                .frame(minHeight: 44).accessibilityValue(model.draft.answers.body.response == .declined ? "Selected" : "Not selected")
        }.disabled(model.pending || model.unknown)
    }

    private var colorDetails: some View {
        VStack(spacing: 16) {
            LabeledField(title: "Preferred colors", text: colorBinding(\.preferredColors), prompt: "Add colors you like")
            LabeledField(title: "Colors to avoid", text: colorBinding(\.avoidedColors), prompt: "Add colors to avoid")
            LabeledField(title: "Preferred patterns", text: colorBinding(\.preferredPatterns), prompt: "Add patterns you like")
            LabeledField(title: "Patterns to avoid", text: colorBinding(\.avoidedPatterns), prompt: "Add patterns to avoid")
            Button("No color or pattern preference") {
                model.update { $0.answers.colors = ColorPreferences(); $0.answers.colors.declined = true }
            }.frame(minHeight: 44).accessibilityValue(model.draft.answers.colors.declined ? "Selected" : "Not selected")
        }.disabled(model.pending || model.unknown)
    }

    private var review: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("\(model.draft.answers.answeredCount) of 6 questions answered\(model.draft.answers.allDeclined ? " · All declined" : "")").font(.subheadline)
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
                                Image(systemName: "chevron.forward").font(.system(size: 22)).frame(width: 22).foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                            }.padding(14).frame(maxWidth: .infinity, minHeight: 80, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.plain).foregroundStyle(AppTheme.ink).accessibilityIdentifier("style.review.\(step)")
                            .disabled(model.pending || model.unknown)
                    }
                }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            }
            Text("Your answers stay private on this iPhone. Body details are optional and used for suggestions only when you allow it. No size or virtual try-on guarantee.")
                .font(.footnote).foregroundStyle(AppTheme.secondary)
        }
    }

    private func answerBinding(_ key: WritableKeyPath<StylePreferences, String>) -> Binding<String> {
        Binding(get: { model.draft.answers[keyPath: key] }, set: { value in model.update { $0.answers[keyPath: key] = value } })
    }
    private func colorBinding(_ key: WritableKeyPath<ColorPreferences, String>) -> Binding<String> {
        Binding(get: { model.draft.answers.colors[keyPath: key] }, set: { value in model.update { $0.answers.colors[keyPath: key] = value; $0.answers.colors.declined = false } })
    }
}
