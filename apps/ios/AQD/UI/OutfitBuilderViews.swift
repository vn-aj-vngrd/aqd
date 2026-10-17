import AQDCore
import SwiftUI

/// Live, tappable collage of the pieces chosen for an outfit draft.
struct OutfitCanvas: View {
    @Environment(AppState.self) private var state
    let pieceIDs: [UUID]
    var isLocked = false
    var remove: (UUID) -> Void

    private var ordered: [UUID] {
        let order = state.pieceCategories.map(\.id)
        func rank(_ id: UUID) -> Int {
            guard let piece = state.ownedPieces.first(where: { $0.id == id }),
                  let category = state.category(for: piece)?.id, let index = order.firstIndex(of: category) else { return order.count }
            return index
        }
        return pieceIDs.enumerated().sorted { (rank($0.element), $0.offset) < (rank($1.element), $1.offset) }.map(\.element)
    }

    var body: some View {
        Group {
            if pieceIDs.isEmpty {
                VStack(spacing: AppSpacing.small) {
                    Image(systemName: "tshirt").font(.system(size: 36, weight: .light)).accessibilityHidden(true)
                    Text("Pick pieces below to build your look")
                        .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }.foregroundStyle(AppTheme.ink).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                layout.padding(AppSpacing.medium)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: AppRadius.field))
        .animation(.smooth(duration: 0.28), value: pieceIDs)
    }

    @ViewBuilder private var layout: some View {
        let gap: CGFloat = 8
        let ids = ordered
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
                        ForEach(rows[row], id: \.self) { tile($0) }
                        if rows[row].count < columns { ForEach(0..<(columns - rows[row].count), id: \.self) { _ in Color.clear } }
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
    static let peek = PresentationDetent.height(272)
    @Bindable var model: OutfitEditorModel
    @Binding var detent: PresentationDetent
    @State private var categoryID: String?
    @State private var query = ""
    @Environment(\.dynamicTypeSize) private var typeSize

    private var isPeek: Bool { detent == Self.peek }
    private var locked: Bool { model.pending || model.unknown || model.generating }
    private var pieces: [WardrobePiece] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return model.state.pieces.filter { piece in
            (categoryID == nil || model.state.category(for: piece)?.id == categoryID)
                && (needle.isEmpty || "\(piece.displayName) \(piece.details.color) \(piece.details.brand)".localizedCaseInsensitiveContains(needle))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Text("Add pieces").font(AppTypography.section)
                Spacer()
                Text("\(model.draft.pieceIDs.count) in outfit").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }.padding(.top, AppSpacing.large)
            if !isPeek { searchField }
            ScrollView(.horizontal) {
                HStack(spacing: AppSpacing.small) {
                    chip(nil)
                    ForEach(model.state.pieceCategories) { chip($0) }
                }.padding(.trailing, AppSpacing.screen)
            }.scrollIndicators(.hidden).frame(height: AppControlMetrics.minimumTarget)
                .mask(LinearGradient(stops: [.init(color: .black, location: 0.92), .init(color: .clear, location: 1)], startPoint: .leading, endPoint: .trailing))
            content
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
                }.padding(.vertical, 2)
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
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.group).strokeBorder(isSelected ? AppTheme.accent : .clear, lineWidth: 2))
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill").symbolRenderingMode(.palette)
                                .foregroundStyle(AppTheme.onAccent, AppTheme.accent).padding(4)
                        }
                    }
                    .opacity(isSelected ? 0.75 : 1)
                Text(piece.displayName).font(AppTypography.metadata).lineLimit(1).foregroundStyle(AppTheme.secondary)
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
            model.update { $0.name = "Look · " + Date.now.formatted(.dateTime.month(.abbreviated).day()) }
        }
    }

    private func chip(_ value: WardrobeCategory?) -> some View {
        let selected = categoryID == value?.id
        return Button { categoryID = value?.id } label: {
            Text(value?.name ?? "All").font(.subheadline).padding(.horizontal, 12).padding(.vertical, 6)
                .frame(minHeight: AppControlMetrics.minimumTarget)
                .foregroundStyle(selected ? AppTheme.onPrimary : AppTheme.ink)
                .background(selected ? AppTheme.primaryFill : AppTheme.surface, in: Capsule())
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
