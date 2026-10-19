import AQDCore
import SwiftUI

/// A larger look at the profile from the avatar, with the edit action in the toolbar.
struct ProfilePreviewView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let edit: () -> Void

    private var identity: LocalProfileIdentity? { state.localIdentity }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.section) {
                    LocalIdentityAvatar(photoID: identity?.photoID, recipe: identity?.photoRecipe ?? .fitOriginal)
                        .frame(width: 240, height: 240).accessibilityLabel("Profile photo")
                    VStack(spacing: AppSpacing.small) {
                        Text(identity?.name ?? "Your profile").font(.title2.weight(.semibold)).foregroundStyle(AppTheme.ink)
                        Text(identity?.caption ?? LocalProfileIdentity.defaultCaption).font(AppTypography.body).foregroundStyle(AppTheme.secondary)
                            .multilineTextAlignment(.center)
                    }
                    HStack(spacing: 0) {
                        stat("Fits", state.fitMemories.count)
                        stat("Outfits", state.outfits.count)
                        stat("Pieces", state.pieces.count)
                    }
                }.padding(AppSpacing.screen).frame(maxWidth: .infinity)
            }.background(AppTheme.canvas).navigationTitle("Profile").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button { dismiss() } label: { Image(systemName: "xmark") }.accessibilityLabel("Close") }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { dismiss(); edit() } label: { Image(systemName: AppSymbols.edit) }.accessibilityLabel("Edit profile")
                    }
                }
        }.tint(AppTheme.ink)
    }

    private func stat(_ title: String, _ count: Int) -> some View {
        VStack(spacing: AppSpacing.xSmall) {
            Text("\(count)").font(.title3.weight(.semibold)).monospacedDigit().foregroundStyle(AppTheme.ink)
            Text(title).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
        }.frame(maxWidth: .infinity).accessibilityElement(children: .combine)
    }
}
