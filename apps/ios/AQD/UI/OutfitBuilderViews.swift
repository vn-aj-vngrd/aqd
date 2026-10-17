import AQDCore
import SwiftUI

/// Live, tappable collage of the pieces chosen for an outfit draft.
struct OutfitCanvas: View {
    @Environment(AppState.self) private var state
    let pieceIDs: [UUID]
    var isLocked = false
    var height: CGFloat = 320
    var remove: (UUID) -> Void

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
        .frame(height: height)
        .background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: AppRadius.field))
        .animation(.smooth(duration: 0.28), value: pieceIDs)
    }

    @ViewBuilder private var layout: some View {
        let gap: CGFloat = 8
        switch pieceIDs.count {
        case 1:
            tile(pieceIDs[0])
        case 2:
            HStack(spacing: gap) { tile(pieceIDs[0]); tile(pieceIDs[1]) }
        case 3:
            HStack(spacing: gap) {
                tile(pieceIDs[0])
                VStack(spacing: gap) { tile(pieceIDs[1]); tile(pieceIDs[2]) }
            }
        default:
            let columns = pieceIDs.count <= 4 ? 2 : 3
            let rows = stride(from: 0, to: pieceIDs.count, by: columns).map { Array(pieceIDs[$0..<min($0 + columns, pieceIDs.count)]) }
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
                        Image(systemName: "minus.circle.fill").font(.title3)
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

/// Bottom tray for adding owned pieces to the draft with one tap each.
struct OutfitPieceTray: View {
    @Bindable var model: OutfitEditorModel
    var seeAll: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var categoryID: String?

    private var pieces: [WardrobePiece] {
        model.state.pieces.filter { categoryID == nil || model.state.category(for: $0)?.id == categoryID }
    }
    private var locked: Bool { model.pending || model.unknown || model.generating }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                ScrollView(.horizontal) {
                    HStack(spacing: AppSpacing.small) {
                        chip(nil)
                        ForEach(model.state.pieceCategories) { chip($0) }
                    }
                }.scrollIndicators(.hidden)
                Button("See all", action: seeAll).font(AppTypography.supporting.weight(.medium))
                    .foregroundStyle(AppTheme.actionText).frame(minHeight: AppControlMetrics.minimumTarget)
                    .accessibilityLabel("See all pieces")
            }
            if pieces.isEmpty {
                Text(model.state.pieces.isEmpty ? "Add pieces to your closet to build an outfit." : "No pieces in this category.")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    .frame(maxWidth: .infinity, minHeight: 104, alignment: .center)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: AppSpacing.medium) {
                        ForEach(pieces) { piece in tile(piece) }
                    }.padding(.vertical, 2)
                }.scrollIndicators(.hidden)
            }
        }
        .padding(.horizontal, AppSpacing.screen).padding(.top, AppSpacing.small).padding(.bottom, AppSpacing.small)
        .background(.regularMaterial)
        .overlay(alignment: .top) { Divider() }
        .sensoryFeedback(.selection, trigger: model.draft.pieceIDs)
    }

    private func tile(_ piece: WardrobePiece) -> some View {
        let isSelected = model.draft.pieceIDs.contains(piece.id)
        return Button { toggle(piece) } label: {
            PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                .frame(width: 84, height: 104)
                .overlay(RoundedRectangle(cornerRadius: AppRadius.group).strokeBorder(isSelected ? AppTheme.ink : .clear, lineWidth: 2))
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill").symbolRenderingMode(.palette)
                            .foregroundStyle(AppTheme.onPrimary, AppTheme.primaryFill).padding(4)
                    }
                }
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
