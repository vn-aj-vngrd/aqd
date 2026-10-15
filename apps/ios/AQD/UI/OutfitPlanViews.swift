import AQDCore
import SwiftUI

struct OutfitPlanEditorView: View {
    @Bindable var model: OutfitPlanEditorModel
    @State private var discard = false
    @State private var choosing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let saved = model.saved {
                        Text("Plan saved").font(AppTypography.section)
                        Text(saved.day.key).font(AppTypography.body)
                        Text(saved.state == .unassigned ? "Outfit unassigned" : model.draft.outfit?.name ?? "Planned outfit")
                        Text("Planning never records wear.").foregroundStyle(AppTheme.secondary)
                        PrimaryAction(title: "Open Planner") { model.finish(openPlanner: true) }
                    } else {
                        LabeledControl(title: "Date") {
                            DatePicker("Date", selection: Binding(get: { (try? model.draft.day.date()) ?? Date() }, set: { date in
                                let zone = TimeZone(identifier: model.draft.day.timeZoneID) ?? .current
                                model.update { $0.day = LocalPlanDay(date: date, timeZone: zone); $0.allowsOverlap = nil }
                            }), displayedComponents: .date)
                            .environment(\.timeZone, TimeZone(identifier: model.draft.day.timeZoneID) ?? .current)
                        }.disabled(model.pending || model.unknown)
                        LabeledField(title: "Occasion", text: Binding(get: { model.draft.occasion }, set: { value in
                            model.update { $0.occasion = value; $0.allowsOverlap = nil }
                        })).disabled(model.pending || model.unknown)
                        DisclosureRow(title: "Outfit", value: model.draft.outfit?.name ?? "Choose outfit") { choosing = true }
                            .disabled(model.pending || model.unknown)
                        LabeledControl(title: "Timezone") {
                            Picker("Timezone", selection: Binding(get: { model.draft.day.timeZoneID }, set: { zone in
                                model.update { $0.day.timeZoneID = zone; $0.allowsOverlap = nil }
                            })) {
                                ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { Text($0).tag($0) }
                            }.pickerStyle(.menu)
                        }.disabled(model.pending || model.unknown)
                        Text("Weather context · Off").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        if model.hasOverlap {
                            Text("Another plan uses this date and occasion. Existing assignments stay unchanged.")
                                .foregroundStyle(AppTheme.secondary)
                            Toggle("Keep both plans", isOn: Binding(get: { model.draft.allowsOverlap == true }, set: { value in
                                model.update { $0.allowsOverlap = value }
                            })).disabled(model.pending || model.unknown)
                        }
                        ActionStack {
                            PrimaryAction(title: model.unknown ? "Check save result" : "Save plan", isPending: model.pending) {
                                Task { await model.save() }
                            }.disabled(!model.unknown && (!model.canSave || (model.hasOverlap && model.draft.allowsOverlap != true)))
                            SecondaryAction(title: "Leave unassigned") { Task { await model.save(leaveUnassigned: true) } }
                                .disabled(model.pending || model.unknown || (model.hasOverlap && model.draft.allowsOverlap != true))
                        }
                    }
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                }.padding(20)
            }.background(AppTheme.canvas)
                .navigationTitle(model.saved == nil ? "Plan a look" : "Plan saved").navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.ink)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if model.saved != nil { model.finish() } else { discard = true }
                        } label: { Image(systemName: model.saved == nil ? "xmark" : "checkmark") }
                            .tint(AppTheme.ink).accessibilityLabel(model.saved == nil ? "Cancel plan" : "Done")
                            .disabled(model.pending || model.unknown)
                    }
                }
                .navigationDestination(isPresented: $choosing) { PlanOutfitChooser(model: model) }
        }.interactiveDismissDisabled()
            .sheet(isPresented: $discard) {
                DraftDiscardSheet(title: "Discard plan draft?", message: "Your saved plans, outfits and wear history stay unchanged.") {
                    model.finish(discarding: true)
                    if model.state.planEditor == nil { discard = false }
                }
            }
    }
}

