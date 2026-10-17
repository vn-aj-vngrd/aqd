import AQDCore
import SwiftUI

struct TripFields: View {
    @Bindable var model: PlanAuthoringModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LabeledField(title: "Destination (optional)", text: Binding(get: { model.draft.plan.trip?.destination ?? "" }, set: { value in
                model.update { $0.plan.trip?.destination = value }
            }))
            LabeledField(title: "Activities (comma-separated)", text: Binding(get: { model.draft.tripActivitiesText ?? model.draft.plan.trip?.activities.joined(separator: ", ") ?? "" }, set: { value in
                model.update { draft in
                    draft.tripActivitiesText = value
                    draft.plan.trip?.activities = value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                }
            }), multiline: true)
            Text("Destination and activities stay on this device. Choose the destination’s timezone; typing a place does not request weather or location.")
                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
        }
    }
}

struct TripDetailContent: View {
    @Environment(AppState.self) private var state
    let plan: PlanDefinition
    @State private var summary: TripPackingSummary?
    @State private var error: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let destination = plan.trip?.destination, !destination.isEmpty { Text(destination).font(AppTypography.section) }
            if let activities = plan.trip?.activities, !activities.isEmpty { Text(activities.joined(separator: ", ")).font(AppTypography.body) }
            VStack(spacing: 0) {
                DisclosureRow(title: "Outfit plan", value: summary.map { "\(state.planEntries.filter { $0.planID == plan.id }.count) entries, \($0.gaps.count) gaps" } ?? "Review saved dates", placement: .grouped) {
                    state.plannerPath.append(.dates(plan.id, false))
                }
                DisclosureRow(title: "Packing list", value: summary.map { "\($0.items.count) unique pieces" } ?? "Open packing", placement: .grouped) {
                    state.plannerPath.append(.packing(plan.id))
                }
            }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            PlannerMetaLine(leading: "Weather context", trailing: "Off", leadingFont: AppTypography.supporting)
            if let error { SemanticFeedback(role: .danger, message: error); Button("Retry packing summary", action: refresh).frame(minHeight: 44) }
        }.onAppear(perform: refresh).onChange(of: state.planEntries) { refresh() }
    }
    private func refresh() {
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            summary = try store.packingSummary(planID: plan.id); error = nil
        } catch { self.error = "The packing summary couldn’t be read. Open the saved dates or retry." }
    }
}

struct PlanDatesView: View {
    @Environment(AppState.self) private var state
    let id: UUID
    var gapsOnly = false
    @State private var summary: TripPackingSummary?
    @State private var error: String?
    private var entries: [OutfitPlanEntry] { state.planEntries.filter { $0.planID == id } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if gapsOnly {
                    if let summary {
                        if summary.gaps.isEmpty { AppEmptyState("Every date has an outfit", systemImage: "checkmark.circle", fillsAvailableSpace: false) }
                        ForEach(summary.gaps) { gap in
                            if let entryID = gap.entryID {
                                NavigationLink(value: PlannerRoute.entry(entryID)) { gapLabel(gap) }.buttonStyle(.plain)
                            } else {
                                Button { state.openPlan(day: gap.day, parentPlanID: id) } label: { gapLabel(gap) }.buttonStyle(.plain)
                            }
                        }
                    }
                } else {
                    ForEach(entries) { entry in
                        NavigationLink(value: PlannerRoute.entry(entry.id)) { PlanAgendaRow(entry: entry, showDate: true) }.buttonStyle(.plain)
                    }
                    if entries.isEmpty { AppEmptyState("No saved entries", systemImage: "calendar", fillsAvailableSpace: false) }
                    if let summary, !summary.gaps.isEmpty {
                        SecondaryAction(title: "Review unassigned dates") { state.plannerPath.append(.dates(id, true)) }
                    }
                }
                if let error { SemanticFeedback(role: .danger, message: error); Button("Retry dates", action: refresh).frame(minHeight: 44) }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle(gapsOnly ? "Review unassigned dates" : "Outfit plan").navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.ink).onAppear(perform: refresh).onChange(of: state.planEntries) { refreshSummary() }
    }
    private func gapLabel(_ gap: PackingGap) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) { Text(gap.day.displayDate).font(AppTypography.body); Text(gap.reason).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
            Spacer(); Image(systemName: "chevron.forward").font(AppTypography.disclosure).accessibilityHidden(true)
        }.foregroundStyle(AppTheme.ink).padding(14).frame(minHeight: 54).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }
    private func refresh() { state.reloadPlanEntries(); state.reloadOutfits(); refreshSummary() }
    private func refreshSummary() {
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            summary = try store.packingSummary(planID: id); error = nil
        } catch { self.error = "These trip dates couldn’t be read. Their saved data is retained; retry." }
    }
}

