//
//  BB_counterUITests.swift
//  BB counterUITests
//
//  Created by user on 2026/1/18.
//

import XCTest

final class BB_counterUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testStackEntryFlowShowsResultDashboard() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingResetDefaults"]
        app.launch()

        app.buttons["onboarding.continue"].tap()

        let addTenK = app.buttons["chip.plus.10k"]
        XCTAssertTrue(addTenK.waitForExistence(timeout: 5))
        addTenK.tap()
        addTenK.tap()
        app.buttons["chip.plus.5k"].tap()
        app.buttons["chips.next"].tap()

        let blindPreset = app.buttons["blind.preset.1000"]
        XCTAssertTrue(blindPreset.waitForExistence(timeout: 5))
        blindPreset.tap()
        app.buttons["blind.showResult"].tap()

        XCTAssertTrue(app.scrollViews["result.screen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["timer.configure"].exists)
        XCTAssertTrue(app.switches["timer.toggle"].exists)
    }

    @MainActor
    func testTimerConfigStartsBlindTimer() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingResetDefaults"]
        app.launch()

        app.buttons["onboarding.continue"].tap()

        let addTenK = app.buttons["chip.plus.10k"]
        XCTAssertTrue(addTenK.waitForExistence(timeout: 5))
        addTenK.tap()
        app.buttons["chips.next"].tap()

        let blindPreset = app.buttons["blind.preset.1000"]
        XCTAssertTrue(blindPreset.waitForExistence(timeout: 5))
        blindPreset.tap()
        app.buttons["blind.showResult"].tap()

        let configure = app.buttons["timer.configure"]
        XCTAssertTrue(configure.waitForExistence(timeout: 5))
        configure.tap()

        XCTAssertTrue(app.buttons["timer.scheme.0"].waitForExistence(timeout: 5))
        app.buttons["timer.scheme.0"].tap()
        app.buttons["timer.start"].tap()

        let timerSwitch = app.switches["timer.toggle"]
        XCTAssertTrue(timerSwitch.waitForExistence(timeout: 5))
        XCTAssertEqual(timerSwitch.value as? String, "1")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
