import SwiftUI

/// One editor for a piece photo: Crop and rotate beside Cut out, so they combine in any order. Each tab applies its own edit and
/// stays open; Close leaves. Switching tabs with an unapplied edit asks first, because the other tab starts from the applied photo.
struct PieceEditorView: View {
    enum Mode: String, CaseIterable { case frame = "Crop and rotate", cutout = "Cut out" }

    @Bindable var capture: CaptureModel
    @State var mode: Mode
    @State private var dirty = false
    @State private var applied = 0
    @State private var pendingMode: Mode?
    @State private var discardToSwitch = false
    @State private var discardToClose = false
    @Environment(\.dismiss) private var dismiss

    init(capture: CaptureModel, mode: Mode = .frame) {
        self.capture = capture
        _mode = State(initialValue: mode)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .frame: PhotoEditorView(model: capture, embedding: embedding)
                case .cutout: PieceCutoutView(capture: capture, embedding: embedding)
                }
            }
            .id("\(mode.rawValue)-\(applied)")
            .safeAreaInset(edge: .top, spacing: 0) {
                AppSegmentedControl(selection: Binding(get: { mode.rawValue }, set: { choose(Mode(rawValue: $0) ?? mode) }),
                                    options: Mode.allCases.map(\.rawValue), accessibilityTitle: "Photo editing", identifierPrefix: "photo.editor.mode")
                    .padding(.horizontal, AppSpacing.screen).padding(.vertical, AppSpacing.small).background(AppTheme.canvas)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dirty ? (discardToClose = true) : dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close").accessibilityIdentifier("photo.editor.back")
                }
            }
            .appConfirmation("Discard this edit?", isPresented: $discardToSwitch) {
                Button("Discard", role: .destructive) { if let pendingMode { mode = pendingMode }; dirty = false; pendingMode = nil }
                Button("Keep editing", role: .cancel) { pendingMode = nil }
            } message: { Text("Tap Apply first to keep it. Your accepted photo and original stay unchanged.") }
            .appConfirmation("Discard this edit?", isPresented: $discardToClose) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            } message: { Text("Tap Apply first to keep it. Your accepted photo and original stay unchanged.") }
        }
        .tint(AppTheme.ink).toggleStyle(AppToggleStyle()).interactiveDismissDisabled(dirty)
    }

    private var embedding: EmbeddedEditing {
        EmbeddedEditing(dirty: { dirty = $0 }, applied: { dirty = false; applied += 1 })
    }

    private func choose(_ next: Mode) {
        guard next != mode else { return }
        if dirty { pendingMode = next; discardToSwitch = true } else { mode = next }
    }
}
