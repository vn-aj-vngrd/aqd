import AQDCore
import SwiftUI

enum PlannerAddChoice: String, CaseIterable { case day = "Plan one day", dates = "Plan several days" }
struct PlannerAddSheet: View {
    let select: (PlannerAddChoice) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ForEach(PlannerAddChoice.allCases, id: \.self) { choice in
                    DisclosureRow(title: choice.rawValue) { select(choice) }
                }
                Spacer(minLength: 0)
            }.padding(20).background(AppTheme.canvas).navigationTitle("Add to Planner").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }.tint(AppTheme.ink).accessibilityLabel("Cancel")
                } }
        }.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
    }
}

struct PlanAuthoringView: View {
    @Bindable var model: PlanAuthoringModel
    @State private var discard = false
    @State private var choosingSlot: UUID?
    @State private var choosingZone = false
    @State private var resolvingConflict: UUID?
    private var locked: Bool { model.pending || model.unknown || model.saved != nil }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let saved = model.saved {
                        Text(saved.plan.name).font(AppTypography.section)
                        Text("\(saved.entries.count) dates saved. Planning hasn’t recorded wear.")
                        PrimaryAction(title: "Open plan") { model.finish(openPlan: true) }
                    } else if model.draft.reviewing {
                        review
                    } else { fields }
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                }.padding(20)
            }.background(AppTheme.canvas).navigationTitle(model.saved != nil ? "Plan saved" : model.draft.reviewing ? "Review plan" : "New plan")
                .navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink)
                .toolbar { ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if model.saved != nil { model.finish() }
                        else if model.draft.reviewing { model.update(invalidateConflicts: false) { $0.reviewing = false } }
                        else { discard = true }
                    } label: { Image(systemName: model.saved != nil ? "checkmark" : model.draft.reviewing ? "chevron.backward" : "xmark") }
                        .accessibilityLabel(model.saved != nil ? "Done" : model.draft.reviewing ? "Back to plan" : "Cancel plan")
                        .tint(AppTheme.ink).disabled(model.pending || model.unknown)
                } }
                .navigationDestination(isPresented: $choosingZone) {
                    TimezoneChooser(current: model.draft.plan.start.timeZoneID) { zone in
                        model.dates { $0.start.timeZoneID = zone; $0.end.timeZoneID = zone }; return model.error == nil
                    }
                }
                .navigationDestination(isPresented: Binding(get: { resolvingConflict != nil }, set: { if !$0 { resolvingConflict = nil } })) {
                    if let entry = model.conflicts.first(where: { $0.id == resolvingConflict }) { PlanConflictView(model: model, existing: entry) }
                    else { ContentUnavailableView("Conflict changed", systemImage: "calendar", description: Text("Return to the plan review and inspect its current dates.")) }
                }
                .navigationDestination(isPresented: Binding(get: { choosingSlot != nil }, set: { if !$0 { choosingSlot = nil } })) {
                    if let id = choosingSlot { PlanSlotOutfitChooser(model: model, slotID: id) }
                }
        }.interactiveDismissDisabled()
            .sheet(isPresented: $discard) {
                DraftDiscardSheet(title: "Discard plan draft?", message: "No dates are saved by discarding. Existing plans and history stay unchanged.") {
                    model.finish(discarding: true)
                    if model.state.planAuthoringEditor == nil { discard = false }
                }
            }
    }
    private var fields: some View {
        VStack(alignment: .leading, spacing: 16) {
            LabeledField(title: "Name", text: Binding(get: { model.draft.plan.name }, set: { value in model.update { $0.plan.name = value } }))
            dateField("Start date", start: true)
            dateField("End date", start: false)
            DisclosureRow(title: "Timezone", value: model.draft.plan.start.timeZoneID) { choosingZone = true }
            Text("Plan up to two weeks. Every date can have a saved outfit or an intentional gap. Weather context is off.")
                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            if (try? model.draft.plan.days()) == nil { SemanticFeedback(role: .warning, message: "Choose an inclusive range of one to fourteen days in the same timezone.") }
            PrimaryAction(title: "Review plan") {
                model.state.reloadPlanEntries(); model.state.reloadOutfits()
                model.update { $0.reviewing = true }
            }.disabled(!model.canReview)
        }.disabled(locked)
    }
    private func dateField(_ title: String, start: Bool) -> some View {
        LabeledControl(title: title) {
            DatePicker(title, selection: Binding(get: { (try? (start ? model.draft.plan.start : model.draft.plan.end).date()) ?? Date() }, set: { value in
                let zone = TimeZone(identifier: model.draft.plan.start.timeZoneID) ?? .current
                model.dates { if start { $0.start = LocalPlanDay(date: value, timeZone: zone) } else { $0.end = LocalPlanDay(date: value, timeZone: zone) } }
            }), displayedComponents: .date).environment(\.timeZone, TimeZone(identifier: model.draft.plan.start.timeZoneID) ?? .current)
        }
    }
    private func conflictLabel(_ entry: OutfitPlanEntry) -> String {
        guard let choice = model.draft.resolutions.first(where: { $0.existing == entry })?.choice else { return "Choose what to keep" }
        return choice == .keepBoth ? "Keep both entries" : "Replace existing entry"
    }
    private var review: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(model.draft.plan.name).font(AppTypography.section)
            Text("\(model.draft.plan.start.key) – \(model.draft.plan.end.key) · \(model.draft.plan.start.timeZoneID)")
                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            ForEach(model.draft.slots) { slot in
                VStack(alignment: .leading, spacing: 8) {
                    DisclosureRow(title: slot.day.key, value: slot.outfit?.name ?? (slot.unassignedByChoice ? "Intentional gap" : "Choose outfit")) { choosingSlot = slot.id }
                    LabeledField(title: "Occasion", text: Binding(get: { model.draft.slots.first { $0.id == slot.id }?.occasion ?? "" }, set: { value in
                        model.update { draft in if let i = draft.slots.firstIndex(where: { $0.id == slot.id }) { draft.slots[i].occasion = value } }
                    }))
                }.disabled(locked)
            }
            if model.draft.slots.contains(where: { $0.outfit == nil && !$0.unassignedByChoice }) {
                SecondaryAction(title: "Leave remaining dates unassigned") {
                    model.update { draft in for i in draft.slots.indices where draft.slots[i].outfit == nil { draft.slots[i].unassignedByChoice = true } }
                }.disabled(locked)
            }
            ForEach(model.conflicts) { entry in
                DisclosureRow(title: "Resolve \(entry.day.key)", value: conflictLabel(entry)) { resolvingConflict = entry.id }.disabled(locked)
            }
            let assigned = model.draft.slots.filter { $0.outfit != nil }.count
            Text("\(assigned) assigned · \(model.draft.slots.count - assigned) gaps · \(model.conflicts.count) overlaps")
                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            PrimaryAction(title: model.unknown ? "Check save result" : "Save plan", isPending: model.pending) { Task { await model.save() } }
                .disabled(!model.unknown && !model.canSave)
        }
    }
}

