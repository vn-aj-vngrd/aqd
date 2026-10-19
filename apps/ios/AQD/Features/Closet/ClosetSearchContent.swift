import AQDCore
import SwiftUI

struct ClosetSearchContent: View {
    let model: ClosetSearchModel?
    let input: ClosetSearchInput
    @State private var pieceAnchor: UUID?
    @State private var outfitAnchor: UUID?
    @State private var themeAnchor: UUID?

    var body: some View {
        if let model {
            Group {
                if model.error == nil && input.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    EmptyStatePage(title: model.closetEmpty ? "Your closet starts here" : "Search your closet",
                                   systemImage: model.closetEmpty ? "tshirt" : "magnifyingglass",
                                   description: Text(model.closetEmpty ? "Add a piece to find it here later." : "Find your pieces, outfits and themes."))
                } else if model.error == nil && !model.loading && model.results?.isEmpty == true {
                    EmptyStatePage(title: "No matches", systemImage: "magnifyingglass",
                                   description: Text("No \(input.scope.rawValue.lowercased()) match “\(input.query)”. Try another search or clear the filters."))
                } else if model.error == nil && model.loading && model.results == nil {
                    LoadingStatePage(title: "Searching your closet",
                                     description: Text("Looking through your \(input.scope.rawValue.lowercased())."))
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if let error = model.error {
                                SemanticFeedback(role: .danger, message: error)
                                PrimaryAction(title: "Retry search", systemImage: "arrow.clockwise", fitsContent: true) { Task { await model.search(input, debounce: false) } }
                            }
                            if let results = model.results {
                                HStack(spacing: AppSpacing.small) {
                                    Text("\(results.count) results").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                                    if model.loading { ProgressView().controlSize(.small).tint(AppTheme.ink).accessibilityLabel("Updating results") }
                                }
                                switch results {
                                case .pieces(let pieces): PieceCollectionGrid(pieces: pieces)
                                case .outfits(let outfits):
                                    LazyVStack(spacing: 24) { ForEach(outfits) { OutfitCollectionCard(outfit: $0) } }.scrollTargetLayout()
                                case .themes(let themes):
                                    LazyVStack(spacing: 12) { ForEach(themes) { ThemeCollectionCard(theme: $0) } }.scrollTargetLayout()
                                }
                            }
                        }.padding(20)
                    }.scrollPosition(id: anchor)
                }
            }
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
}
