import SwiftUI

extension View {
    /// Let iOS own the compact alert, safe cancellation and destructive styling.
    /// Failed discard operations leave the editor and its recovery state intact.
    func draftDiscardConfirmation(isPresented: Binding<Bool>, title: String,
                                  message: String, discard: @escaping () -> Void) -> some View {
        alert(title, isPresented: isPresented) {
            Button("Keep editing", role: .cancel) {}
            Button("Discard draft", role: .destructive, action: discard)
        } message: {
            Text(message)
        }
    }
}
