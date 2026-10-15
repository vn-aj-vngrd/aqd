import XCTest

/// Real user routes and local writes in a UUID-isolated closet. No Photos fixture.
@MainActor
final class StyleFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--aqd-ui-testing"]
        app.launchEnvironment["AQD_TEST_STORE_ID"] = UUID().uuidString
        app.launchEnvironment["AQD_TEST_RETURNING_ENTRY"] = "1"
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }
    override func tearDown() async throws {
        if testRun?.failureCount ?? 0 > 0 { capture("Failure — \(name)") }
        app.terminate()
        try await super.tearDown()
    }

    func testProfileExplicitAnswersReviewEditAndSavedRelaunch() {
        openStyle(settings: false)
        XCTAssertFalse(app.buttons["Continue"].isEnabled)
        app.buttons["Wear more of my closet"].tap()
        app.buttons["Plan outfits faster"].tap()
        app.buttons["Try new combinations"].tap()
        XCTAssertEqual(app.buttons["Try new combinations"].value as? String, "Not selected")
        capture("E3 goals explicit selection and two-choice limit")
        app.buttons["Continue"].tap()
        app.buttons["Work"].tap()
        app.buttons["Continue"].tap()
        app.buttons["Classic"].tap()
        app.buttons["Continue"].tap()
        app.buttons["Relaxed"].tap()
        app.buttons["Continue"].tap()
        declineBodyAndColors()
        XCTAssertTrue(app.staticTexts["6 of 6 questions answered"].exists)
        capture("E3 mixed answered review with body use off")
        app.buttons["style.review.0"].tap()
        XCTAssertEqual(app.buttons["Wear more of my closet"].value as? String, "Selected")
        app.buttons["Back to review"].tap()
        saveAndFinish()
        XCTAssertTrue(app.navigationBars["Profile"].exists)
        app.terminate(); app.launch()
        openStyle(settings: false)
        XCTAssertEqual(app.buttons["Wear more of my closet"].value as? String, "Selected")
        XCTAssertEqual(app.buttons["Plan outfits faster"].value as? String, "Selected")
        capture("E4 saved preferences restored after relaunch")
    }

    func testSettingsDraftRelaunchDiscardAndAllDeclinedSaveReturnToCaller() {
        openStyle(settings: true)
        app.buttons["Wear more of my closet"].tap()
        app.buttons["Continue"].tap()
        app.buttons["Travel"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(app.navigationBars["Your occasions"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["Travel"].value as? String, "Selected")
        capture("E4 Settings draft resumes same step and answers")
        app.buttons["Back"].tapAfterSystemBannersClear(in: app)
        XCTAssertTrue(app.navigationBars["Your goals"].exists)
        XCTAssertEqual(app.buttons["Wear more of my closet"].value as? String, "Selected")
        app.buttons["Back"].tapAfterSystemBannersClear(in: app)
        keepEditing()
        XCTAssertTrue(app.navigationBars["Your goals"].exists)
        app.buttons["Continue"].tap()
        XCTAssertEqual(app.buttons["Travel"].value as? String, "Selected")
        app.buttons["Back"].tapAfterSystemBannersClear(in: app); app.buttons["Back"].tapAfterSystemBannersClear(in: app); app.buttons["Discard draft"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        openSettingsStyle()
        XCTAssertFalse(app.buttons["Continue"].isEnabled)
        completeRefusals()
        capture("E3 explicit all-declined review is valid")
        saveAndFinish()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        openSettingsStyle()
        XCTAssertEqual(app.buttons["No preference"].value as? String, "Selected")
        app.buttons["Wear more of my closet"].tap()
        app.buttons["Back"].tapAfterSystemBannersClear(in: app); app.buttons["Discard draft"].tap()
        openSettingsStyle()
        XCTAssertEqual(app.buttons["No preference"].value as? String, "Selected")
        capture("E4 cancel retains prior saved preferences and Settings source")
    }

    func testConfirmedSaveFailureRetainsReviewAndSameDraftCanRetryAfterRestart() {
        app.terminate()
        app.launchEnvironment["AQD_TEST_DENIED_STYLE_SAVE"] = "1"
        app.launch()
        openStyle(settings: true)
        completeRefusals()
        app.buttons["Save preferences"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Preferences weren’t saved.")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Review preferences"].exists)
        capture("E4 confirmed write failure keeps review and recovery")
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "AQD_TEST_DENIED_STYLE_SAVE")
        app.launch()
        XCTAssertTrue(app.navigationBars["Review preferences"].waitForExistence(timeout: 10))
        saveAndFinish()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        capture("E4 same retained preference task succeeds after restart")
    }

    func testUnknownAcknowledgmentChecksSameSaveAndRelaunchRecoversReceipt() {
        app.terminate()
        app.launchEnvironment["AQD_TEST_UNKNOWN_STYLE_SAVE"] = "1"
        app.launch()
        openStyle(settings: true)
        completeRefusals()
        app.buttons["Save preferences"].tap()
        XCTAssertTrue(app.buttons["Check save"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Back"].isEnabled)
        capture("E4 unknown acknowledgment freezes editing and offers reconciliation")
        app.buttons["Check save"].tap()
        XCTAssertTrue(app.staticTexts["Preferences saved"].waitForExistence(timeout: 5))
        app.buttons["style.saved.continue"].tap()
        openSettingsStyle()
        app.buttons["Wear more of my closet"].tap()
        for _ in 0..<6 { app.buttons["Continue"].tap() }
        app.buttons["Save preferences"].tap()
        XCTAssertTrue(app.buttons["Check save"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["Preferences saved"].waitForExistence(timeout: 10))
        capture("E4 interrupted acknowledgment recovers the durable exact receipt")
        app.buttons["style.saved.continue"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }

    private func openStyle(settings: Bool) {
        app.buttons["root.tab.profile"].tap()
        app.buttons["More"].tapAfterSystemBannersClear(in: app)
        if settings { app.buttons["Settings"].tap(); openSettingsStyle() }
        else {
            let style = app.buttons["Style"]
            XCTAssertTrue(style.wait(for: \.isHittable, toEqual: true, timeout: 5))
            style.tap()
        }
        XCTAssertTrue(app.navigationBars["Your goals"].waitForExistence(timeout: 5))
    }
    private func completeRefusals() {
        for _ in 0..<4 { app.buttons["No preference"].tap(); app.buttons["Continue"].tap() }
        declineBodyAndColors()
    }
    private func openSettingsStyle() {
        let style = app.buttons["Style, Edit preferences"]
        XCTAssertTrue(style.wait(for: \.isHittable, toEqual: true, timeout: 5), "Wait for the actual Settings control after native cover dismissal")
        style.tap()
        XCTAssertTrue(app.navigationBars["Your goals"].waitForExistence(timeout: 5))
    }
    private func declineBodyAndColors() {
        XCTAssertEqual(app.switches["Use body details for suggestions"].value as? String, "0")
        app.buttons["Prefer not to share body details"].tap()
        app.buttons["Continue"].tap()
        app.buttons["No color or pattern preference"].tap()
        app.buttons["Continue"].tap()
    }
    private func saveAndFinish() {
        app.buttons["Save preferences"].tap()
        XCTAssertTrue(app.staticTexts["Preferences saved"].waitForExistence(timeout: 5))
        capture("E4 acknowledged preference save")
        app.buttons["style.saved.continue"].tap()
    }
    private func keepEditing() {
        let keep = app.buttons["Keep editing"]
        XCTAssertTrue(keep.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Discard this preference draft?"].exists)
        capture("E4 native discard sheet with blue safe and red destructive actions")
        keep.tap()
        XCTAssertTrue(keep.waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.buttons["Wear more of my closet"].value as? String, "Selected")
    }
    private func capture(_ title: String) {
        guard waitForUnobstructedAQD(app) else { return }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = title; attachment.lifetime = .keepAlways; add(attachment)
    }
}
