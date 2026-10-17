import AQDCore
import SwiftUI

struct LocalPlannerView: View {
    @Environment(AppState.self) private var state
    @State private var showPast = false
    private var zone: TimeZone { TimeZone(identifier: state.plannerDay.timeZoneID) ?? .current }
    private var today: LocalPlanDay { LocalPlanDay(timeZone: zone) }
    private var entries: [OutfitPlanEntry] {
        state.planEntries.filter { $0.day.key == state.plannerDay.key }
            .sorted { ($0.state == .worn || $0.state == .skipped ? 1 : 0) < ($1.state == .worn || $1.state == .skipped ? 1 : 0) }
    }
    private var outfitRevisions: [UUID: Int] { Dictionary(state.outfits.map { ($0.id, $0.revision) }, uniquingKeysWith: { first, _ in first }) }
    private var markers: [String: PlannerDayMarker] { PlannerPresentation.markers(for: state.planEntries, outfitRevisions: outfitRevisions) }
    private var visibleDays: [LocalPlanDay] { (try? PlannerCalendar.days(containing: state.plannerDay, mode: state.plannerMode)) ?? [] }
    private var groups: PlannerPresentation.PlanGroups { PlannerPresentation.group(state.planDefinitions, visible: visibleDays, today: today) }
    private var summaries: [UUID: PlannerPresentation.PlanSummary] {
        Dictionary(PlannerPresentation.summaries(plans: state.planDefinitions, entries: state.planEntries, today: today,
                                                 outfitRevisions: outfitRevisions).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
    private var counts: [String: Int] { markers.mapValues(\.total) }
    private var isToday: Bool { state.plannerDay.key == today.key }
    private var selectedDateLabel: String {
        guard let date = try? state.plannerDay.date() else { return state.plannerDay.displayDate }
        return date.formatted(Date.FormatStyle(timeZone: zone).weekday(.wide).month(.wide).day())
    }
    private var daySummary: String {
        guard let marker = markers[state.plannerDay.key], !marker.isEmpty else { return "Nothing planned" }
        let parts = [(marker.planned, "planned"), (marker.gaps, "to choose"), (marker.worn, "worn"), (marker.skipped, "skipped")]
            .filter { $0.0 > 0 }.map { "\($0.0) \($0.1)" }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        @Bindable var state = state
        NavigationStack(path: $state.plannerPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PlannerCalendarHeader(day: $state.plannerDay, mode: $state.plannerMode, counts: counts, markers: markers)
                    dayHeader
                    if let error = state.planError {
                        SemanticFeedback(role: .danger, message: error)
                        Button("Retry plans") { state.reloadPlanEntries() }.frame(minHeight: 44)
                    }
                    savedBanner
                    dayEntries
                    plansSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .padding(.top, AppSpacing.large).background(AppTheme.canvas).navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: PlannerRoute.self) { route in
                switch route {
                case .entry(let id): LocalPlanEntryView(id: id)
                case .plan(let id): PlanDefinitionView(id: id)
                case .packing(let id): TripPackingView(id: id)
                case .dates(let id, let gaps): PlanDatesView(id: id, gapsOnly: gaps)
                }
            }
            .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        AccessoryButton("Plan one day", systemImage: "calendar") { state.openPlan(day: state.plannerDay) }
                        AccessoryButton("Plan several days", systemImage: "calendar.badge.plus") { state.openPlanAuthoring(day: state.plannerDay) }
                        AccessoryButton("Create a routine", systemImage: "repeat") { state.openPlanAuthoring(day: state.plannerDay, routine: true) }
                        AccessoryButton("Plan an event or trip", systemImage: "suitcase") { state.openPlanAuthoring(day: state.plannerDay, trip: true) }
                    } label: { Label("Add to Planner", systemImage: "plus") }.tint(AppTheme.ink)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today") { withAnimation { state.plannerDay = today } }
                        .tint(AppTheme.ink).disabled(isToday).accessibilityHint("Jumps to today")
                }
            }
            .onAppear { state.reloadPlanEntries(); state.reloadOutfits() }
        }.tint(AppTheme.ink)
    }

    private var dayHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isToday ? "Today" : selectedDateLabel).font(AppTypography.section)
                Text(isToday ? "\(selectedDateLabel) · \(daySummary)" : daySummary)
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }
            Spacer(minLength: 12)
            Button { state.openPlan(day: state.plannerDay) } label: {
                Label("Plan", systemImage: "plus").font(AppTypography.supporting)
            }.buttonStyle(.bordered).buttonBorderShape(.capsule).tint(AppTheme.ink).frame(minHeight: 44)
                .accessibilityLabel("Plan this day")
        }.accessibilityElement(children: .contain)
    }

    @ViewBuilder private var savedBanner: some View {
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
    }

    @ViewBuilder private var dayEntries: some View {
        if entries.isEmpty && state.planError == nil {
            VStack(spacing: 12) {
                AppEmptyState("Nothing planned", systemImage: "calendar",
                    description: Text("Choose an outfit, or leave an intentional gap. Planning never records wear."), fillsAvailableSpace: false)
                Button { state.openPlan(day: state.plannerDay) } label: {
                    Text("Plan this day").frame(minWidth: 160, minHeight: 44)
                }.buttonStyle(.borderedProminent).buttonBorderShape(.capsule).tint(AppTheme.primaryFill)
                    .foregroundStyle(AppTheme.onPrimary)
            }.frame(maxWidth: .infinity)
        }
        ForEach(entries) { entry in PlanDayCard(entry: entry, outfitRevisions: outfitRevisions) }
    }

    @ViewBuilder private var plansSection: some View {
        let groups = groups
        if !groups.inRange.isEmpty { planGroup(state.plannerMode == .week ? "This week" : "This month", groups.inRange) }
        if !groups.upcoming.isEmpty { planGroup("Upcoming", groups.upcoming) }
        if !groups.past.isEmpty {
            DisclosureGroup(isExpanded: $showPast) {
                VStack(spacing: 8) { ForEach(groups.past) { planRow($0) } }.padding(.top, 8)
            } label: { Text("Past · \(groups.past.count)").font(AppTypography.section) }
                .tint(AppTheme.ink).foregroundStyle(AppTheme.ink)
        }
    }

    private func planGroup(_ title: String, _ plans: [PlanDefinition]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(AppTypography.section)
            ForEach(plans) { planRow($0) }
        }
    }

    private func planRow(_ plan: PlanDefinition) -> some View {
        let summary = summaries[plan.id]
        let kind = summary?.kind ?? .plan
        let symbol = kind == .trip ? "suitcase" : kind == .routine ? "repeat" : "calendar"
        let range = plan.start.key == plan.end.key ? plan.start.displayDate : "\(plan.start.displayDate) – \(plan.end.displayDate)"
        var status: [String] = []
        if let summary {
            if summary.gaps > 0 { status.append("\(summary.gaps) to choose") }
            if summary.needsReview > 0 { status.append("\(summary.needsReview) to review") }
        }
        return NavigationLink(value: kind == .trip && !(summary?.isPast ?? false) ? PlannerRoute.packing(plan.id) : PlannerRoute.plan(plan.id)) {
            HStack(spacing: 12) {
                Image(systemName: symbol).frame(width: 28).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.name.isEmpty ? "Untitled plan" : plan.name).font(AppTypography.body)
                    Text(range).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    if !status.isEmpty {
                        Text(status.joined(separator: " · ")).font(AppTypography.metadata).foregroundStyle(AppTheme.warning)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.forward").font(AppTypography.disclosure).foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
            }.foregroundStyle(AppTheme.ink).padding(14).frame(minHeight: 54)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
            .contextMenu {
                AccessoryButton("Open plan", systemImage: "calendar") { state.plannerPath.append(.plan(plan.id)) }
                AccessoryButton("Review dates", systemImage: "list.bullet") { state.plannerPath.append(.dates(plan.id, false)) }
                if plan.trip != nil {
                    AccessoryButton("Packing list", systemImage: "suitcase") { state.plannerPath.append(.packing(plan.id)) }
                }
            }
    }
}

