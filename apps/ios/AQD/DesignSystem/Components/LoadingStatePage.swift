import SwiftUI

/// The loading counterpart of `EmptyStatePage`: one centered spinner, a truthful title and an optional line of context.
/// It appears after a short delay, so a fast load never flashes a full-page loader.
struct LoadingStatePage: View {
    let title: LocalizedStringKey
    var description: Text?
    var delay: Duration = .milliseconds(250)
    @State private var visible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(title).font(.headline)
            } icon: {
                ProgressView().controlSize(.large).tint(AppTheme.ink)
            }
        } description: {
            if let description { description.font(AppTypography.supporting).padding(.top, AppSpacing.small) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(visible ? 1 : 0)
        .task {
            do { try await Task.sleep(for: delay) } catch { return }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { visible = true }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(.updatesFrequently)
    }
}
