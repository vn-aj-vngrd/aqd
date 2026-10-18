import AQDCore
import SwiftUI

struct LocalPlannerView: View {
    @Environment(AppState.self) private var state
    @State private var showPast = false
    @State private var searching = false
    @State private var query = PlannerQuery()
    private var zone: TimeZone { TimeZone(identifier: state.plannerDay.timeZoneID) ?? .current }
    private var today: LocalPlanDay { LocalPlanDay(timeZone: zone) }
    private var outfitNames: [UUID: String] { Dictionary(state.outfits.map { ($0.id, $0.displayName) }, uniquingKeysWith: { first, _ in first }) }
    private var dayQuery: PlannerQuery { PlannerQuery(status: query.status) }
    private var entries: [OutfitPlanEntry] {
        PlannerPresentation.openFirst(dayQuery.apply(to: state.planEntries.filter { $0.day.key == state.plannerDay.key }, outfitRevisions: outfitRevisions))
    }
    private var outfitRevisions: [UUID: Int] { Dictionary(state.outfits.map { ($0.id, $0.revision) }, uniquingKeysWith: { first, _ in first }) }
    private var markers: [String: PlannerDayMarker] { PlannerPresentation.markers(for: state.planEntries, outfitRevisions: outfitRevisions) }
    private var visibleDays: [LocalPlanDay] { (try? PlannerCalendar.days(containing: state.plannerDay, mode: state.plannerMode)) ?? [] }
    private var filteredPlans: [PlanDefinition] { query.apply(to: state.planDefinitions) }
    private var groups: PlannerPresentation.PlanGroups { PlannerPresentation.group(filteredPlans, visible: visibleDays, today: today) }
    private var summaries: [UUID: PlannerPresentation.PlanSummary] {
        Dictionary(PlannerPresentation.summaries(plans: state.planDefinitions, entries: state.planEntries, today: today,
                                                 outfitRevisions: outfitRevisions).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
    private var counts: [String: Int] { markers.mapValues(\.total) }
    private var isToday: Bool { state.plannerDay.key == today.key }
    private var selectedDateLabel: String { state.plannerDay.display(.full) }
    private var daySummary: String {
        guard let marker = markers[state.plannerDay.key], !marker.isEmpty else { return "Nothing planned" }
        let parts = [(marker.planned, "planned"), (marker.gaps, "to choose"), (marker.worn, "worn"), (marker.skipped, "skipped")]
            .filter { $0.0 > 0 }.map { "\($0.0) \($0.1)" }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        @Bindable var state = state
        NavigationStack(path: $state.plannerPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    if query.isSearching {
                        searchResults
                    } else {
                        PlannerCalendarHeader(day: $state.plannerDay, mode: $state.plannerMode, counts: counts, markers: markers,
                                              onToday: isToday ? nil : { withAnimation { state.plannerDay = today } })
                        dayHeader
                        if let error = state.planError {
                            SemanticFeedback(role: .danger, message: error)
                            SecondaryAction(title: "Retry plans", compact: true) { state.reloadPlanEntries() }
                        }
                        savedBanner
                        dayEntries
                        plansSection
                    }
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.bottom, AppSpacing.section)
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
                if !searching {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { searching = true } label: { Label("Search planner", systemImage: "magnifyingglass") }
                            .tint(AppTheme.ink).accessibilityIdentifier("planner.search")
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            AccessoryButton("Plan one day", systemImage: "calendar") { state.openPlan(day: state.plannerDay) }
                            AccessoryButton("Plan several days", systemImage: "calendar.badge.plus") { state.openPlanAuthoring(day: state.plannerDay) }
                            AccessoryButton("Create a routine", systemImage: "repeat") { state.openPlanAuthoring(day: state.plannerDay, routine: true) }
                            AccessoryButton("Plan an event or trip", systemImage: "suitcase") { state.openPlanAuthoring(day: state.plannerDay, trip: true) }
                        } label: { Label("Add to Planner", systemImage: "plus") }
                            .tint(AppTheme.ink).accessibilityIdentifier("planner.add")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) { filterMenu }
            }
            .modifier(PlannerSearchField(query: $query.text, active: $searching))
            .onAppear { state.reloadPlanEntries(); state.reloadOutfits() }
        }.tint(AppTheme.ink)
    }

    /// Same icon everywhere; it fills while a filter hides content. In search every section still applies to the results.
    private var filterMenu: some View {
        Menu {
            Section("Show entries") {
                ForEach(PlannerQuery.Status.allCases, id: \.self) { option($0.rawValue, $0, $query.status) }
            }
            Section("Show plans") {
                ForEach(PlannerQuery.Kind.allCases, id: \.self) { option($0.rawValue, $0, $query.kind) }
            }
            // Sort only orders plans, so it appears only when there are at least two to order.
            if state.planDefinitions.count > 1 {
                Section("Sort plans by") {
                    ForEach(PlannerQuery.Sort.allCases, id: \.self) { option($0.rawValue, $0, $query.sort) }
                }
            }
            if !query.isDefault {
                Button("Reset filters", systemImage: "arrow.counterclockwise") { query = PlannerQuery(text: query.text) }
            }
        } label: {
            Label("Filter and sort", systemImage: query.isFiltering ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease")
        }.tint(AppTheme.ink).accessibilityIdentifier("planner.filter").accessibilityValue(query.isFiltering ? "Filters on" : "No filters")
    }

    private func option<Value: Equatable>(_ title: String, _ value: Value, _ selection: Binding<Value>) -> some View {
        Toggle(title, isOn: Binding(get: { selection.wrappedValue == value }, set: { if $0 { selection.wrappedValue = value } }))
    }

    /// Search spans every date, so results carry their date and sit apart from the calendar.
    @ViewBuilder private var searchResults: some View {
        let matchedEntries = query.apply(to: state.planEntries, outfitRevisions: outfitRevisions, outfitNames: outfitNames)
            .sorted { $0.day.key == $1.day.key ? $0.id.uuidString < $1.id.uuidString : $0.day.key < $1.day.key }
        let matchedPlans = query.apply(to: state.planDefinitions)
        if matchedEntries.isEmpty && matchedPlans.isEmpty {
            ContentUnavailableView.search(text: query.searchTerm)
        }
        if !matchedPlans.isEmpty {
            planGroup("Plans", matchedPlans)
        }
        if !matchedEntries.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Entries").font(AppTypography.section)
                ForEach(matchedEntries) { PlanDayCard(entry: $0, outfitRevisions: outfitRevisions, showDate: true) }
            }
        }
    }

    private var dayHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            PlannerMetaLine(leading: isToday ? "Today" : selectedDateLabel, trailing: daySummary, leadingFont: AppTypography.section)
            if isToday { Text(selectedDateLabel).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading).accessibilityElement(children: .combine)
            .accessibilityIdentifier("planner.dayHeader")
    }

    @ViewBuilder private var savedBanner: some View {
        if let recent = state.recentPlan {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack {
                    Text("Plan saved for \(recent.day.displayDate)")
                    Spacer()
                    if state.planUndoPending || (state.planUndoDeadline ?? .distantPast) >= context.date {
                        Button(state.planUndoPending ? "Check Undo" : "Undo") { state.undoRecentPlan() }
                            .foregroundStyle(AppTheme.ink).frame(minHeight: AppControlMetrics.minimumTarget)
                    }
                }.font(AppTypography.supporting)
            }
        }
    }

    @ViewBuilder private var dayEntries: some View {
        if entries.isEmpty && state.planError == nil && query.status != .all {
            VStack(spacing: AppSpacing.small) {
                AppEmptyState("No entries match", systemImage: "line.3.horizontal.decrease",
                    description: Text("Nothing on this day matches “\(query.status.rawValue)”."), fillsAvailableSpace: false)
                SecondaryAction(title: "Show all entries", compact: true) { query.status = .all }
            }.frame(maxWidth: .infinity)
        } else if entries.isEmpty && state.planError == nil {
            AppEmptyState("Nothing planned", systemImage: "calendar",
                description: Text("Choose an outfit, or leave an intentional gap. Planning never records wear."), fillsAvailableSpace: false)
                .frame(maxWidth: .infinity).padding(.vertical, AppSpacing.section)
        }
        ForEach(entries) { entry in PlanDayCard(entry: entry, outfitRevisions: outfitRevisions) }
    }

    @ViewBuilder private var plansSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.section) {
            let groups = groups
            if !groups.inRange.isEmpty { planGroup(state.plannerMode == .week ? "This week" : "This month", groups.inRange) }
            if !groups.upcoming.isEmpty { planGroup("Upcoming", groups.upcoming) }
            if filteredPlans.isEmpty && !state.planDefinitions.isEmpty && query.isFiltering {
                VStack(spacing: AppSpacing.small) {
                    AppEmptyState("No plans match", systemImage: "line.3.horizontal.decrease",
                        description: Text("The plan filter hides every plan."), fillsAvailableSpace: false)
                    SecondaryAction(title: "Clear filters", compact: true) { query = PlannerQuery(text: query.text) }
                }.frame(maxWidth: .infinity)
            }
            if !groups.past.isEmpty {
                DisclosureGroup(isExpanded: $showPast) {
                    VStack(spacing: 0) { ForEach(groups.past) { planRow($0) } }
                } label: { PlannerMetaLine(leading: "Past", trailing: "\(groups.past.count)", leadingFont: AppTypography.section) }
                    .tint(AppTheme.ink).foregroundStyle(AppTheme.ink)
            }
        }.padding(.top, AppSpacing.large)
    }

    private func planGroup(_ title: String, _ plans: [PlanDefinition]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(AppTypography.section).padding(.bottom, AppSpacing.small)
            ForEach(plans) { planRow($0) }
        }
    }

    /// Flat row: name, then kind and range, then what still needs a decision. No kind icon competes with status.
    private func planRow(_ plan: PlanDefinition) -> some View {
        let summary = summaries[plan.id]
        let kind = summary?.kind ?? .plan
        let range = LocalPlanDay.displayRange(plan.start, plan.end)
        let kindLabel = kind == .trip ? "Trip" : kind == .routine ? "Routine" : nil
        var status: [String] = []
        if let summary {
            if summary.gaps > 0 { status.append("\(summary.gaps) to choose") }
            if summary.needsReview > 0 { status.append("\(summary.needsReview) to review") }
        }
        return NavigationLink(value: kind == .trip && !(summary?.isPast ?? false) ? PlannerRoute.packing(plan.id) : PlannerRoute.plan(plan.id)) {
            HStack(spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.name.isEmpty ? "Untitled plan" : plan.name).font(AppTypography.body)
                    PlannerMetaLine(leading: range, trailing: kindLabel, leadingFont: AppTypography.metadata)
                    if !status.isEmpty {
                        Text(status.joined(separator: ", ")).font(AppTypography.metadata).foregroundStyle(AppTheme.warning)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.forward").font(AppTypography.disclosure).foregroundStyle(AppTheme.secondary)
                    .frame(width: AppControlMetrics.disclosureLane).accessibilityHidden(true)
            }.foregroundStyle(AppTheme.ink).padding(.vertical, AppSpacing.small).frame(minHeight: AppControlMetrics.rowHeight)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier("planner.plan.\(plan.name)")
            .contextMenu {
                AccessoryButton("Open plan", systemImage: "calendar") { state.plannerPath.append(.plan(plan.id)) }
                AccessoryButton("Review dates", systemImage: "list.bullet") { state.plannerPath.append(.dates(plan.id, false)) }
                if plan.trip != nil {
                    AccessoryButton("Packing list", systemImage: "suitcase") { state.plannerPath.append(.packing(plan.id)) }
                }
            }
    }
}

