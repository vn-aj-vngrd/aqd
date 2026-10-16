import AQDCore
import SwiftUI

struct TodayEditorView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: model.unknown ? "Check result" : "Save", isPending: model.pending) {
                        if model.saved != nil { model.finish() } else { Task { await model.save() } }
                    }.disabled(model.importing || pendingKind != nil || (model.saved == nil && !model.unknown && (try? model.draft.result()) == nil))
    }

    @Bindable var model: TodayEditorModel
    @State private var discard = false
    @State private var library = false
    @State private var pendingKind: TodayWidgetKind?
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    var body: some View {
        NavigationStack {
            List {
                if !model.availableKinds.isEmpty {
                    Section {
                        HStack {
                            addButton.disabled(model.locked || pendingKind != nil).accessibilityLabel("Add widget")
                            Spacer(minLength: 0)
                        }.listRowInsets(EdgeInsets()).listRowBackground(Color.clear).listRowSeparator(.hidden)
                            .moveDisabled(true).deleteDisabled(true)
                    }
                }
                Section {
                    ForEach(Array(model.draft.value.instances.enumerated()), id: \.element.id) { index, instance in
                        HStack(spacing: 12) {
                            Button { model.begin(instance) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: instance.kind.symbol).font(.system(size: 20)).foregroundStyle(AppTheme.ink).frame(width: 24).accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 4) {
                                    Text(instance.kind.title).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                                    }
                                }.frame(maxWidth: .infinity, alignment: .leading).frame(minHeight: 52)
                                    .contentShape(Rectangle())
                            }.buttonStyle(.borderless).disabled(model.locked)
                                .accessibilityHint("Configure widget")
                            widgetOptions(instance, index: index)
                        }.listRowBackground(AppTheme.surface).moveDisabled(model.locked)
                            .accessibilityValue("Position \(index + 1) of \(model.draft.value.instances.count)")
                    }.onMove { offsets, destination in
                        model.update { $0.value.instances.move(fromOffsets: offsets, toOffset: destination) }
                    }
                }
                if let error = model.error {
                    Section { SemanticFeedback(role: .danger, message: error) }.listRowBackground(AppTheme.surface)
                }
            }.listStyle(.insetGrouped).listSectionSpacing(12).scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
                .background(AppTheme.canvas).navigationTitle("Customize Today").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if model.saved == nil { confirmation }
            } }
                .toolbar { ToolbarItem(placement: model.saved == nil ? .topBarLeading : .topBarTrailing) {
                    Button {
                        if model.saved != nil { model.finish() }
                        else if !model.draft.hasChanges { model.finish(discarding: true) } else { discard = true }
                    } label: { if model.saved == nil { Image(systemName: "xmark") } else { Text("Done") } }.accessibilityLabel(model.saved == nil ? "Cancel Today changes" : "Done").disabled(model.pending || model.unknown || pendingKind != nil)
                } }
                .navigationDestination(isPresented: $library) {
                    List(model.availableKinds, id: \.self) { kind in
                        Button {
                            guard pendingKind == nil else { return }
                            pendingKind = kind; library = false
                        } label: {
                            HStack(spacing: 12) {
                                Label(kind.title, systemImage: kind.symbol).foregroundStyle(AppTheme.ink)
                                Spacer()
                                Image(systemName: "chevron.forward").font(AppTypography.disclosure).accessibilityHidden(true)
                            }.frame(maxWidth: .infinity, minHeight: 52, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.plain).listRowBackground(AppTheme.surface).disabled(model.locked || pendingKind != nil)
                    }.scrollContentBackground(.hidden).background(AppTheme.canvas)
                        .navigationTitle("Add widget").tint(AppTheme.ink)
                        .onDisappear {
                            guard let kind = pendingKind else { return }
                            pendingKind = nil
                            guard model.state.todayEditor?.id == model.id, !model.locked else { return }
                            model.beginNew(kind)
                        }
                }
                .onAppear {
                    model.state.reloadPlanEntries(); model.state.reloadPieces(); model.state.reloadOutfits(); model.state.reloadThemes(); model.state.reloadFits()
                }
                .sheet(isPresented: Binding(get: { model.draft.nested != nil }, set: { _ in })) { TodayWidgetConfigurationView(model: model) }
        }.tint(AppTheme.ink).interactiveDismissDisabled()
            .draftDiscardConfirmation(isPresented: $discard, title: "Discard Today changes?", message: "Your saved layout, notes and photos stay unchanged.") { model.finish(discarding: true); if model.state.todayEditor == nil { discard = false } }
    }
    @ViewBuilder private var addButton: some View {
        if #available(iOS 26.0, *), !reduceTransparency, contrast != .increased {
            addAction.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            addAction.background(AppTheme.surface, in: Capsule())
                .overlay(Capsule().stroke(AppTheme.controlBoundary, lineWidth: 1))
        }
    }
    private var addAction: some View {
        Button { library = true } label: {
            Label("Add", systemImage: "plus").font(AppTypography.body).foregroundStyle(AppTheme.ink).padding(.horizontal, 16).frame(minHeight: 44).contentShape(Capsule())
        }.buttonStyle(.plain)
    }

    private func widgetOptions(_ instance: TodayWidgetInstance, index: Int) -> some View {
        Menu {
            Button("Configure", systemImage: "slider.horizontal.3") { model.begin(instance) }
            Button("Move up", systemImage: "arrow.up") { model.move(instance.id, by: -1) }.disabled(index == 0)
            Button("Move down", systemImage: "arrow.down") { model.move(instance.id, by: 1) }.disabled(index == model.draft.value.instances.count - 1)
            Button("Remove", systemImage: "minus.circle") { model.update { try $0.remove(instance.id) } }
        } label: {
            Label("Options for \(instance.kind.title), position \(index + 1) of \(model.draft.value.instances.count)", systemImage: "ellipsis")
                .labelStyle(.iconOnly).frame(width: 44, height: 44).contentShape(Rectangle())
        }.disabled(model.locked)
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
