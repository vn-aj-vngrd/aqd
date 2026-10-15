import AQDCore
import SwiftUI

struct ClosetView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var category: PieceCategory?
    @State private var archived = false
    @State private var availability: PieceAvailability?
    @State private var sort = PieceSort.name
    @State private var results: [WardrobePiece] = []
    @State private var error: String?
    @State private var addPresented = false
    @State private var pendingAdd: ClosetAddAction?
    @State private var favoritesOnly = false
    @State private var themeID: UUID?
    @State private var searchFavoritesOnly = false
    @State private var searchThemeID: UUID?
    @State private var searchModel: ClosetSearchModel?

    private var scope: String { state.closetSearchActive ? state.closetSearchScope : state.closetScope }
    private var searchInput: ClosetSearchInput {
        ClosetSearchInput(query: state.closetSearchQuery, scope: ClosetSearchScope(rawValue: state.closetSearchScope) ?? .pieces,
                          favoritesOnly: searchFavoritesOnly, themeID: searchThemeID)
    }

    var body: some View {
        @Bindable var state = state
        NavigationStack(path: $state.closetPath) {
            VStack(spacing: 0) {
                scopePicker.padding(.horizontal, 20).padding(.bottom, 12)
                if scope == "Outfits" { outfitFilters.padding(.horizontal, 20).padding(.bottom, 8) }
                if state.closetSearchActive {
                    ClosetSearchContent(model: searchModel, input: searchInput,
                                        clear: { state.closetSearchQuery = "" },
                                        browse: { state.closetSearchActive = false },
                                        addPiece: { state.addPiece() })
                } else if scope == "Pieces" {
                    pieceCollection
                } else if scope == "Outfits" {
                    OutfitCollectionView(favoritesOnly: favoritesOnly, themeID: themeID) { favoritesOnly = false; themeID = nil }
                } else { ThemeCollectionView() }
            }
            .background(AppTheme.canvas)
            .navigationTitle("Closet")
            .toolbar {
                if !state.closetSearchActive {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { state.closetSearchActive = true } label: { Label("Search closet", systemImage: "magnifyingglass") }.tint(AppTheme.ink)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { addPresented = true } label: { Label("Add to closet", systemImage: "plus") }
                            .tint(AppTheme.ink).accessibilityIdentifier("closet.addPiece")
                    }
                    if scope == "Pieces" { pieceFilterMenu }
                }
            }
            .searchable(text: $state.closetSearchQuery, isPresented: $state.closetSearchActive,
                        placement: .navigationBarDrawer(displayMode: .always), prompt: "Search your \(scope.lowercased())")
            .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
            .onAppear(perform: refresh)
            .onChange(of: state.closetSearchActive) { _, active in
                if active {
                    state.closetSearchSourceScope = state.closetScope
                    state.closetSearchScope = state.closetScope
                    state.closetSearchRestoresSource = true
                } else {
                    if state.closetSearchRestoresSource { state.closetScope = state.closetSearchSourceScope }
                    state.closetSearchRestoresSource = true
                    state.closetSearchQuery = ""; searchModel?.clearCache()
                }
            }
            .onChange(of: category) { refreshPieces() }
            .onChange(of: archived) { refreshPieces() }
            .onChange(of: availability) { refreshPieces() }
            .onChange(of: sort) { refreshPieces() }
            .onChange(of: state.collectionRefreshID) { refreshPieces() }
            .sheet(isPresented: $addPresented, onDismiss: performAdd) {
                ClosetAddSheet { action in pendingAdd = action; addPresented = false }
            }
        }.tint(state.closetSearchActive ? AppTheme.actionText : AppTheme.ink)
    }

    private var scopeSelection: Binding<String> {
        Binding(get: { scope }, set: { value in
            if state.closetSearchActive { state.closetSearchScope = value } else { state.closetScope = value }
        })
    }
    @ViewBuilder private var scopePicker: some View {
        if typeSize.isAccessibilitySize {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(ClosetSearchScope.allCases, id: \.self) { value in
                        Button { scopeSelection.wrappedValue = value.rawValue } label: {
                            Label(value.rawValue, systemImage: scope == value.rawValue ? "checkmark.circle.fill" : "circle")
                                .padding(.horizontal, 12).frame(minHeight: 44)
                        }.buttonStyle(.plain).foregroundStyle(scope == value.rawValue ? AppTheme.actionText : AppTheme.ink)
                            .accessibilityAddTraits(scope == value.rawValue ? [.isSelected] : [])
                    }
                }
            }.scrollIndicators(.hidden)
        } else {
            Picker("Closet collection", selection: scopeSelection) {
                ForEach(ClosetSearchScope.allCases, id: \.self) { Text($0.rawValue).tag($0.rawValue) }
            }.pickerStyle(.segmented).frame(minHeight: 44)
        }
    }
    private var outfitFilters: some View {
        HStack(spacing: 12) {
            Toggle("Favorites", isOn: state.closetSearchActive ? $searchFavoritesOnly : $favoritesOnly)
                .toggleStyle(.button).tint(AppTheme.actionText)
            Picker("Theme", selection: state.closetSearchActive ? $searchThemeID : $themeID) {
                Text("All themes").tag(Optional<UUID>.none)
                ForEach(state.themes) { Text($0.name).tag(Optional($0.id)) }
            }.pickerStyle(.menu).tint(AppTheme.actionText)
            Spacer(minLength: 0)
        }
    }
    private var pieceFilterMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Category", selection: $category) {
                    Text("All categories").tag(Optional<PieceCategory>.none)
                    ForEach(PieceCategory.allCases, id: \.self) { Text($0.rawValue).tag(Optional($0)) }
                }
                Picker("Availability", selection: $availability) {
                    Text("All availability").tag(Optional<PieceAvailability>.none)
                    ForEach([PieceAvailability.available, .unavailable, .laundry], id: \.self) { Text($0.rawValue.capitalized).tag(Optional($0)) }
                }
                Button("Archived pieces") { state.closetPath.append(.archivedPieces) }
                Picker("Sort pieces", selection: $sort) {
                    ForEach(PieceSort.allCases, id: \.self) { Text($0.title).tag($0) }
                }
            } label: { Label("Filter and sort pieces", systemImage: "line.3.horizontal.decrease") }.tint(AppTheme.ink)
        }
    }
    private var pieceCollection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let error {
                    SemanticFeedback(role: .danger, message: error)
                    Button("Retry", action: refreshPieces).frame(minHeight: 44)
                } else if results.isEmpty {
                    ContentUnavailableView(archived ? "No archived pieces" : category == nil && availability == nil ? "Your closet starts here" : "No matching pieces", systemImage: "tshirt",
                                           description: Text(category == nil && availability == nil ? "Add a photo and a few details. Everything stays on this device." : "Try another category or clear the filters."))
                    if category == nil && availability == nil && !archived {
                        PrimaryAction(title: "Add piece") { state.addPiece() }
                    } else {
                        PrimaryAction(title: "Clear filters") { category = nil; availability = nil; archived = false }
                    }
                } else {
                    if [.mostWorn, .leastWorn, .lastWorn].contains(sort) {
                        Text("Wear totals include prior estimates. Last worn uses recorded dates; pieces without dated history appear last.")
                            .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }
                    PieceCollectionGrid(pieces: results)
                }
            }.padding(20)
        }.scrollPosition(id: Binding(get: { state.closetPieceAnchor }, set: { state.closetPieceAnchor = $0 }))
    }
    private func refresh() {
        refreshPieces(); state.reloadOutfits(); state.reloadThemes()
        if searchModel == nil, let store = state.store { searchModel = ClosetSearchModel(store: store) }
    }
    private func refreshPieces() {
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            results = try store.pieces(category: category, archived: archived, availability: availability, sort: sort); error = nil
        } catch { self.error = "Your saved collection couldn’t be read. Its data is retained; retry." }
    }
    private func performAdd() {
        let action = pendingAdd; pendingAdd = nil
        switch action { case .piece: state.addPiece(); case .outfit: state.buildOutfit(); case .theme: state.openTheme(); case nil: break }
    }
}

