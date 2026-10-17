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
                        HStack(spacing: 12) {
                            ThemeCover(outfits: model.state.outfits.filter { theme.outfitIDs.contains($0.id) }, height: 48).frame(width: 48)
                                .padding(4).background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: 8)).accessibilityHidden(true)
                            Text(theme.displayName).foregroundStyle(AppTheme.ink).frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: selected.contains(theme.id) ? "checkmark" : "circle")
                                .frame(width: 22).foregroundStyle(selected.contains(theme.id) ? AppTheme.ink : AppTheme.secondary)
                        }.frame(minHeight: 64).padding(.horizontal, 14)
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

/// Collage cover for a theme, generated from its member outfits (no stored artwork).
/// The Themes grid, theme editor and theme chooser all share it.
struct ThemeCover: View {
    @Environment(AppState.self) private var state
    let outfits: [Outfit]
    var height: CGFloat = 134

    var body: some View {
        Group {
            if outfits.isEmpty {
                Image(systemName: "folder").font(.title2).foregroundStyle(AppTheme.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity).accessibilityLabel("Empty theme")
            } else if outfits.count == 1 {
                CollectionArtwork(pieceIDs: outfits[0].pieceIDs, height: height)
            } else {
                let shown = Array(outfits.prefix(4))
                let rows = shown.count > 2 ? 2 : 1
                let cell = max(0, (height - CGFloat(rows - 1) * 6) / CGFloat(rows))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 2), spacing: 6) {
                    ForEach(shown) { outfit in
                        if let id = outfit.pieceIDs.first, let piece = state.ownedPieces.first(where: { $0.id == id }) {
                            PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                                .frame(maxWidth: .infinity).frame(height: cell).clipped()
                        } else {
                            Image(systemName: "tshirt").foregroundStyle(AppTheme.secondary)
                                .frame(maxWidth: .infinity).frame(height: cell)
                        }
                    }
                }
            }
        }.frame(height: height).clipped()
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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var discard = false
    @State private var outfits: [Outfit] = []
    @State private var outfitsError: String?
    @FocusState private var nameEditing: Bool
    private var locked: Bool { model.pending || model.unknown }
    private var selected: Set<UUID> { Set(model.draft.outfitIDs) }
    private var selectedOutfits: [Outfit] { outfits.filter { selected.contains($0.id) } }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.section) {
                        if let notice = model.notice { Text(notice).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                        if let saved = model.saved {
                            Text("Theme saved").font(AppTypography.section)
                            Text(saved.displayName)
                        } else {
                            ThemeCover(outfits: selectedOutfits, height: 180).padding(AppSpacing.medium)
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: AppRadius.field))
                                .animation(.smooth(duration: 0.25), value: model.draft.outfitIDs)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("Theme cover, \(selectedOutfits.count) outfits")
                            LabeledField(title: "Name", text: Binding(get: { model.draft.displayName }, set: { name in model.update { $0.name = name } }),
                                         prompt: "e.g. Weekend", editingFocus: $nameEditing)
                                .submitLabel(.done).onSubmit { nameEditing = false }.disabled(locked)
                            LabeledField(title: "Description", text: Binding(get: { model.draft.displayDescription }, set: { value in model.update { $0.description = value } }), multiline: true).disabled(locked)
                            outfitPicker.id("outfits")
                        }
                        if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                    }.padding(AppSpacing.screen)
                }.scrollDismissesKeyboard(.interactively)
                    .onAppear {
                        if model.startsWithOutfits {
                            model.startsWithOutfits = false
                            Task { try? await Task.sleep(for: .milliseconds(250)); withAnimation { proxy.scrollTo("outfits", anchor: .top) } }
                        }
                    }
            }.background(AppTheme.canvas)
                .navigationTitle(model.draft.baseRevision == 0 ? "Create theme" : "Edit theme").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if model.saved == nil { confirmation }
            } }
            .tint(AppTheme.ink)
                .toolbar {
                    ToolbarItem(placement: model.saved == nil ? .topBarLeading : .topBarTrailing) {
                        Button {
                            if model.saved != nil { finishSaved() }
                            else if model.hasUnsavedChanges { discard = true }
                            else if model.finish(discarding: true) { dismiss() }
                        } label: { if model.saved == nil { Image(systemName: "xmark") } else { Text("Done") } }
                            .tint(AppTheme.ink).accessibilityLabel(model.saved == nil ? "Cancel theme" : "Done")
                            .disabled(locked)
                    }
                }
        }.interactiveDismissDisabled()
            .onAppear {
                if model.saved != nil { finishSaved() }
                loadOutfits()
            }
            .draftDiscardConfirmation(isPresented: $discard, title: "Discard theme draft?", message: "Your saved theme and outfits stay unchanged.") {
                    if model.finish(discarding: true) { discard = false; dismiss() }
                }
    }

    private var outfitPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text("Outfits").font(AppTypography.fieldLabel).foregroundStyle(AppTheme.secondary)
                Spacer()
                Text(selected.isEmpty ? "None selected" : "\(selected.count) selected")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }
            if let outfitsError { SemanticFeedback(role: .danger, message: outfitsError) }
            else if outfits.isEmpty {
                Text("No saved outfits yet. An empty theme is ready for outfits later.")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.medium, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: AppSpacing.medium) {
                    ForEach(outfits) { outfit in outfitCard(outfit) }
                }.sensoryFeedback(.selection, trigger: model.draft.outfitIDs)
            }
        }
    }

    private func outfitCard(_ outfit: Outfit) -> some View {
        let isSelected = selected.contains(outfit.id)
        return Button { toggle(outfit) } label: {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                CollectionArtwork(pieceIDs: outfit.pieceIDs, height: 110).padding(AppSpacing.small)
                    .background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: AppRadius.group))
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.group).strokeBorder(isSelected ? AppTheme.ink : .clear, lineWidth: 2))
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill").symbolRenderingMode(.palette)
                                .foregroundStyle(AppTheme.onPrimary, AppTheme.primaryFill).padding(6)
                        }
                    }
                Text(outfit.displayName).font(AppTypography.supporting).lineLimit(1).foregroundStyle(AppTheme.ink)
            }
        }.buttonStyle(.plain).disabled(locked)
            .accessibilityLabel(outfit.displayName)
            .accessibilityValue(isSelected ? "In theme" : "Not in theme")
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func toggle(_ outfit: Outfit) {
        nameEditing = false
        var ids = selected
        if ids.contains(outfit.id) { ids.remove(outfit.id) } else { ids.insert(outfit.id) }
        model.update { $0.outfitIDs = outfits.filter { ids.contains($0.id) }.map(\.id) }
    }

    private func loadOutfits() {
        do { outfits = try model.store.outfits(); outfitsError = nil }
        catch { outfitsError = "Outfits couldn’t be read. Your selected membership is retained." }
    }

    private func finishSaved() {
        guard let saved = model.saved, model.finish() else { return }
        if let didSave { didSave(saved) }
        else if model.draft.baseRevision == 0 { state.openClosetDestination(scope: "Themes", route: .theme(saved.id)) }
        dismiss()
    }
}
