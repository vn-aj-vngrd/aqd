import XCTest

@MainActor
final class EntryFlowTests: XCTestCase {
    private var app: XCUIApplication!
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--aqd-ui-testing"]
        app.launchEnvironment["AQD_TEST_STORE_ID"] = UUID().uuidString
        app.launch()
    }
    override func tearDown() async throws {
        if testRun?.failureCount ?? 0 > 0 { capture("Entry failure — \(name)") }
        app.terminate()
        try await super.tearDown()
    }

    func testFreshWelcomeExploreAndReturningLaunchDoNotCompletePreferences() {
        XCTAssertTrue(app.buttons["Start my closet"].waitForExistence(timeout: 10))
        capture("E1 fresh Welcome with immediately available actions")
        app.buttons["Start my closet"].tap()
        XCTAssertTrue(app.navigationBars["Start privately"].waitForExistence(timeout: 5))
        capture("E2 private introduction before optional questionnaire")
        app.buttons["Explore first"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Start my closet"].exists)
        openSettings()
        app.buttons["Style, Edit preferences"].tap()
        XCTAssertTrue(app.navigationBars["Your goals"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Continue"].isEnabled)
        XCTAssertEqual(app.buttons["No preference"].value as? String, "Not selected")
        capture("E2 bypass does not fabricate completed preferences")
    }

    func testOnboardingDraftResumesAndAcknowledgedSaveOpensTourThenRealCapture() {
        app.buttons["Start my closet"].tap()
        app.buttons["Personalize my closet"].tap()
        XCTAssertTrue(app.navigationBars["Your goals"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Skip setup"].exists)
        XCTAssertFalse(app.buttons["Skip question"].exists)
        app.buttons["No preference"].tap(); app.buttons["Continue"].tap()
        app.buttons["Work"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(app.navigationBars["Your occasions"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["Work"].value as? String, "Selected")
        capture("E1 onboarding interruption resumes the real draft")
        app.buttons["Continue"].tap()
        for _ in 0..<2 { app.buttons["No preference"].tap(); app.buttons["Continue"].tap() }
        app.buttons["Prefer not to share body details"].tap(); app.buttons["Continue"].tap()
        app.buttons["No color or pattern preference"].tap(); app.buttons["Continue"].tap()
        app.buttons["Save preferences"].tap()
        XCTAssertTrue(app.staticTexts["Preferences saved"].waitForExistence(timeout: 5))
        capture("E4 saved preferences offer Take the tour and Open my closet")
        app.buttons["style.saved.continue"].tap()
        finishOnboardingTour()
        app.buttons["Add piece"].tap()
        XCTAssertTrue(app.navigationBars["Add piece"].waitForExistence(timeout: 5))
        assertFreshCapture()
        capture("E4 onboarding success opens an empty real capture task")
        app.buttons["capture.back"].tapAfterSystemBannersClear(in: app)
        app.terminate(); app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Start my closet"].exists)
    }

    func testSavedPreferencesCanOpenTheRealClosetWithoutTakingTheTour() {
        app.buttons["Start my closet"].tap(); app.buttons["Personalize my closet"].tap()
        XCTAssertTrue(app.navigationBars["Your goals"].waitForExistence(timeout: 5))
        for _ in 0..<4 { app.buttons["No preference"].tap(); app.buttons["Continue"].tap() }
        app.buttons["Prefer not to share body details"].tap(); app.buttons["Continue"].tap()
        app.buttons["No color or pattern preference"].tap(); app.buttons["Continue"].tap()
        app.buttons["Save preferences"].tap()
        XCTAssertTrue(app.staticTexts["Preferences saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["style.saved.continue"].label, "Take the tour")
        capture("E4 Welcome-pattern saved receipt with tour and real Closet destinations")
        app.buttons["style.saved.closet"].tap()
        XCTAssertTrue(app.staticTexts["Your closet starts here"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Finish tour"].exists)
        capture("E4 saved receipt opens the actual empty Closet without sample records")
        app.terminate(); app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Start my closet"].exists)
        openSettings(); app.buttons["Style, Edit preferences"].tap()
        XCTAssertTrue(app.navigationBars["Your goals"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["No preference"].value as? String, "Selected")
    }

    func testDarkWelcomeTourReadyAndWordmarkRemainReadable() {
        app.terminate()
        app.launchArguments = ["--aqd-ui-testing"]
        app.launchEnvironment["AQD_TEST_APPEARANCE"] = "dark"
        app.launch()
        testWelcomeTourBackResumeFinishAndReadyCreateNoDemoPieces()
    }

    func testOnboardingCancelAndFailedSavePreservePrivateEntryAndResumeReview() {
        app.terminate()
        app.launchEnvironment["AQD_TEST_DENIED_STYLE_SAVE"] = "1"
        app.launch()
        app.buttons["Start my closet"].tap(); app.buttons["Personalize my closet"].tap()
        XCTAssertFalse(app.navigationBars["Start privately"].buttons["Back"].isHittable, "The background navigation control is inert")
        app.buttons["Wear more of my closet"].tap()
        app.buttons["style.back"].tapAfterSystemBannersClear(in: app); app.buttons["Discard draft"].tap()
        XCTAssertTrue(app.navigationBars["Start privately"].waitForExistence(timeout: 5))
        capture("E4 onboarding cancellation returns to private introduction")
        let personalize = app.buttons["Personalize my closet"]
        XCTAssertTrue(personalize.wait(for: \.isHittable, toEqual: true, timeout: 5))
        personalize.tap()
        XCTAssertFalse(app.buttons["Continue"].isEnabled)
        for _ in 0..<4 { app.buttons["No preference"].tap(); app.buttons["Continue"].tap() }
        app.buttons["Prefer not to share body details"].tap(); app.buttons["Continue"].tap()
        app.buttons["No color or pattern preference"].tap(); app.buttons["Continue"].tap()
        app.buttons["Save preferences"].tap()
        XCTAssertTrue(app.buttons["Retry save"].waitForExistence(timeout: 5))
        capture("E4 onboarding failed save retains review without entering the closet")
        app.terminate(); app.launchEnvironment.removeValue(forKey: "AQD_TEST_DENIED_STYLE_SAVE"); app.launch()
        XCTAssertTrue(app.navigationBars["Review preferences"].waitForExistence(timeout: 10))
        app.buttons["Save preferences"].tap()
        XCTAssertTrue(app.staticTexts["Preferences saved"].waitForExistence(timeout: 5))
        capture("E4 saved preferences offer Take the tour and Open my closet")
        app.buttons["style.saved.continue"].tap()
        finishOnboardingTour()
        app.buttons["Add piece"].tap()
        XCTAssertTrue(app.navigationBars["Add piece"].waitForExistence(timeout: 5))
        capture("E4 retained onboarding operation succeeds and opens actual capture")
    }

    func testPrivateExplanationAndReadyFirstPieceUseRealManualCapture() {
        app.buttons["Start my closet"].tap()
        app.buttons["Private on this iPhone, Learn more"].tap()
        XCTAssertTrue(app.navigationBars["Your closet, privately"].waitForExistence(timeout: 5))
        capture("E1 private storage and device-loss explanation")
        app.buttons["Back"].tapAfterSystemBannersClear(in: app)
        app.buttons["Take the tour"].tap()
        for _ in 0..<3 { app.buttons["Next"].tap() }
        app.buttons["Finish tour"].tap()
        XCTAssertTrue(app.buttons["Add piece"].waitForExistence(timeout: 5))
        app.buttons["Add piece"].tap()
        XCTAssertTrue(app.navigationBars["Add piece"].waitForExistence(timeout: 5))
        assertFreshCapture()
        capture("E5 Ready opens manual capture without carrying demo imagery")
        let name = app.textFields["capture.field.name"]
        name.tap(); name.typeText("Disposable isolated draft")
        app.buttons["capture.options"].tap(); app.buttons["capture.discard"].tap()
        XCTAssertTrue(app.buttons["Keep editing"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Discard this draft?"].exists)
        capture("E1 native capture discard sheet with blue safe and red destructive actions")
        app.buttons["Discard draft"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        app.buttons["root.tab.closet"].tap()
        XCTAssertTrue(app.staticTexts["Your closet starts here"].waitForExistence(timeout: 5))
        capture("E1 explicit content-draft discard leaves saved pieces unchanged")
    }

    func testWelcomeTourBackResumeFinishAndReadyCreateNoDemoPieces() {
        app.buttons["Take a quick tour"].tap()
        XCTAssertTrue(app.staticTexts["1 of 4 · Preview only"].waitForExistence(timeout: 5))
        app.buttons["Back"].tapAfterSystemBannersClear(in: app)
        XCTAssertTrue(app.buttons["Start my closet"].waitForExistence(timeout: 5))
        app.buttons["Take a quick tour"].tap()
        capture("E5 Today preview is clearly illustrative and inert")
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["2 of 4 · Preview only"].exists)
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["2 of 4 · Preview only"].waitForExistence(timeout: 10))
        capture("E5 interrupted tour resumes Closet preview")
        app.buttons["Back"].tapAfterSystemBannersClear(in: app)
        XCTAssertTrue(app.staticTexts["1 of 4 · Preview only"].exists)
        app.buttons["Next"].tap(); app.buttons["Next"].tap()
        capture("E5 Agent preview")
        app.buttons["Next"].tap()
        capture("E5 Profile preview")
        app.buttons["Finish tour"].tap()
        XCTAssertTrue(app.staticTexts["Ready when you are"].waitForExistence(timeout: 5))
        capture("E5 Ready explains examples were never saved")
        app.buttons["Back"].tapAfterSystemBannersClear(in: app)
        XCTAssertTrue(app.staticTexts["4 of 4 · Preview only"].waitForExistence(timeout: 5))
        for _ in 0..<4 { app.buttons["tour.back"].tap() }
        XCTAssertTrue(app.buttons["Start my closet"].waitForExistence(timeout: 5), "Ready Back retains the original Welcome source")
        app.buttons["Take a quick tour"].tap()
        for _ in 0..<3 { app.buttons["Next"].tap() }
        app.buttons["Finish tour"].tap()
        app.buttons["Open Today"].tap()
        app.buttons["root.tab.closet"].tap()
        XCTAssertTrue(app.staticTexts["Your closet starts here"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Cotton shirt"].exists)
        capture("E5 actual Closet remains empty after the tour")
    }

    func testTourSkipAndSettingsReplayPreserveRealCaptureDraftAndSource() {
        app.buttons["Start my closet"].tap()
        app.buttons["Take the tour"].tap()
        XCTAssertFalse(app.navigationBars["Start privately"].buttons["Back"].isHittable, "The actual background stays inert during preview")
        app.buttons["Skip tour"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        app.buttons["root.tab.closet"].tap()
        app.buttons["closet.addPiece"].tap()
        XCTAssertTrue(app.textFields["capture.field.name"].waitForExistence(timeout: 5))
        app.textFields["capture.field.name"].tap(); app.textFields["capture.field.name"].typeText("Tour retained capture")
        app.buttons["capture.back"].tapAfterSystemBannersClear(in: app)
        openSettings()
        replayTour()
        app.buttons["Back"].tapAfterSystemBannersClear(in: app)
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        replayTour()
        for _ in 0..<3 { app.buttons["Next"].tap() }
        app.buttons["Finish tour"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        capture("E5 Settings replay returns to its actual source")
        app.buttons["root.tab.closet"].tap()
        app.buttons["closet.addPiece"].tap()
        XCTAssertEqual(app.textFields["capture.field.name"].value as? String, "Tour retained capture")
        capture("E5 real capture draft survives preview replay")
    }

    private func finishOnboardingTour() {
        XCTAssertTrue(app.staticTexts["1 of 4 · Preview only"].waitForExistence(timeout: 5))
        capture("E4 acknowledged onboarding starts the actual tour")
        for _ in 0..<3 { app.buttons["Next"].tap() }
        app.buttons["Finish tour"].tap()
        XCTAssertTrue(app.buttons["Add piece"].waitForExistence(timeout: 5))
    }

    private func openSettings() {
        app.buttons["root.tab.profile"].tap(); app.buttons["More"].tapAfterSystemBannersClear(in: app); app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }
    private func replayTour() {
        let replay = app.buttons["Take the tour, Preview only"]
        XCTAssertTrue(replay.wait(for: \.isHittable, toEqual: true, timeout: 5))
        replay.tap()
        XCTAssertTrue(app.staticTexts["1 of 4 · Preview only"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Settings"].buttons["Profile"].isHittable)
    }
    private func assertFreshCapture() {
        let name = app.textFields["capture.field.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        // iOS27 exposes a genuinely empty value as nil; a prompt is not input.
        XCTAssertEqual(name.value as? String ?? "", "")
        XCTAssertFalse(app.buttons["capture.save"].isEnabled)
        XCTAssertFalse(app.buttons["capture.options"].exists, "An empty Add task has no discard/delete action")
    }
    private func capture(_ title: String) {
        if app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'of 4 · Preview only'")).firstMatch.exists {
            for button in [app.buttons["tour.back"], app.buttons["Next"].exists ? app.buttons["Next"] : app.buttons["Finish tour"]] {
                XCTAssertTrue(button.isHittable)
                XCTAssertTrue(app.frame.contains(button.frame), "The complete tour footer action must fit the viewport")
            }
        }
        guard waitForUnobstructedAQD(app) else { return }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = title; attachment.lifetime = .keepAlways; add(attachment)
    }
}