/// One day entry with its next actions in view: no detour through a detail page to record wear or skip.
struct PlanDayCard: View {
    @Environment(AppState.self) private var state
    let entry: OutfitPlanEntry
    let outfitRevisions: [UUID: Int]
    @State private var actions = PlanEntryActions()
    private var outfit: Outfit? { state.outfits.first { $0.id == entry.outfitID } }
    private var isOpen: Bool { entry.state == .planned || entry.state == .unassigned }
    private var stale: Bool { PlannerPresentation.isStale(entry, outfitRevisions: outfitRevisions) }

    var body: some View {
        VStack(spacing: 0) {
            NavigationLink(value: PlannerRoute.entry(entry.id)) {
                PlanAgendaRow(entry: entry, embedded: true)
            }.buttonStyle(.plain)
            if isOpen {
                HStack(spacing: 8) {
                    if entry.state == .unassigned {
                        Button { state.openPlan(editing: entry) } label: { Text("Choose outfit").frame(maxWidth: .infinity, minHeight: 36) }
                            .buttonStyle(.borderedProminent).tint(AppTheme.primaryFill).foregroundStyle(AppTheme.onPrimary)
                    } else if stale {
                        Button { state.openPlan(editing: entry) } label: { Text("Review").frame(maxWidth: .infinity, minHeight: 36) }
                            .buttonStyle(.borderedProminent).tint(AppTheme.primaryFill).foregroundStyle(AppTheme.onPrimary)
                    } else {
                        Button { state.openWear(outfitID: entry.outfitID, entry: entry) } label: {
                            Text("Record wear").frame(maxWidth: .infinity, minHeight: 36)
                        }.buttonStyle(.borderedProminent).tint(AppTheme.primaryFill).foregroundStyle(AppTheme.onPrimary)
                    }
                    Button { actions.skip(entry, state: state) } label: {
                        Text(actions.isSkipPending ? "Check skip" : "Skip").frame(minWidth: 64, minHeight: 36)
                    }.buttonStyle(.bordered).tint(AppTheme.ink)
                    Menu {
                        AccessoryButton("Edit plan", systemImage: AppSymbols.edit) { state.openPlan(editing: entry) }
                        if entry.state == .planned && !stale {
                            AccessoryButton("Change outfit", systemImage: "arrow.triangle.2.circlepath") { state.openPlan(editing: entry) }
                        }
                        if entry.state == .unassigned || stale {
                            AccessoryButton("Record wear", systemImage: "checkmark.circle") { state.openWear(outfitID: entry.outfitID, entry: entry) }
                        }
                    } label: { Image(systemName: "ellipsis").frame(width: 44, height: 36) }
                        .buttonStyle(.bordered).tint(AppTheme.ink).accessibilityLabel("More plan options")
                }.controlSize(.regular).padding(.horizontal, 14).padding(.bottom, 14)
            }
            if let error = actions.error {
                SemanticFeedback(role: .danger, message: error).padding(.horizontal, 14).padding(.bottom, 14)
            }
        }
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            AccessoryButton("Open plan", systemImage: "calendar") { state.plannerPath.append(.entry(entry.id)) }
            AccessoryButton("Edit plan", systemImage: AppSymbols.edit) { state.openPlan(editing: entry) }
                .disabled(!isOpen)
        } preview: {
            CollectionContextPreview(title: outfit?.displayName ?? "Outfit unassigned", detail: entry.day.displayDate) {
                if let outfit {
                    CollectionArtwork(pieceIDs: outfit.pieceIDs, height: 300)
                } else {
                    Image(systemName: "calendar").font(.largeTitle).foregroundStyle(AppTheme.secondary)
                        .frame(maxWidth: .infinity).frame(height: 180)
                }
            }.environment(state)
        }
    }
}

