import AQDCore
import SwiftUI

struct BodyDetailsView: View {
    @Bindable var model: StyleEditorModel
    @FocusState private var heightEditing: Bool
    @AccessibilityFocusState private var shapeFocused: Bool
    private var input: HeightInput { model.draft.heightInput ?? HeightInput(body: model.draft.answers.body) }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Height").font(AppTypography.fieldLabel).foregroundStyle(AppTheme.secondary)
                HStack(spacing: 12) {
                    if input.units == .cm {
                        heightField("Height in centimeters", field: .centimeters, value: input.cmText, id: "style.height.cm")
                    } else {
                        heightField("Feet", field: .feet, value: input.feetText, id: "style.height.feet")
                        Text("ft").foregroundStyle(AppTheme.secondary)
                        heightField("Inches", field: .inches, value: input.inchesText, id: "style.height.inches")
                        Text("in").foregroundStyle(AppTheme.secondary)
                    }
                    Picker("Height units", selection: Binding(get: { input.units }, set: { units in
                        heightEditing = false; model.update { $0.switchHeightUnits(to: units) }
                    })) {
                        Text("cm").tag(BodyPreferences.Units.cm)
                        Text("ft/in").tag(BodyPreferences.Units.feetInches)
                    }.pickerStyle(.menu).tint(AppTheme.ink).fixedSize(horizontal: true, vertical: false)
                        .frame(minWidth: 76, minHeight: 44).layoutPriority(1)
                        .disabled(!input.isValid).accessibilityIdentifier("style.height.units")
                }.padding(.horizontal, 14).padding(.vertical, 5).frame(minHeight: 54)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                if !input.isValid {
                    SemanticFeedback(role: .danger, message: "Enter a positive, finite height. Feet must be whole; inches must be less than 12. Clear the fields to leave height unknown.")
                        .accessibilityIdentifier("style.height.error")
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Body shape").font(AppTypography.fieldLabel).foregroundStyle(AppTheme.secondary)
                Button {
                    heightEditing = false
                    model.update { $0.openBodyShapePicker() }
                } label: {
                    HStack(spacing: 12) {
                        Text(model.draft.answers.body.shape ?? "Not added").foregroundStyle(model.draft.answers.body.shape == nil ? AppTheme.secondary : AppTheme.ink)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.forward").frame(width: 22).foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                    }.padding(14).frame(maxWidth: .infinity, minHeight: 54, alignment: .leading).contentShape(Rectangle())
                }.buttonStyle(.plain).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel("Body shape").accessibilityValue(model.draft.answers.body.shape ?? "Not added")
                    .accessibilityIdentifier("style.body.shape").accessibilityFocused($shapeFocused)
            }
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Use body details for suggestions", isOn: Binding(get: { model.draft.answers.body.useForSuggestions }, set: { value in
                    model.update { $0.answers.body.useForSuggestions = value }
                })).tint(AppTheme.accent).padding(14).frame(minHeight: 60)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                Text("Off by default. On allows private suggestions to use these details. Apple Intelligence also needs Style context enabled. No automatic cloud sharing.")
                    .font(.subheadline).foregroundStyle(AppTheme.secondary)
            }
            Button {
                heightEditing = false; model.update { $0.declineBody() }
            } label: {
                HStack(spacing: 16) {
                    Text("Prefer not to share body details")
                    Spacer(minLength: 0)
                    Image(systemName: model.draft.answers.body.response == .declined ? "checkmark.square.fill" : "square")
                        .foregroundStyle(model.draft.answers.body.response == .declined ? AppTheme.accent : AppTheme.secondary)
                }.padding(.horizontal, 14).frame(maxWidth: .infinity, minHeight: 54).contentShape(Rectangle())
            }.buttonStyle(.plain).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityValue(model.draft.answers.body.response == .declined ? "Selected" : "Not selected")
        }.disabled(model.pending || model.unknown)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button { heightEditing = false } label: {
                        Text("Done")
                    }.frame(minWidth: 44, minHeight: 44)
                }
            }
            .sheet(isPresented: Binding(get: { model.draft.bodyShapePicker != nil }, set: { presented in
                if !presented { model.update { $0.cancelBodyShapePicker() } }
            }), onDismiss: { shapeFocused = true }) {
                BodyShapePickerView(model: model)
            }
    }
    private func heightField(_ title: String, field: HeightInput.Field, value: String, id: String) -> some View {
        TextField(title, text: Binding(get: { value }, set: { text in model.update { $0.editHeight(field, text: text) } }), prompt: Text("Not added"))
            .keyboardType(.decimalPad).focused($heightEditing).frame(minHeight: 44)
            .accessibilityLabel(title).accessibilityIdentifier(id)
    }
}