private struct PlanOutfitChooser: View {
    @Bindable var model: OutfitPlanEditorModel
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let error = model.state.outfitError {
                    SemanticFeedback(role: .danger, message: error)
                    Button("Retry outfits") { model.state.reloadOutfits() }
                } else if model.state.outfits.isEmpty {
                    ContentUnavailableView("No saved outfits", systemImage: "square.stack",
                                           description: Text("Keep this date unassigned, or save an outfit in Closet first."))
                }
                ForEach(model.state.outfits.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }) { outfit in
                    Button {
                        model.update { $0.outfit = outfit; $0.unassignedByChoice = nil; $0.allowsOverlap = nil }
                        if model.error == nil { dismiss() }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            OutfitComposition(pieceIDs: outfit.pieceIDs)
                            Text(outfit.name).foregroundStyle(AppTheme.ink)
                        }
                    }.buttonStyle(.plain)
                }
                if let error = model.error { SemanticFeedback(role: .danger, message: error) }
            }.padding(20)
        }.background(AppTheme.canvas)
            .navigationTitle("Choose one outfit").navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.ink)
            .searchable(text: $query, prompt: "Search outfits")
            .onAppear { model.state.reloadOutfits() }
    }
}

struct LocalPlannerView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let error = state.planError {
                        SemanticFeedback(role: .danger, message: error)
                        Button("Retry plans") { state.reloadPlanEntries() }
                    } else if state.planEntries.isEmpty {
                        ContentUnavailableView("Make room for a look", systemImage: "calendar",
                                               description: Text("Plan an outfit for a day. Plans and actual wear stay separate."))
                        PrimaryAction(title: "Plan an outfit") { state.openPlan() }
                    }
                    ForEach(state.planEntries) { entry in
                        NavigationLink { LocalPlanEntryView(id: entry.id) } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(entry.day.key).font(AppTypography.fieldLabel)
                                Text(entry.outfitID.flatMap { id in state.outfits.first { $0.id == id }?.name } ?? "Outfit unassigned")
                                    .font(AppTypography.body)
                                Text([entry.occasion, entry.state.rawValue.capitalized].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(14)
                                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                        }.buttonStyle(.plain).foregroundStyle(AppTheme.ink)
                    }
                }.padding(20)
            }.background(AppTheme.canvas)
                .navigationTitle("Planner")
                .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
                .toolbar { ToolbarItem(placement: .topBarTrailing) {
                    Button { state.openPlan() } label: { Label("Add plan", systemImage: "plus") }.tint(AppTheme.ink)
                } }
                .onAppear { state.reloadPlanEntries(); state.reloadOutfits() }
        }
    }
}

private struct LocalPlanEntryView: View {
    @Environment(AppState.self) private var state
    let id: UUID
    var body: some View {
        ScrollView {
            if let entry = state.planEntries.first(where: { $0.id == id }) {
                VStack(alignment: .leading, spacing: 20) {
                    Text(entry.day.key).font(AppTypography.section)
                    Text(entry.day.timeZoneID).foregroundStyle(AppTheme.secondary)
                    if !entry.occasion.isEmpty { Text(entry.occasion) }
                    if let outfit = state.outfits.first(where: { $0.id == entry.outfitID }) {
                        OutfitComposition(pieceIDs: outfit.pieceIDs)
                        NavigationLink(value: ClosetRoute.outfit(outfit.id)) { Text("Open outfit") }.frame(minHeight: 44)
                        if entry.requiresReview || outfit.revision != entry.outfitRevision {
                            SemanticFeedback(role: .warning, message: "This outfit changed after planning. Review its current pieces before wearing it.")
                        }
                    } else { Text("Outfit unassigned").foregroundStyle(AppTheme.secondary) }
                    Text("Planning this date hasn’t recorded wear.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }.padding(20)
            } else { ContentUnavailableView("Plan unavailable", systemImage: "calendar") }
        }.background(AppTheme.canvas).navigationTitle("Plan entry").navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.ink)
    }
}
