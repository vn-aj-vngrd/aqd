import AQDCore
import SwiftUI

struct OutfitEditorView: View {
    @Bindable var model: OutfitEditorModel
    @State private var choosing = false
    @State private var discard = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    OutfitComposition(pieceIDs: model.draft.pieceIDs)
                        .frame(minHeight: 245)
                    if let saved = model.saved {
                        Text("Outfit saved").font(AppTypography.section)
                        Text(saved.name).font(AppTypography.body)
                        Text("Only you. Saving an outfit doesn’t plan a day or record wear.")
                            .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        PrimaryAction(title: "Open my outfits") { model.finish(openOutfits: true) }
                    } else {
                        LabeledField(title: "Outfit name", text: Binding(get: { model.draft.name }, set: { value in
                            model.update { $0.name = value }
                        }), accessibilityID: "outfit.name").disabled(model.pending || model.unknown)
                        DisclosureRow(title: "Selected pieces", value: "\(model.draft.pieceIDs.count) pieces") { choosing = true }
                            .disabled(model.pending || model.unknown)
                        Text("A partial combination is fine. You can add more pieces whenever you like.")
                            .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                        PrimaryAction(title: model.unknown ? "Check save result" : "Save outfit", isPending: model.pending) {
                            Task { await model.save() }
                        }.disabled(!model.unknown && !model.canSave)
                    }
                    if model.saved != nil, let error = model.error { SemanticFeedback(role: .danger, message: error) }
                }.padding(20)
            }
            .background(AppTheme.canvas)
            .navigationTitle(model.saved == nil ? (model.draft.baseRevision == 0 ? "Build outfit" : "Edit outfit") : "Outfit saved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if model.saved != nil { model.finish() } else { discard = true }
                    } label: { Image(systemName: model.saved == nil ? "xmark" : "checkmark") }
                        .accessibilityLabel(model.saved == nil ? "Cancel outfit" : "Done")
                        .tint(AppTheme.ink).disabled(model.pending || model.unknown)
                }
            }
            .navigationDestination(isPresented: $choosing) { OutfitPieceChooser(model: model) }
        }
        .interactiveDismissDisabled()
        .sheet(isPresented: $discard) {
            DraftDiscardSheet(title: "Discard outfit draft?", message: "Your saved outfits and pieces stay unchanged.") {
                model.discard()
                if model.state.outfitEditor == nil { discard = false }
            }
        }
    }
}

private struct OutfitPieceChooser: View {
    @Bindable var model: OutfitEditorModel
    @State private var query = ""
    @State private var category: PieceCategory?
    @Environment(\.dismiss) private var dismiss

    private var pieces: [WardrobePiece] {
        model.state.pieces.filter {
            (category == nil || $0.category == category) &&
            (query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
             "\($0.name) \($0.details.color) \($0.details.brand)".localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !model.draft.pieceIDs.isEmpty {
                    Text("Selected pieces").font(AppTypography.fieldLabel)
                    ForEach(model.draft.pieceIDs, id: \.self) { id in
                        let item = model.state.pieces.first { $0.id == id }
                        Button {
                            model.update { $0.remove(id) }
                        } label: {
                            Label(item?.name ?? "Unavailable piece · Remove", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }.tint(AppTheme.actionText)
                    }
                }
                Picker("Category", selection: $category) {
                    Text("All categories").tag(Optional<PieceCategory>.none)
                    ForEach(PieceCategory.allCases, id: \.self) { Text($0.rawValue).tag(Optional($0)) }
                }.pickerStyle(.menu)
                if pieces.isEmpty {
                    ContentUnavailableView("No matching pieces", systemImage: "tshirt",
                                           description: Text("Clear the search or choose another category. Your selection stays here."))
                }
                ForEach(pieces) { piece in
                    let selected = model.draft.pieceIDs.contains(piece.id)
                    Button {
                        model.update { draft in
                            if selected { draft.remove(piece.id) } else { draft.select(piece.id) }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe).frame(width: 60, height: 72)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(piece.name).foregroundStyle(AppTheme.ink)
                                Text(piece.category.rawValue).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        }.padding(14).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain)
                        .accessibilityLabel(piece.name)
                        .accessibilityValue(selected ? "Selected" : "Not selected")
                        .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
                if let error = model.error { SemanticFeedback(role: .danger, message: error) }
            }.padding(20)
        }
        .background(AppTheme.canvas)
        .navigationTitle("Choose pieces").navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Search your pieces")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: { Image(systemName: "checkmark") }.tint(AppTheme.ink).accessibilityLabel("Done choosing pieces")
            }
        }
    }
}

struct OutfitComposition: View {
    @Environment(AppState.self) private var state
    let pieceIDs: [UUID]
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if pieceIDs.isEmpty {
                ContentUnavailableView("Choose your pieces", systemImage: "tshirt",
                                       description: Text("Build a look from your own closet."))
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 8) {
                    ForEach(pieceIDs, id: \.self) { id in
                        if let piece = state.pieces.first(where: { $0.id == id }) {
                            PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                                .frame(height: 130).accessibilityLabel(piece.name)
                        } else {
                            Label("Piece unavailable", systemImage: "tshirt").frame(minHeight: 80)
                        }
                    }
                }.padding(12)
            }
        }.frame(maxWidth: .infinity).background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: 4))
    }
}

struct OutfitCollectionView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let error = state.outfitError {
                    SemanticFeedback(role: .danger, message: error)
                    Button("Retry outfits") { state.reloadOutfits() }.frame(minHeight: 44)
                } else if state.outfits.isEmpty {
                    ContentUnavailableView("Your first outfit starts here", systemImage: "square.stack",
                                           description: Text("Combine pieces from your closet. Every outfit stays private."))
                    PrimaryAction(title: "Build outfit") { state.buildOutfit() }
                }
                ForEach(state.outfits) { outfit in
                    NavigationLink { OutfitDetailView(id: outfit.id) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            OutfitComposition(pieceIDs: outfit.pieceIDs)
                            Text(outfit.name).font(AppTypography.body).foregroundStyle(AppTheme.ink)
                            Text("\(outfit.pieceIDs.count) pieces").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }
                    }.buttonStyle(.plain)
                }
            }.padding(20)
        }.onAppear { state.reloadOutfits() }
    }
}

struct OutfitDetailView: View {
    @Environment(AppState.self) private var state
    let id: UUID
    var body: some View {
        ScrollView {
            if let outfit = state.outfits.first(where: { $0.id == id }) {
                VStack(alignment: .leading, spacing: 20) {
                    OutfitComposition(pieceIDs: outfit.pieceIDs)
                    Text(outfit.name).font(AppTypography.section)
                    Text("Only you · \(outfit.pieceIDs.count) pieces").foregroundStyle(AppTheme.secondary)
                    PrimaryAction(title: "Edit outfit") { state.buildOutfit(editing: outfit) }
                    ForEach(outfit.pieceIDs, id: \.self) { pieceID in
                        NavigationLink { PieceDetailView(id: pieceID) } label: {
                            Label(state.pieces.first(where: { $0.id == pieceID })?.name ?? "Unavailable piece", systemImage: "tshirt")
                                .frame(minHeight: 44)
                        }
                    }
                }.padding(20)
            } else {
                ContentUnavailableView("Outfit unavailable", systemImage: "square.stack", description: Text("The outfit is no longer in your closet."))
            }
        }.background(AppTheme.canvas)
            .navigationTitle("Outfit").navigationBarTitleDisplayMode(.inline)
    }
}