private struct BodyShapePickerView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: "Done") {
                        var edited = picker
                        do {
                            try edited.useDescription()
                            descriptionEditing = false
                            model.update { $0.bodyShapePicker = edited }
                        } catch { model.error = "Use a nonblank description of 160 characters or fewer." }
                    }.disabled(!picker.canUseDescription || model.error != nil)
    }

    @Bindable var model: StyleEditorModel
    @FocusState private var descriptionEditing: Bool
    private var picker: BodyShapeDraft { model.draft.bodyShapePicker ?? BodyShapeDraft(current: nil) }
    var body: some View {
        NavigationStack {
            Group {
                if picker.isEditingCustom { customDescription }
                else { choices }
            }.background(AppTheme.canvas)
                .navigationTitle("Body shape").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if picker.isEditingCustom { confirmation }
            } }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            descriptionEditing = false
                            model.update {
                                if picker.isEditingCustom { $0.bodyShapePicker?.cancelDescription() }
                                else { $0.cancelBodyShapePicker() }
                            }
                        } label: {
                            Label("Cancel", systemImage: "xmark").labelStyle(.iconOnly)
                        }.frame(minWidth: 44, minHeight: 44).tint(AppTheme.ink)
                    }
                    if !picker.isEditingCustom {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { model.update { $0.finishBodyShapePicker() } } label: {
                                Text("Done")
                            }.frame(minWidth: 44, minHeight: 44)
                                .accessibilityIdentifier("style.body.picker.done")
                        }
                    }
                }
        }.tint(AppTheme.ink).interactiveDismissDisabled()
            .presentationDetents([.large])
    }
    private var choices: some View {
        List {
            if let error = model.error { Section { SemanticFeedback(role: .danger, message: error); Button("Retry saving draft") { model.persist() } } }
            Section {
                option("Not added", value: nil)
                ForEach(BodyPreferences.shapes, id: \.self) { option($0, value: $0) }
                Button("Describe in my own words…") { model.update { $0.bodyShapePicker?.isEditingCustom = true } }
                    .frame(minHeight: 44).accessibilityIdentifier("style.body.custom")
                if let selected = picker.selection, !BodyPreferences.shapes.contains(selected) {
                    Label(selected, systemImage: "checkmark").foregroundStyle(AppTheme.ink)
                        .accessibilityLabel("Pending custom description, \(selected)")
                }
            } header: {
                Text("Choose words that feel right to you. No body label is required.").textCase(nil).font(.subheadline)
            }
        }.scrollContentBackground(.hidden)
    }
    private func option(_ title: String, value: String?) -> some View {
        Button { model.update { $0.bodyShapePicker?.selection = value } } label: {
            HStack {
                Text(title).foregroundStyle(AppTheme.ink)
                Spacer(minLength: 12)
                Image(systemName: "checkmark").foregroundStyle(AppTheme.secondary).opacity(picker.selection == value ? 1 : 0).accessibilityHidden(true)
            }.frame(minHeight: 44).contentShape(Rectangle())
        }.accessibilityLabel(title).accessibilityValue(picker.selection == value ? "Selected" : "Not selected")
    }
    private var customDescription: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Describe in my own words").font(AppTypography.section)
                Text("Use words that feel right. This stays private.").font(.subheadline).foregroundStyle(AppTheme.secondary)
                LabeledField(title: "Your description", text: Binding(get: { picker.customText }, set: { value in
                    model.update { $0.bodyShapePicker?.customText = value }
                }), prompt: "Describe in your own words", multiline: true,
                             accessibilityID: "style.body.description", editingFocus: $descriptionEditing)
                Text("\(picker.customText.count) / 160").font(.footnote).foregroundStyle(AppTheme.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing).accessibilityIdentifier("style.body.count")
                if picker.customText.count > 160 {
                    SemanticFeedback(role: .danger, message: "Remove \(picker.customText.count - 160) character\(picker.customText.count == 161 ? "" : "s") to continue.")
                        .accessibilityIdentifier("style.body.description.error")
                }
                Text("Adding a description doesn’t turn on body use. Suggestions use it only if you choose to allow it.")
                    .font(.subheadline).foregroundStyle(AppTheme.secondary)
                if let error = model.error { SemanticFeedback(role: .danger, message: error); Button("Retry saving draft") { model.persist() } }
            }.padding(20)
        }.scrollDismissesKeyboard(.immediately)

            .task { descriptionEditing = true }
    }
}
