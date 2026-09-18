import XCTest

/// End-to-end UI coverage standing in for the "verify manually" steps in
/// tasks 4.5, 5.1, 5.2, 6.1, 6.3, 6.4, 7.1, 7.2, 7.3: this drives the real
/// app through its accessibility tree (there's no way for an automated
/// run to literally tap a screen or watch it, so this is the most
/// rigorous available substitute).
final class ResetTinnitusUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFreshLaunchFlowThroughDisclaimerAndPitchMatchToMain() {
        let app = launchFreshApp()

        let disclaimerButton = app.buttons["disclaimerAcknowledgeButton"]
        XCTAssertTrue(disclaimerButton.waitForExistence(timeout: 5), "expected the disclaimer on first launch")
        disclaimerButton.tap()

        let slider = app.sliders["pitchMatchSlider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5), "expected the pitch-match screen after acknowledging the disclaimer")
        let frequencyLabel = app.staticTexts["pitchMatchFrequencyLabel"]
        let initialFrequencyText = frequencyLabel.label

        slider.adjust(toNormalizedSliderPosition: 0.9)
        let updatedFrequencyText = frequencyLabel.label
        XCTAssertNotEqual(initialFrequencyText, updatedFrequencyText, "expected the frequency label to update live as the slider moves")

        app.buttons["pitchMatchConfirmButton"].tap()

        let matchedLabel = app.staticTexts["mainMatchedFrequencyLabel"]
        XCTAssertTrue(matchedLabel.waitForExistence(timeout: 5), "expected to land on the main screen with the matched frequency shown")

        let startButton = app.buttons["startSessionButton"]
        XCTAssertTrue(startButton.exists)
        XCTAssertTrue(startButton.isEnabled, "expected Start to be enabled once a frequency is stored")
    }

    func testRelaunchAfterMatchSkipsDisclaimer() {
        let app = launchFreshApp()
        completeOnboarding(app)
        app.terminate()

        let relaunched = XCUIApplication()
        relaunched.launch() // No reset argument: the stored frequency persists.
        let matchedLabel = relaunched.staticTexts["mainMatchedFrequencyLabel"]
        XCTAssertTrue(matchedLabel.waitForExistence(timeout: 5), "expected to land directly on the main screen, skipping the disclaimer")
        XCTAssertFalse(relaunched.buttons["disclaimerAcknowledgeButton"].exists)
    }

    func testStartStopSessionAndRematchFlow() {
        let app = launchFreshApp()
        completeOnboarding(app)

        let startButton = app.buttons["startSessionButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let remainingLabel = app.staticTexts["remainingTimeLabel"]
        XCTAssertTrue(remainingLabel.waitForExistence(timeout: 5), "expected Start to begin an active, visibly-counting-down session")
        let firstReading = remainingLabel.label

        Thread.sleep(forTimeInterval: 2)
        let secondReading = remainingLabel.label
        XCTAssertNotEqual(firstReading, secondReading, "expected the remaining-time display to count down while playing")

        let stopButton = app.buttons["stopSessionButton"]
        XCTAssertTrue(stopButton.exists)
        stopButton.tap()

        XCTAssertTrue(app.buttons["startSessionButton"].waitForExistence(timeout: 5), "expected Stop to return to the idle state immediately")

        app.buttons["rematchButton"].tap()

        XCTAssertTrue(app.sliders["pitchMatchSlider"].waitForExistence(timeout: 5), "expected re-match to reopen pitch matching")
        XCTAssertFalse(app.buttons["disclaimerAcknowledgeButton"].exists, "re-match must not show the disclaimer again")
    }

    func testSessionKeepsRunningInBackground() {
        let app = launchFreshApp()
        completeOnboarding(app)

        let startButton = app.buttons["startSessionButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let remainingLabel = app.staticTexts["remainingTimeLabel"]
        XCTAssertTrue(remainingLabel.waitForExistence(timeout: 5))
        let beforeBackground = Self.parseRemainingSeconds(remainingLabel.label)

        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 3)
        app.activate()

        let afterLabel = app.staticTexts["remainingTimeLabel"]
        XCTAssertTrue(afterLabel.waitForExistence(timeout: 5), "expected the session still active after returning from the background")
        let afterBackground = Self.parseRemainingSeconds(afterLabel.label)

        XCTAssertNotNil(beforeBackground)
        XCTAssertNotNil(afterBackground)
        if let before = beforeBackground, let after = afterBackground {
            XCTAssertLessThan(after, before, "expected the countdown to have advanced while the app was backgrounded, proving playback kept running")
        }

        app.buttons["stopSessionButton"].tap()
    }

    private func launchFreshApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestResetState"]
        app.launch()
        return app
    }

    private func completeOnboarding(_ app: XCUIApplication) {
        let disclaimerButton = app.buttons["disclaimerAcknowledgeButton"]
        if disclaimerButton.waitForExistence(timeout: 5) {
            disclaimerButton.tap()
        }
        let confirmButton = app.buttons["pitchMatchConfirmButton"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()
    }

    private static func parseRemainingSeconds(_ text: String) -> Int? {
        let parts = text.split(separator: ":").compactMap { Int($0) }
        guard !parts.isEmpty else { return nil }
        var total = 0
        for part in parts {
            total = total * 60 + part
        }
        return total
    }
}
