import SwiftUI

extension View {
    /// One consistent rule for names and captions in tight spaces: stay on `lines` and end with an ellipsis.
    /// The full text stays available to VoiceOver and in the detail view.
    func truncated(_ lines: Int = 1) -> some View {
        lineLimit(lines).truncationMode(.tail)
    }
}
