import AQDCore
import SwiftUI

struct RoutineFields: View {
    @Bindable var model: PlanAuthoringModel
    let chooseOutfits: () -> Void
    @Environment(\.calendar) private var calendar
    private var routine: RoutineConfiguration { model.draft.plan.routine ?? RoutineConfiguration() }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Repeat days").font(AppTypography.fieldLabel)
            ForEach(0..<7, id: \.self) { offset in
                let weekday = (offset + calendar.firstWeekday - 1) % 7 + 1
                Toggle(calendar.weekdaySymbols[weekday - 1], isOn: Binding(get: { routine.weekdays.contains(weekday) }, set: { selected in
                    model.dates { plan in
                        if selected { if plan.routine?.weekdays.contains(weekday) == false { plan.routine?.weekdays.append(weekday) } }
                        else { plan.routine?.weekdays.removeAll { $0 == weekday } }
                    }
                })).frame(minHeight: 44).tint(AppTheme.ink)
            }
            LabeledField(title: "Occasion", text: Binding(get: { routine.occasion }, set: { value in
                model.update { draft in
                    draft.plan.routine?.occasion = value
                    for i in draft.slots.indices { draft.slots[i].occasion = value }
                }
            }))
            DisclosureRow(title: "Choose outfits", value: "\(routine.preferredOutfitIDs.count) selected", action: chooseOutfits)
            LabeledControl(title: "Repetition") {
                Picker("Repetition", selection: Binding(get: { routine.repetition }, set: { value in
                    model.update { $0.plan.routine?.repetition = value }
                })) { ForEach(RoutineRepetition.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu)
            }
            SecondaryAction(title: "Fill dates from selected outfits") { model.fillRoutine() }
                .disabled(routine.preferredOutfitIDs.isEmpty)
        }
    }
}

struct RoutineOutfitChooser: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: "Done") {
                    model.update { $0.plan.routine?.preferredOutfitIDs = selected }
                    if model.error == nil { dismiss() }
                }
    }

    @Bindable var model: PlanAuthoringModel
    @State private var selected: [UUID] = []
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose outfits for a reviewed rotation. Selecting them doesn’t change saved dates.").foregroundStyle(AppTheme.secondary)
                if model.state.outfits.isEmpty { AppEmptyState("No saved outfits", systemImage: "square.stack", description: Text("Build an outfit in Closet, or leave your routine dates unassigned."), fillsAvailableSpace: false) }
                ForEach(model.state.outfits.filter { selected.contains($0.id) || query.isEmpty || $0.displayName.localizedCaseInsensitiveContains(query) }) { outfit in
                    Button {
                        if selected.contains(outfit.id) { selected.removeAll { $0 == outfit.id } } else { selected.append(outfit.id) }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            OutfitComposition(pieceIDs: outfit.pieceIDs)
                            HStack { Text(outfit.displayName); Spacer(); Image(systemName: selected.contains(outfit.id) ? "checkmark.circle.fill" : "circle") }
                                .foregroundStyle(AppTheme.ink).frame(minHeight: 44)
                        }
                    }.buttonStyle(.plain).accessibilityValue(selected.contains(outfit.id) ? "Selected" : "Not selected")
                }

                if let error = model.error { SemanticFeedback(role: .danger, message: error) }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Choose outfits").navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: { Label("Cancel", systemImage: "xmark") }
                    .disabled(model.pending || model.unknown)
            } }
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                confirmation.disabled(model.pending || model.unknown)
            } }
            .searchable(text: $query, prompt: "Search outfits").tint(AppTheme.ink)
            .onAppear { model.state.reloadOutfits(); selected = model.draft.plan.routine?.preferredOutfitIDs ?? [] }
    }
}

struct RoutineScopeChooser: View {
    let entries: [OutfitPlanEntry]
    var isRoutine = true
    let choose: (RoutineEditScope, UUID?) -> Void
    @State private var selectedID: UUID?
    @Environment(\.dismiss) private var dismiss
    private var editable: [OutfitPlanEntry] { entries.filter { $0.state == .planned || $0.state == .unassigned } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Which entries should change?").font(AppTypography.section)
                    Text("Recorded wear and completed entries stay intact.").foregroundStyle(AppTheme.secondary)
                    if !editable.isEmpty {
                        Picker("Starting entry", selection: $selectedID) {
                            ForEach(editable) { Text("\($0.day.displayDate) · \($0.occasion)").tag(Optional($0.id)) }
                        }.pickerStyle(.menu).frame(minHeight: 44)
                        DisclosureRow(title: "This entry") { choose(.entry, selectedID) }.disabled(selectedID == nil)
                        DisclosureRow(title: "This and future entries") { choose(.future, selectedID) }.disabled(selectedID == nil)
                    }
                    DisclosureRow(title: isRoutine ? "Whole routine" : "Whole plan") { choose(.whole, selectedID) }
                }.padding(20)
            }.background(AppTheme.canvas).navigationTitle(isRoutine ? "Edit routine" : "Edit plan").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }.tint(AppTheme.ink).accessibilityLabel("Cancel")
                } }
        }.onAppear { selectedID = editable.first?.id }
    }
}
