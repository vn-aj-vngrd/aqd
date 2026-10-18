import Foundation

/// The one task editor that may be open at a time. A sum type makes the rule structural: opening a
/// second editor means replacing this slot, so openers only ask `hasActiveEditor`.
enum ActiveEditor {
    case capture(CaptureModel)
    case outfit(OutfitEditorModel)
    case theme(ThemeEditorModel)
    case plan(OutfitPlanEditorModel)
    case planAuthoring(PlanAuthoringModel)
    case wear(OutfitWearEditorModel)
    case style(StyleEditorModel)
    case fit(FitEditorModel)
    case identity(LocalIdentityEditorModel)
    case today(TodayEditorModel)
}

/// Typed views of the slot for sheet bindings and callers. Setting `nil` clears only the matching case,
/// so closing one editor never dismisses another.
extension AppState {
    var hasActiveEditor: Bool { activeEditor != nil }

    var capture: CaptureModel? {
        get { if case .capture(let model) = activeEditor { model } else { nil } }
        set { setEditor(newValue.map(ActiveEditor.capture)) { if case .capture = $0 { true } else { false } } }
    }
    var outfitEditor: OutfitEditorModel? {
        get { if case .outfit(let model) = activeEditor { model } else { nil } }
        set { setEditor(newValue.map(ActiveEditor.outfit)) { if case .outfit = $0 { true } else { false } } }
    }
    var themeEditor: ThemeEditorModel? {
        get { if case .theme(let model) = activeEditor { model } else { nil } }
        set { setEditor(newValue.map(ActiveEditor.theme)) { if case .theme = $0 { true } else { false } } }
    }
    var planEditor: OutfitPlanEditorModel? {
        get { if case .plan(let model) = activeEditor { model } else { nil } }
        set { setEditor(newValue.map(ActiveEditor.plan)) { if case .plan = $0 { true } else { false } } }
    }
    var planAuthoringEditor: PlanAuthoringModel? {
        get { if case .planAuthoring(let model) = activeEditor { model } else { nil } }
        set { setEditor(newValue.map(ActiveEditor.planAuthoring)) { if case .planAuthoring = $0 { true } else { false } } }
    }
    var wearEditor: OutfitWearEditorModel? {
        get { if case .wear(let model) = activeEditor { model } else { nil } }
        set { setEditor(newValue.map(ActiveEditor.wear)) { if case .wear = $0 { true } else { false } } }
    }
    var styleEditor: StyleEditorModel? {
        get { if case .style(let model) = activeEditor { model } else { nil } }
        set { setEditor(newValue.map(ActiveEditor.style)) { if case .style = $0 { true } else { false } } }
    }
    var fitEditor: FitEditorModel? {
        get { if case .fit(let model) = activeEditor { model } else { nil } }
        set { setEditor(newValue.map(ActiveEditor.fit)) { if case .fit = $0 { true } else { false } } }
    }
    var identityEditor: LocalIdentityEditorModel? {
        get { if case .identity(let model) = activeEditor { model } else { nil } }
        set { setEditor(newValue.map(ActiveEditor.identity)) { if case .identity = $0 { true } else { false } } }
    }
    var todayEditor: TodayEditorModel? {
        get { if case .today(let model) = activeEditor { model } else { nil } }
        set { setEditor(newValue.map(ActiveEditor.today)) { if case .today = $0 { true } else { false } } }
    }

    private func setEditor(_ editor: ActiveEditor?, clearing matches: (ActiveEditor) -> Bool) {
        if let editor { activeEditor = editor } else if let current = activeEditor, matches(current) { activeEditor = nil }
    }
}