struct PieceThumbnail: View {
    @Environment(AppState.self) private var state
    let photoID: UUID
    var recipe: PhotoEditRecipe = .fit
    @State private var image: UIImage?

    private struct Request: Equatable {
        let id: UUID
        let recipe: PhotoEditRecipe
    }

    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFit() }
            else { Image(systemName: "photo").foregroundStyle(AppTheme.secondary).accessibilityLabel("Photo unavailable") }
        }
        .background(AppTheme.imageGround)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .task(id: Request(id: photoID, recipe: recipe)) {
            if let data = try? state.store?.photoThumbnail(id: photoID, recipe: recipe) { image = UIImage(data: data) }
            else { image = nil }
        }
    }
}

/// A bounded public UIKit menu preserves a measurable native button target.
/// SwiftUI's custom toolbar Menu label exposes nested, non-hittable button nodes
/// on iOS 18; UIKit owns menu presentation, source anchoring and accessibility.
private struct PieceOptionsButton: UIViewRepresentable {
    let isArchived: Bool
    let archiveDisabled: Bool
    let archive: () -> Void
    let delete: () -> Void
    let availability: () -> Void

    final class TargetButton: UIButton {
        override var intrinsicContentSize: CGSize { CGSize(width: 48, height: 44) }
    }

    func makeUIView(context: Context) -> TargetButton {
        let button = TargetButton(type: .system)
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 22), forImageIn: .normal)
        button.accessibilityLabel = "More piece options"
        button.showsMenuAsPrimaryAction = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .vertical)
        return button
    }

    func updateUIView(_ button: TargetButton, context: Context) {
        button.tintColor = UIColor(AppTheme.ink)
        let archiveAction = UIAction(title: isArchived ? "Restore" : "Archive",
                                     image: UIImage(systemName: isArchived ? "arrow.uturn.backward" : "archivebox"),
                                     attributes: archiveDisabled ? .disabled : []) { _ in archive() }
        let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"),
                                    attributes: .destructive) { _ in delete() }
        let destructiveGroup = UIMenu(options: .displayInline, children: [deleteAction])
        let availabilityAction = UIAction(title: "Availability", image: UIImage(systemName: "checkmark.circle"),
                                          attributes: archiveDisabled ? .disabled : []) { _ in availability() }
        button.menu = UIMenu(children: [availabilityAction, archiveAction, destructiveGroup])
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: TargetButton, context: Context) -> CGSize? {
        uiView.intrinsicContentSize
    }
}

