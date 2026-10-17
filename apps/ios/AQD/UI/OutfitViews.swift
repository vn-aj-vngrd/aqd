import AQDCore
import SwiftUI

struct OutfitEditorView: View {
    @Bindable var model: OutfitEditorModel
    @State private var choosing = false
    @State private var discard = false
    @State private var choosingThemes = false
    @FocusState private var nameEditing: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var locked: Bool { model.pending || model.unknown || model.generating }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    if let saved = model.saved {
                        OutfitComposition(pieceIDs: saved.pieceIDs)
                        Text("Outfit saved").font(AppTypography.section)
                        Text(saved.displayName).font(AppTypography.body)
                        Text("Only you. Saving an outfit doesn’t plan a day or record wear.")
                            .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        PrimaryAction(title: "Open outfit") { model.finish(openOutfit: true) }
                        SecondaryAction(title: "Plan this look") { model.planSavedOutfit() }
                    } else {
                        Button { nameEditing = false; choosing = true } label: {
                            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                                HStack {
                                    Text("Your outfit").font(AppTypography.fieldLabel)
                                    Spacer()
                                    Text("\(model.draft.pieceIDs.count) pieces").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                                }
                                Group {
                                    if model.draft.pieceIDs.isEmpty {
                                        OutfitComposition(pieceIDs: []).frame(minHeight: 180)
                                    } else {
                                        CollectionArtwork(pieceIDs: model.draft.pieceIDs, height: 220)
                                    }
                                }.animation(reduceMotion ? nil : AQDMotion.reflow, value: model.draft.pieceIDs)
                                HStack {
                                    Label(model.draft.pieceIDs.isEmpty ? "Choose pieces" : "Change pieces", systemImage: "plus")
                                    Spacer()
                                    Image(systemName: "chevron.forward").font(AppTypography.disclosure).accessibilityHidden(true)
                                }.frame(minHeight: 44)
                            }.foregroundStyle(AppTheme.ink).padding(AppSpacing.screen)
                                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
                        }.buttonStyle(.plain).disabled(locked).accessibilityIdentifier("outfit.choosePieces")
                        LabeledField(title: "Outfit name", text: Binding(get: { model.draft.displayName }, set: { value in model.update { $0.name = value } }),
                                     prompt: "e.g. An easy afternoon", accessibilityID: "outfit.name", editingFocus: $nameEditing).submitLabel(.done).onSubmit { nameEditing = false }.disabled(locked)
                        DisclosureRow(title: "Themes", value: model.draft.themeIDs?.isEmpty == false ? "\(model.draft.themeIDs?.count ?? 0) selected" : "None selected") { nameEditing = false; choosingThemes = true }
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field)).disabled(locked)
                        if model.needsPieceReview {
                            SemanticFeedback(role: .warning, message: "Pieces changed. Open Change pieces to review the current records before saving.")
                        }
                    }
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                }.padding(AppSpacing.screen)
            }.scrollDismissesKeyboard(.interactively).background(AppTheme.canvas)
                .navigationTitle(model.saved != nil ? "Outfit saved" : model.draft.baseRevision == 0 ? "Build outfit" : "Edit outfit")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: model.saved == nil ? .topBarLeading : .topBarTrailing) {
                        Button {
                            if model.saved != nil { model.finish() }
                            else if model.hasUnsavedChanges { discard = true }
                            else { model.discard() }
                        } label: { if model.saved == nil { Image(systemName: "xmark") } else { Text("Done") } }
                            .accessibilityLabel(model.saved == nil ? "Cancel outfit" : "Done").tint(AppTheme.ink).disabled(locked)
                    }
                    if model.saved != nil {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu { AccessoryButton("Edit outfit", systemImage: AppSymbols.edit) { model.editSavedOutfit() } }
                                label: { Label("More outfit options", systemImage: "ellipsis") }
                                .tint(AppTheme.ink).disabled(model.pending || model.unknown)
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if model.saved == nil {
                            ToolbarSaveAction(title: model.unknown ? "Check result" : "Save", isPending: model.pending) { Task { await model.save(); if model.saved != nil { model.finish() } } }
                                .disabled(!model.unknown && !model.canSave)
                        }
                    }
                }
                .navigationDestination(isPresented: $choosing) { OutfitPieceChooser(model: model) }
                .navigationDestination(isPresented: $choosingThemes) { OutfitThemeChooser(model: model) }
        }.interactiveDismissDisabled()
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
                          error: model.error, isLocked: model.pending || model.unknown || model.generating,
                          showsComposition: true) { ids in
            model.applyManualPieces(ids)
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
                                       description: Text("Build a look from your own closet."), fillsAvailableSpace: false)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 8) {
                    ForEach(shownIDs, id: \.self) { id in
                        if let piece = state.ownedPieces.first(where: { $0.id == id }) {
                            VStack(spacing: 4) {
                                PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                                    .frame(height: pieceHeight).accessibilityLabel(piece.displayName)
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

enum OutfitCollectionSort: String, CaseIterable {
    case recentlyUpdated = "Recently updated", nameAscending = "Name A–Z", nameDescending = "Name Z–A"
    func apply(_ outfits: [Outfit]) -> [Outfit] {
        outfits.sorted { first, second in
            if self == .recentlyUpdated {
                return first.updatedAt == second.updatedAt ? first.id.uuidString < second.id.uuidString : first.updatedAt > second.updatedAt
            }
            let order = first.displayName.localizedStandardCompare(second.displayName)
            if order == .orderedSame { return first.id.uuidString < second.id.uuidString }
            return self == .nameAscending ? order == .orderedAscending : order == .orderedDescending
        }
    }
}

struct OutfitCollectionView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(AppState.self) private var state
    var favoritesOnly = false
    var themeID: UUID?
    var sort = OutfitCollectionSort.recentlyUpdated
    private var outfits: [Outfit] {
        sort.apply(state.outfits.filter { outfit in
            (!favoritesOnly || outfit.isFavorite) && (themeID == nil || state.themes.contains { $0.id == themeID && $0.outfitIDs.contains(outfit.id) })
        })
    }
    var summary: ClosetCollectionSummary? = nil
    var body: some View {
        Group {
            if state.outfitError == nil && outfits.isEmpty {
                EmptyStatePage(title: state.outfits.isEmpty ? "Your first outfit starts here" : "No matching outfits",
                               systemImage: "square.stack",
                               description: Text(state.outfits.isEmpty ? "Combine pieces from your closet. Every outfit stays private." : "Clear the theme or Favorites filter to see your other looks."))
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppSpacing.large) {
                        if let summary { summary }
                        if let error = state.outfitError {
                            SemanticFeedback(role: .danger, message: error)
                            Button("Retry outfits") { state.reloadOutfits() }.frame(minHeight: 44)
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 16) {
                                ForEach(outfits) { OutfitCollectionCard(outfit: $0) }
                            }.scrollTargetLayout()
                        }
                    }.padding(20).scrollTargetLayout()
                }.scrollPosition(id: Binding(get: { state.closetOutfitAnchor }, set: { state.closetOutfitAnchor = $0 }))
            }
        }.onAppear { state.reloadOutfits(); state.reloadThemes() }
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
        } }.tint(AppTheme.ink).secondaryPage()
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
        return piece.displayName + (piece.isArchived ? " · Archived" : "")
    }

    var body: some View {
        ScrollView {
            if let outfit = state.outfits.first(where: { $0.id == id }) {
                VStack(alignment: .leading, spacing: 20) {
                    OutfitComposition(pieceIDs: outfit.pieceIDs)
                    Text("\(outfit.pieceIDs.count) pieces · Private on this iPhone").foregroundStyle(AppTheme.secondary)
                    if outfit.isFavorite { Label("Favorite", systemImage: "heart.fill").foregroundStyle(AppTheme.ink) }
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
            .navigationTitle(state.outfits.first { $0.id == id }?.displayName ?? "Outfit").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let outfit = state.outfits.first(where: { $0.id == id }) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            AccessoryButton("Edit outfit", systemImage: AppSymbols.edit) { state.buildOutfit(editing: outfit) }
                            AccessoryButton(outfit.isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: outfit.isFavorite ? "heart.slash" : "heart") {
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
            .appConfirmation("Delete this outfit?", isPresented: $deletePresented) {
                Button("Delete outfit", role: .destructive) { if let deleteReview { apply(deleteReview) } }
                Button("Cancel", role: .cancel) { deleteReview = nil }
            } message: { Text(deletionMessage) }
            .onAppear { state.reloadOutfits() }
    }

    private var deletionMessage: String {
        guard let request = deleteReview, case .delete(let dependencies) = request.action else { return "Review the current outfit before deleting it." }
        return "Delete \(request.outfit.displayName). Remove its membership in \(dependencies.themeRevisions.count) themes and its links from \(dependencies.planRevisions.count) plan entries, keeping their dates. Your pieces, photos and recorded wear stay unchanged. This cannot be undone."
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
