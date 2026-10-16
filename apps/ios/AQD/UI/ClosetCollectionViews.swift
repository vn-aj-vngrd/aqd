import AQDCore
import SwiftUI

struct PieceCollectionGrid: View {
    @Environment(AppState.self) private var state
    let pieces: [WardrobePiece]
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2), alignment: .leading, spacing: 16) {
            ForEach(pieces) { piece in
                NavigationLink(value: ClosetRoute.piece(piece.id)) {
                    ClosetCard(title: piece.displayName, detail: [state.categoryName(for: piece), piece.details.color,
                        piece.isArchived ? "Archived" : ""]
                        .filter { !$0.isEmpty }.joined(separator: " · ")) {
                        PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                            .frame(maxWidth: .infinity).frame(height: 134).clipped()
                            .overlay(alignment: .topTrailing) { PieceAvailabilityBadge(piece: piece) }
                    }
                }.buttonStyle(.plain).id(piece.id)
                    .contextMenu {
                        NavigationLink(value: ClosetRoute.piece(piece.id)) { AccessoryLabel("Open piece", systemImage: "arrow.up.forward.square") }
                        AccessoryButton("Edit piece", systemImage: "square.and.pencil") { state.editPiece(piece) }
                        AccessoryButton("Build an outfit", systemImage: "square.stack") { state.buildOutfit(pieceID: piece.id) }
                            .disabled(piece.isArchived || piece.availability != .available)
                    } preview: {
                        CollectionContextPreview(title: piece.displayName, detail: state.categoryName(for: piece)) {
                            PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                                .frame(height: 300).clipped()
                        }.environment(state)
                    }
            }
        }.scrollTargetLayout()
    }
}

struct PieceAvailabilityBadge: View {
    let piece: WardrobePiece
    private var symbol: String {
        if piece.isArchived { return "archivebox" }
        switch piece.availability {
        case .available: return "checkmark"
        case .unavailable: return "xmark"
        case .laundry: return "washer"
        }
    }
    private var tint: Color {
        if piece.isArchived { return AppTheme.secondary }
        switch piece.availability {
        case .available: return AppTheme.success
        case .unavailable: return AppTheme.error
        case .laundry: return AppTheme.information
        }
    }
    var body: some View {
        Image(systemName: symbol).font(.system(size: 11, weight: .semibold)).foregroundStyle(tint)
            .frame(width: 24, height: 24).background(AppTheme.surface, in: Circle())
            .accessibilityLabel(piece.isArchived ? "Archived" : piece.availability.rawValue.capitalized)
    }
}

/// Collection previews stay bounded; saved outfits keep every selected piece.
struct CollectionArtwork: View {
    @Environment(AppState.self) private var state
    let pieceIDs: [UUID]
    var badge: String? = nil
    var height: CGFloat = 134
    private var shown: [UUID] { Array(pieceIDs.prefix(4)) }
    var body: some View {
        GeometryReader { geometry in
            let columns = shown.count == 1 ? 1 : 2
            let rows = max(1, (shown.count + columns - 1) / columns)
            let height = max(0, (geometry.size.height - CGFloat(rows - 1) * 6) / CGFloat(rows))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: columns), spacing: 6) {
                ForEach(shown, id: \.self) { id in
                    if let piece = state.ownedPieces.first(where: { $0.id == id }) {
                        PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                            .frame(maxWidth: .infinity).frame(height: height).clipped()
                            .accessibilityLabel(piece.displayName)
                    } else {
                        Image(systemName: "tshirt").foregroundStyle(AppTheme.secondary)
                            .frame(maxWidth: .infinity).frame(height: height).accessibilityLabel("Piece unavailable")
                    }
                }
            }
            if shown.isEmpty {
                Image(systemName: "folder").font(.title2).foregroundStyle(AppTheme.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity).accessibilityLabel("Empty theme")
            }
        }
        .frame(height: height).clipped()
        .overlay(alignment: .bottomTrailing) {
            if let text = badge ?? (pieceIDs.count > 4 ? "+\(pieceIDs.count - 4) more" : nil) {
                Text(text).font(AppTypography.metadata).lineLimit(1).truncationMode(.tail)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(AppTheme.surface, in: Capsule()).padding(4)
                    .accessibilityLabel(text)
            }
        }
    }
}

