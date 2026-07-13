//
//  odbrUITests.swift
//  odbrUITests
//
//  Created by 이현규 on 7/7/26.
//

import XCTest

final class odbrUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDefaultLaunchShowsScanFlow() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.scrollViews["scan.screen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["scan.capture"].exists)
        XCTAssertTrue(app.tabBars.buttons["스캔"].isSelected)
    }

    @MainActor
    func testGuideSearchShowsEmptyState() {
        let app = XCUIApplication()
        app.launchArguments += ["-initialTab", "guide"]
        app.launch()

        let searchField = app.textFields["guide.search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("xyz")

        XCTAssertTrue(app.descendants(matching: .any)["guide.empty"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["검색어 지우기"].exists)
    }

    @MainActor
    func testNephronLaunchShowsOfficialGuide() {
        let app = XCUIApplication()
        app.launchArguments += ["-initialTab", "nephron"]
        app.launch()

        XCTAssertTrue(app.scrollViews["nephron.screen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["가까운 회수기 찾기"].exists)
        XCTAssertTrue(app.staticTexts["투명 페트병"].exists)

        app.scrollViews["nephron.screen"].swipeUp()
        XCTAssertTrue(app.descendants(matching: .any)["nephron.officialLink"].waitForExistence(timeout: 2))
    }
}