private struct PlanConflictView: View {
    @Bindable var model: PlanAuthoringModel
    let existing: OutfitPlanEntry
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resolve a conflict").font(AppTypography.fieldLabel)
            Text("\(existing.day.key) · \(existing.occasion)")
            Text(model.state.outfits.first { $0.id == existing.outfitID }?.name ?? "Existing unassigned entry")
                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            Button { choose(.keepBoth) } label: {
                Label("Keep both entries", systemImage: selected(.keepBoth) ? "checkmark.circle.fill" : "circle")
            }.frame(minHeight: 44)
            if existing.state == .planned || existing.state == .unassigned {
                Button { choose(.replace) } label: {
                    Label("Replace existing entry", systemImage: selected(.replace) ? "checkmark.circle.fill" : "circle")
                }.frame(minHeight: 44)
            }
            Text("Nothing changes until the complete plan is saved.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            if let error = model.error { SemanticFeedback(role: .danger, message: error) }
        }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Resolve a conflict").navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink)
    }
    private func choose(_ choice: PlanConflictChoice) {
        model.chooseConflict(existing, choice: choice)
        if model.error == nil { dismiss() }
    }
    private func selected(_ choice: PlanConflictChoice) -> Bool {
        model.draft.resolutions.contains { $0.existing == existing && $0.choice == choice }
    }
}

private struct PlanSlotOutfitChooser: View {
    @Bindable var model: PlanAuthoringModel
    let slotID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SecondaryAction(title: "Leave unassigned") { choose(nil) }
                if model.state.outfits.isEmpty { ContentUnavailableView("No saved outfits", systemImage: "square.stack", description: Text("Keep this date unassigned. You can build outfits in Closet.")) }
                ForEach(model.state.outfits.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }) { outfit in
                    Button { choose(outfit) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            OutfitComposition(pieceIDs: outfit.pieceIDs)
                            Text(outfit.name).foregroundStyle(AppTheme.ink)
                        }
                    }.buttonStyle(.plain)
                }
                if let error = model.error { SemanticFeedback(role: .danger, message: error) }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Choose outfit").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search outfits").tint(AppTheme.ink)
            .onAppear { model.state.reloadOutfits() }
    }
    private func choose(_ outfit: Outfit?) {
        model.update { draft in
            if let i = draft.slots.firstIndex(where: { $0.id == slotID }) {
                draft.slots[i].outfit = outfit; draft.slots[i].unassignedByChoice = outfit == nil
            }
        }
        if model.error == nil { dismiss() }
    }
}

struct PlanDefinitionView: View {
    @Environment(AppState.self) private var state
    let id: UUID
    private var plan: PlanDefinition? { state.planDefinitions.first { $0.id == id } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let plan {
                    Text("\(plan.start.key) – \(plan.end.key)").font(AppTypography.body)
                    Text(plan.start.timeZoneID).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    ForEach(state.planEntries.filter { $0.planID == id }) { entry in
                        NavigationLink(value: PlannerRoute.entry(entry.id)) { PlanAgendaRow(entry: entry, showDate: true) }.buttonStyle(.plain)
                    }
                    Text("Saved dates are intentions. Recorded wear and history are separate.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                } else { ContentUnavailableView("Plan unavailable", systemImage: "calendar") }
                if let error = state.planError { SemanticFeedback(role: .danger, message: error); Button("Retry plans") { state.reloadPlanEntries() } }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle(plan?.name ?? "Plan").navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink)
            .onAppear { state.reloadPlanEntries(); state.reloadOutfits() }
    }
}
