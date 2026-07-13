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
        app.launchArguments += ["-initialTab", "search"]
        app.launch()

        let searchField = app.textFields["search.field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("xyz")

        XCTAssertTrue(app.descendants(matching: .any)["search.empty"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["검색어 지우기"].exists)
    }

    @MainActor
    func testProductSearchShowsColaPackageChoices() {
        let app = XCUIApplication()
        app.launchArguments += ["-initialTab", "search"]
        app.launch()

        let searchField = app.textFields["search.field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("콜라")

        XCTAssertTrue(app.descendants(matching: .any)["search.family.cola"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["알루미늄·철 콜라캔"].exists)
        XCTAssertTrue(app.staticTexts["무색 투명 PET 콜라병"].exists)
        XCTAssertTrue(app.staticTexts["유리 콜라병"].exists)
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
