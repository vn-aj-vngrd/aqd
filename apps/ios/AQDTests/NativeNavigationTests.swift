import AQDCore
import SwiftUI
import Testing
import UIKit
@testable import AQD

@Suite(.serialized) @MainActor struct NativeNavigationTests {
    @Test func prominentAgentPreservesLogicalRootsAndInterception() {
        var selected = 0
        let binding = Binding(get: { selected }, set: { selected = $0 })
        let coordinator = NativeTabs.Coordinator(agent: { _ in AnyView(Color.clear) }, selection: binding)
        let controller = UITabBarController()
        coordinator.install(on: controller, roots: (0..<4).map { _ in AnyView(Color.clear) })
        #expect(controller.tabs.map(\.identifier) == ["aqd.today", "aqd.closet", "aqd.planner", "aqd.agent", "aqd.profile"])
        #expect(controller.tabs.allSatisfy { $0.title.isEmpty })
        #expect(controller.tabs.map(\.accessibilityLabel) == ["Today", "Closet", "Planner", "Agent", "Profile"])
        #expect(controller.tabBar.items?.allSatisfy { $0.title == nil || $0.title == "" } == true)
        #expect(controller.tabBar.items?.map(\.accessibilityLabel) == ["Today", "Closet", "Planner", "Agent", "Profile"])
        if #available(iOS 27.0, *) { #expect(controller.prominentTabIdentifier == "aqd.agent") }
        coordinator.selectRoot(4)
        #expect(controller.selectedTab?.identifier == "aqd.profile")
        let profile = controller.selectedTab?.viewController
        coordinator.setRootChromeHidden(true)
        #expect(controller.isTabBarHidden)
        coordinator.selectRoot(4)
        coordinator.setRootChromeHidden(false)
        #expect(!controller.isTabBarHidden)
        #expect(controller.selectedTab?.viewController === profile)
        // Agent is an intercepted task, never an accidentally selected blank root.
        #expect(!coordinator.tabBarController(controller, shouldSelectTab: controller.tabs[3]))
        #expect(controller.selectedTab?.identifier == "aqd.profile")
        coordinator.selectRoot(3)
        #expect(controller.selectedTab?.identifier == "aqd.profile")
        coordinator.tabBarController(controller, didSelectTab: controller.tabs[1], previousTab: controller.tabs[4])
        #expect(selected == 1)
    }

    @Test func leavingSettingsForClosetRestoresChromeWithoutDroppingSettingsReturn() {
        let state = AppState(deferOpening: true)
        state.selection = 4; state.profileSettings = true
        #expect(state.isSettingsVisible)
        // Agent's Open Closet keeps the retained Profile stack but changes roots.
        state.selection = 1
        #expect(!state.isSettingsVisible && state.profileSettings)
        state.selection = 4
        #expect(state.isSettingsVisible)
        state.profileSettings = false
        #expect(!state.isSettingsVisible)
    }

    @Test func readableDayDoesNotShiftAcrossExtremeTimezones() {
        let east = LocalPlanDay(year: 2026, month: 10, day: 16, timeZoneID: "Pacific/Kiritimati")
        let west = LocalPlanDay(year: 2026, month: 10, day: 16, timeZoneID: "Pacific/Honolulu")
        #expect(east.displayDate == west.displayDate)
        #expect(east.displayDate != east.key)
    }
}
