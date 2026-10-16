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
                        PrimaryAction(title: "Open outfit") { model.finish(openOutfit: true) }
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
                if model.saved != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Edit outfit", systemImage: "square.and.pencil") { model.editSavedOutfit() }
                        } label: { Label("More outfit options", systemImage: "ellipsis") }
                            .tint(AppTheme.ink).disabled(model.pending || model.unknown)
                    }
                }
            }
            .navigationDestination(isPresented: $choosing) { OutfitPieceChooser(model: model) }
            .navigationDestination(isPresented: $choosingThemes) { OutfitThemeChooser(model: model) }
            .navigationDestination(isPresented: Binding(get: { replacing != nil }, set: { if !$0 { replacing = nil } })) {
                if let replacing { OutfitReplacementView(model: model, pieceID: replacing) }
            }
        }
        .interactiveDismissDisabled()
        .draftDiscardConfirmation(isPresented: $discard, title: "Discard outfit draft?", message: "Your saved outfits and pieces stay unchanged.") {
                model.discard()
                if model.state.outfitEditor == nil { discard = false }
            }
    }
}

private struct OutfitPieceChooser: View {
    @Bindable var model: OutfitEditorModel
    var body: some View {
        OwnedPieceChooser(pieces: model.state.pieces, initialSelection: model.draft.pieceIDs,
                          pinnedIDs: model.draft.pinnedPieceIDs ?? [], error: model.error,
                          isLocked: model.pending || model.unknown || model.generating) { ids in
            do {
                var updated = model.draft
                try updated.applyManualSelection(ids, pieces: model.state.pieces)
                model.update { $0 = updated }
                return model.error == nil
            } catch { model.error = "Review current pieces and pins before applying this selection."; return false }
        }.onAppear { model.state.reloadPieces() }
    }
}

struct OutfitComposition: View {
    @Environment(AppState.self) private var state
    let pieceIDs: [UUID]
    var pieceHeight: CGFloat = 130
    var limit: Int? = nil
    private var shownIDs: [UUID] { limit.map { Array(pieceIDs.prefix($0)) } ?? pieceIDs }
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if pieceIDs.isEmpty {
                AppEmptyState("Choose your pieces", systemImage: "tshirt",
                                       description: Text("Build a look from your own closet."))
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 8) {
                    ForEach(shownIDs, id: \.self) { id in
                        if let piece = state.ownedPieces.first(where: { $0.id == id }) {
                            VStack(spacing: 4) {
                                PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                                    .frame(height: pieceHeight).accessibilityLabel(piece.name)
                                if piece.isArchived { Text("Archived").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary) }
                            }
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
    var favoritesOnly = false
    var themeID: UUID?
    let clearFilters: () -> Void
    private var outfits: [Outfit] {
        state.outfits.filter { outfit in
            (!favoritesOnly || outfit.isFavorite) && (themeID == nil || state.themes.contains { $0.id == themeID && $0.outfitIDs.contains(outfit.id) })
        }
    }
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if let error = state.outfitError {
                    SemanticFeedback(role: .danger, message: error)
                    Button("Retry outfits") { state.reloadOutfits() }.frame(minHeight: 44)
                } else if state.outfits.isEmpty {
                    AppEmptyState("Your first outfit starts here", systemImage: "square.stack", description: Text("Combine pieces from your closet. Every outfit stays private."))
                    PrimaryAction(title: "Build outfit") { state.buildOutfit() }
                } else if outfits.isEmpty {
                    AppEmptyState("No matching outfits", systemImage: "square.stack", description: Text("Clear the theme or Favorites filter to see your other looks."))
                    PrimaryAction(title: "Clear filters", action: clearFilters)
                } else {
                    ForEach(outfits) { OutfitCollectionCard(outfit: $0) }
                    PrimaryAction(title: "Suggest an outfit") { state.buildOutfit(suggest: true) }
                }
            }.padding(20).scrollTargetLayout()
        }.scrollPosition(id: Binding(get: { state.closetOutfitAnchor }, set: { state.closetOutfitAnchor = $0 }))
            .onAppear { state.reloadOutfits(); state.reloadThemes() }
    }
}

struct ClosetDestination: View {
    let route: ClosetRoute
    var body: some View {
        Group { switch route {
        case .piece(let id): PieceDetailView(id: id)
        case .outfit(let id): OutfitDetailView(id: id)
        case .theme(let id): ThemeDetailView(id: id)
        case .archivedPieces: ArchivedPiecesView()
        } }.tint(AppTheme.ink)
    }
}

