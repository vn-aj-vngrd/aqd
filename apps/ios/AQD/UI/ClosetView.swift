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
    @State private var favoritesOnly = false
    @State private var themeID: UUID?
    @State private var searchFavoritesOnly = false
    @State private var searchThemeID: UUID?
    @State private var themeQuery = ThemeCollectionQuery()
    @State private var searchThemeQuery = ThemeCollectionQuery()
    @State private var searchModel: ClosetSearchModel?

    private var scope: String { state.closetSearchActive ? state.closetSearchScope : state.closetScope }
    private var searchInput: ClosetSearchInput {
        ClosetSearchInput(query: state.closetSearchQuery, scope: ClosetSearchScope(rawValue: state.closetSearchScope) ?? .pieces,
                          favoritesOnly: searchFavoritesOnly, themeID: searchThemeID, themeQuery: searchThemeQuery)
    }

    var body: some View {
        @Bindable var state = state
        NavigationStack(path: $state.closetPath) {
            VStack(spacing: 0) {
                scopePicker.padding(.horizontal, 20).padding(.bottom, 12)
                if state.closetSearchActive {
                    ClosetSearchContent(model: searchModel, input: searchInput,
                                        clear: { state.closetSearchQuery = "" },
                                        browse: { state.closetSearchActive = false },
                                        addPiece: { state.addPiece() },
                                        clearFilters: scope == "Themes" && searchThemeQuery.content != .all ? { searchThemeQuery = ThemeCollectionQuery() } : nil)
                } else if scope == "Pieces" {
                    pieceCollection
                } else if scope == "Outfits" {
                    OutfitCollectionView(favoritesOnly: favoritesOnly, themeID: themeID, clearFilters: { favoritesOnly = false; themeID = nil }, summary: collectionSummary)
                } else { ThemeCollectionView(query: themeQuery, clearFilters: { themeQuery = ThemeCollectionQuery() }, summary: collectionSummary) }
            }
            .padding(.top, AppSpacing.large)
            .background(AppTheme.canvas)
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !state.closetSearchActive {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { state.closetSearchActive = true } label: { Label("Search closet", systemImage: "magnifyingglass") }
                            .tint(AppTheme.ink).accessibilityIdentifier("closet.search")
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button("Add a piece", systemImage: "tshirt") { state.addPiece() }
                            Button("Build an outfit", systemImage: "square.stack") { state.buildOutfit() }
                            Button("Create a theme", systemImage: "folder") { state.openTheme() }
                        } label: { Label("Add to closet", systemImage: "plus") }
                            .tint(AppTheme.ink).accessibilityIdentifier("closet.addPiece")
                    }
                }
                if scope == "Pieces", !state.closetSearchActive { pieceFilterMenu }
                if scope == "Outfits" { outfitFilterMenu }
                if scope == "Themes" { themeFilterMenu }
            }
            .modifier(ClosetSearchField(query: $state.closetSearchQuery, active: $state.closetSearchActive,
                                        prompt: "Search your \(scope.lowercased())"))
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
            ClosetScopeControl(selection: scopeSelection)
        }
    }
    private var themeFilterMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Contents", selection: state.closetSearchActive ? $searchThemeQuery.content : $themeQuery.content) {
                    ForEach(ThemeCollectionQuery.Content.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Picker("Sort themes", selection: state.closetSearchActive ? $searchThemeQuery.sort : $themeQuery.sort) {
                    ForEach(ThemeCollectionQuery.Sort.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Button("Clear filters") {
                    if state.closetSearchActive { searchThemeQuery = ThemeCollectionQuery() }
                    else { themeQuery = ThemeCollectionQuery() }
                }
            } label: { Label("Filter and sort themes", systemImage: "line.3.horizontal.decrease") }
            .tint(AppTheme.ink).accessibilityIdentifier("closet.themes.filter")
            .accessibilityValue((state.closetSearchActive ? searchThemeQuery : themeQuery).content.rawValue)
        }
    }
    private var collectionSummary: ClosetCollectionSummary {
        let summary = collectionSummaryData
        return ClosetCollectionSummary(title: summary.title, order: summary.order)
    }
    private var collectionSummaryData: (title: String, order: String) {
        func count(_ value: Int, _ singular: String, _ plural: String) -> String { "\(value) \(value == 1 ? singular : plural)" }
        switch scope {
        case "Pieces":
            guard error == nil else { return ("Pieces unavailable", "") }
            return (count(results.count, "piece", "pieces"), sort.title)
        case "Outfits":
            guard state.outfitError == nil && state.themeError == nil else { return ("Outfits unavailable", "") }
            let outfits = state.outfits.filter { outfit in
                (!favoritesOnly || outfit.isFavorite) && (themeID == nil || state.themes.contains { $0.id == themeID && $0.outfitIDs.contains(outfit.id) })
            }
            return (count(outfits.count, "outfit", "outfits"), "Recently updated")
        default:
            guard state.themeError == nil else { return ("Themes unavailable", "") }
            return (count(themeQuery.apply(to: state.themes).count, "theme", "themes"), themeQuery.sort.rawValue)
        }
    }
    private var outfitFilterMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Toggle("Favorites", isOn: state.closetSearchActive ? $searchFavoritesOnly : $favoritesOnly)
                Picker("Theme", selection: state.closetSearchActive ? $searchThemeID : $themeID) {
                    Text("All themes").tag(Optional<UUID>.none)
                    ForEach(state.themes) { Text($0.name).tag(Optional($0.id)) }
                    if let selectedID = state.closetSearchActive ? searchThemeID : themeID,
                       !state.themes.contains(where: { $0.id == selectedID }) {
                        Text("Unavailable theme").tag(Optional(selectedID))
                    }
                }
            } label: { Label("Filter outfits", systemImage: "line.3.horizontal.decrease") }
            .tint(AppTheme.ink)
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
    @ViewBuilder private var pieceCollection: some View {
        if error == nil && results.isEmpty {
            EmptyStatePage(title: archived ? "No archived pieces" : category == nil && availability == nil ? "Your closet starts here" : "No matching pieces",
                           systemImage: "tshirt",
                           description: Text(category == nil && availability == nil ? "Add a photo and a few details. Everything stays on this device." : "Try another category or clear the filters.")) {
                if category == nil && availability == nil && !archived {
                    PrimaryAction(title: "Add piece") { state.addPiece() }
                } else {
                    PrimaryAction(title: "Clear filters") { category = nil; availability = nil; archived = false }
                }
            }
        } else {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                collectionSummary
                if let error {
                    SemanticFeedback(role: .danger, message: error)
                    Button("Retry", action: refreshPieces).frame(minHeight: 44)
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
    let edit: () -> Void
    let archive: () -> Void
    let delete: () -> Void
    let availability: () -> Void

    final class TargetButton: UIButton {
        override var intrinsicContentSize: CGSize { CGSize(width: 48, height: 44) }
    }

    func makeUIView(context: Context) -> TargetButton {
        let button = TargetButton(type: .system)
        if #available(iOS 26.0, *) {
            button.configuration = .glass()
        }
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
        let editAction = UIAction(title: "Edit piece", image: UIImage(systemName: "square.and.pencil"),
                                  attributes: archiveDisabled ? .disabled : []) { _ in edit() }
        let archiveAction = UIAction(title: isArchived ? "Restore" : "Archive",
                                     image: UIImage(systemName: isArchived ? "arrow.uturn.backward" : "archivebox"),
                                     attributes: archiveDisabled ? .disabled : []) { _ in archive() }
        let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"),
                                    attributes: .destructive) { _ in delete() }
        let destructiveGroup = UIMenu(options: .displayInline, children: [deleteAction])
        let availabilityAction = UIAction(title: "Availability", image: UIImage(systemName: "checkmark.circle"),
                                          attributes: archiveDisabled ? .disabled : []) { _ in availability() }
        button.menu = UIMenu(children: [editAction, availabilityAction, archiveAction, destructiveGroup])
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
    @State private var photoPresented = false

    private var deleteInFlight: Bool { deleteDecision }

    var body: some View {
        ScrollView {
            if let piece {
                VStack(alignment: .leading, spacing: 24) {
                    Button { photoPresented = true } label: {
                        PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                            .frame(maxWidth: .infinity).frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo))
                            .padding(AppSpacing.medium)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View photo of \(piece.name) full screen")
                    .accessibilityHint("Opens a zoomable photo viewer")
                    .accessibilityIdentifier("piece.photo.fullScreen")
                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text(piece.name).font(AppTypography.section)
                            Text(piece.category.rawValue).foregroundStyle(AppTheme.secondary)
                        }
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
                        if !piece.details.notes.isEmpty { detail("Notes", piece.details.notes) }
                        if let estimate = piece.details.priorWearCount {
                            detail("Prior wear estimate", String(estimate))
                            Text("This is an estimate, not recorded wear.").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                        }
                        if piece.isArchived { Text("Archived").font(AppTypography.supporting) }
                    }
                    .padding(AppSpacing.screen).frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
                    if let wear {
                        VStack(alignment: .leading, spacing: AppSpacing.large) {
                            detail("Recorded wears", String(wear.recorded))
                            detail("Last worn", wear.lastWorn?.key ?? "No recorded history")
                            NavigationLink { LocalWearHistoryView(pieceID: piece.id) } label: {
                                HStack {
                                    Text("Wear history")
                                    Spacer()
                                    Image(systemName: "chevron.forward").font(AppTypography.disclosure).accessibilityHidden(true)
                                }.frame(minHeight: AppControlMetrics.minimumTarget).contentShape(Rectangle())
                            }.foregroundStyle(AppTheme.ink)
                        }
                        .padding(AppSpacing.screen).frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
                    }
                    if let revision = undoArchiveRevision {
                        Button("Undo archive") { setArchive(false, expectedRevision: revision, operation: UUID()) }
                            .frame(minHeight: 44).disabled(deleteInFlight)
                    }
                    if let error {
                        Text(error).foregroundStyle(AppTheme.error)
                    }
                }.padding(20)
            } else {
                AppEmptyState("Piece unavailable", systemImage: "tshirt", description: Text(error ?? "The record is no longer here."))
            }
        }
        .background(AppTheme.canvas)
        .navigationTitle("Piece").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let piece {
                if !piece.isArchived && piece.availability == .available {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { state.buildOutfit(pieceID: piece.id, suggest: true) } label: {
                            Label("Style this", systemImage: "sparkles")
                        }
                        .tint(AppTheme.ink).accessibilityIdentifier("piece.style")
                        .disabled(deleteInFlight)
                    }
                }
                optionsToolbar(for: piece)
            }
        }
        .fullScreenCover(isPresented: $photoPresented) {
            if let piece { PiecePhotoViewer(piece: piece) }
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
        PieceOptionsButton(isArchived: piece.isArchived, archiveDisabled: deleteInFlight, edit: {
            state.editPiece(piece)
        }) {
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

/// Read-only full-resolution rendition, isolated from photo-editing draft state.
private struct PiecePhotoViewer: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let piece: WardrobePiece
    @State private var image: UIImage?
    @State private var loaded = false
    @State private var zoom: CGFloat = 1
    @State private var startingZoom: CGFloat = 1

    var body: some View {
        NavigationStack {
            Group {
                if let image {
                    GeometryReader { geometry in
                        ScrollView([.horizontal, .vertical]) {
                            Image(uiImage: image)
                                .resizable().scaledToFit()
                                .frame(width: geometry.size.width * zoom, height: geometry.size.height * zoom)
                                .accessibilityLabel("Photo of \(piece.name)")
                        }
                        .scrollIndicators(.hidden)
                        .simultaneousGesture(MagnifyGesture()
                            .onChanged { zoom = min(5, max(1, startingZoom * $0.magnification)) }
                            .onEnded { _ in startingZoom = zoom })
                    }
                } else if loaded {
                    AppEmptyState("Photo unavailable", systemImage: "photo",
                                  description: Text("The saved photo could not be read. Your piece is unchanged."))
                } else {
                    OperationProgress(title: "Opening photo…")
                }
            }
            .background(AppTheme.canvas)
            .navigationTitle(piece.name).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if image != nil {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button { setZoom(zoom - 1) } label: { Label("Zoom out", systemImage: "minus.magnifyingglass") }
                            .disabled(zoom <= 1)
                        Spacer()
                        Text(Double(zoom).formatted(.percent.precision(.fractionLength(0)))).font(AppTypography.metadata)
                            .accessibilityLabel("Zoom \(Double(zoom).formatted(.percent.precision(.fractionLength(0))))")
                        Spacer()
                        Button { setZoom(zoom + 1) } label: { Label("Zoom in", systemImage: "plus.magnifyingglass") }
                            .disabled(zoom >= 5)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Label("Close photo", systemImage: "xmark") }
                }
            }
        }
        .tint(AppTheme.ink)
        .task {
            if let data = try? state.store?.photoRendition(id: piece.photoID, recipe: piece.photoRecipe) {
                image = UIImage(data: data)
            }
            loaded = true
        }
    }

    private func setZoom(_ value: CGFloat) {
        zoom = min(5, max(1, value))
        startingZoom = zoom
    }
}

