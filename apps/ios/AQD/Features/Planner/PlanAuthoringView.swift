import AQDCore
import SwiftUI

struct PlanAuthoringView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: model.unknown ? "Check result" : "Save", isPending: model.pending) { Task { await model.save(); if model.saved != nil { model.finish() } } }
                .disabled(!model.unknown && !model.canSave)
    }

    @Bindable var model: PlanAuthoringModel
    @State private var discard = false
    @State private var choosingZone = false
    @State private var resolvingConflict: UUID?
    @State private var choosingPreferred = false
    private var definitionLocked: Bool { model.draft.editScope == .entry }
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
                    if let error = model.error {
                        SemanticFeedback(role: .danger, message: error)
                        if model.draft.basePlan != nil && !model.unknown {
                            Text("Refresh replaces original entries with their latest saved values and keeps your added dates.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                            Button("Refresh reviewed entries") { model.refreshReviewedBase() }.frame(minHeight: 44).disabled(model.pending)
                        }
                    }
                }.padding(20)
            }.background(AppTheme.canvas).navigationTitle(model.saved != nil ? "Plan saved" : model.draft.reviewing ? "Review plan" : model.draft.basePlan != nil ? "Edit plan" : model.draft.plan.routine != nil ? "New routine" : model.draft.plan.trip != nil ? "New trip" : "New plan")
                .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if model.saved == nil {
                    if model.draft.reviewing { confirmation }
                    else {
                        ToolbarForwardAction(title: "Next") {
                            model.state.reloadPlanEntries(); model.state.reloadOutfits(); model.state.reloadPieces()
                            model.update { $0.reviewing = true }
                        }.disabled(!model.canReview || locked)
                    }
                }
            } }.tint(AppTheme.ink)
                .toolbar { ToolbarItem(placement: model.saved == nil ? .topBarLeading : .topBarTrailing) {
                    Button {
                        if model.saved != nil { model.finish() }
                        else if model.hasUnsavedChanges { discard = true }
                        else { model.finish(discarding: true) }
                    } label: { if model.saved != nil { Text("Done") } else { Image(systemName: "xmark") } }
                        .accessibilityLabel(model.saved != nil ? "Done" : "Cancel plan")
                        .tint(AppTheme.ink).disabled(model.pending || model.unknown)
                } }
                .navigationDestination(isPresented: $choosingPreferred) { RoutineOutfitChooser(model: model) }
                .navigationDestination(isPresented: $choosingZone) {
                    TimezoneChooser(current: model.draft.plan.start.timeZoneID) { zone in
                        model.dates { $0.start.timeZoneID = zone; $0.end.timeZoneID = zone }; return model.error == nil
                    }
                }
                .navigationDestination(isPresented: Binding(get: { resolvingConflict != nil }, set: { if !$0 { resolvingConflict = nil } })) {
                    if let entry = model.conflicts.first(where: { $0.id == resolvingConflict }) { PlanConflictView(model: model, existing: entry) }
                    else { AppEmptyState("Conflict changed", systemImage: "calendar", description: Text("Return to the plan review and inspect its current dates."), fillsAvailableSpace: false) }
                }
        }.onAppear { model.state.reloadPieces(); model.state.reloadOutfits() }.interactiveDismissDisabled()
            .draftDiscardConfirmation(isPresented: $discard, title: "Discard plan draft?", message: "No dates are saved by discarding. Existing plans and history stay unchanged.") {
                    model.finish(discarding: true)
                    if model.state.planAuthoringEditor == nil { discard = false }
                }
    }
    private var fields: some View {
        VStack(alignment: .leading, spacing: 16) {
            LabeledField(title: "Name", text: Binding(get: { model.draft.plan.name }, set: { value in model.update { $0.plan.name = value } })).disabled(definitionLocked)
            VStack(spacing: 0) {
                dateField("Starts", start: true)
                Divider().padding(.leading, 14)
                dateField("Ends", start: false)
                Divider().padding(.leading, 14)
                DisclosureRow(title: "Timezone", value: model.draft.plan.start.timeZoneID) { choosingZone = true }
            }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16)).disabled(definitionLocked)
            if model.draft.plan.trip != nil { TripFields(model: model).disabled(definitionLocked) }
            if model.draft.plan.routine != nil {
                RoutineFields(model: model) { choosingPreferred = true }.disabled(definitionLocked)
            }
            Text(model.draft.plan.routine == nil ? "Plan up to two weeks. Assign outfits on the next step." : "Choose weekdays for up to three months. Review dates before saving.")
                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            if (try? model.draft.plan.days()) == nil { SemanticFeedback(role: .warning, message: model.draft.plan.routine == nil ? "Choose an inclusive range of one to fourteen days in the same timezone." : "Choose weekdays and a range of up to three calendar months in the same timezone.") }
        }.disabled(locked)
    }
    private func dateField(_ title: String, start: Bool) -> some View {
        ThemedDatePicker(title, selection: Binding(get: { (try? (start ? model.draft.plan.start : model.draft.plan.end).date()) ?? Date() }, set: { value in
                let zone = TimeZone(identifier: model.draft.plan.start.timeZoneID) ?? .current
                model.dates { if start { $0.start = LocalPlanDay(date: value, timeZone: zone) } else { $0.end = LocalPlanDay(date: value, timeZone: zone) } }
            }), displayedComponents: .date).environment(\.timeZone, TimeZone(identifier: model.draft.plan.start.timeZoneID) ?? .current)
            .padding(.horizontal, 14).frame(minHeight: 54)
    }
    private func chooseSlot(_ id: UUID, _ outfit: Outfit?) {
        model.update { draft in
            if let i = draft.slots.firstIndex(where: { $0.id == id }) {
                draft.slots[i].outfit = outfit; draft.slots[i].unassignedByChoice = outfit == nil
            }
        }
    }
    private func needsCompositionReview(_ slot: PlanSlotDraft) -> Bool {
        guard let base = model.draft.baseEntries?.first(where: { $0.id == slot.id }),
              let outfit = slot.outfit, base.outfitID == outfit.id else { return false }
        return base.requiresReview || base.outfitRevision != outfit.revision
    }
    private func conflictLabel(_ entry: OutfitPlanEntry) -> String {
        guard let choice = model.draft.resolutions.first(where: { $0.existing == entry })?.choice else { return "Choose what to keep" }
        return choice == .keepBoth ? "Keep both entries" : "Replace existing entry"
    }
    private var review: some View {
        VStack(alignment: .leading, spacing: 16) {
            DisclosureRow(title: model.draft.plan.name, value: "Edit details") {
                model.update(invalidateConflicts: false) { $0.reviewing = false }
            }.disabled(locked)
            Text("\(model.draft.plan.start.displayDate) – \(model.draft.plan.end.displayDate) · \(model.draft.plan.start.timeZoneID)")
                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            if let scope = model.draft.editScope {
                Text(scope == .entry ? "This entry only. Shared plan settings stay unchanged." : scope == .future ? "This and future entries. Earlier and completed entries stay intact." : "Whole routine. Recorded wear and completed entries stay intact.")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                if !model.draft.removedEntryIDs.isEmpty {
                    Text("\(model.draft.removedEntryIDs.count) reviewed entries will be removed from this scope.").foregroundStyle(AppTheme.warning)
                }
            }
            if model.draft.usesRules == true { Text("Rule-based rotation · Review before saving").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
            ForEach(model.draft.slots) { slot in
                VStack(alignment: .leading, spacing: 8) {
                    if let conflict = model.availabilityMessage(for: slot) { SemanticFeedback(role: .warning, message: conflict) }
                    if needsCompositionReview(slot), let outfit = slot.outfit {
                        SemanticFeedback(role: .warning, message: "This outfit changed. Review its current pieces below; Save confirms the updated composition.")
                        OutfitComposition(pieceIDs: outfit.pieceIDs)
                    }
                    HStack {
                        Text(slot.day.displayDate).font(AppTypography.fieldLabel)
                        Spacer()
                        AppChip(title: "Gap", isSelected: slot.outfit == nil && slot.unassignedByChoice) { chooseSlot(slot.id, nil) }
                    }.padding(.bottom, -AppSpacing.small)
                    OutfitSelectionStrip(outfits: model.state.outfits, selectedID: slot.outfit?.id, locked: locked) { chooseSlot(slot.id, $0) }
                    LabeledField(title: "Occasion", text: Binding(get: { model.draft.slots.first { $0.id == slot.id }?.occasion ?? "" }, set: { value in
                        model.update { draft in if let i = draft.slots.firstIndex(where: { $0.id == slot.id }) { draft.slots[i].occasion = value } }
                    }))
                }.disabled(locked)
            }
            if model.draft.slots.contains(where: { $0.outfit == nil && !$0.unassignedByChoice }) {
                PlanUnassignedAction(title: "Leave remaining dates unassigned") {
                    model.update { draft in for i in draft.slots.indices where draft.slots[i].outfit == nil { draft.slots[i].unassignedByChoice = true } }
                }.disabled(locked)
            }
            ForEach(model.conflicts) { entry in
                DisclosureRow(title: "Resolve \(entry.day.displayDate)", value: conflictLabel(entry)) { resolvingConflict = entry.id }.disabled(locked)
            }
            let assigned = model.draft.slots.filter { $0.outfit != nil }.count
            Text("\(assigned) assigned · \(model.draft.slots.count - assigned) gaps · \(model.conflicts.count) overlaps")
                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
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
            Text("\(existing.day.displayDate) · \(existing.occasion)")
            Text(model.state.outfits.first { $0.id == existing.outfitID }?.displayName ?? "Existing unassigned entry")
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

struct PlanDefinitionView: View {
    @Environment(AppState.self) private var state
    let id: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var deletion: HistoryMutation?
    @State private var confirmingDeletion = false
    @State private var deletionError: String?
    @State private var editPresented = false
    @State private var pendingScope: RoutineEditScope?
    @State private var anchorEntryID: UUID?
    private var plan: PlanDefinition? { state.planDefinitions.first { $0.id == id } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let plan {
                    Text("\(plan.start.displayDate) – \(plan.end.displayDate)").font(AppTypography.body)
                    Text(plan.start.timeZoneID).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    if plan.trip != nil { TripDetailContent(plan: plan) }
                    else {
                        ForEach(state.planEntries.filter { $0.planID == id }) { entry in
                            NavigationLink(value: PlannerRoute.entry(entry.id)) { PlanAgendaRow(entry: entry, showDate: true) }.buttonStyle(.plain)
                        }
                    }
                    Button("Delete plan", role: .destructive) {
                        deletion = HistoryMutation(action: .deletePlan(plan, state.planEntries.filter { $0.planID == id }))
                        confirmingDeletion = true
                    }.frame(minHeight: 44)
                    if let deletionError {
                        SemanticFeedback(role: .danger, message: deletionError)
                        if deletion != nil { Button("Retry reviewed deletion", action: deletePlan).frame(minHeight: 44) }
                    }
                    Text("Saved dates are intentions. Recorded wear and history are separate.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                } else { AppEmptyState("Plan unavailable", systemImage: "calendar") }
                if let error = state.planError { SemanticFeedback(role: .danger, message: error); Button("Retry plans") { state.reloadPlanEntries() } }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle(plan?.name ?? "Plan").navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink)
            .appConfirmation("Delete this plan and its entries?", isPresented: $confirmingDeletion) {
                Button("Delete plan", role: .destructive, action: deletePlan)
                Button("Cancel", role: .cancel) { deletion = nil }
            } message: { Text("Actual wear and its counts stay in history. Outfits and pieces stay in Closet.") }
            .onAppear { state.reloadPlanEntries(); state.reloadOutfits() }
            .toolbar {
                if plan != nil { ToolbarItem(placement: .topBarTrailing) {
                    Button { editPresented = true } label: { Label("Edit plan scope", systemImage: AppSymbols.edit) }.tint(AppTheme.ink)
                } }
            }
            .sheet(isPresented: $editPresented, onDismiss: {
                guard let scope = pendingScope, let plan else { return }
                pendingScope = nil
                if scope == .entry {
                    if let entry = state.planEntries.first(where: { $0.id == anchorEntryID }) { state.openPlan(editing: entry) }
                } else { state.editPlanDefinition(plan, scope: scope, anchorEntryID: anchorEntryID) }
            }) {
                RoutineScopeChooser(entries: state.planEntries.filter { $0.planID == id }, isRoutine: plan?.routine != nil) { scope, anchor in
                    pendingScope = scope; anchorEntryID = anchor; editPresented = false
                }
            }
    }
    private func deletePlan() {
        guard let deletion else { return }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.applyHistoryMutation(deletion); state.reloadPlanEntries(); dismiss()
        } catch PieceStore.StoreError.staleRevision {
            self.deletion = nil; deletionError = "The plan changed. Review it before deleting."; state.reloadPlanEntries()
        } catch { deletionError = "Deletion is not acknowledged. Retry this reviewed operation." }
    }
}
