import AQDCore
import SwiftUI

extension View {
    /// Single recipe for tappable compact controls (chips, secondary buttons, round icon buttons).
    /// iOS 26+ uses native interactive regular glass; Reduce Transparency, Increase Contrast and
    /// older systems fall back to a flat white surface with a hairline. No hand-drawn shadows.
    func glassControlSurface<S: InsettableShape>(_ shape: S) -> some View {
        modifier(GlassControlSurface(shape: shape))
    }
}

extension View {
    /// The one compact tappable control: glass capsule, 32 pt visible height inside a 44 pt target, one font.
    /// `fullWidth` stretches it to equal-width rows and keeps the full 44 pt height.
    func compactControl(fullWidth: Bool = false, tint: Color = AppTheme.ink) -> some View {
        font(.subheadline.weight(.medium)).foregroundStyle(tint).lineLimit(1)
            .padding(.horizontal, AppSpacing.medium)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: fullWidth ? AppControlMetrics.minimumTarget : 32)
            .glassControlSurface(Capsule())
            .frame(minHeight: AppControlMetrics.minimumTarget)
            .contentShape(Rectangle())
    }
}

private struct GlassControlSurface<S: InsettableShape>: ViewModifier {
    let shape: S
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26, *), !reduceTransparency, contrast != .increased {
            content.glassEffect(.regular.interactive(!reduceMotion), in: shape)
        } else {
            content.background {
                shape.fill(AppTheme.surface)
                    .overlay(shape.strokeBorder(contrast == .increased ? AppTheme.controlBoundary : AppTheme.divider, lineWidth: 1))
            }
        }
    }
}

/// Shared selectable capsule for category and filter rows. Selected uses the neutral
/// primary pair; unselected uses the shared glass control surface.
struct AppChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(.subheadline).truncated()
                .padding(.horizontal, AppSpacing.medium).frame(minHeight: 32)
                .foregroundStyle(isSelected ? AppTheme.onPrimary : AppTheme.ink)
                .background { if isSelected { Capsule().fill(AppTheme.primaryFill) } }
                .modifier(RaisedWhenUnselected(isSelected: isSelected))
                .frame(minHeight: AppControlMetrics.minimumTarget).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct RaisedWhenUnselected: ViewModifier {
    let isSelected: Bool
    func body(content: Content) -> some View {
        if isSelected { content } else { content.glassControlSurface(Capsule()) }
    }
}

extension View {
    /// Shared selected-tile treatment: neutral ring and checkmark (never gold).
    func selectionIndicator(_ isSelected: Bool, cornerRadius: CGFloat = AppRadius.group) -> some View {
        overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(isSelected ? AppTheme.ink : .clear, lineWidth: 2))
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").symbolRenderingMode(.palette)
                        .foregroundStyle(AppTheme.onPrimary, AppTheme.primaryFill).padding(6)
                }
            }
    }
}

/// Inline horizontal choice of one saved outfit, replacing pushed outfit choosers.
struct OutfitSelectionStrip: View {
    let outfits: [Outfit]
    let selectedID: UUID?
    var locked = false
    let select: (Outfit) -> Void

    var body: some View {
        if outfits.isEmpty {
            Text("No saved outfits yet. Save an outfit in Closet first.")
                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: AppSpacing.medium) {
                    ForEach(outfits) { outfit in
                        let isSelected = outfit.id == selectedID
                        Button { select(outfit) } label: {
                            VStack(spacing: 4) {
                                CollectionArtwork(pieceIDs: outfit.pieceIDs, height: 108).padding(AppSpacing.small)
                                    .frame(width: 104)
                                    .background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: AppRadius.group))
                                    .selectionIndicator(isSelected)
                                Text(outfit.displayName).font(AppTypography.metadata).truncated()
                                    .foregroundStyle(AppTheme.secondary).frame(width: 104)
                            }
                        }.buttonStyle(.plain).disabled(locked)
                            .accessibilityLabel(outfit.displayName)
                            .accessibilityValue(isSelected ? "Selected" : "Not selected")
                            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    }
                }.padding(.vertical, 2)
            }.scrollIndicators(.hidden).sensoryFeedback(.selection, trigger: selectedID)
        }
    }
}

/// Inline horizontal multi-select of owned pieces, replacing pushed piece choosers.
struct PieceSelectionStrip: View {
    let pieces: [WardrobePiece]
    let selected: [UUID]
    var locked = false
    let toggle: (WardrobePiece) -> Void

    var body: some View {
        if pieces.isEmpty {
            Text("No pieces available.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: AppSpacing.medium) {
                    ForEach(pieces) { piece in
                        let isSelected = selected.contains(piece.id)
                        Button { toggle(piece) } label: {
                            VStack(spacing: 4) {
                                PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                                    .frame(width: 88, height: 112).selectionIndicator(isSelected)
                                    .opacity(isSelected ? 0.75 : 1)
                                Text(piece.displayName).font(AppTypography.metadata).truncated()
                                    .foregroundStyle(AppTheme.secondary).frame(width: 88)
                            }
                        }.buttonStyle(.plain).disabled(locked)
                            .accessibilityLabel(piece.displayName)
                            .accessibilityValue(isSelected ? "Selected" : "Not selected")
                            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    }
                }.padding(.vertical, 2)
            }.scrollIndicators(.hidden).sensoryFeedback(.selection, trigger: selected)
        }
    }
}