/// Skip stays one retryable operation: a failed acknowledgement keeps the same request until it settles.
@MainActor @Observable final class PlanEntryActions {
    private var request: HistoryMutation?
    var error: String?
    var isSkipPending: Bool { request != nil }

    func skip(_ entry: OutfitPlanEntry, state: AppState) {
        if request == nil { request = HistoryMutation(action: .skip(entry)) }
        do {
            guard let store = state.store, let request else { throw PieceStore.StoreError.corruptStore }
            try store.applyHistoryMutation(request); self.request = nil; state.reloadPlanEntries(); error = nil
        } catch PieceStore.StoreError.staleRevision {
            request = nil; error = "This entry changed. Review it again."; state.reloadPlanEntries()
        } catch { self.error = "Skip is not acknowledged. Retry the same operation." }
    }
}

struct PlanAgendaRow: View {
    @Environment(AppState.self) private var state
    let entry: OutfitPlanEntry
    var showDate = false
    var embedded = false
    private var outfit: Outfit? { state.outfits.first { $0.id == entry.outfitID } }
    private var occasion: String? {
        let value = entry.occasion.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = (outfit?.displayName ?? "Outfit unassigned").trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty || value.caseInsensitiveCompare(title) == .orderedSame ? nil : value
    }
    var body: some View {
        HStack(spacing: 12) {
            if let outfit { OutfitComposition(pieceIDs: outfit.pieceIDs, pieceHeight: 56, limit: 2).frame(width: 64, height: 80).clipped() }
            VStack(alignment: .leading, spacing: 4) {
                Text(outfit?.displayName ?? "Outfit unassigned").font(AppTypography.body).foregroundStyle(AppTheme.ink)
                if showDate { Text(entry.day.displayDate).font(AppTypography.supporting) }
                if let occasion { Text(occasion).font(AppTypography.supporting) }
                Text(entry.state.rawValue.capitalized).font(AppTypography.supporting)
                if entry.requiresReview || (outfit != nil && outfit?.revision != entry.outfitRevision) {
                    Text("Needs review").font(AppTypography.metadata).foregroundStyle(AppTheme.warning)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(AppTheme.secondary)
            Image(systemName: "chevron.forward").font(AppTypography.disclosure).foregroundStyle(AppTheme.secondary).frame(width: 22).accessibilityHidden(true)
        }.padding(14).frame(minHeight: outfit == nil ? 80 : 108)
            .background { if !embedded { AppTheme.surface.clipShape(RoundedRectangle(cornerRadius: 12)) } }
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
    @State private var skipActions = PlanEntryActions()
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
                if let error = error ?? skipActions.error {
                    SemanticFeedback(role: .danger, message: error)
                }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Plan entry").navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.ink)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                if let entry {
                    Menu {
                        if let outfit = state.outfits.first(where: { $0.id == entry.outfitID }) {
                            NavigationLink(value: ClosetRoute.outfit(outfit.id)) { AccessoryLabel("Open outfit", systemImage: "square.stack") }
                        }
                        AccessoryButton("Edit plan", systemImage: AppSymbols.edit) { state.openPlan(editing: entry) }
                            .disabled(removal != nil || skipActions.isSkipPending || entry.state == .worn || entry.state == .skipped)
                        if entry.state == .planned || entry.state == .unassigned {
                            AccessoryButton(skipActions.isSkipPending ? "Check skip result" : "Skip this date", systemImage: "forward.end") { skipActions.skip(entry, state: state) }
                                .disabled(removal != nil)
                            Section {
                                Button("Remove from Planner", systemImage: "trash", role: .destructive) {
                                    removal = PlanEntryDeletionRequest(entry: entry); confirming = true
                                }.disabled(removal != nil || skipActions.isSkipPending)
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
                        if skipActions.isSkipPending {
                            PrimaryAction(title: "Check skip result") { skipActions.skip(entry, state: state) }
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
            .appConfirmation("Remove from Planner?", isPresented: $confirming) {
                Button("Remove entry", role: .destructive, action: remove)
                Button("Cancel", role: .cancel) { removal = nil }
            } message: { Text("Removes this entry only. Your outfits, recorded wear, other dates and routine stay.") }
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
