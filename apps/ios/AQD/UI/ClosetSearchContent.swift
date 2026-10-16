import AQDCore
import SwiftUI

struct ClosetSearchContent: View {
    let model: ClosetSearchModel?
    let input: ClosetSearchInput
    let clear: () -> Void
    let browse: () -> Void
    let addPiece: () -> Void
    @State private var pieceAnchor: UUID?
    @State private var outfitAnchor: UUID?
    @State private var themeAnchor: UUID?

    var body: some View {
        if let model {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let error = model.error {
                        SemanticFeedback(role: .danger, message: error)
                        PrimaryAction(title: "Retry search") { Task { await model.search(input, debounce: false) } }
                    }
                    if input.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && model.error == nil {
                        if model.closetEmpty {
                            AppEmptyState("Your closet starts here", systemImage: "tshirt", description: Text("Add a piece to find it here later."))
                            PrimaryAction(title: "Add a piece", action: addPiece)
                        } else {
                            AppEmptyState("Search your closet", systemImage: "magnifyingglass", description: Text("Find your pieces, outfits and themes."))
                            PrimaryAction(title: "Browse closet", action: browse)
                        }
                    } else if model.loading && model.results == nil {
                        ProgressView("Searching your closet…").tint(AppTheme.actionText)
                        searchSkeleton
                    } else if let results = model.results {
                        if model.loading { ProgressView("Updating results…").tint(AppTheme.actionText) }
                        if results.count == 0 && model.error == nil {
                            AppEmptyState("No matches", systemImage: "magnifyingglass", description: Text("No \(input.scope.rawValue.lowercased()) match “\(input.query)”. Try another search or clear the filters."))
                            PrimaryAction(title: "Clear search", action: clear)
                            SecondaryAction(title: "Add a piece", action: addPiece)
                        } else {
                            Text("\(results.count) results").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            switch results {
                            case .pieces(let pieces): PieceCollectionGrid(pieces: pieces)
                            case .outfits(let outfits):
                                LazyVStack(spacing: 24) { ForEach(outfits) { OutfitCollectionCard(outfit: $0) } }.scrollTargetLayout()
                            case .themes(let themes):
                                LazyVStack(spacing: 12) { ForEach(themes) { ThemeCollectionCard(theme: $0) } }.scrollTargetLayout()
                            }
                        }
                    }
                }.padding(20)
            }
            .scrollPosition(id: anchor)
            .task(id: input) { await model.search(input) }
            .onSubmit(of: .search) { Task { await model.search(input, debounce: false) } }
            .onChange(of: input.query) { pieceAnchor = nil; outfitAnchor = nil; themeAnchor = nil }
        } else {
            SemanticFeedback(role: .danger, message: "Search can’t open until the saved closet is available.").padding(20)
        }
    }
    private var anchor: Binding<UUID?> {
        switch input.scope { case .pieces: $pieceAnchor; case .outfits: $outfitAnchor; case .themes: $themeAnchor }
    }
    private var searchSkeleton: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4).fill(AppTheme.surface).frame(height: 134)
                if input.scope == .pieces { RoundedRectangle(cornerRadius: 4).fill(AppTheme.surface).frame(height: 134) }
            }
            RoundedRectangle(cornerRadius: 4).fill(AppTheme.surface).frame(height: 20)
        }.accessibilityHidden(true)
    }
}