struct ClosetCard<Artwork: View>: View {
    let title: String
    let detail: String
    var favorite = false
    @ViewBuilder var artwork: () -> Artwork
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            artwork().padding(8).background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: 10)).padding(8)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(title).font(AppTypography.fieldLabel).lineLimit(1).truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if favorite { Image(systemName: "heart.fill").font(AppTypography.metadata).foregroundStyle(AppTheme.ink).accessibilityLabel("Favorite") }
                }.foregroundStyle(AppTheme.ink)
                Text(detail).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).lineLimit(1).truncationMode(.tail)
            }.padding(.horizontal, 12).padding(.top, 4).padding(.bottom, 12)
        }.frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct OutfitCollectionCard: View {
    @Environment(AppState.self) private var state
    let outfit: Outfit
    var body: some View {
        NavigationLink(value: ClosetRoute.outfit(outfit.id)) {
            let memberships = state.themes.filter { $0.outfitIDs.contains(outfit.id) }.map(\.displayName)
            ClosetCard(title: outfit.displayName, detail: (["\(outfit.pieceIDs.count) pieces"] + memberships).joined(separator: " · "), favorite: outfit.isFavorite) {
                CollectionArtwork(pieceIDs: outfit.pieceIDs)
            }
        }.buttonStyle(.plain).id(outfit.id)
            .contextMenu {
                NavigationLink(value: ClosetRoute.outfit(outfit.id)) { AccessoryLabel("Open outfit", systemImage: "arrow.up.forward.square") }
                AccessoryButton("Edit outfit", systemImage: "square.and.pencil") { state.buildOutfit(editing: outfit) }
                AccessoryButton("Plan outfit", systemImage: "calendar") { state.openPlan(outfitID: outfit.id) }
                AccessoryButton("Record wear", systemImage: "checkmark.circle") { state.openWear(outfitID: outfit.id) }
            } preview: {
                CollectionContextPreview(title: outfit.displayName, detail: "\(outfit.pieceIDs.count) pieces") {
                    CollectionArtwork(pieceIDs: outfit.pieceIDs, height: 300)
                }.environment(state)
            }
    }
}

struct ThemeCollectionView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dynamicTypeSize) private var typeSize
    var query = ThemeCollectionQuery()
    var clearFilters: () -> Void = {}
    private var themes: [OutfitTheme] { query.apply(to: state.themes) }
    var summary: ClosetCollectionSummary? = nil
    var body: some View {
        Group {
            if state.themeError == nil && themes.isEmpty {
                EmptyStatePage(title: state.themes.isEmpty ? "Make a little collection" : "No matching themes", systemImage: "folder",
                               description: Text(state.themes.isEmpty ? "Keep outfits together by mood or occasion. A theme can start empty." : "Try another content filter to see your other themes.")) {
                    if state.themes.isEmpty { PrimaryAction(title: "Create theme") { state.openTheme() } }
                    else { PrimaryAction(title: "Clear filters", action: clearFilters) }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        if let summary { summary }
                        if let error = state.themeError {
                            SemanticFeedback(role: .danger, message: error)
                            Button("Retry themes") { state.reloadThemes() }
                        }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 16) {
                            ForEach(themes) { ThemeCollectionCard(theme: $0) }
                        }.scrollTargetLayout()
                    }.padding(20).scrollTargetLayout()
                }.scrollPosition(id: Binding(get: { state.closetThemeAnchor }, set: { state.closetThemeAnchor = $0 }))
            }
        }.onAppear { state.reloadThemes() }
    }
}

struct ThemeCollectionCard: View {
    @Environment(AppState.self) private var state
    let theme: OutfitTheme
    private var members: [Outfit] { state.outfits.filter { theme.outfitIDs.contains($0.id) } }
    var body: some View {
        NavigationLink(value: ClosetRoute.theme(theme.id)) {
            ClosetCard(title: theme.displayName, detail: "\(theme.outfitIDs.count) outfits") {
                CollectionArtwork(pieceIDs: members.first?.pieceIDs ?? [], badge: members.count > 1 ? "+\(members.count - 1) outfits" : nil)
            }
        }.buttonStyle(.plain).id(theme.id)
            .contextMenu {
                NavigationLink(value: ClosetRoute.theme(theme.id)) { AccessoryLabel("Open theme", systemImage: "folder") }
                AccessoryButton("Edit theme", systemImage: "square.and.pencil") { state.openTheme(editing: theme) }
                AccessoryButton("Add outfits", systemImage: "plus") { state.openTheme(editing: theme, chooseOutfits: true) }
                AccessoryButton("Build an outfit", systemImage: "square.stack") { state.buildOutfit(themeID: theme.id) }
            } preview: {
                CollectionContextPreview(title: theme.displayName, detail: "\(theme.outfitIDs.count) outfits") {
                    CollectionArtwork(pieceIDs: members.first?.pieceIDs ?? [], badge: members.count > 1 ? "+\(members.count - 1) outfits" : nil, height: 300)
                }.environment(state)
            }
    }
}

