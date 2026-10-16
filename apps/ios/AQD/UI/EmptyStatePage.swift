import SwiftUI

/// A page empty state centers its message in the remaining safe area. Actions
/// stay at the bottom; long accessibility text scrolls without covering them.
struct EmptyStatePage<Actions: View>: View {
    let title: LocalizedStringKey
    let systemImage: String
    var description: Text? = nil
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                AppEmptyState(title, systemImage: systemImage, description: description)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ActionFooter { ActionStack(content: actions) }
        }
    }
}
