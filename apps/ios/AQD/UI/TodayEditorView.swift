import AQDCore
import SwiftUI

struct TodayEditorView: View {
    @Bindable var model: TodayEditorModel
    @State private var discard = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(model.catalog.enumerated()), id: \.element.id) { index, instance in
                        HStack(spacing: 12) {
                            Button { model.begin(instance) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: instance.kind.symbol).foregroundStyle(AppTheme.controlIcon).font(.system(size: 20)).frame(width: 24).accessibilityHidden(true)
                                    Text(instance.kind.title).font(AppTypography.body).frame(maxWidth: .infinity, alignment: .leading)
                                }.foregroundStyle(AppTheme.ink).frame(minHeight: AppControlMetrics.minimumTarget).contentShape(Rectangle())
                            }.buttonStyle(.borderless).disabled(model.locked).accessibilityHint("Configure widget")
                            Button { model.setVisibility(instance.id, visible: !instance.isVisible) } label: {
                                Image(systemName: instance.isVisible ? "eye" : "eye.slash")
                                    .font(.system(size: 18)).foregroundStyle(AppTheme.controlIcon)
                                    .frame(width: 44, height: 44).contentShape(Rectangle())
                            }.buttonStyle(.borderless).disabled(model.locked)
                                .accessibilityLabel("\(instance.isVisible ? "Hide" : "Show") \(instance.kind.title) on Home")
                                .accessibilityValue(instance.isVisible ? "Visible" : "Hidden")
                        }
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: AppRadius.field)
                                    .fill(AppTheme.surface)
                                    .padding(.vertical, AppSpacing.xSmall)
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: AppSpacing.small, leading: AppSpacing.medium,
                                                     bottom: AppSpacing.small, trailing: AppSpacing.medium))
                            .accessibilityValue("Position \(index + 1) of \(model.catalog.count)")
                            .moveDisabled(model.locked)
                            .accessibilityAction(named: "Move up") { model.moveInCatalog(instance.id, to: index - 1) }
                            .accessibilityAction(named: "Move down") { model.moveInCatalog(instance.id, to: index + 1) }
                    }.onMove { offsets, destination in
                        model.moveInCatalog(from: offsets, to: destination)
                    }
                }
                if let error = model.error { Section { SemanticFeedback(role: .danger, message: error) }.listRowBackground(AppTheme.surface) }
            }.environment(\.editMode, .constant(.active)).listStyle(.insetGrouped).contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden)
                .background(AppTheme.canvas)
                .animation(reduceMotion ? nil : AQDMotion.reflow, value: model.catalog.map(\.id))
                .navigationTitle("Customize Today").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if model.saved != nil { model.finish() }
                            else if !model.draft.hasChanges { model.finish(discarding: true) }
                            else { discard = true }
                        } label: { Image(systemName: "xmark") }.accessibilityLabel("Close Customize Today").disabled(model.pending || model.unknown)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        ToolbarSaveAction(title: model.unknown ? "Check result" : "Save", isPending: model.pending) {
                            if model.saved != nil { model.finish() } else { Task { await model.save() } }
                        }.disabled(model.importing || (model.saved == nil && !model.unknown && (!model.draft.hasChanges || (try? model.draft.result()) == nil)))
                    }
                }
                .onAppear { model.state.reloadPlanEntries(); model.state.reloadPieces(); model.state.reloadOutfits(); model.state.reloadThemes(); model.state.reloadFits() }
                .sheet(isPresented: Binding(get: { model.draft.nested != nil }, set: { _ in })) { TodayWidgetConfigurationView(model: model) }
        }.tint(AppTheme.ink).interactiveDismissDisabled()
            .draftDiscardConfirmation(isPresented: $discard, title: "Discard Today changes?", message: "Your saved layout, notes and photos stay unchanged.") {
                model.finish(discarding: true); if model.state.todayEditor == nil { discard = false }
            }
    }
}

extension TodayWidgetKind {
    var symbol: String {
        switch self {
        case .todayLook: "tshirt"
        case .weekInWear: "calendar"
        case .closetInUse: "chart.bar"
        case .upcomingPlans: "calendar.badge.clock"
        case .wearAgain: "arrow.clockwise"
        case .favoriteOutfits: "star"
        case .theme: "folder"
        case .fitJournal: "photo.on.rectangle"
        case .weatherContext: "cloud.sun"
        case .quickActions: "bolt"
        case .personalNote: "note.text"
        case .personalPhoto: "photo"
        }
    }
}
