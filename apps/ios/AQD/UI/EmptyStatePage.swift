import SwiftUI

/// Informational empty content, centered and scrollable without an action footer.
struct EmptyStatePage: View {
    let title: LocalizedStringKey
    let systemImage: String
    var description: Text? = nil
    var detail: String? = nil

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    AppEmptyState(title, systemImage: systemImage, description: description, fillsAvailableSpace: false)
                        .fixedSize(horizontal: false, vertical: true)
                    if let detail {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your retained draft").font(.headline)
                            Text(detail).font(AppTypography.body).textSelection(.enabled)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
                    }
                }.frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
    }
}

/// Short informational pages share the empty-page vertical rhythm while their
/// caller owns the safe-area action footer. Long text remains scrollable.
struct CenteredPageContent<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20, content: content)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: max(0, geometry.size.height - 40))
                    .padding(20)
            }
        }
    }
}
