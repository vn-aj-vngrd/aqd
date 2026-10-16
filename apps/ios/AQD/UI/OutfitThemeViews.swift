import AQDCore
import SwiftUI

struct OutfitThemeChooser: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: "Done") {
                    model.update { $0.themeIDs = themes.filter { selected.contains($0.id) }.map(\.id) }
                    if model.error == nil { dismiss() }
                }.disabled(error != nil)
    }

    @Bindable var model: OutfitEditorModel
    @State private var themes: [OutfitTheme] = []
    @State private var selected: Set<UUID> = []
    @State private var initialized = false
    @State private var error: String?
    @State private var creating: ThemeEditorModel?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Select themes for this outfit draft.").foregroundStyle(AppTheme.secondary)
                if let error { SemanticFeedback(role: .danger, message: error); Button("Retry themes", action: refresh) }
                else if themes.isEmpty { Text("No themes yet. Create one, or save your outfit without a theme.").foregroundStyle(AppTheme.secondary) }
                ForEach(themes) { theme in
                    Button {
                        if selected.contains(theme.id) { selected.remove(theme.id) } else { selected.insert(theme.id) }
                    } label: {
                        HStack(spacing: 16) {
                            Text(theme.name).foregroundStyle(AppTheme.ink).frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: selected.contains(theme.id) ? "checkmark" : "circle")
                                .frame(width: 22).foregroundStyle(selected.contains(theme.id) ? AppTheme.actionText : AppTheme.secondary)
                        }.frame(minHeight: 54).padding(.horizontal, 14)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain).accessibilityValue(selected.contains(theme.id) ? "Selected" : "Not selected")
                }

                SecondaryAction(title: "Create theme") {
                    do {
                        guard let store = model.state.store else { throw PieceStore.StoreError.corruptStore }
                        let draft = try store.themeDraft() ?? ThemeDraft(ownerID: model.draft.ownerID)
                        if try store.themeDraft() == nil { try store.saveThemeDraft(draft) }
                        creating = try ThemeEditorModel(store: store, draft: draft)
                    } catch { self.error = "A theme draft couldn’t be opened. Your existing themes are retained." }
                }
                if let message = model.error { SemanticFeedback(role: .danger, message: message) }
            }.padding(20)
        }.background(AppTheme.canvas)
            .navigationTitle("Choose themes").navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: { Label("Cancel", systemImage: "xmark") }
                    .disabled(model.pending || model.unknown)
            } }
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                confirmation
            } }
            .tint(AppTheme.ink)
            .onAppear {
                if !initialized { selected = Set(model.draft.themeIDs ?? []); initialized = true }
                refresh()
            }
            .sheet(item: $creating, onDismiss: refresh) { editor in
                ThemeEditorView(model: editor) { saved in
                    refresh(); selected.insert(saved.id)
                }
            }
    }

    private func refresh() {
        do {
            guard let store = model.state.store else { throw PieceStore.StoreError.corruptStore }
            themes = try store.themes(); error = nil
        } catch { self.error = "Themes couldn’t be read. Keep your existing data and retry." }
    }
}

struct ThemeEditorView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: model.unknown ? "Check result" : "Save", isPending: model.pending) {
                            Task { await model.save(); if model.saved != nil { finishSaved() } }
                        }.disabled(!model.unknown && !model.canSave)
    }

    @Bindable var model: ThemeEditorModel
    var didSave: ((OutfitTheme) -> Void)? = nil
    @Environment(AppState.self) private var state
    @State private var discard = false
    @State private var choosingOutfits = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let notice = model.notice { Text(notice).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                    if let saved = model.saved {
                        Text("Theme saved").font(AppTypography.section)
                        Text(saved.name)
                        Text("Your outfits can belong to more than one theme.").foregroundStyle(AppTheme.secondary)

                    } else {
                        LabeledField(title: "Name", text: Binding(get: { model.draft.name }, set: { name in model.update { $0.name = name } })).disabled(model.pending || model.unknown)
                        LabeledField(title: "Description", text: Binding(get: { model.draft.description }, set: { value in model.update { $0.description = value } }), multiline: true).disabled(model.pending || model.unknown)
                        DisclosureRow(title: "Outfits", value: model.draft.outfitIDs.isEmpty ? "None selected" : "\(model.draft.outfitIDs.count) selected") { choosingOutfits = true }.disabled(model.pending || model.unknown)
                        Text("An outfit can belong to more than one theme.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)

                    }
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                }.padding(20)
            }.background(AppTheme.canvas)
                .navigationTitle(model.draft.baseRevision == 0 ? "Create theme" : "Edit theme").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if model.saved == nil { confirmation }
            } }
            .tint(AppTheme.ink)
                .toolbar {
                    ToolbarItem(placement: model.saved == nil ? .topBarLeading : .topBarTrailing) {
                        Button {
                            if model.saved != nil { finishSaved() } else { discard = true }
                        } label: { if model.saved == nil { Image(systemName: "xmark") } else { Text("Done") } }
                            .tint(AppTheme.ink).accessibilityLabel(model.saved == nil ? "Cancel theme" : "Done")
                            .disabled(model.pending || model.unknown)
                    }
                }
                .navigationDestination(isPresented: $choosingOutfits) { ThemeOutfitChooser(model: model) }
        }.interactiveDismissDisabled()
            .onAppear {
                if model.saved != nil { finishSaved() }
                else if model.startsWithOutfits { choosingOutfits = true; model.startsWithOutfits = false }
            }
            .draftDiscardConfirmation(isPresented: $discard, title: "Discard theme draft?", message: "Your saved theme and outfits stay unchanged.") {
                    if model.finish(discarding: true) { discard = false; dismiss() }
                }
    }
    private func finishSaved() {
        guard let saved = model.saved, model.finish() else { return }
        if let didSave { didSave(saved) }
        else if model.draft.baseRevision == 0 { state.openClosetDestination(scope: "Themes", route: .theme(saved.id)) }
        dismiss()
    }

}

private struct ThemeOutfitChooser: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: "Done") {
                    model.update { $0.outfitIDs = outfits.filter { selected.contains($0.id) }.map(\.id) }
                    if model.error == nil { dismiss() }
                }.disabled(error != nil || model.pending || model.unknown)
    }

    @Bindable var model: ThemeEditorModel
    @State private var outfits: [Outfit] = []
    @State private var selected: Set<UUID> = []
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let error { SemanticFeedback(role: .danger, message: error) }
                else if outfits.isEmpty { Text("No saved outfits yet. An empty theme is ready for outfits later.").foregroundStyle(AppTheme.secondary) }
                ForEach(outfits) { outfit in
                    Button {
                        if selected.contains(outfit.id) { selected.remove(outfit.id) } else { selected.insert(outfit.id) }
                    } label: {
                        HStack {
                            Text(outfit.name).foregroundStyle(AppTheme.ink).frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: selected.contains(outfit.id) ? "checkmark.circle.fill" : "circle")
                        }.frame(minHeight: 54).padding(.horizontal, 14)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain).accessibilityValue(selected.contains(outfit.id) ? "Selected" : "Not selected")
                }

            }.padding(20)
        }.background(AppTheme.canvas)
            .navigationTitle("Choose outfits").navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: { Label("Cancel", systemImage: "xmark") }
                    .disabled(model.pending || model.unknown)
            } }
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                confirmation
            } }
            .tint(AppTheme.ink)
            .onAppear {
                selected = Set(model.draft.outfitIDs)
                do { outfits = try model.store.outfits(); error = nil }
                catch { self.error = "Outfits couldn’t be read. Your selected membership is retained." }
            }
    }
}
