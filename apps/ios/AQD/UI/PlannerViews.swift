import AQDCore
import SwiftUI

struct LocalPlannerView: View {
    @Environment(AppState.self) private var state
    @State private var addPresented = false
    @State private var pendingAdd: PlannerAddChoice?
    private var entries: [OutfitPlanEntry] { state.planEntries.filter { $0.day.key == state.plannerDay.key } }
    private var selectedDateLabel: String {
        guard let date = try? state.plannerDay.date(),
              let zone = TimeZone(identifier: state.plannerDay.timeZoneID) else { return state.plannerDay.displayDate }
        return date.formatted(Date.FormatStyle(timeZone: zone).weekday(.abbreviated).month(.abbreviated).day())
    }
    private var counts: [String: Int] { Dictionary(grouping: state.planEntries, by: { $0.day.key }).mapValues(\.count) }
    var body: some View {
        @Bindable var state = state
        NavigationStack(path: $state.plannerPath) {
            VStack(alignment: .leading, spacing: 16) {
                PlannerCalendarHeader(day: $state.plannerDay, mode: $state.plannerMode, counts: counts).padding(.horizontal, 20)
                Text(selectedDateLabel).font(AppTypography.body).foregroundStyle(AppTheme.secondary).padding(.horizontal, 20)
                if state.planError == nil && entries.isEmpty && state.planDefinitions.isEmpty {
                    EmptyStatePage(title: "No plans for this day", systemImage: "calendar",
                                   description: Text("Choose an outfit, or leave an intentional gap. Planning never records wear.")) {
                        PrimaryAction(title: "Plan an outfit") { state.openPlan(day: state.plannerDay) }
                    }
                } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let error = state.planError {
                        SemanticFeedback(role: .danger, message: error)
                        Button("Retry plans") { state.reloadPlanEntries() }.frame(minHeight: 44)
                    }
                    if let recent = state.recentPlan {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            HStack {
                                Text("Plan saved · \(recent.day.displayDate)")
                                Spacer()
                                if state.planUndoPending || (state.planUndoDeadline ?? .distantPast) >= context.date {
                                    Button(state.planUndoPending ? "Check Undo" : "Undo") { state.undoRecentPlan() }.frame(minHeight: 44)
                                }
                            }.font(AppTypography.supporting)
                        }
                    }
                    if entries.isEmpty && state.planError == nil {
                        AppEmptyState("No plans for this day", systemImage: "calendar",
                            description: Text("Choose an outfit, or leave an intentional gap. Planning never records wear."), fillsAvailableSpace: false)
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
                                    Text(plan.start.displayDate).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                                    Image(systemName: "chevron.forward").font(AppTypography.disclosure).accessibilityHidden(true)
                                }.foregroundStyle(AppTheme.ink).padding(14).frame(minHeight: 54)
                                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                            }.buttonStyle(.plain)
                        }
                    }

                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .safeAreaInset(edge: .bottom) {
                if entries.isEmpty && state.planError == nil {
                    ActionFooter { PrimaryAction(title: "Plan an outfit") { state.openPlan(day: state.plannerDay) } }
                }
            }
                }
            }.padding(.top, 16).background(AppTheme.canvas).navigationTitle("").navigationBarTitleDisplayMode(.inline)
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
    private var occasion: String? {
        let value = entry.occasion.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = (outfit?.name ?? "Outfit unassigned").trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty || value.caseInsensitiveCompare(title) == .orderedSame ? nil : value
    }
    var body: some View {
        HStack(spacing: 12) {
            if let outfit { OutfitComposition(pieceIDs: outfit.pieceIDs, pieceHeight: 56, limit: 2).frame(width: 64, height: 80).clipped() }
            VStack(alignment: .leading, spacing: 4) {
                Text(outfit?.name ?? "Outfit unassigned").font(AppTypography.body).foregroundStyle(AppTheme.ink)
                if showDate { Text(entry.day.displayDate).font(AppTypography.supporting) }
                if let occasion { Text(occasion).font(AppTypography.supporting) }
                Text(entry.state.rawValue.capitalized).font(AppTypography.supporting)
                if entry.requiresReview || (outfit != nil && outfit?.revision != entry.outfitRevision) {
                    Text("Needs review").font(AppTypography.metadata).foregroundStyle(AppTheme.warning)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(AppTheme.secondary)
            Image(systemName: "chevron.forward").font(AppTypography.disclosure).foregroundStyle(AppTheme.secondary).frame(width: 22).accessibilityHidden(true)
        }.padding(14).frame(minHeight: outfit == nil ? 80 : 108).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct LocalPlanEntryView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let id: UUID
    @State private var confirming = false
    @State private var viewingWear = false
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
                    }
                    if entry.requiresReview { SemanticFeedback(role: .warning, message: "Review the current outfit before using this plan.") }
                    Text("Planning this date hasn’t recorded wear. Actual wear remains a separate action.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                } else { AppEmptyState("Plan unavailable", systemImage: "calendar") }
                if let error {
                    SemanticFeedback(role: .danger, message: error)
                }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Plan entry").navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.ink)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                if let entry {
                    Menu {
                        if let outfit = state.outfits.first(where: { $0.id == entry.outfitID }) {
                            NavigationLink(value: ClosetRoute.outfit(outfit.id)) { Label("Open outfit", systemImage: "square.stack") }
                        }
                        Button("Edit plan", systemImage: "square.and.pencil") { state.openPlan(editing: entry) }
                            .disabled(removal != nil || skipRequest != nil || entry.state == .worn || entry.state == .skipped)
                        if entry.state == .planned || entry.state == .unassigned {
                            Button(skipRequest == nil ? "Skip this date" : "Check skip result", systemImage: "forward.end") { skip(entry) }
                                .disabled(removal != nil)
                            Section {
                                Button("Remove from Planner", systemImage: "trash", role: .destructive) {
                                    removal = PlanEntryDeletionRequest(entry: entry); confirming = true
                                }.disabled(removal != nil || skipRequest != nil)
                            }
                        }
                    } label: { Label("More plan options", systemImage: "ellipsis") }
                }
            } }
            .safeAreaInset(edge: .bottom) {
                if removal != nil {
                    ActionFooter { PrimaryAction(title: "Check removal result", action: remove) }
                } else if let entry {
                    ActionFooter {
                        if skipRequest != nil {
                            PrimaryAction(title: "Check skip result") { skip(entry) }
                        } else if entry.state == .planned || entry.state == .unassigned {
                            PrimaryAction(title: "Record wear") { state.openWear(outfitID: entry.outfitID, entry: entry) }
                        } else if entry.wearRecordID != nil {
                            PrimaryAction(title: "View recorded wear") { viewingWear = true }
                        } else {
                            PrimaryAction(title: "Open Planner") { state.selection = 2; dismiss() }
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $viewingWear) {
                if let wearID = entry?.wearRecordID { LocalWearDetailView(id: wearID) }
            }
            .alert("Remove from Planner?", isPresented: $confirming) {
                Button("Remove entry", role: .destructive, action: remove)
                Button("Cancel", role: .cancel) { removal = nil }
            } message: { Text("Removes this entry only. Your outfits, recorded wear, other dates and routine stay.") }
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
