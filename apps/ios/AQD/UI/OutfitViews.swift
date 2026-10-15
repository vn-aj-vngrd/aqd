import AQDCore
import SwiftUI

struct OutfitEditorView: View {
    @Bindable var model: OutfitEditorModel
    @State private var choosing = false
    @State private var discard = false
    @State private var choosingThemes = false
    @State private var replacing: UUID?

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
                        SecondaryAction(title: "Plan this look") { model.planSavedOutfit() }
                    } else if model.draft.stage == .readiness {
                        OutfitReadinessContent(model: model)
                    } else if model.draft.stage == .suggest {
                        OutfitSuggestionContent(model: model)
                    } else {
                        if let provenance = model.proposalSource {
                            Text(provenance).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }
                        LabeledField(title: "Outfit name", text: Binding(get: { model.draft.name }, set: { value in
                            model.update { $0.name = value }
                        }), accessibilityID: "outfit.name").disabled(model.pending || model.unknown)
                        DisclosureRow(title: "Selected pieces", value: "\(model.draft.pieceIDs.count) pieces") { choosing = true }
                            .disabled(model.pending || model.unknown)
                        DisclosureRow(title: "Themes", value: model.draft.themeIDs?.isEmpty == false ? "\(model.draft.themeIDs?.count ?? 0) selected" : "None selected") { choosingThemes = true }
                            .disabled(model.pending || model.unknown)
                        if model.needsPieceReview {
                            SemanticFeedback(role: .warning, message: "Pieces changed after this draft was prepared. Open Selected pieces to review current records before saving.")
                        }
                        ForEach(model.draft.pieceIDs, id: \.self) { id in
                            let piece = model.state.pieces.first { $0.id == id }
                            let pinned = (model.draft.pinnedPieceIDs ?? []).contains(id)
                            VStack(alignment: .leading, spacing: 4) {
                                Button {
                                    model.update { draft in if pinned { draft.unpin(id) } else { draft.pin(id) } }
                                } label: { Label("\(piece?.name ?? "Unavailable piece") · \(pinned ? "Unpin" : "Pin")", systemImage: pinned ? "pin.fill" : "pin") }
                                    .frame(minHeight: 44).disabled(model.pending || model.unknown || model.generating)
                                if !pinned, piece != nil {
                                    Button("Replace piece") { replacing = id }.frame(minHeight: 44)
                                        .disabled(model.pending || model.unknown || model.generating)
                                }
                            }
                        }
                        SecondaryAction(title: "Suggest a variation") { model.update { $0.stage = .suggest } }
                            .disabled(model.pending || model.unknown || model.generating)
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
            .navigationTitle(model.saved != nil ? "Outfit saved" : model.draft.stage == .readiness ? "First outfit" : model.draft.stage == .suggest ? "Suggest an outfit" : model.draft.stage == .review ? "Review outfit" : model.draft.baseRevision == 0 ? "Build outfit" : "Edit outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if model.saved != nil { model.finish() } else { discard = true }
                    } label: { Image(systemName: model.saved == nil ? "xmark" : "checkmark") }
                        .accessibilityLabel(model.saved == nil ? "Cancel outfit" : "Done")
                        .tint(AppTheme.ink).disabled(model.pending || model.unknown || model.generating)
                }
            }
            .navigationDestination(isPresented: $choosing) { OutfitPieceChooser(model: model) }
            .navigationDestination(isPresented: $choosingThemes) { OutfitThemeChooser(model: model) }
            .navigationDestination(isPresented: Binding(get: { replacing != nil }, set: { if !$0 { replacing = nil } })) {
                if let replacing { OutfitReplacementView(model: model, pieceID: replacing) }
            }
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
    @State private var selected: [UUID] = []
    @State private var initialized = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

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
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        categoryButton(nil)
                        ForEach(PieceCategory.allCases, id: \.self) { categoryButton($0) }
                    }
                }.scrollIndicators(.hidden)
                if pieces.isEmpty {
                    ContentUnavailableView("No matching pieces", systemImage: "tshirt",
                                           description: Text("Clear the search or choose another category. Your selection stays here."))
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 16) {
                    ForEach(pieces) { piece in
                        let isSelected = selected.contains(piece.id)
                        Button {
                            if isSelected {
                                if !(model.draft.pinnedPieceIDs ?? []).contains(piece.id) { selected.removeAll { $0 == piece.id } }
                            } else { selected.append(piece.id) }
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                                    .frame(height: 134)
                                    .overlay(alignment: .topTrailing) {
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill").font(.title3)
                                                .symbolRenderingMode(.palette).foregroundStyle(AppTheme.onAccent, AppTheme.accent)
                                                .padding(8)
                                        }
                                    }
                                Text(piece.name).font(AppTypography.fieldLabel).foregroundStyle(AppTheme.ink)
                                Text([piece.category.rawValue, piece.details.color].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }.buttonStyle(.plain)
                            .accessibilityLabel(piece.name)
                            .accessibilityValue(isSelected ? "Selected" : "Not selected")
                            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    }
                }
                ForEach(selected.filter { id in !model.state.pieces.contains(where: { $0.id == id }) }, id: \.self) { id in
                    Button("Remove unavailable piece") { selected.removeAll { $0 == id } }.frame(minHeight: 44)
                }
                Text("\(selected.count) selected · Kept when filters change")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                PrimaryAction(title: "Add selected pieces") {
                    model.update { draft in
                        for id in draft.pieceIDs { draft.remove(id) }
                        for id in selected { draft.select(id) }
                        do { try draft.reviewCurrentPieces(model.state.pieces) } catch { draft.reviewedPieceRevisions = [:] }
                    }
                    if model.error == nil { dismiss() }
                }.disabled(model.pending || model.unknown)
            }.padding(20)
        }
        .background(AppTheme.canvas)
        .navigationTitle("Choose pieces").navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Search your pieces")
        .onAppear { if !initialized { selected = model.draft.pieceIDs; initialized = true } }
    }

    private func categoryButton(_ value: PieceCategory?) -> some View {
        Button { category = value } label: {
            HStack(spacing: 6) {
                if category == value { Image(systemName: "checkmark") }
                Text(value?.rawValue ?? "All pieces")
            }.font(.subheadline).padding(.horizontal, 12).padding(.vertical, 6)
                .frame(minHeight: 44)
                .foregroundStyle(category == value ? AppTheme.onAccent : AppTheme.ink)
                .background(category == value ? AppTheme.accent : AppTheme.surface, in: Capsule())
        }.buttonStyle(.plain).accessibilityAddTraits(category == value ? [.isSelected] : [])
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
                    PrimaryAction(title: "Plan outfit") { state.openPlan(outfitID: outfit.id) }
                    SecondaryAction(title: "Edit outfit") { state.buildOutfit(editing: outfit) }
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
