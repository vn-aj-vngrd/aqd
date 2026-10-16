import AQDCore
import SwiftUI

struct OutfitPlanEditorView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: model.unknown ? "Check result" : "Save", isPending: model.pending) {
                                Task { await model.save() }
                            }.disabled(!model.unknown && (!model.canSave || (model.hasOverlap && model.draft.allowsOverlap != true)))
    }

    @Bindable var model: OutfitPlanEditorModel
    @State private var discard = false
    @State private var choosing = false
    @State private var choosingZone = false
    @State private var weather = false

    private var namedPlan: PlanDefinition? { model.state.planDefinitions.first { $0.id == model.draft.planID } }
    private var dateBounds: ClosedRange<Date> {
        guard let plan = namedPlan else { return Date.distantPast...Date.distantFuture }
        let zone = TimeZone(identifier: model.draft.day.timeZoneID) ?? .current
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
        var start = plan.start, end = plan.end
        start.timeZoneID = zone.identifier; end.timeZoneID = zone.identifier
        guard let first = try? start.date(), let last = try? end.date(),
              let upper = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: last)) else { return Date.distantPast...Date.distantFuture }
        return calendar.startOfDay(for: first)...upper.addingTimeInterval(-1)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let saved = model.saved {
                        Text("Plan saved").font(AppTypography.section)
                        Text(saved.day.displayDate).font(AppTypography.body)
                        Text(saved.state == .unassigned ? "Outfit unassigned" : model.draft.outfit?.displayName ?? "Planned outfit")
                        Text("Planning never records wear.").foregroundStyle(AppTheme.secondary)
                        PrimaryAction(title: "Open Planner") { model.finish(openPlanner: true) }
                    } else {
                        LabeledControl(title: "Date") {
                            DatePicker("Date", selection: Binding(get: { (try? model.draft.day.date()) ?? Date() }, set: { date in
                                let zone = TimeZone(identifier: model.draft.day.timeZoneID) ?? .current
                                model.update { $0.day = LocalPlanDay(date: date, timeZone: zone); $0.allowsOverlap = nil }
                            }), in: dateBounds, displayedComponents: .date)
                            .environment(\.timeZone, TimeZone(identifier: model.draft.day.timeZoneID) ?? .current).labelsHidden()
                        }.disabled(model.pending || model.unknown)
                        if let plan = namedPlan {
                            Text("Part of \(plan.name). Edit the whole plan to change its date range or timezone.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }
                        DisclosureRow(title: "Weather context", value: model.draft.weather?.place.name ?? "Off") { weather = true }.disabled(model.pending || model.unknown)
                        LabeledField(title: "Occasion", text: Binding(get: { model.draft.occasion }, set: { value in
                            model.update { $0.occasion = value; $0.allowsOverlap = nil }
                        })).disabled(model.pending || model.unknown)
                        DisclosureRow(title: "Outfit", value: model.draft.outfit?.displayName ?? "Choose outfit") { choosing = true }
                            .disabled(model.pending || model.unknown)
                        DisclosureRow(title: "Timezone", value: model.draft.day.timeZoneID) { choosingZone = true }
                            .disabled(model.pending || model.unknown || namedPlan != nil)
                        if let context = model.draft.weather {
                            Text("\(context.day.displayDate) · \(context.place.timeZoneID)").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }
                        if model.hasOverlap {
                            Text("Another plan uses this date and occasion. Existing assignments stay unchanged.")
                                .foregroundStyle(AppTheme.secondary)
                            Toggle("Keep both plans", isOn: Binding(get: { model.draft.allowsOverlap == true }, set: { value in
                                model.update { $0.allowsOverlap = value }
                            })).disabled(model.pending || model.unknown)
                        }
                        if let conflict = model.availabilityConflict { SemanticFeedback(role: .warning, message: conflict) }
                        ActionStack {


                        }
                    }
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                }.padding(20)
            }.background(AppTheme.canvas)
                .navigationTitle(model.saved == nil ? model.draft.baseEntry == nil ? "Plan a look" : "Edit plan entry" : "Plan saved").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                if model.saved == nil {
                    Menu { Button("Leave unassigned") { Task { await model.save(leaveUnassigned: true) } }
                                .disabled(model.pending || model.unknown || (model.hasOverlap && model.draft.allowsOverlap != true)) } label: { Label("More plan options", systemImage: "ellipsis") }
                }
            } }
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if model.saved == nil { confirmation }
            } }
            .tint(AppTheme.ink)
                .toolbar {
                    ToolbarItem(placement: model.saved == nil ? .topBarLeading : .topBarTrailing) {
                        Button {
                            if model.saved != nil { model.finish() }
                            else if model.hasUnsavedChanges { discard = true }
                            else { model.finish(discarding: true) }
                        } label: { if model.saved == nil { Image(systemName: "xmark") } else { Text("Done") } }
                            .tint(AppTheme.ink).accessibilityLabel(model.saved == nil ? "Cancel plan" : "Done")
                            .disabled(model.pending || model.unknown)
                    }
                }
                .sheet(isPresented: $weather) {
                if let client = model.state.weatherClient {
                    WeatherContextView(client: client, initial: model.draft.weather, day: model.draft.day) { selection in model.update { $0.weather = selection }; return model.draft.weather == selection && model.error == nil }
                }
            }
            .navigationDestination(isPresented: $choosing) { PlanOutfitChooser(model: model) }
                .navigationDestination(isPresented: $choosingZone) {
                    TimezoneChooser(current: model.draft.day.timeZoneID) { zone in
                        model.update { $0.day.timeZoneID = zone; $0.allowsOverlap = nil }
                        return model.error == nil
                    }
                }
        }.interactiveDismissDisabled()
            .draftDiscardConfirmation(isPresented: $discard, title: "Discard plan draft?", message: "Your saved plans, outfits and wear history stay unchanged.") {
                    model.finish(discarding: true)
                    if model.state.planEditor == nil { discard = false }
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
                    AppEmptyState("No saved outfits", systemImage: "square.stack",
                                           description: Text("Keep this date unassigned, or save an outfit in Closet first."))
                }
                ForEach(model.state.outfits.filter { query.isEmpty || $0.displayName.localizedCaseInsensitiveContains(query) }) { outfit in
                    Button {
                        model.update { $0.outfit = outfit; $0.unassignedByChoice = nil; $0.allowsOverlap = nil }
                        if model.error == nil { dismiss() }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            OutfitComposition(pieceIDs: outfit.pieceIDs)
                            Text(outfit.displayName).foregroundStyle(AppTheme.ink)
                        }
                    }.buttonStyle(.plain)
                }
                if let error = model.error { SemanticFeedback(role: .danger, message: error) }
            }.padding(20)
        }.background(AppTheme.canvas)
            .navigationTitle("Choose one outfit").navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.ink)
            .searchable(text: $query, prompt: "Search outfits")
            .onAppear { model.state.reloadOutfits(); model.state.reloadPieces() }
    }
}