struct ThemeDetailView: View {
    @Environment(AppState.self) private var state
    let id: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var deletion: ThemeDeletionRequest?
    @State private var confirming = false
    @State private var submitted = false
    @State private var error: String?
    var body: some View {
        ScrollView {
            if let error {
                SemanticFeedback(role: .danger, message: error).padding(.horizontal, 20)
                if submitted { Button("Retry reviewed deletion", action: remove).frame(minHeight: 44) }
            }
            if let theme = state.themes.first(where: { $0.id == id }) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("\(theme.outfitIDs.count) outfits · Private theme").foregroundStyle(AppTheme.secondary)
                    if !theme.description.isEmpty { Text(theme.displayDescription) }
                    if let error = state.outfitError {
                        SemanticFeedback(role: .danger, message: error)
                        Button("Retry outfits") { state.reloadOutfits() }
                    } else if theme.outfitIDs.isEmpty {
                        AppEmptyState("Room for your outfits", systemImage: "square.stack", description: Text("Add saved outfits to this theme. Your other themes stay independent."), fillsAvailableSpace: false)
                        PrimaryAction(title: "Add outfits") { state.openTheme(editing: theme, chooseOutfits: true) }
                    }
                    ForEach(state.outfits.filter { theme.outfitIDs.contains($0.id) }) { OutfitCollectionCard(outfit: $0) }
                }.padding(20)
            } else { AppEmptyState("Theme unavailable", systemImage: "folder", description: Text("The theme is no longer in this closet.")) }
        }.background(AppTheme.canvas)
            .navigationTitle(state.themes.first { $0.id == id }?.displayName ?? "Theme").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let theme = state.themes.first(where: { $0.id == id }) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            AccessoryButton("Edit theme", systemImage: "square.and.pencil") { state.openTheme(editing: theme) }
                            AccessoryButton("Add outfits", systemImage: "plus") { state.openTheme(editing: theme, chooseOutfits: true) }
                            AccessoryButton("Build an outfit", systemImage: "square.stack") { state.buildOutfit(themeID: theme.id) }
                            Button("Delete theme", systemImage: "trash", role: .destructive) {
                                deletion = ThemeDeletionRequest(theme: theme); confirming = true
                            }
                        } label: { Label("More theme options", systemImage: "ellipsis") }.tint(AppTheme.ink).disabled(submitted)
                    }
                }
            }.onAppear { state.reloadThemes(); state.reloadOutfits() }
            .confirmationDialog("Delete this theme?", isPresented: $confirming, titleVisibility: .visible) {
                Button("Delete theme", role: .destructive, action: remove)
                Button("Cancel", role: .cancel) { deletion = nil }
            } message: { Text("Removes this theme and its memberships. Your outfits, pieces, favorites and wear history stay.") }
    }
    private func remove() {
        guard let deletion else { return }
        submitted = true
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.deleteTheme(deletion)
            state.reloadThemes(); state.reloadOutfits(); dismiss()
        } catch PieceStore.StoreError.staleRevision {
            submitted = false; self.deletion = nil
            self.error = "This theme changed. Review its latest contents before deleting."
            state.reloadThemes()
        } catch { self.error = "Deletion isn’t acknowledged. Retry this same operation to reconcile it." }
    }
}

/// The system owns the context-menu lift, backdrop and actions; this is its bounded content preview.
struct CollectionContextPreview<Artwork: View>: View {
    let title: String
    let detail: String
    @ViewBuilder var artwork: () -> Artwork
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            artwork().frame(maxWidth: .infinity).background(AppTheme.imageGround)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(AppTypography.section).foregroundStyle(AppTheme.ink).lineLimit(2)
                if !detail.isEmpty { Text(detail).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).lineLimit(2) }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.padding(16).frame(width: 320).background(AppTheme.surface)
    }
}
