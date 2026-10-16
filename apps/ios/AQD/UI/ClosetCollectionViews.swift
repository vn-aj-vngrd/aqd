import AQDCore
import SwiftUI

struct PieceCollectionGrid: View {
    let pieces: [WardrobePiece]
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2), alignment: .leading, spacing: 24) {
            ForEach(pieces) { piece in
                NavigationLink(value: ClosetRoute.piece(piece.id)) {
                    VStack(alignment: .leading, spacing: 8) {
                        PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe).frame(height: 134)
                        Text(piece.name).font(AppTypography.fieldLabel).foregroundStyle(AppTheme.ink)
                        Text([piece.category.rawValue, piece.details.color].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                        if piece.isArchived { Text("Archived").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary) }
                        if piece.availability != .available { Text(piece.availability.rawValue.capitalized).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary) }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(.plain).id(piece.id)
            }
        }.scrollTargetLayout()
    }
}

enum ClosetAddAction: String, CaseIterable { case piece = "Add a piece", outfit = "Build an outfit", theme = "Create a theme" }
struct ClosetAddSheet: View {
    let select: (ClosetAddAction) -> Void
    var body: some View {
        NativeChoiceSheet(title: "Add to closet") {
            ForEach(ClosetAddAction.allCases, id: \.self) { action in
                NativeChoiceRow(title: action.rawValue,
                                symbol: action == .piece ? "tshirt" : action == .outfit ? "square.stack" : "folder") {
                    select(action)
                }
            }
        }
    }
}

struct OutfitCollectionCard: View {
    @Environment(AppState.self) private var state
    let outfit: Outfit
    var body: some View {
        NavigationLink(value: ClosetRoute.outfit(outfit.id)) {
            VStack(alignment: .leading, spacing: 12) {
                OutfitComposition(pieceIDs: outfit.pieceIDs)
                HStack {
                    Text(outfit.name).font(AppTypography.section)
                    if outfit.isFavorite { Image(systemName: "heart.fill").foregroundStyle(AppTheme.actionText).accessibilityLabel("Favorite") }
                }.foregroundStyle(AppTheme.ink)
                let memberships = state.themes.filter { $0.outfitIDs.contains(outfit.id) }.map(\.name)
                Text((["\(outfit.pieceIDs.count) pieces"] + memberships).joined(separator: " · "))
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }
        }.buttonStyle(.plain).id(outfit.id)
    }
}

struct ThemeCollectionView: View {
    @Environment(AppState.self) private var state
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
                    VStack(alignment: .leading, spacing: 12) {
                        if let summary { summary }
                        if let error = state.themeError {
                            SemanticFeedback(role: .danger, message: error)
                            Button("Retry themes") { state.reloadThemes() }
                        }
                        ForEach(themes) { ThemeCollectionCard(theme: $0) }
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
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Text(theme.name).font(AppTypography.body).foregroundStyle(AppTheme.ink).frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(theme.outfitIDs.count) outfits").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    Image(systemName: "chevron.forward").foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                }.frame(minHeight: 54)
                if !members.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(Array(members.prefix(3))) { OutfitComposition(pieceIDs: $0.pieceIDs, pieceHeight: 30, limit: 4) }
                    }
                    if members.count > 3 { Text("\(members.count - 3) more outfits").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary) }
                }
            }.padding(14).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain).id(theme.id)
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
                    if !theme.description.isEmpty { Text(theme.description) }
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
            .navigationTitle(state.themes.first { $0.id == id }?.name ?? "Theme").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let theme = state.themes.first(where: { $0.id == id }) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Edit theme", systemImage: "square.and.pencil") { state.openTheme(editing: theme) }
                            Button("Add outfits", systemImage: "plus") { state.openTheme(editing: theme, chooseOutfits: true) }
                            Button("Build an outfit", systemImage: "square.stack") { state.buildOutfit(themeID: theme.id) }
                            Button("Suggest an outfit", systemImage: "sparkles") { state.buildOutfit(suggest: true, themeID: theme.id) }
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