struct OutfitDetailView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let id: UUID
    @State private var deletePresented = false
    @State private var deleteReview: OutfitMutationRequest?
    @State private var pendingMutation: OutfitMutationRequest?
    @State private var error: String?

    private func pieceLabel(_ id: UUID) -> String {
        guard let piece = state.ownedPieces.first(where: { $0.id == id }) else { return "Unavailable piece" }
        return piece.name + (piece.isArchived ? " · Archived" : "")
    }

    var body: some View {
        ScrollView {
            if let outfit = state.outfits.first(where: { $0.id == id }) {
                VStack(alignment: .leading, spacing: 20) {
                    OutfitComposition(pieceIDs: outfit.pieceIDs)
                    Text("\(outfit.pieceIDs.count) pieces · Private on this iPhone").foregroundStyle(AppTheme.secondary)
                    if outfit.isFavorite { Label("Favorite", systemImage: "heart.fill").foregroundStyle(AppTheme.actionText) }
                    PrimaryAction(title: "Plan outfit") { state.openPlan(outfitID: outfit.id) }.disabled(pendingMutation != nil)
                    SecondaryAction(title: "Record wear") { state.openWear(outfitID: outfit.id) }.disabled(pendingMutation != nil)
                    ForEach(outfit.pieceIDs, id: \.self) { pieceID in
                        NavigationLink(value: ClosetRoute.piece(pieceID)) {
                            Label(pieceLabel(pieceID), systemImage: "tshirt")
                                .frame(minHeight: 44)
                        }
                    }
                    if let error { SemanticFeedback(role: .danger, message: error) }
                    if let pendingMutation {
                        PrimaryAction(title: "Check previous change") { apply(pendingMutation) }
                    }
                }.padding(20)
            } else {
                AppEmptyState("Outfit unavailable", systemImage: "square.stack", description: Text("The outfit is no longer in your closet."))
                if let pendingMutation {
                    PrimaryAction(title: "Check previous change") { apply(pendingMutation) }.padding(20)
                }
            }
        }.background(AppTheme.canvas)
            .navigationTitle(state.outfits.first { $0.id == id }?.name ?? "Outfit").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let outfit = state.outfits.first(where: { $0.id == id }) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Edit outfit", systemImage: "square.and.pencil") { state.buildOutfit(editing: outfit) }
                            Button(outfit.isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: outfit.isFavorite ? "heart.slash" : "heart") {
                                apply(OutfitMutationRequest(outfit: outfit, action: .favorite(!outfit.isFavorite)))
                            }
                            Button("Delete outfit", systemImage: "trash", role: .destructive) {
                                do {
                                    guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
                                    deleteReview = try store.outfitDeletionReview(id: id)
                                    deletePresented = true
                                } catch { self.error = "The current deletion impact couldn’t be reviewed. Your outfit is retained." }
                            }
                        } label: { Label("More outfit options", systemImage: "ellipsis") }
                            .tint(AppTheme.ink).disabled(pendingMutation != nil)
                    }
                }
            }
            .confirmationDialog("Delete this outfit?", isPresented: $deletePresented, titleVisibility: .visible) {
                Button("Delete outfit", role: .destructive) { if let deleteReview { apply(deleteReview) } }
                Button("Cancel", role: .cancel) { deleteReview = nil }
            } message: { Text(deletionMessage) }
            .onAppear { state.reloadOutfits() }
    }

    private var deletionMessage: String {
        guard let request = deleteReview, case .delete(let dependencies) = request.action else { return "Review the current outfit before deleting it." }
        return "Delete \(request.outfit.name). Remove its membership in \(dependencies.themeRevisions.count) themes and its links from \(dependencies.planRevisions.count) plan entries, keeping their dates. Your pieces, photos and recorded wear stay unchanged. This cannot be undone."
    }
    private func apply(_ request: OutfitMutationRequest) {
        pendingMutation = request
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            let receipt = try store.applyOutfitMutation(request)
            complete(receipt)
        } catch {
            let failure = error
            if let store = state.store {
                do {
                    if let receipt = try store.outfitMutationReceipt(for: request) { complete(receipt); return }
                    if case PieceStore.StoreError.staleRevision = failure {
                        pendingMutation = nil; deleteReview = nil
                        state.reloadOutfits()
                        self.error = "The outfit or its impact changed. Review the current record and try again."
                        return
                    }
                } catch { }
            }
            state.reloadOutfits()
            self.error = "The change didn’t finish. Check the same operation before starting another change."
        }
    }

    private func complete(_ receipt: OutfitMutationReceipt) {
        pendingMutation = nil; error = nil
        state.reloadOutfits(); state.reloadThemes(); state.reloadPlanEntries()
        if case .deleted = receipt { dismiss() }
    }
}