/// Two related facts without a separator glyph: the second sits trailing, or on its own line when space runs out.
struct PlannerMetaLine: View {
    let leading: String
    var trailing: String?
    var leadingFont: Font = AppTypography.body
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.medium) {
                Text(leading).font(leadingFont).foregroundStyle(AppTheme.ink)
                if let trailing {
                    Spacer(minLength: AppSpacing.small)
                    Text(trailing).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(leading).font(leadingFont).foregroundStyle(AppTheme.ink)
                if let trailing { Text(trailing).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.accessibilityElement(children: .ignore).accessibilityLabel([leading, trailing].compactMap { $0 }.joined(separator: ", "))
    }
}

/// Search chrome exists only while the owner explicitly opens search, as in Closet.
private struct PlannerSearchField: ViewModifier {
    @Binding var query: String
    @Binding var active: Bool

    @ViewBuilder func body(content: Content) -> some View {
        if active {
            content.searchable(text: $query, isPresented: $active, placement: .navigationBarDrawer(displayMode: .always),
                               prompt: "Search plans, trips and outfits")
        } else {
            content
        }
    }
}

/// One day entry with its single next step in view; Skip, Edit and the rest sit in one ellipsis menu.
struct PlanDayCard: View {
    @Environment(AppState.self) private var state
    let entry: OutfitPlanEntry
    let outfitRevisions: [UUID: Int]
    var showDate = false
    @State private var actions = PlanEntryActions()
    private var outfit: Outfit? { state.outfits.first { $0.id == entry.outfitID } }
    private var isOpen: Bool { entry.state == .planned || entry.state == .unassigned }
    private var next: PlannerPresentation.NextAction? { PlannerPresentation.nextAction(for: entry, outfitRevisions: outfitRevisions) }
    private var identifier: String { "planner.card.\((outfit?.displayName ?? "unassigned").replacingOccurrences(of: " ", with: "-"))" }

    var body: some View {
        VStack(spacing: 0) {
            NavigationLink(value: PlannerRoute.entry(entry.id)) {
                PlanAgendaRow(entry: entry, showDate: showDate, embedded: true)
            }.buttonStyle(.plain)
            if isOpen, let next {
                HStack(spacing: AppSpacing.small) {
                    Button { perform(next) } label: {
                        Label(next.rawValue, systemImage: nextSymbol(next)).compactControl()
                    }.buttonStyle(.plain)
                    Spacer(minLength: 0)
                    Menu {
                        AccessoryButton("Edit plan", systemImage: AppSymbols.edit) { state.openPlan(editing: entry) }
                        if next != .recordWear {
                            AccessoryButton("Record wear", systemImage: "checkmark.circle") { state.openWear(outfitID: entry.outfitID, entry: entry) }
                        }
                        AccessoryButton(actions.isSkipPending ? "Check skip result" : "Skip this date", systemImage: "forward.end") {
                            actions.skip(entry, state: state)
                        }
                    } label: {
                        Image(systemName: "ellipsis").foregroundStyle(AppTheme.ink)
                            .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget).contentShape(Rectangle())
                    }.accessibilityLabel("More plan options")
                }.padding(.horizontal, AppSpacing.medium).padding(.bottom, AppSpacing.small)
            }
            if let error = actions.error {
                SemanticFeedback(role: .danger, message: error).padding(.horizontal, 14).padding(.bottom, 14)
            }
        }
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .accessibilityIdentifier(identifier)
        .contextMenu {
            AccessoryButton("Open plan", systemImage: "calendar") { state.plannerPath.append(.entry(entry.id)) }
            if isOpen {
                AccessoryButton("Edit plan", systemImage: AppSymbols.edit) { state.openPlan(editing: entry) }
                AccessoryButton(actions.isSkipPending ? "Check skip result" : "Skip this date", systemImage: "forward.end") {
                    actions.skip(entry, state: state)
                }
            }
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

    private func nextSymbol(_ action: PlannerPresentation.NextAction) -> String {
        switch action {
        case .chooseOutfit: "tshirt"
        case .review: "doc.text.magnifyingglass"
        case .recordWear: "checkmark.circle"
        }
    }

    private func perform(_ action: PlannerPresentation.NextAction) {
        switch action {
        case .chooseOutfit, .review: state.openPlan(editing: entry)
        case .recordWear: state.openWear(outfitID: entry.outfitID, entry: entry)
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
            if let outfit { OutfitComposition(pieceIDs: outfit.pieceIDs, pieceHeight: 56, limit: 2, ground: AppTheme.imageGround, cornerRadius: AppRadius.group).frame(width: 64, height: 80).clipped() }
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
            .background { if !embedded { AppTheme.surface.clipShape(RoundedRectangle(cornerRadius: AppRadius.card)) } }
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
                                DestructiveMenuButton("Remove from Planner") {
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
