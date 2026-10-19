import AQDCore
import SwiftUI

/// Live, tappable collage of the pieces chosen for an outfit draft.
struct OutfitCanvas: View {
    @Environment(AppState.self) private var state
    let pieceIDs: [UUID]
    var isLocked = false
    var remove: (UUID) -> Void

    private static let mainOrder: [PieceCategory] = [.layers, .tops, .dresses, .bottoms]

    private func type(_ id: UUID) -> PieceCategory? { state.ownedPieces.first { $0.id == id }?.category }

    /// Garments read large, in wearing order; shoes and accessories form a smaller strip.
    private var split: (main: [UUID], small: [UUID]) {
        func rank(_ id: UUID) -> Int { type(id).flatMap { Self.mainOrder.firstIndex(of: $0) } ?? Self.mainOrder.count }
        let isSmall: (UUID) -> Bool = { id in type(id) == .shoes || type(id) == .accessories }
        let main = pieceIDs.enumerated().filter { !isSmall($0.element) }
            .sorted { (rank($0.element), $0.offset) < (rank($1.element), $1.offset) }.map(\.element)
        let small = pieceIDs.filter(isSmall)
        return small.count == pieceIDs.count ? (small, []) : (main, small)
    }

    var body: some View {
        Group {
            if pieceIDs.isEmpty {
                VStack(spacing: AppSpacing.small) {
                    Image(systemName: "tshirt").font(.system(size: 36, weight: .light)).accessibilityHidden(true)
                    Text("Tap a piece below to start your look")
                        .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }.foregroundStyle(AppTheme.ink).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let parts = split
                VStack(spacing: AppSpacing.medium) {
                    collage(parts.main)
                    if !parts.small.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(parts.small, id: \.self) { tile($0).frame(maxWidth: 96) }
                        }.frame(height: 92).frame(maxWidth: .infinity)
                    }
                }.padding(AppSpacing.medium)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .animation(.smooth(duration: 0.28), value: pieceIDs)
    }

    @ViewBuilder private func collage(_ ids: [UUID]) -> some View {
        let gap: CGFloat = 8
        switch ids.count {
        case 1:
            tile(ids[0])
        case 2:
            HStack(spacing: gap) { tile(ids[0]); tile(ids[1]) }
        case 3:
            HStack(spacing: gap) {
                tile(ids[0])
                VStack(spacing: gap) { tile(ids[1]); tile(ids[2]) }
            }
        default:
            let columns = ids.count <= 4 ? 2 : 3
            let rows = stride(from: 0, to: ids.count, by: columns).map { Array(ids[$0..<min($0 + columns, ids.count)]) }
            VStack(spacing: gap) {
                ForEach(rows.indices, id: \.self) { row in
                    HStack(spacing: gap) {
                        if columns == 3, rows[row].count == 1 { Color.clear }
                        ForEach(rows[row], id: \.self) { tile($0) }
                        if columns == 3, rows[row].count == 1 { Color.clear }
                    }
                }
            }
        }
    }

    @ViewBuilder private func tile(_ id: UUID) -> some View {
        if let piece = state.ownedPieces.first(where: { $0.id == id }) {
            PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topTrailing) {
                    Button { remove(id) } label: {
                        Image(systemName: "minus.circle.fill").font(.body)
                            .symbolRenderingMode(.palette).foregroundStyle(AppTheme.onPrimary, AppTheme.primaryFill)
                            .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
                    }.buttonStyle(.plain).disabled(isLocked).accessibilityLabel("Remove \(piece.displayName)")
                }
                .transition(.scale(scale: 0.92).combined(with: .opacity))
        } else {
            Button { remove(id) } label: {
                Label("Remove unavailable piece", systemImage: "tshirt").font(AppTypography.supporting)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }.buttonStyle(.plain).foregroundStyle(AppTheme.secondary).disabled(isLocked)
        }
    }
}

/// Resizable picker shown over the builder: a peek row, then a searchable grid.
struct OutfitPickerSheet: View {
    static let collapsed = PresentationDetent.height(72)
    static let peek = PresentationDetent.height(272)
    @Bindable var model: OutfitEditorModel
    @Binding var detent: PresentationDetent
    @State private var categoryID: String?
    @State private var query = ""
    @Environment(\.dynamicTypeSize) private var typeSize

