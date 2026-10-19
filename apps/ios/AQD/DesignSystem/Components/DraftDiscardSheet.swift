import SwiftUI
import UIKit

extension View {
    /// App-owned confirmations share one appearance; system permission prompts stay native.
    func appConfirmation<Actions: View, Message: View>(
        _ title: String, isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping () -> Actions,
        @ViewBuilder message: @escaping () -> Message
    ) -> some View {
        modifier(AppConfirmationPresentation(title: title, isPresented: isPresented,
                                             actions: actions, message: message))
    }

    func appConfirmation<Actions: View>(
        _ title: String, isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping () -> Actions
    ) -> some View {
        appConfirmation(title, isPresented: isPresented, actions: actions, message: { EmptyView() })
    }

    /// The one delete confirmation: "Delete this <noun>?" names the item, so the red button is just "Delete" and fits on one line.
    func deleteConfirmation(_ noun: String, isPresented: Binding<Bool>, actionTitle: String? = nil, message: String,
                            cancel: @escaping () -> Void = {}, delete: @escaping () -> Void) -> some View {
        appConfirmation("Delete this \(noun)?", isPresented: isPresented) {
            Button(actionTitle ?? "Delete", role: .destructive, action: delete)
            Button("Cancel", role: .cancel, action: cancel)
        } message: { Text(message) }
    }

    func draftDiscardConfirmation(isPresented: Binding<Bool>, title: String,
                                  message: String, discard: @escaping () -> Void) -> some View {
        appConfirmation(title, isPresented: isPresented) {
            Button("Keep editing", role: .cancel) {}
            Button("Discard draft", role: .destructive, action: discard)
        } message: { Text(message) }
    }
}

private struct AppConfirmationPresentation<Actions: View, Message: View>: ViewModifier {
    let title: String
    @Binding var isPresented: Bool
    let actions: () -> Actions
    let message: () -> Message

    func body(content: Content) -> some View {
        content.background {
            ConfirmationPresenter(isPresented: $isPresented) { perform in
                AppConfirmationCard(title: title, perform: perform, actions: actions, message: message)
            }
        }
    }
}

/// Over-full-screen presentation keeps the editor visible in UIKit's lifecycle.
/// A fullScreenCover would fire onDisappear and cancel in-progress editor work.
private struct ConfirmationPresenter<Dialog: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let dialog: (@escaping (@escaping () -> Void) -> Void) -> Dialog
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> ConfirmationAnchor {
        let anchor = ConfirmationAnchor()
        anchor.onReady = { [weak coordinator = context.coordinator, weak anchor] in
            if let anchor { coordinator?.update(from: anchor) }
        }
        return anchor
    }
    func updateUIViewController(_ anchor: ConfirmationAnchor, context: Context) {
        context.coordinator.parent = self
        context.coordinator.update(from: anchor)
    }
    static func dismantleUIViewController(_ anchor: ConfirmationAnchor, coordinator: Coordinator) {
        anchor.onReady = nil
        coordinator.host?.dismiss(animated: false)
        coordinator.host = nil
    }

    @MainActor final class Coordinator {
        var parent: ConfirmationPresenter
        var host: UIHostingController<Dialog>?
        private var dismissing = false
        init(_ parent: ConfirmationPresenter) { self.parent = parent }

        func update(from anchor: ConfirmationAnchor) {
            guard !dismissing else { return }
            guard parent.isPresented else {
                if host != nil { close(action: nil) }
                return
            }
            let content = parent.dialog { [weak self] action in self?.close(action: action) }
            if let host {
                host.rootView = content
                host.overrideUserInterfaceStyle = parent.colorScheme == .dark ? .dark : .light
                return
            }
            guard anchor.viewIfLoaded?.window != nil else { return }
            let controller = UIHostingController(rootView: content)
            controller.modalPresentationStyle = .overFullScreen
            controller.modalTransitionStyle = .crossDissolve
            controller.overrideUserInterfaceStyle = parent.colorScheme == .dark ? .dark : .light
            controller.view.backgroundColor = .clear
            controller.view.accessibilityViewIsModal = true
            controller.isModalInPresentation = true
            host = controller
            anchor.present(controller, animated: !parent.reduceMotion)
        }

        private func close(action: (() -> Void)?) {
            guard let host, !dismissing else { return }
            dismissing = true
            host.dismiss(animated: !parent.reduceMotion) { [self] in
                self.host = nil
                // Consume reviewed optional targets before clearing their binding, and
                // wait for dismissal so an action can present Photos or another sheet.
                action?()
                parent.isPresented = false
                dismissing = false
            }
        }
    }
}

