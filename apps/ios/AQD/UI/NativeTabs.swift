import SwiftUI
import UIKit

/// Native root chrome only. Each supplied view owns its own NavigationStack.
/// Root builders are evaluated once per bridge lifetime; use observable state in
/// those views for live data. Agent is built anew for every full-screen launch.
@MainActor
struct NativeTabs: UIViewControllerRepresentable {
    typealias RootBuilder = @MainActor () -> AnyView
    typealias AgentBuilder = @MainActor (@escaping @MainActor () -> Void) -> AnyView

    @Binding var selection: Int
    let today: RootBuilder
    let closet: RootBuilder
    let planner: RootBuilder
    let profile: RootBuilder
    let agent: AgentBuilder

    func makeCoordinator() -> Coordinator {
        Coordinator(agent: agent, selection: $selection)
    }

    func makeUIViewController(context: Context) -> UITabBarController {
        let controller = UITabBarController()
        controller.mode = .tabBar
        controller.tabBar.itemPositioning = .fill
        controller.delegate = context.coordinator
        context.coordinator.install(
            on: controller,
            roots: [today(), closet(), planner(), profile()]
        )
        return controller
    }

    func updateUIViewController(_ controller: UITabBarController, context: Context) {
        // Never rebuild root controllers/stacks in response to a parent update.
        context.coordinator.agent = agent
        context.coordinator.selection = $selection
        context.coordinator.selectRoot(selection)
    }

    static func dismantleUIViewController(_ controller: UITabBarController, coordinator: Coordinator) {
        controller.delegate = nil
        coordinator.tearDown()
    }

    @MainActor
    final class Coordinator: NSObject, UITabBarControllerDelegate, UIAdaptivePresentationControllerDelegate {
        var agent: AgentBuilder
        var selection: Binding<Int>
        private weak var controller: UITabBarController?
        private var hosts: [UIHostingController<AnyView>] = []
        private var taskHost: AgentHostingController?
        private var taskID: UUID?
        private var originIndex = 0
        private weak var originAccessibilityElement: AnyObject?
        private let agentIndex = 3

        init(agent: @escaping AgentBuilder, selection: Binding<Int>) {
            self.agent = agent
            self.selection = selection
        }

        func selectRoot(_ index: Int) {
            guard taskID == nil, (0..<5).contains(index), index != agentIndex else { return }
            controller?.selectedIndex = index
            originIndex = index
        }

        fileprivate func install(on controller: UITabBarController, roots: [AnyView]) {
            self.controller = controller
            // The launch slot also has real content, never a blank/dead root.
            // Normal tab activation is intercepted below, before selection.
            let agentRoot = agent { [weak self] in
                self?.dismissAgent()
            }
            let content = [roots[0], roots[1], roots[2], agentRoot, roots[3]]
            let names = ["Today", "Closet", "Planner", "Agent", "Profile"]
            let symbols = ["house", "tshirt", "calendar", "sparkle", "person.crop.circle"]
            let selectedSymbols = ["house.fill", "tshirt.fill", "calendar", "sparkle", "person.crop.circle.fill"]
            hosts = content.enumerated().map { index, root in
                let host = UIHostingController(rootView: root)
                let item = UITabBarItem(title: nil, image: UIImage(systemName: symbols[index]), tag: index)
                item.selectedImage = UIImage(systemName: selectedSymbols[index])
                item.accessibilityLabel = names[index]
                item.accessibilityIdentifier = "root.tab.\(names[index].lowercased())"
                // UIKit supplies the tab role and selected trait, not an app-owned
                // accessibility overlay that could hide the real native targets.
                host.tabBarItem = item
                return host
            }
            controller.setViewControllers(hosts, animated: false)
            controller.selectedIndex = originIndex
        }

        func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
            guard viewController === hosts[agentIndex] else {
                return taskID == nil
            }
            presentAgent()
            return false
        }

        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            if tabBarController.selectedIndex != agentIndex {
                originIndex = tabBarController.selectedIndex
                selection.wrappedValue = originIndex
            }
        }

        private func presentAgent() {
            guard let controller, taskID == nil,
                  controller.presentedViewController == nil,
                  controller.viewIfLoaded?.window != nil else { return }
            originIndex = controller.selectedIndex
            originAccessibilityElement = UIAccessibility.focusedElement(using: .notificationVoiceOver) as AnyObject?
            let id = UUID()
            taskID = id
            let host = AgentHostingController(rootView: agent { [weak self] in
                self?.dismissAgent(id: id)
            })
            host.onDismiss = { [weak self] in self?.finishAgent(id: id) }
            host.modalPresentationStyle = .fullScreen
            taskHost = host
            controller.present(host, animated: true)
            host.presentationController?.delegate = self
        }

        private func dismissAgent(id: UUID? = nil) {
            guard let currentID = taskID, id == nil || id == currentID else { return }
            guard let host = taskHost, !host.isBeingDismissed else { return }
            // Dismiss from the presenter to close any task-owned child modal too.
            controller?.dismiss(animated: true) { [weak self] in
                self?.finishAgent(id: currentID)
            }
        }

        private func finishAgent(id: UUID) {
            guard taskID == id else { return }
            let requested = selection.wrappedValue
            let destination = (0..<5).contains(requested) && requested != agentIndex ? requested : originIndex
            controller?.selectedIndex = destination
            selection.wrappedValue = destination
            taskID = nil
            taskHost = nil
            let focus = originAccessibilityElement
            originAccessibilityElement = nil
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .screenChanged, argument: focus)
            }
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            guard presentationController.presentedViewController === taskHost, let id = taskID else { return }
            finishAgent(id: id)
        }

        fileprivate func tearDown() {
            taskHost?.onDismiss = nil
            taskID = nil
            taskHost = nil
            hosts.removeAll()
            originAccessibilityElement = nil
            controller = nil
        }
    }
}

/// Also catches task dismissal via SwiftUI's environment dismiss action. A child
/// cover merely hides this host and must not be mistaken for exiting the task.
@MainActor
private final class AgentHostingController: UIHostingController<AnyView> {
    var onDismiss: (@MainActor () -> Void)?

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || presentingViewController == nil {
            onDismiss?()
        }
    }
}
