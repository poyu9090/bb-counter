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

        selectThousandBlindPreset(in: app)
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

        selectThousandBlindPreset(in: app)
        app.buttons["blind.showResult"].tap()

        let configure = app.buttons["timer.configure"]
        XCTAssertTrue(configure.waitForExistence(timeout: 5))
        configure.tap()

        let scheme = app.buttons["timer.scheme.0"]
        XCTAssertTrue(scheme.waitForExistence(timeout: 5))
        scheme.tap()

        // sheet 還在動畫時「開始」雖然存在卻點不到，等它可命中再按。
        let start = app.buttons["timer.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertTrue(
            start.waitForExistence(timeout: 5) && waitUntilHittable(start, timeout: 5),
            "timer.start 一直沒有變成可點狀態"
        )
        start.tap()

        let timerSwitch = app.switches["timer.toggle"]
        XCTAssertTrue(timerSwitch.waitForExistence(timeout: 5))
        // 關閉 sheet 後畫面還要一小段時間才把開關切成開啟。
        XCTAssertTrue(
            waitUntil(timeout: 5) { timerSwitch.value as? String == "1" },
            "計時器開關沒有變成啟用"
        )
    }

    @MainActor
    func testTabsReachEveryMainSection() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingResetDefaults"]
        app.launch()

        app.buttons["onboarding.continue"].tap()

        let addTenK = app.buttons["chip.plus.10k"]
        XCTAssertTrue(addTenK.waitForExistence(timeout: 5))
        addTenK.tap()
        app.buttons["chips.next"].tap()

        selectThousandBlindPreset(in: app)
        app.buttons["blind.showResult"].tap()

        XCTAssertTrue(app.scrollViews["result.screen"].waitForExistence(timeout: 5))

        let tabs = app.tabBars.buttons
        XCTAssertEqual(tabs.count, 4)

        // 行動線分頁
        tabs.element(boundBy: 1).tap()
        XCTAssertTrue(app.buttons["hand.create"].waitForExistence(timeout: 5))

        // 設定分頁：重置搬到這裡了
        tabs.element(boundBy: 3).tap()
        XCTAssertTrue(app.buttons["settings.reset"].waitForExistence(timeout: 5))

        // 回到儀表板
        tabs.element(boundBy: 0).tap()
        XCTAssertTrue(app.scrollViews["result.screen"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        waitUntil(timeout: timeout) { element.isHittable }
    }

    @MainActor
    private func waitUntil(timeout: TimeInterval, condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            _ = XCUIApplication().wait(for: .runningForeground, timeout: 0.2)
        }
        return condition()
    }

    /// 盲注預設是分頁輪播，只有目前頁的按鈕存在，所以要先用箭頭翻到 500/1000。
    @MainActor
    private func selectThousandBlindPreset(in app: XCUIApplication) {
        let nextPreset = app.buttons["blind.next"]
        XCTAssertTrue(nextPreset.waitForExistence(timeout: 5))
        let target = app.buttons["blind.preset.1000"]
        for _ in 0..<8 where !target.exists {
            nextPreset.tap()
        }
        XCTAssertTrue(target.waitForExistence(timeout: 5))
        target.tap()
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