private final class ConfirmationAnchor: UIViewController {
    var onReady: (() -> Void)?
    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onReady?()
    }
}

private struct AppConfirmationCard<Actions: View, Message: View>: View {
    let title: String
    let perform: (@escaping () -> Void) -> Void
    @ViewBuilder let actions: () -> Actions
    @ViewBuilder let message: () -> Message
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @AccessibilityFocusState private var titleFocused: Bool
    @State private var cancelAction: (() -> Void)?
    private let shape = RoundedRectangle(cornerRadius: AppRadius.composer, style: .continuous)

    var body: some View {
        ZStack {
            AppTheme.scrim.ignoresSafeArea().accessibilityHidden(true)
            ViewThatFits(in: .vertical) {
                card.fixedSize(horizontal: false, vertical: true)
                ScrollView { card }.scrollBounceBehavior(.basedOnSize)
            }.padding(AppSpacing.section)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        // Escape activates the original cancel cleanup rather than only hiding the card.
        .accessibilityAction(.escape) { cancelAction?() }
        .onAppear {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            titleFocused = true
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(title).font(.headline).foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader).accessibilityFocused($titleFocused)
                message().font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }.frame(maxWidth: .infinity, alignment: .leading)
            ViewThatFits(in: .horizontal) {
                if !typeSize.isAccessibilitySize {
                    HStack(spacing: AppSpacing.small) { actions() }
                }
                VStack(spacing: AppSpacing.small) { actions() }
            }
            .buttonStyle(ConfirmationActionStyle(perform: perform, registerCancel: { cancelAction = $0 }))
        }
        .padding(.horizontal, AppSpacing.screen).padding(.vertical, AppSpacing.screen).frame(maxWidth: 340)
        .background {
            if reduceTransparency { shape.fill(AppTheme.surface) }
            else { shape.fill(.regularMaterial) }
        }
        .overlay(shape.stroke(AppTheme.glassEdge, lineWidth: 1))
        .shadow(color: AppTheme.controlShadow, radius: AppSpacing.section, y: AppSpacing.small)
    }
}

/// Keep the same actions and roles while replacing system alert button chrome.
private struct ConfirmationActionStyle: PrimitiveButtonStyle {
    let perform: (@escaping () -> Void) -> Void
    let registerCancel: (@escaping () -> Void) -> Void
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.dynamicTypeSize) private var typeSize
    func makeBody(configuration: Configuration) -> some View {
        Button(role: configuration.role) {
            perform { configuration.trigger() }
        } label: {
            configuration.label
                .font(configuration.role == .cancel ? .body.weight(.semibold) : AppTypography.body)
                .foregroundStyle(configuration.role == .destructive ? AppTheme.error : AppTheme.ink)
                // One line at normal sizes so side-by-side buttons stay level; the words shrink a little before they wrap.
                // Accessibility sizes may wrap instead, because a clipped word cannot be read.
                .lineLimit(typeSize.isAccessibilitySize ? nil : 1).minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.75)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: typeSize.isAccessibilitySize)
                .padding(.horizontal, AppSpacing.medium).padding(.vertical, AppSpacing.medium)
                .frame(maxWidth: .infinity, minHeight: AppControlMetrics.minimumTarget)
                .background(AppTheme.imageGround, in: Capsule()).contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.45)
        .onAppear {
            if configuration.role == .cancel {
                registerCancel { perform { configuration.trigger() } }
            }
        }
        .modifier(ConfirmationCancelAction(isCancel: configuration.role == .cancel, action: {
            perform { configuration.trigger() }
        }))
    }
}

private struct ConfirmationCancelAction: ViewModifier {
    let isCancel: Bool
    let action: () -> Void
    func body(content: Content) -> some View {
        if isCancel {
            content.keyboardShortcut(.cancelAction)
                .accessibilityAction(.escape, action)
        } else { content }
    }
}
