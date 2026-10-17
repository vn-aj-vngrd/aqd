import AQDCore
import SwiftUI

struct WardrobeCategorySettingsView: View {
    @Environment(AppState.self) private var state
    @State private var categories = WardrobeCategory.defaults
    @State private var editing: WardrobeCategory?
    @State private var error: String?
    @State private var loaded = false
    @State private var editMode = EditMode.inactive
    var body: some View {
        List {
            Section {
                ForEach(categories) { category in
                    Button { editing = category } label: {
                        HStack {
                            Text(category.name).foregroundStyle(AppTheme.ink)
                            Spacer()
                            Text("\(state.ownedPieces.filter { state.category(for: $0)?.id == category.id }.count) pieces")
                                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }.frame(minHeight: AppControlMetrics.minimumTarget)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .reorderableSurfaceRow()
                }.onMove { source, destination in
                    var updated = categories; updated.move(fromOffsets: source, toOffset: destination)
                    _ = save(updated)
                }.onDelete { indices in
                    var updated = categories; updated.remove(atOffsets: indices)
                    _ = save(updated)
                }
            } footer: {
                Text("Choose a category when adding a piece. Removing a category keeps its pieces under their original type. Keep at least one category.")
            }
            if let error { Section { SemanticFeedback(role: .danger, message: error) }.listRowBackground(AppTheme.surface) }
        }.listStyle(.insetGrouped).contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden).background(AppTheme.canvas)
            .navigationTitle("Categories").navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation { editMode = editMode.isEditing ? .inactive : .active }
                    } label: {
                        if editMode.isEditing { Image(systemName: "checkmark") }
                        else { Image(systemName: AppSymbols.edit) }
                    }.tint(AppTheme.ink).disabled(!loaded)
                        .accessibilityLabel(editMode.isEditing ? "Finish editing categories" : "Edit categories")
                    Button { editing = WardrobeCategory(name: "", type: .tops) } label: { Label("Add category", systemImage: "plus") }
                        .disabled(!loaded || categories.count >= 64)
                }
            }
            .environment(\.editMode, $editMode)
            .onAppear {
                do {
                    guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
                    categories = try store.localExperience().pieceCategories ?? WardrobeCategory.defaults
                    state.pieceCategories = categories; loaded = true; error = nil
                } catch { self.error = "Categories couldn’t open. Your saved settings are retained. Reopen this screen to retry." }
            }
            .sheet(item: $editing) { category in
                WardrobeCategoryEditor(category: category, isNew: !categories.contains { $0.id == category.id }) { updated in
                    var values = categories
                    if let index = values.firstIndex(where: { $0.id == updated.id }) { values[index] = updated }
                    else { values.append(updated) }
                    return save(values)
                }
            }
    }
    private func save(_ values: [WardrobeCategory]) -> Bool {
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.savePieceCategories(values, expected: categories)
            categories = values; state.pieceCategories = values; state.collectionRefreshID = UUID(); error = nil
            return true
        } catch {
            // A repeated write can reconcile an acknowledgement lost after commit.
            if let stored = try? state.store?.localExperience().pieceCategories, stored == values {
                categories = values; state.pieceCategories = values; state.collectionRefreshID = UUID(); self.error = nil
                return true
            }
            self.error = "Changes weren’t confirmed. Use unique category names, keep at least one category, and retry. Saved pieces are unchanged."
            return false
        }
    }
}

private struct WardrobeCategoryEditor: View {
    let category: WardrobeCategory
    let isNew: Bool
    let save: (WardrobeCategory) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var type: PieceCategory
    @State private var error: String?
    @State private var discard = false
    init(category: WardrobeCategory, isNew: Bool, save: @escaping (WardrobeCategory) -> Bool) {
        self.category = category; self.isNew = isNew; self.save = save
        _name = State(initialValue: category.name); _type = State(initialValue: category.type)
    }
    private var changed: Bool { name != category.name || type != category.type }
    var body: some View {
        NavigationStack {
            Form {
                TextField("Category name", text: $name).textInputAutocapitalization(.words)
                if isNew {
                    Picker("Piece type", selection: $type) {
                        ForEach(PieceCategory.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }
                if let error { SemanticFeedback(role: .danger, message: error) }
            }.contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden).background(AppTheme.canvas)
                .navigationTitle(isNew ? "New category" : "Edit category").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { if changed { discard = true } else { dismiss() } } label: { Label("Close", systemImage: "xmark") }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            let value = WardrobeCategory(id: category.id, name: name.trimmingCharacters(in: .whitespacesAndNewlines), type: type)
                            if save(value) { dismiss() } else { error = "Couldn’t save. Use a unique name of 1–40 characters, then retry." }
                        }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || name.trimmingCharacters(in: .whitespacesAndNewlines).count > 40 || !changed)
                    }
                }
        }.tint(AppTheme.ink).interactiveDismissDisabled(changed)
            .draftDiscardConfirmation(isPresented: $discard, title: "Discard category changes?", message: "Your saved categories and pieces stay unchanged.") { dismiss() }
    }
}