    private var isPeek: Bool { detent == Self.peek }
    private var isCollapsed: Bool { detent == Self.collapsed }
    private var locked: Bool { model.pending || model.unknown || model.generating }
    private var pieces: [WardrobePiece] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = model.state.pieces.filter { piece in
            (categoryID == nil || model.state.category(for: piece)?.id == categoryID)
                && (needle.isEmpty || "\(piece.displayName) \(piece.details.color) \(piece.details.brand)".localizedCaseInsensitiveContains(needle))
        }
        guard isPeek else { return matches }
        let chosen = Set(model.draft.pieceIDs)
        return matches.filter { !chosen.contains($0.id) } + matches.filter { chosen.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Button { detent = isCollapsed ? Self.peek : Self.collapsed } label: {
                HStack(spacing: AppSpacing.small) {
                    Text("Add pieces").font(.headline)
                    Spacer()
                    if isCollapsed {
                        Text("\(model.draft.pieceIDs.count) in outfit").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }
                    Image(systemName: isCollapsed ? "chevron.up" : "chevron.down")
                        .font(.footnote.weight(.semibold)).foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                }.frame(minHeight: AppControlMetrics.minimumTarget).contentShape(Rectangle())
            }.buttonStyle(.plain).foregroundStyle(AppTheme.ink).padding(.top, AppSpacing.small)
                .accessibilityLabel("Add pieces").accessibilityValue(isCollapsed ? "Collapsed" : "Expanded")
                .accessibilityHint(isCollapsed ? "Expands the piece picker" : "Collapses the piece picker")
            if !isCollapsed {
                if !isPeek { searchField }
                ScrollView(.horizontal) {
                    HStack(spacing: AppSpacing.small) {
                        chip(nil)
                        ForEach(model.state.categoriesWithPieces(keeping: categoryID)) { chip($0) }
                    }.padding(.trailing, AppSpacing.screen)
                }.scrollIndicators(.hidden).frame(height: AppControlMetrics.minimumTarget)
                    .mask(LinearGradient(stops: [.init(color: .black, location: 0.92), .init(color: .clear, location: 1)], startPoint: .leading, endPoint: .trailing))
                content
            }
        }
        .padding(.horizontal, AppSpacing.screen)
        .sensoryFeedback(.selection, trigger: model.draft.pieceIDs)
        .animation(.smooth(duration: 0.25), value: isPeek)
    }

    @ViewBuilder private var content: some View {
        if pieces.isEmpty {
            Text(model.state.pieces.isEmpty ? "Add pieces to your closet to build an outfit." : "No matching pieces.")
                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                .frame(maxWidth: .infinity, minHeight: 120)
            Spacer(minLength: 0)
        } else if isPeek {
            ScrollView(.horizontal) {
                LazyHStack(spacing: AppSpacing.medium) {
                    ForEach(pieces) { tile($0, width: 88, height: 112) }
                }.padding(.vertical, 2).animation(.smooth(duration: 0.25), value: model.draft.pieceIDs)
            }.scrollIndicators(.hidden)
        } else {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.medium), count: typeSize.isAccessibilitySize ? 2 : 3), spacing: AppSpacing.medium) {
                    ForEach(pieces) { tile($0, width: nil, height: 128) }
                }.padding(.bottom, AppSpacing.screen)
            }.scrollDismissesKeyboard(.interactively)
        }
    }

    private var searchField: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
            TextField("Search your pieces", text: $query).submitLabel(.search)
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.secondary) }
                    .buttonStyle(.plain).accessibilityLabel("Clear search")
            }
        }.padding(.horizontal, AppControlMetrics.fieldPadding).frame(height: 44)
            .background(AppTheme.surface, in: Capsule())
    }

    private func tile(_ piece: WardrobePiece, width: CGFloat?, height: CGFloat) -> some View {
        let isSelected = model.draft.pieceIDs.contains(piece.id)
        return Button { toggle(piece) } label: {
            VStack(spacing: 4) {
                PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                    .frame(maxWidth: width ?? .infinity).frame(height: height)
                    .selectionIndicator(isSelected)
                    .opacity(isSelected ? 0.75 : 1)
                Text(width == nil ? piece.displayName : model.state.categoryName(for: piece)).font(AppTypography.metadata).truncated().foregroundStyle(AppTheme.secondary)
            }.frame(width: width)
        }.buttonStyle(.plain).disabled(locked)
            .accessibilityLabel(piece.displayName)
            .accessibilityValue(isSelected ? "In outfit" : "Not in outfit")
            .accessibilityHint(isSelected ? "Removes from the outfit" : "Adds to the outfit")
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func toggle(_ piece: WardrobePiece) {
        var ids = model.draft.pieceIDs
        if let index = ids.firstIndex(of: piece.id) { ids.remove(at: index) } else { ids.append(piece.id) }
        guard model.applyManualPieces(ids) else { return }
        if model.draft.baseRevision == 0, model.draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !ids.isEmpty {
            model.update { $0.name = Date.now.formatted(.dateTime.weekday(.wide)) + " look" }
        }
    }

    private func chip(_ value: WardrobeCategory?) -> some View {
        AppChip(title: value?.name ?? "All", isSelected: categoryID == value?.id) { categoryID = value?.id }
    }
}