/// Search chrome exists only while the owner explicitly opens search.
private struct ClosetSearchField: ViewModifier {
    @Binding var query: String
    @Binding var active: Bool
    let prompt: String

    @ViewBuilder func body(content: Content) -> some View {
        if active {
            content.searchable(text: $query, isPresented: $active,
                               placement: .navigationBarDrawer(displayMode: .always), prompt: prompt)
        } else {
            content
        }
    }
}

private struct ClosetScopeControl: View {
    @Binding var selection: String
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Namespace private var selectedSegment
    private let scopes = ClosetSearchScope.allCases.map(\.rawValue)

    var body: some View {
        Group {
            if #available(iOS 26, *), !reduceTransparency, contrast != .increased {
                segments.glassEffect(.regular, in: Capsule())
            } else {
                segments.background(AppTheme.surface, in: Capsule())
                    .overlay(Capsule().stroke(contrast == .increased ? AppTheme.controlBoundary : AppTheme.divider, lineWidth: 1))
            }
        }.accessibilityElement(children: .contain).accessibilityLabel("Closet collection")
    }
    private var segments: some View {
        HStack(spacing: 0) {
            ForEach(scopes, id: \.self) { scope in
                Button { selection = scope } label: {
                    Text(scope).font(AppTypography.supporting).fontWeight(selection == scope ? .semibold : .regular)
                        .foregroundStyle(AppTheme.ink).frame(maxWidth: .infinity, minHeight: 44)
                        .background {
                            if selection == scope {
                                Capsule().fill(AppTheme.segmentSelection)
                                    .matchedGeometryEffect(id: "selected", in: selectedSegment)
                            }
                        }.contentShape(Capsule())
                }.buttonStyle(.plain)
                    .accessibilityAddTraits(selection == scope ? [.isSelected] : [])
                    .accessibilityIdentifier("closet.scope.\(scope.lowercased())")
            }
        }.padding(4).animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: selection)
    }
}

struct ClosetCollectionSummary: View {
    let title: String
    let order: String
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if typeSize.isAccessibilitySize {
                Text(title).font(AppTypography.fieldLabel).foregroundStyle(AppTheme.ink)
                if !order.isEmpty { Text(order).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary) }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(title).font(AppTypography.fieldLabel).foregroundStyle(AppTheme.ink)
                    Spacer(minLength: 12)
                    if !order.isEmpty { Text(order).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary) }
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine).accessibilityIdentifier("closet.collection.summary")
    }
}
