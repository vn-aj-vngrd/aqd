import AQDCore
import SwiftUI

struct TodayWidgetConfigurationView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: "Done") { model.applyNested() }.disabled(!model.canApply)
    }

    @Bindable var model: TodayEditorModel
    @State private var discard = false
    @State private var editPhoto = false
    @State private var themeTask: ThemeEditorModel?
    private var instance: TodayWidgetInstance? { model.draft.nested }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let instance {
                        Label(instance.kind.title, systemImage: instance.kind.symbol)
                            .font(AppTypography.fieldLabel).foregroundStyle(AppTheme.secondary)
                        VStack(alignment: .leading, spacing: 20) {
                            configuration(instance)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16)).disabled(model.locked)
                        if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).background(AppTheme.canvas).navigationTitle(instance?.kind.title ?? "Configure widget").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if instance != nil { confirmation }
            } }
                .editImportedPhoto(model, importing: model.importing, locked: model.locked, presented: $editPhoto)
                .navigationDestination(isPresented: $editPhoto) { PhotoEditorView(model: model).secondaryPage() }
                .toolbar { ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if model.draft.nested == model.draft.nestedBase { model.cancelNested() } else { discard = true }
                    } label: { Image(systemName: "xmark") }.accessibilityLabel("Cancel widget edits")
                } }
        }.tint(AppTheme.ink).interactiveDismissDisabled()
        .sheet(item: $themeTask, onDismiss: { model.state.reloadThemes() }) { task in
            ThemeEditorView(model: task, didSave: { theme in model.nested { $0.options?.pinnedID = theme.id }; model.state.reloadThemes() })
        }.draftDiscardConfirmation(isPresented: $discard, title: "Discard widget edits?", message: "Your previous Today draft is retained.") { model.cancelNested(); discard = false }
    }
    @ViewBuilder private func configuration(_ instance: TodayWidgetInstance) -> some View {
        switch instance.kind {
        case .personalNote, .personalPhoto: personal(instance)
        case .quickActions: actions
        case .weekInWear, .closetInUse:
            Toggle(instance.kind == .weekInWear ? "Follow this week" : "Latest completed month", isOn: Binding(get: { instance.options?.period == nil }, set: { follow in model.nested { $0.options?.period = follow ? nil : (instance.kind == .weekInWear ? LocalPlanDay() : try? TodaySources.completedMonth(before: LocalPlanDay())) } }))
            if let period = instance.options?.period {
                ThemedDatePicker(instance.kind == .weekInWear ? "Week containing" : "Completed month", selection: Binding(get: { (try? period.date()) ?? Date() }, set: { date in model.nested { $0.options?.period = LocalPlanDay(date: date) } }), in: ...Date(), displayedComponents: .date)
            }
            Text(instance.kind == .closetInUse ? "Only completed months can be selected. Plans and earlier estimates are excluded." : "Only recorded wear in this week counts. Plans and earlier estimates are excluded.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
        case .upcomingPlans:
            Picker("Window", selection: Binding(get: { instance.options?.upcomingDays ?? 7 }, set: { days in model.nested { $0.options?.upcomingDays = days } })) { Text("Next seven days").tag(7); Text("Next fourteen days").tag(14) }
            sourcePicker(instance, title: "Plan", choices: model.state.planDefinitions.map { ($0.id, $0.name) }, defaultTitle: "Follow upcoming plans")
        case .todayLook:
            sourcePicker(instance, title: "Plan entry", choices: model.state.planEntries.map { ($0.id, "\($0.day.key), \($0.occasion.isEmpty ? "Occasion" : $0.occasion)") }, defaultTitle: "Follow Today")
        case .wearAgain:
            sourcePicker(instance, title: "Piece", choices: model.state.pieces.filter { $0.availability == .available }.map { ($0.id, $0.displayName) }, defaultTitle: "Least recently recorded")
        case .favoriteOutfits:
            sourcePicker(instance, title: "Outfit", choices: model.state.outfits.map { ($0.id, $0.displayName) }, defaultTitle: "Owned favorites")
        case .theme:
            sourcePicker(instance, title: "Theme", choices: model.state.themes.map { ($0.id, $0.displayName) }, defaultTitle: "Choose a theme")
            if instance.options?.pinnedID == nil { Text("Choose a theme or create one before tapping Done.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
            Button("Create theme") {
                do {
                    guard let store = model.state.store else { return }
                    let draft = try store.themeDraft() ?? ThemeDraft(ownerID: model.draft.base.ownerID)
                    try store.saveThemeDraft(draft); themeTask = try ThemeEditorModel(store: store, draft: draft)
                } catch { model.error = "The theme task could not open. Your Today draft is retained." }
            }.frame(minHeight: 44)
        case .fitJournal:
            sourcePicker(instance, title: "Memory", choices: model.state.fitMemories.map { ($0.id, $0.day.key) }, defaultTitle: "Latest memory")
        case .weatherContext:
            Text("This widget opens Weather setup or details. Adding it does not enable weather or location.").foregroundStyle(AppTheme.secondary)
        }
    }
    private func sourcePicker(_ instance: TodayWidgetInstance, title: String, choices: [(UUID, String)], defaultTitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledControl(title: title) {
                Picker(title, selection: Binding(get: { instance.options?.pinnedID }, set: { id in model.nested { $0.options?.pinnedID = id } })) {
                    Text(defaultTitle).tag(nil as UUID?)
                    ForEach(choices, id: \.0) { choice in Text(choice.1).tag(Optional(choice.0)) }
                    if let pin = instance.options?.pinnedID, !choices.contains(where: { $0.0 == pin }) { Text("Selected source unavailable").tag(Optional(pin)) }
                }.pickerStyle(.menu).labelsHidden().frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            if choices.isEmpty { Text("No saved \(title.lowercased()) records yet. Your layout draft stays here.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    @ViewBuilder private func personal(_ instance: TodayWidgetInstance) -> some View {
        NavigationLink("Saved notes and photos") { SavedTodayCardsView(model: model) }.frame(minHeight: 44)
        if let card = instance.options?.personal {
            LabeledField(title: "Title, optional", text: Binding(get: { card.title }, set: { title in model.nested { $0.options?.personal?.title = title } }))
            if instance.kind == .personalPhoto {
                TodayPersonalPhoto(card: card).frame(minHeight: 160, maxHeight: 260)
                SharedPhotoSourceButton(title: card.photoID == nil ? "Choose photo" : "Replace photo", selectionToken: model.importID, locked: model.locked || model.importing,
                    onEdit: card.photoID == nil ? nil : { editPhoto = true },
                    onRemove: card.photoID == nil ? nil : { model.cancelImport(); model.nested { $0.options?.personal?.photoID = nil; $0.options?.personal?.photoRecipe = .fitOriginal } }, onData: model.importPhoto)
                if model.importing { ProgressView("Preparing photo"); Button("Cancel import") { model.cancelImport() }.frame(minHeight: 44) }
            }
            Text(instance.kind == .personalNote ? "Note" : "Caption, optional").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            TextEditor(text: Binding(get: { card.text }, set: { text in model.nested { $0.options?.personal?.text = text } })
                .limited(to: instance.kind == .personalNote ? TextAreaLimits.note : TextAreaLimits.caption))
                .frame(minHeight: 180).padding(14).scrollContentBackground(.hidden).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16)).accessibilityLabel(instance.kind == .personalNote ? "Full private note" : "Photo caption")
            TextAreaCounter(text: card.text, limit: instance.kind == .personalNote ? TextAreaLimits.note : TextAreaLimits.caption)
            if instance.kind == .personalNote, card.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { Text("A note needs some text.").foregroundStyle(AppTheme.error) }
            Button(instance.kind == .personalNote ? "Clear note" : "Clear caption") { model.nested { $0.options?.personal?.text = "" } }.frame(minHeight: 44)
            Text("Done updates your Today draft. Save in Customize Today keeps it.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
        }
    }
    private var actions: some View {
        let selected = instance?.options?.actions ?? TodayAction.defaults
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(TodayAction.allCases, id: \.self) { action in
                Toggle(action.title, isOn: Binding(get: { selected.contains(action) }, set: { enabled in
                    model.nested { instance in var actions = instance.options?.actions ?? TodayAction.defaults; actions.removeAll { $0 == action }; if enabled { actions.append(action) }; instance.options?.actions = actions }
                }))
            }
            if selected.isEmpty { SemanticFeedback(role: .warning, message: "Choose at least one action before tapping Done.") }
            Text("Actions appear in selection order. Turn an action off and on to move it to the end. Keep at least one.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
        }
    }
}
struct TodayPersonalPhoto: View {
    let card: TodayPersonalCard
    /// On a Today card the photo fills the card width at a 4:5 frame instead of floating centered.
    var fillsWidth = false
    @Environment(AppState.self) private var state
    var body: some View {
        if let id = card.photoID, let data = try? state.store?.photoRendition(id: id, recipe: card.photoRecipe), let image = UIImage(data: data) {
            if fillsWidth {
                Color.clear.aspectRatio(4 / 5, contentMode: .fit).frame(maxHeight: 380).frame(maxWidth: .infinity)
                    .overlay { Image(uiImage: image).resizable().scaledToFill() }
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.field))
                    .accessibilityElement().accessibilityLabel(card.title.isEmpty ? "Private Today photo" : card.title)
            } else {
                Image(uiImage: image).resizable().scaledToFit().accessibilityLabel(card.title.isEmpty ? "Private Today photo" : card.title)
            }
        } else {
            AppEmptyState(card.photoID == nil ? "Choose your own photo" : "Saved photo unavailable", systemImage: "photo", description: Text("Replace or recover the AQD photo. Your title and caption are retained."), fillsAvailableSpace: false)
        }
    }
}