struct TripPackingView: View {
    @Environment(AppState.self) private var state
    let id: UUID
    @State private var summary: TripPackingSummary?
    @State private var packingState: PackingState?
    @State private var pending: PackingCheckRequest?
    @State private var error: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let plan = state.planDefinitions.first(where: { $0.id == id }) {
                    Text(plan.name).font(AppTypography.section)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(plan.start.displayDate) – \(plan.end.displayDate)")
                        Text(plan.start.timeZoneID)
                    }.font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }
                if let summary {
                    Text("\(summary.items.count) unique pieces from your assigned outfits. \(summary.gaps.count) dates or assignments need review.")
                        .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    if summary.items.isEmpty { AppEmptyState("No pieces to pack yet", systemImage: "suitcase", description: Text("Assign saved outfits to the trip’s dates to build this list."), fillsAvailableSpace: false) }
                    ForEach(summary.items) { item in
                        Button { check(item) } label: {
                            HStack(spacing: 12) {
                                PieceThumbnail(photoID: item.piece.photoID, recipe: item.piece.photoRecipe).frame(width: 48, height: 56)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.piece.displayName).font(AppTypography.body)
                                    Text("Used in \(item.uses) planned looks").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                                    if item.piece.isArchived || item.piece.availability != .available { Text("Needs attention").font(AppTypography.metadata).foregroundStyle(AppTheme.warning) }
                                }.frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: item.checked ? "checkmark.square.fill" : "square").foregroundStyle(item.checked ? AppTheme.ink : AppTheme.controlBoundary)
                                    .frame(width: 44, height: 44)
                            }.foregroundStyle(AppTheme.ink).padding(.horizontal, 14).padding(.vertical, 12).frame(minHeight: 80)
                                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                        }.buttonStyle(.plain).disabled(pending != nil).accessibilityValue(item.checked ? "Packed" : "Not packed")
                    }
                    if !summary.gaps.isEmpty {
                        DisclosureRow(title: "Review unassigned dates", value: "\(summary.gaps.count)") { state.plannerPath.append(.dates(id, true)) }
                    }
                } else if error == nil { ProgressView("Reading packing list…") }
                if let error {
                    SemanticFeedback(role: .danger, message: error)
                    if let pending { PrimaryAction(title: "Check previous packing change") { apply(pending) } }
                    else { Button("Retry packing list", action: refresh).frame(minHeight: 44) }
                }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Packing list").navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink)
            .onAppear(perform: refresh).onChange(of: state.planEntries) { refresh() }.onChange(of: state.collectionRefreshID) { refresh() }
    }
    private func check(_ item: PackingItem) {
        guard let packingState else { return }
        let request = PackingCheckRequest(planID: id, pieceID: item.id, checked: !item.checked, expectedRevision: packingState.revision)
        pending = request; apply(request)
    }
    private func apply(_ request: PackingCheckRequest) {
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            _ = try store.setPackingCheck(request)
            pending = nil; refresh()
        } catch PieceStore.StoreError.staleRevision {
            pending = nil; refresh(); self.error = "Packing or assignments changed. Review the latest list before checking again."
        } catch { self.error = "The packing change isn’t acknowledged. Check this same operation before changing another item." }
    }
    private func refresh() {
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            let current = try store.packingState(planID: id)
            let result = try store.packingSummary(planID: id)
            packingState = current; summary = result
            if pending == nil { error = nil }
        } catch { self.error = "The packing list couldn’t be read. Its saved data is retained; retry." }
    }
}
