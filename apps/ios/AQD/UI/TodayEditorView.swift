import AQDCore
import SwiftUI

struct TodayEditorView: View {
    @Bindable var model: TodayEditorModel
    @State private var discard = false
    @State private var library = false
    @State private var reorder = false
    @State private var restore = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(model.draft.value.instances.enumerated()), id: \.element.id) { index, instance in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(instance.kind.title).font(AppTypography.body)
                                Text(summary(instance)).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            Menu {
                                Button("Configure", systemImage: "slider.horizontal.3") { model.begin(instance) }
                                Button("Duplicate", systemImage: "plus.square.on.square") { model.update { $0.value.instances.insert(instance.independentCopy(), at: index + 1) } }
                                Button("Move up", systemImage: "arrow.up") { model.move(instance.id, by: -1) }.disabled(index == 0)
                                Button("Move down", systemImage: "arrow.down") { model.move(instance.id, by: 1) }.disabled(index == model.draft.value.instances.count - 1)
                                Button("Remove", systemImage: "minus.circle") { model.update { try $0.remove(instance.id) } }
                            } label: { Label("Options for \(instance.kind.title), position \(index + 1) of \(model.draft.value.instances.count)", systemImage: "ellipsis").labelStyle(.iconOnly).frame(width: 44, height: 44) }.disabled(model.locked)
                        }.padding(14).frame(minHeight: 52).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16)).id(instance.id)
                    }
                    SecondaryAction(title: "Add widget") { library = true }.disabled(model.locked)
                    DisclosureRow(title: "Reorder widgets", value: "") { reorder = true }.disabled(model.locked)
                    DisclosureRow(title: "Restore defaults", value: "") { restore = true }.disabled(model.locked)
                    if model.draft.defaultsUndo != nil { Button("Undo restore defaults") { model.update { $0.undoDefaults() } }.frame(minHeight: 44).disabled(model.locked) }
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                    PrimaryAction(title: model.saved != nil ? "Done" : model.unknown ? "Check save result" : "Done", isPending: model.pending) {
                        if model.saved != nil { model.finish() } else { Task { await model.save() } }
                    }.disabled(model.importing || (model.saved == nil && !model.unknown && (try? model.draft.result()) == nil))
                    Text("Changes stay on this iPhone. Removing a widget keeps its saved note or photo.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }.padding(20)
            }.background(AppTheme.canvas).navigationTitle("Customize Today").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if model.saved != nil { model.finish() }
                        else if !model.draft.hasChanges { model.finish(discarding: true) } else { discard = true }
                    } label: { Image(systemName: model.saved == nil ? "xmark" : "checkmark") }.accessibilityLabel(model.saved == nil ? "Cancel Today changes" : "Done").disabled(model.pending || model.unknown)
                } }
                .navigationDestination(isPresented: $library) {
                    List(TodayWidgetKind.allCases, id: \.self) { kind in
                        Button(kind.title) { model.begin(TodayWidgetInstance(kind: kind)); library = false }.frame(minHeight: 44)
                    }.navigationTitle("Add widget").tint(AppTheme.ink)
                }
                .navigationDestination(isPresented: $reorder) { TodayReorderView(model: model) }
                .sheet(isPresented: Binding(get: { model.draft.nested != nil }, set: { _ in })) { TodayWidgetConfigurationView(model: model) }
        }.tint(AppTheme.ink).interactiveDismissDisabled()
            .draftDiscardConfirmation(isPresented: $discard, title: "Discard Today changes?", message: "Your saved layout, notes and photos stay unchanged.") { model.finish(discarding: true); if model.state.todayEditor == nil { discard = false } }
            .alert("Restore the three default widgets?", isPresented: $restore) {
                Button("Cancel", role: .cancel) { }
                Button("Restore defaults") { model.update { $0.restoreDefaults() } }
            } message: { Text("Today’s look, Your week in wear and Closet in use will replace the draft placements. Saved notes and photos remain available. Undo is available before Done.") }
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
private struct TodayReorderView: View {
    @Bindable var model: TodayEditorModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        List {
            ForEach(Array(model.draft.value.instances.enumerated()), id: \.element.id) { index, instance in
                HStack {
                    Text(instance.kind.title).frame(maxWidth: .infinity, alignment: .leading)
                    Button { model.move(instance.id, by: -1) } label: { Image(systemName: "arrow.up") }.accessibilityLabel("Move \(instance.kind.title) up").disabled(index == 0).frame(minWidth: 44, minHeight: 44)
                    Button { model.move(instance.id, by: 1) } label: { Image(systemName: "arrow.down") }.accessibilityLabel("Move \(instance.kind.title) down").disabled(index == model.draft.value.instances.count - 1).frame(minWidth: 44, minHeight: 44)
                }.accessibilityValue("Position \(index + 1) of \(model.draft.value.instances.count)").buttonStyle(.borderless)
            }.onMove { offsets, destination in model.update { $0.value.instances.move(fromOffsets: offsets, toOffset: destination) } }
        }.environment(\.editMode, .constant(.active)).navigationTitle("Reorder widgets")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { dismiss() } label: { Image(systemName: "checkmark") }.accessibilityLabel("Done reordering") } }
    }
}
