import AQDCore
import SwiftUI

struct LocalPlannerView: View {
    @Environment(AppState.self) private var state
    @State private var addPresented = false
    @State private var pendingAdd: PlannerAddChoice?
    private var entries: [OutfitPlanEntry] { state.planEntries.filter { $0.day.key == state.plannerDay.key } }
    private var counts: [String: Int] { Dictionary(grouping: state.planEntries, by: { $0.day.key }).mapValues(\.count) }
    var body: some View {
        @Bindable var state = state
        NavigationStack(path: $state.plannerPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PlannerCalendarView(day: $state.plannerDay, mode: $state.plannerMode, counts: counts)
                    if let error = state.planError {
                        SemanticFeedback(role: .danger, message: error)
                        Button("Retry plans") { state.reloadPlanEntries() }.frame(minHeight: 44)
                    }
                    if let recent = state.recentPlan {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            HStack {
                                Text("Plan saved · \(recent.day.key)")
                                Spacer()
                                if state.planUndoPending || (state.planUndoDeadline ?? .distantPast) >= context.date {
                                    Button(state.planUndoPending ? "Check Undo" : "Undo") { state.undoRecentPlan() }.frame(minHeight: 44)
                                }
                            }.font(AppTypography.supporting)
                        }
                    }
                    Text(state.plannerDay.key).font(AppTypography.section)
                    if entries.isEmpty && state.planError == nil {
                        ContentUnavailableView("No plans for this day", systemImage: "calendar",
                            description: Text("Choose an outfit, or leave an intentional gap. Planning never records wear."))
                        PrimaryAction(title: "Plan an outfit") { state.openPlan(day: state.plannerDay) }
                    }
                    ForEach(entries) { entry in
                        NavigationLink(value: PlannerRoute.entry(entry.id)) { PlanAgendaRow(entry: entry) }.buttonStyle(.plain)
                    }
                    if !state.planDefinitions.isEmpty {
                        Text("Your plans").font(AppTypography.section)
                        ForEach(state.planDefinitions) { plan in
                            NavigationLink(value: PlannerRoute.plan(plan.id)) {
                                HStack {
                                    Text(plan.name).frame(maxWidth: .infinity, alignment: .leading)
                                    Text(plan.start.key).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                                    Image(systemName: "chevron.forward").accessibilityHidden(true)
                                }.foregroundStyle(AppTheme.ink).padding(14).frame(minHeight: 54)
                                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                            }.buttonStyle(.plain)
                        }
                    }
                    let upcoming = state.planEntries.filter { $0.day.key > state.plannerDay.key }
                    if !upcoming.isEmpty {
                        Text("Upcoming plans").font(AppTypography.section)
                        ForEach(Array(upcoming.prefix(8))) { entry in
                            NavigationLink(value: PlannerRoute.entry(entry.id)) { PlanAgendaRow(entry: entry, showDate: true) }.buttonStyle(.plain)
                        }
                    }
                }.padding(20)
            }.background(AppTheme.canvas).navigationTitle("Planner")
                .navigationDestination(for: PlannerRoute.self) { route in
                    switch route {
                    case .entry(let id): LocalPlanEntryView(id: id)
                    case .plan(let id): PlanDefinitionView(id: id)
                    case .packing(let id): TripPackingView(id: id)
                    case .dates(let id, let gaps): PlanDatesView(id: id, gapsOnly: gaps)
                    }
                }
                .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
                .toolbar { ToolbarItem(placement: .topBarTrailing) {
                    Button { addPresented = true } label: { Label("Add to Planner", systemImage: "plus") }.tint(AppTheme.ink)
                } }
                .onAppear { state.reloadPlanEntries(); state.reloadOutfits() }
                .sheet(isPresented: $addPresented, onDismiss: {
                    let choice = pendingAdd; pendingAdd = nil
                    if choice == .day { state.openPlan(day: state.plannerDay) }
                    else if choice == .dates { state.openPlanAuthoring(day: state.plannerDay) }
                    else if choice == .routine { state.openPlanAuthoring(day: state.plannerDay, routine: true) }
                    else if choice == .trip { state.openPlanAuthoring(day: state.plannerDay, trip: true) }
                }) {
                    PlannerAddSheet { pendingAdd = $0; addPresented = false }
                }
        }.tint(AppTheme.ink)
    }
}

