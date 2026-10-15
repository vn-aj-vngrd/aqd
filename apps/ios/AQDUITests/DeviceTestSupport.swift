import XCTest

/// Banners can cover native header controls on the owner's real phone.
/// Read only their presence, never their private text or notification action.
@MainActor
func waitForUnobstructedAQD(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) -> Bool {
    let banner = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        .descendants(matching: .any).matching(identifier: "NotificationShortLookView").firstMatch
    guard !banner.exists || banner.waitForNonExistence(timeout: 20) else {
        XCTFail("A system notification still covers AQD. No tap or screenshot was taken.", file: file, line: line)
        return false
    }
    guard app.state == .runningForeground else {
        XCTFail("AQD left the foreground. No tap or screenshot was taken.", file: file, line: line)
        return false
    }
    return true
}

@MainActor
extension XCUIElement {
    func tapAfterSystemBannersClear(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        guard waitForUnobstructedAQD(app, file: file, line: line) else { return }
        tap()
    }
}
