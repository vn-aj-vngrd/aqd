import AQDCore
import SwiftUI

struct OutfitPlanEditorView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: model.unknown ? "Check result" : "Save", isPending: model.pending) {
                                Task { await model.save(); if model.saved != nil { model.finish() } }
                            }.disabled(!model.unknown && (!model.canSave || (model.hasOverlap && model.draft.allowsOverlap != true)))
    }

    @Bindable var model: OutfitPlanEditorModel
    @State private var discard = false
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

    private var planHero: some View {
        Group {
            if let outfit = model.draft.outfit {
                CollectionArtwork(pieceIDs: outfit.pieceIDs, height: 200).padding(AppSpacing.medium)
                    .accessibilityLabel(outfit.displayName)
            } else {
                VStack(spacing: AppSpacing.small) {
                    Image(systemName: "calendar").font(.system(size: 32, weight: .light)).accessibilityHidden(true)
                    Text(model.draft.unassignedByChoice == true ? "Date kept unassigned" : "Choose an outfit below")
                        .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }.foregroundStyle(AppTheme.ink)
            }
        }.frame(maxWidth: .infinity).frame(height: 224)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
            .animation(.smooth(duration: 0.25), value: model.draft.outfit?.id)
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
                        planHero
                        HStack {
                            Text("Outfit").font(AppTypography.fieldLabel).foregroundStyle(AppTheme.secondary)
                            Spacer()
                            AppChip(title: "Unassigned", isSelected: model.draft.outfit == nil && model.draft.unassignedByChoice == true) {
                                model.update { $0.outfit = nil; $0.unassignedByChoice = true; $0.allowsOverlap = nil }
                            }.disabled(model.pending || model.unknown)
                        }.padding(.bottom, -AppSpacing.small)
                        OutfitSelectionStrip(outfits: model.state.outfits, selectedID: model.draft.outfit?.id, locked: model.pending || model.unknown) { outfit in
                            model.update { $0.outfit = outfit; $0.unassignedByChoice = nil; $0.allowsOverlap = nil }
                        }
                        ThemedDatePicker("Date", selection: Binding(get: { (try? model.draft.day.date()) ?? Date() }, set: { date in
                                let zone = TimeZone(identifier: model.draft.day.timeZoneID) ?? .current
                                model.update { $0.day = LocalPlanDay(date: date, timeZone: zone); $0.allowsOverlap = nil }
                            }), in: dateBounds, displayedComponents: .date)
                            .environment(\.timeZone, TimeZone(identifier: model.draft.day.timeZoneID) ?? .current).labelsHidden()
                            .padding(.horizontal, AppControlMetrics.fieldPadding)
                            .frame(minHeight: AppControlMetrics.rowHeight)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                            .disabled(model.pending || model.unknown)
                        if let plan = namedPlan {
                            Text("Part of \(plan.name). Edit the whole plan to change its date range or timezone.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }
                        DisclosureRow(title: "Weather context", value: model.draft.weather?.place.name ?? "Off") { weather = true }.disabled(model.pending || model.unknown)
                        LabeledField(title: "Occasion", text: Binding(get: { model.draft.occasion }, set: { value in
                            model.update { $0.occasion = value; $0.allowsOverlap = nil }
                        })).disabled(model.pending || model.unknown)
                        DisclosureRow(title: "Timezone", value: model.draft.day.timeZoneID) { choosingZone = true }
                            .disabled(model.pending || model.unknown || namedPlan != nil)
                        if let context = model.draft.weather {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(context.day.displayDate)
                                Text(context.place.timeZoneID)
                            }.font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }
                        if model.hasOverlap {
                            Text("Another plan uses this date and occasion. Existing assignments stay unchanged.")
                                .foregroundStyle(AppTheme.secondary)
                            Toggle("Keep both plans", isOn: Binding(get: { model.draft.allowsOverlap == true }, set: { value in
                                model.update { $0.allowsOverlap = value }
                            })).disabled(model.pending || model.unknown)
                        }
                        if let conflict = model.availabilityConflict { SemanticFeedback(role: .warning, message: conflict) }
                    }
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                }.padding(20)
            }.background(AppTheme.canvas).onAppear { model.state.reloadOutfits(); model.state.reloadPieces() }
                .navigationTitle(model.saved == nil ? model.draft.baseEntry == nil ? "Plan a look" : "Edit plan entry" : "Plan saved").navigationBarTitleDisplayMode(.inline)
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

/// An explicit draft choice. The editor's Save action commits the plan.
struct PlanUnassignedAction: View {
    var title = "Leave unassigned"
    var isSelected = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.medium) {
                Text(title).font(AppTypography.body)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: AppSpacing.small)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(AppTheme.controlIcon).accessibilityHidden(true)
            }
            .foregroundStyle(AppTheme.ink)
            .padding(AppSpacing.large)
            .frame(maxWidth: .infinity, minHeight: AppControlMetrics.rowHeight)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.card))
        }.buttonStyle(.plain)
            .accessibilityValue(isSelected ? "Selected" : "Not selected")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