struct PieceDetailView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let id: UUID
    @State private var piece: WardrobePiece?
    @State private var error: String?
    @State private var deleteDecision = false
    @State private var archiveDecision = false
    @State private var archiveOperationID = UUID()
    @State private var undoArchiveRevision: Int?
    @State private var reviewedArchive: WardrobePiece?
    @State private var availabilityPresented = false
    @State private var wear: PieceWearSummary?

    private var deleteInFlight: Bool { deleteDecision }

    var body: some View {
        ScrollView {
            if let piece {
                VStack(alignment: .leading, spacing: 24) {
                    PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe).frame(maxWidth: .infinity).frame(height: 300)
                    Text(piece.name).font(.title2.weight(.medium))
                    Text(piece.category.rawValue).foregroundStyle(AppTheme.secondary)
                    if !piece.details.color.isEmpty { detail("Color", piece.details.color) }
                    if !piece.details.brand.isEmpty { detail("Brand", piece.details.brand) }
                    if !piece.details.size.isEmpty { detail("Size", piece.details.size) }
                    if !piece.details.fit.isEmpty { detail("Fit", piece.details.fit) }
                    if !piece.details.material.isEmpty { detail("Material", piece.details.material) }
                    if !piece.details.season.isEmpty { detail("Season", piece.details.season) }
                    if !piece.details.condition.isEmpty { detail("Condition", piece.details.condition) }
                    if !piece.details.ownershipAge.isEmpty { detail("Ownership", piece.details.ownershipAge) }
                    if !piece.details.tags.isEmpty { detail("Tags", piece.details.tags.joined(separator: ", ")) }
                    detail("Availability", piece.availability == .laundry ? "In the laundry" : piece.availability.rawValue.capitalized)
                    if let wear {
                        detail("Recorded wears", String(wear.recorded))
                        detail("Last worn", wear.lastWorn?.key ?? "No recorded history")
                        NavigationLink("Wear history") { LocalWearHistoryView(pieceID: piece.id) }.frame(minHeight: 44)
                    }
                    if !piece.isArchived && piece.availability == .available {
                        PrimaryAction(title: "Style this") { state.buildOutfit(pieceID: piece.id, suggest: true) }
                            .disabled(deleteInFlight)
                    }
                    SecondaryAction(title: "Edit piece") { state.editPiece(piece) }.disabled(deleteInFlight)
                    if !piece.details.notes.isEmpty { detail("Notes", piece.details.notes) }
                    if let estimate = piece.details.priorWearCount {
                        detail("Prior wear estimate", String(estimate))
                        Text("This is an estimate, not recorded wear.").font(.footnote).foregroundStyle(AppTheme.secondary)
                    }
                    if piece.isArchived { Text("Archived").font(.subheadline) }
                    if let revision = undoArchiveRevision {
                        Button("Undo archive") { setArchive(false, expectedRevision: revision, operation: UUID()) }
                            .frame(minHeight: 44).disabled(deleteInFlight)
                    }
                    if let error {
                        Text(error).foregroundStyle(AppTheme.error)
                    }
                }.padding(20)
            } else {
                ContentUnavailableView("Piece unavailable", systemImage: "tshirt", description: Text(error ?? "The record is no longer here."))
            }
        }
        .background(AppTheme.canvas)
        .navigationTitle("Piece").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let piece {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { state.editPiece(piece) } label: { Label("Edit piece", systemImage: "square.and.pencil") }
                        .tint(AppTheme.ink).accessibilityIdentifier("piece.edit")
                        .disabled(deleteInFlight)
                }
                optionsToolbar(for: piece)
            }
        }
        .sheet(isPresented: $availabilityPresented) {
            if let piece { PieceAvailabilityView(piece: piece) }
        }
        .onAppear(perform: refresh)
        .onChange(of: state.collectionRefreshID) { refresh() }
        .sheet(isPresented: $deleteDecision) {
            if let piece { PieceDeletionView(piece: piece) { deleteDecision = false; dismiss() } }
        }
        .confirmationDialog("Archive \(reviewedArchive?.name ?? "this piece")?", isPresented: $archiveDecision, titleVisibility: .visible) {
            Button("Archive") {
                if let reviewedArchive { setArchive(true, expectedRevision: reviewedArchive.revision, operation: archiveOperationID) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("The piece keeps its identity and can be restored.") }
    }

    @ToolbarContentBuilder
    private func optionsToolbar(for piece: WardrobePiece) -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarTrailing) {
                optionsButton(for: piece)
            }
            // The automatic shared background clips custom menu content to a
            // 36pt host on iOS26. Opt out using the public toolbar API so the
            // native UIButton's 48×44 bounds also remain reachable by touch.
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                optionsButton(for: piece)
            }
        }
    }

    private func optionsButton(for piece: WardrobePiece) -> some View {
        PieceOptionsButton(isArchived: piece.isArchived, archiveDisabled: deleteInFlight) {
            if piece.isArchived {
                setArchive(false, expectedRevision: piece.revision, operation: UUID())
            } else {
                archiveOperationID = UUID(); reviewedArchive = piece; archiveDecision = true
            }
        } delete: { deleteDecision = true } availability: { availabilityPresented = true }
        .frame(width: 48, height: 44)
    }

    private func detail(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline).foregroundStyle(AppTheme.secondary)
            Text(value)
        }
    }

    private func refresh() {
        do {
            piece = try state.store?.piece(id: id)
            if let piece, let store = state.store { wear = PieceWearSummary(piece: piece, records: try store.wearRecords()) }
        }
        catch { self.error = "The saved piece couldn’t be read. Its data has not been replaced." }
    }

    private func setArchive(_ value: Bool, expectedRevision: Int, operation: UUID) {
        guard !deleteInFlight else {
            error = "Reconcile the reviewed deletion before changing this piece."
            return
        }
        do {
            try state.store?.setArchived(id: id, archived: value, expectedRevision: expectedRevision, operationID: operation)
            state.reloadPieces()
            refresh()
            undoArchiveRevision = value ? piece?.revision : nil
            error = nil
        } catch { self.error = "The piece wasn’t changed. Reopen the latest record and retry." }
    }

}