struct PlanAgendaRow: View {
    @Environment(AppState.self) private var state
    let entry: OutfitPlanEntry
    var showDate = false
    private var outfit: Outfit? { state.outfits.first { $0.id == entry.outfitID } }
    var body: some View {
        HStack(spacing: 12) {
            if let outfit { OutfitComposition(pieceIDs: outfit.pieceIDs, pieceHeight: 56, limit: 2).frame(width: 64, height: 80).clipped() }
            VStack(alignment: .leading, spacing: 4) {
                Text(outfit?.name ?? "Outfit unassigned").font(AppTypography.body).foregroundStyle(AppTheme.ink)
                if showDate { Text(entry.day.key).font(AppTypography.supporting) }
                if !entry.occasion.isEmpty { Text(entry.occasion).font(AppTypography.supporting) }
                Text(entry.state.rawValue.capitalized).font(AppTypography.supporting)
                if entry.requiresReview || (outfit != nil && outfit?.revision != entry.outfitRevision) {
                    Text("Needs review").font(AppTypography.metadata).foregroundStyle(AppTheme.warning)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(AppTheme.secondary)
            Image(systemName: "chevron.forward").font(.system(size: 22)).foregroundStyle(AppTheme.secondary).frame(width: 22).accessibilityHidden(true)
        }.padding(14).frame(minHeight: 108).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct LocalPlanEntryView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let id: UUID
    @State private var confirming = false
    @State private var removal: PlanEntryDeletionRequest?
    @State private var error: String?
    @State private var skipRequest: HistoryMutation?
    private var entry: OutfitPlanEntry? { state.planEntries.first { $0.id == id } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let entry {
                    PlanAgendaRow(entry: entry, showDate: true)
                    Text(entry.day.timeZoneID).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    if let outfit = state.outfits.first(where: { $0.id == entry.outfitID }) {
                        OutfitComposition(pieceIDs: outfit.pieceIDs)
                        NavigationLink(value: ClosetRoute.outfit(outfit.id)) { Text("Open outfit") }.frame(minHeight: 44)
                    }
                    if entry.requiresReview { SemanticFeedback(role: .warning, message: "Review the current outfit before using this plan.") }
                    if entry.state == .planned || entry.state == .unassigned {
                        PrimaryAction(title: "Record wear") { state.openWear(outfitID: entry.outfitID, entry: entry) }
                            .disabled(removal != nil || skipRequest != nil)
                        SecondaryAction(title: skipRequest == nil ? "Skip entry" : "Check skip result") {
                            skip(entry)
                        }
                    }
                    if entry.wearRecordID != nil {
                        NavigationLink("View recorded wear") { LocalWearHistoryView() }.frame(minHeight: 44)
                    }
                    PrimaryAction(title: "Edit entry") { state.openPlan(editing: entry) }
                        .disabled(removal != nil || entry.state == .worn || entry.state == .skipped)
                    Text("Planning this date hasn’t recorded wear. Actual wear remains a separate action.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    Button("Remove entry", role: .destructive) { removal = PlanEntryDeletionRequest(entry: entry); confirming = true }.frame(minHeight: 44)
                } else { ContentUnavailableView("Plan unavailable", systemImage: "calendar") }
                if let error {
                    SemanticFeedback(role: .danger, message: error)
                    if removal != nil { Button("Retry reviewed removal", action: remove).frame(minHeight: 44) }
                }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Plan entry").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Remove this plan entry?", isPresented: $confirming, titleVisibility: .visible) {
                Button("Remove entry", role: .destructive, action: remove)
                Button("Cancel", role: .cancel) { removal = nil }
            } message: { Text("Removes this planned assignment. Its outfit and recorded wear stay. Other dates and your routine remain.") }
    }
    private func skip(_ entry: OutfitPlanEntry) {
        if skipRequest == nil { skipRequest = HistoryMutation(action: .skip(entry)) }
        do {
            guard let store = state.store, let request = skipRequest else { throw PieceStore.StoreError.corruptStore }
            try store.applyHistoryMutation(request); skipRequest = nil; state.reloadPlanEntries(); error = nil
        } catch PieceStore.StoreError.staleRevision {
            skipRequest = nil; error = "This entry changed. Review it again."; state.reloadPlanEntries()
        } catch { self.error = "Skip is not acknowledged. Retry the same operation." }
    }
    private func remove() {
        guard let removal else { return }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.deletePlanEntry(removal); state.reloadPlanEntries(); dismiss()
        } catch PieceStore.StoreError.staleRevision {
            self.removal = nil; self.error = "This entry changed. Reopen the latest entry before removing it."; state.reloadPlanEntries()
        } catch { self.error = "Removal isn’t acknowledged. Retry this same reviewed operation." }
    }
}
