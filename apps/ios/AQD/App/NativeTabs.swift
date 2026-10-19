import SwiftUI
import UIKit

/// Native root chrome only. Each supplied view owns its own NavigationStack.
/// Root builders are evaluated once per bridge lifetime; use observable state in
/// those views for live data. Agent is built anew for every full-screen launch.
@MainActor
struct NativeTabs: UIViewControllerRepresentable {
    typealias RootBuilder = @MainActor () -> AnyView
    typealias AgentBuilder = @MainActor (@escaping @MainActor () -> Void) -> AnyView

    @Environment(\.colorScheme) private var colorScheme
    @Binding var selection: Int
    let today: RootBuilder
    let closet: RootBuilder
    let planner: RootBuilder
    let profile: RootBuilder
    let agent: AgentBuilder
    var agentLaunchID: UUID?
    var isReadOnlyPreview = false
    var isTabBarHidden = false

    func makeCoordinator() -> Coordinator {
        Coordinator(agent: agent, selection: $selection)
    }

    func makeUIViewController(context: Context) -> UITabBarController {
        let controller = UITabBarController()
        controller.mode = .tabBar
        controller.tabBar.itemPositioning = .fill
        if #available(iOS 26.0, *) {
            controller.tabBarMinimizeBehavior = isReadOnlyPreview ? .never : .onScrollDown
        }
        // UIKit owns chrome/geometry; Paper owns the semantic symbol tints.
        // Set the bridge explicitly instead of relying on SwiftUI tint inheritance.
        controller.tabBar.tintColor = UIColor(AppTheme.ink)
        controller.tabBar.unselectedItemTintColor = UIColor(AppTheme.tabInactive)
        let appearance = controller.tabBar.standardAppearance
        for layout in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            layout.normal.iconColor = UIColor(AppTheme.tabInactive)
            layout.selected.iconColor = UIColor(AppTheme.ink)
        }
        controller.tabBar.standardAppearance = appearance
        controller.delegate = context.coordinator
        controller.tabBar.isUserInteractionEnabled = !isReadOnlyPreview
        controller.tabBar.accessibilityElementsHidden = isReadOnlyPreview
        context.coordinator.install(
            on: controller,
            roots: [today(), closet(), planner(), profile()]
        )
        context.coordinator.setAppearance(colorScheme)
        context.coordinator.setRootChromeHidden(isTabBarHidden)
        return controller
    }

    func updateUIViewController(_ controller: UITabBarController, context: Context) {
        // Never rebuild root controllers/stacks in response to a parent update.
        context.coordinator.setAppearance(colorScheme)
        context.coordinator.agent = agent
        context.coordinator.selection = $selection
        context.coordinator.setRootChromeHidden(isTabBarHidden)
        context.coordinator.selectRoot(selection)
        context.coordinator.requestAgent(agentLaunchID)
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
        private var requestedAgentID: UUID?
        private weak var originAccessibilityElement: AnyObject?
        private let agentIndex = 3
        private var tabs: [UITab] = []

        init(agent: @escaping AgentBuilder, selection: Binding<Int>) {
            self.agent = agent
            self.selection = selection
        }

        func requestAgent(_ id: UUID?) {
            guard let id, id != requestedAgentID else { return }; requestedAgentID = id
            DispatchQueue.main.async { [weak self] in self?.presentAgent() }
        }

        func selectRoot(_ index: Int) {
            guard taskID == nil, tabs.indices.contains(index), index != agentIndex,
                  let controller else { return }
            // UIKit27 invalidates hosted content even for a same-index assignment.
            // A representable update must not schedule another equivalent update.
            if controller.selectedTab !== tabs[index] { controller.selectedTab = tabs[index] }
            originIndex = index
        }

        func install(on controller: UITabBarController, roots: [AnyView]) {
            self.controller = controller
            // The launch slot also has real content, never a blank/dead root.
            // Normal tab activation is intercepted below, before selection.
            let agentRoot = agent { [weak self] in
                self?.dismissAgent()
            }
            let content = [roots[0], roots[1], roots[2], agentRoot, roots[3]]
            let names = ["Today", "Closet", "Planner", "Agent", "Profile"]
            let symbols = ["house", "hanger", "calendar", "sparkle", "person"]
            let selectedSymbols = ["house.fill", "hanger", "calendar", "sparkle", "person.fill"]
            hosts = content.enumerated().map { index, root in
                let host = UIHostingController(rootView: root)
                let item = UITabBarItem(title: nil, image: Self.tabImage(symbols[index], selected: false), tag: index)
                item.selectedImage = Self.tabImage(selectedSymbols[index], selected: true)
                item.accessibilityLabel = names[index]
                item.accessibilityIdentifier = "root.tab.\(names[index].lowercased())"
                // UIKit supplies the tab role and selected trait, not an app-owned
                // accessibility overlay that could hide the real native targets.
                host.tabBarItem = item
                return host
            }
            tabs = hosts.enumerated().map { index, host in
                let tab = UITab(title: "", image: host.tabBarItem.image,
                                identifier: "aqd.\(names[index].lowercased())") { _ in host }
                tab.accessibilityLabel = names[index]
                tab.accessibilityIdentifier = "root.tab.\(names[index].lowercased())"
                tab.preferredPlacement = .fixed
                if #available(iOS 26.1, *) { tab.selectedImage = host.tabBarItem.selectedImage }
                return tab
            }
            controller.setTabs(tabs, animated: false)
            for (index, item) in (controller.tabBar.items ?? []).enumerated() where names.indices.contains(index) {
                item.title = nil
                item.accessibilityLabel = names[index]
            }
            if #available(iOS 27.0, *) { controller.prominentTabIdentifier = tabs[agentIndex].identifier }
            controller.selectedTab = tabs[originIndex]
        }

        func setRootChromeHidden(_ hidden: Bool) {
            guard let controller, controller.isTabBarHidden != hidden else { return }
            controller.setTabBarHidden(hidden, animated: controller.viewIfLoaded?.window != nil)
        }

        /// Rasterize the chosen public SF Symbol into a template so UIKit cannot
        /// replace inactive outlines with its automatic filled-symbol variant.
        private static func tabImage(_ name: String, selected: Bool) -> UIImage? {
            guard let symbol = UIImage(systemName: name, withConfiguration:
                UIImage.SymbolConfiguration(pointSize: 22, weight: selected ? .semibold : .light)) else { return nil }
            return UIGraphicsImageRenderer(size: symbol.size).image { _ in
                symbol.draw(at: .zero)
            }.withRenderingMode(.alwaysTemplate)
        }

        func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
            guard tab === tabs[agentIndex] else { return taskID == nil }
            presentAgent()
            return false
        }

        func tabBarController(_ tabBarController: UITabBarController, didSelectTab selectedTab: UITab, previousTab: UITab?) {
            guard let index = tabs.firstIndex(where: { $0 === selectedTab }), index != agentIndex else { return }
            originIndex = index
            selection.wrappedValue = index
        }

        private var selectedRootIndex: Int {
            guard let selected = controller?.selectedTab else { return originIndex }
            return tabs.firstIndex(where: { $0 === selected }) ?? originIndex
        }

        func setAppearance(_ scheme: ColorScheme) {
            let style: UIUserInterfaceStyle = scheme == .dark ? .dark : .light
            controller?.overrideUserInterfaceStyle = style
            taskHost?.overrideUserInterfaceStyle = style
        }

        private func presentAgent() {
            guard let controller, taskID == nil,
                  controller.presentedViewController == nil,
                  controller.viewIfLoaded?.window != nil else { return }
            originIndex = selectedRootIndex
            originAccessibilityElement = UIAccessibility.focusedElement(using: .notificationVoiceOver) as AnyObject?
            let id = UUID()
            taskID = id
            let host = AgentHostingController(rootView: agent { [weak self] in
                self?.dismissAgent(id: id)
            })
            host.overrideUserInterfaceStyle = controller.overrideUserInterfaceStyle
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
            controller?.selectedTab = tabs[destination]
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
            tabs.removeAll()
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

private struct SecondaryPageChrome: ViewModifier {
    @Environment(AppState.self) private var state
    @State private var token = UUID()
    func body(content: Content) -> some View {
        content.toolbar(.hidden, for: .tabBar)
            .onAppear { state.secondaryPageOwners[token] = state.selection }
            .onDisappear { state.secondaryPageOwners.removeValue(forKey: token) }
    }
}
extension View {
    func secondaryPage() -> some View { modifier(SecondaryPageChrome()) }
}
