import AQDCore
import SwiftUI

struct TodayEditorView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: model.unknown ? "Check result" : "Save", isPending: model.pending) {
                        if model.saved != nil { model.finish() } else { Task { await model.save() } }
                    }.disabled(model.importing || (model.saved == nil && !model.unknown && (try? model.draft.result()) == nil))
    }

    @Bindable var model: TodayEditorModel
    @State private var discard = false
    @State private var library = false
    @State private var restore = false
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(model.draft.value.instances.enumerated()), id: \.element.id) { index, instance in
                        HStack(spacing: 12) {
                            Button { model.begin(instance) } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(instance.kind.title).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                                    Text(summary(instance)).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
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
                } header: {
                    HStack(spacing: 8) {
                        Text("\(model.draft.value.instances.count) widgets").font(AppTypography.fieldLabel)
                        Spacer(minLength: 0)
                        Menu {
                            Button("Restore defaults", systemImage: "arrow.counterclockwise") { restore = true }
                            if model.draft.defaultsUndo != nil {
                                Button("Undo restore defaults", systemImage: "arrow.uturn.backward") { model.update { $0.undoDefaults() } }
                            }
                        } label: { Label("Layout options", systemImage: "ellipsis").labelStyle(.iconOnly).frame(width: 44, height: 44) }
                            .disabled(model.locked)
                        Button { library = true } label: {
                            Text("Add").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                        }
                            .disabled(model.locked).accessibilityLabel("Add widget")
                    }.textCase(nil).tint(AppTheme.actionText)
                } footer: {
                    Text("Drag to reorder. Tap a widget to edit. Removing widgets keeps saved notes and photos.")
                }
                if let error = model.error {
                    Section { SemanticFeedback(role: .danger, message: error) }.listRowBackground(AppTheme.surface)
                }
            }.listStyle(.insetGrouped).scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
                .background(AppTheme.canvas).navigationTitle("Customize Today").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if model.saved == nil { confirmation }
            } }
                .toolbar { ToolbarItem(placement: model.saved == nil ? .topBarLeading : .topBarTrailing) {
                    Button {
                        if model.saved != nil { model.finish() }
                        else if !model.draft.hasChanges { model.finish(discarding: true) } else { discard = true }
                    } label: { if model.saved == nil { Image(systemName: "xmark") } else { Text("Done") } }.accessibilityLabel(model.saved == nil ? "Cancel Today changes" : "Done").disabled(model.pending || model.unknown)
                } }
                .navigationDestination(isPresented: $library) {
                    List(TodayWidgetKind.allCases, id: \.self) { kind in
                        Button(kind.title) { model.begin(TodayWidgetInstance(kind: kind)); library = false }.frame(minHeight: 44)
                    }.scrollContentBackground(.hidden).background(AppTheme.canvas)
                        .navigationTitle("Add widget").tint(AppTheme.ink)
                }
                .sheet(isPresented: Binding(get: { model.draft.nested != nil }, set: { _ in })) { TodayWidgetConfigurationView(model: model) }
        }.tint(AppTheme.ink).interactiveDismissDisabled()
            .draftDiscardConfirmation(isPresented: $discard, title: "Discard Today changes?", message: "Your saved layout, notes and photos stay unchanged.") { model.finish(discarding: true); if model.state.todayEditor == nil { discard = false } }
            .alert("Restore the three default widgets?", isPresented: $restore) {
                Button("Cancel", role: .cancel) { }
                Button("Restore defaults") { model.update { $0.restoreDefaults() } }
            } message: { Text("Today’s look, Your week in wear and Closet in use will replace the draft placements. Saved notes and photos remain available. Undo is available before Save.") }
    }
    private func widgetOptions(_ instance: TodayWidgetInstance, index: Int) -> some View {
        Menu {
            Button("Configure", systemImage: "slider.horizontal.3") { model.begin(instance) }
            Button("Duplicate", systemImage: "plus.square.on.square") { model.update { $0.value.instances.insert(instance.independentCopy(), at: index + 1) } }
            Button("Move up", systemImage: "arrow.up") { model.move(instance.id, by: -1) }.disabled(index == 0)
            Button("Move down", systemImage: "arrow.down") { model.move(instance.id, by: 1) }.disabled(index == model.draft.value.instances.count - 1)
            Button("Remove", systemImage: "minus.circle") { model.update { try $0.remove(instance.id) } }
        } label: {
            Label("Options for \(instance.kind.title), position \(index + 1) of \(model.draft.value.instances.count)", systemImage: "ellipsis")
                .labelStyle(.iconOnly).frame(width: 44, height: 44).contentShape(Rectangle())
        }.disabled(model.locked)
    }
    private func summary(_ instance: TodayWidgetInstance) -> String {
        if let card = instance.options?.personal { return card.title.isEmpty ? instance.kind.title : card.title }
        if let period = instance.options?.period { return period.key }
        if instance.options?.pinnedID != nil { return "Selected record" }
        switch instance.kind {
        case .todayLook: return "Today"
        case .weekInWear: return "This week"
        case .closetInUse: return "Last completed month"
        case .upcomingPlans: return "Next \(instance.options?.upcomingDays ?? 7) days"
        case .quickActions: return "\((instance.options?.actions ?? TodayAction.defaults).count) actions"
        default: return "Configure"
        }
    }
}
