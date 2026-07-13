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
        XCTAssertTrue(app.buttons["scan.photoPicker"].exists)
        XCTAssertTrue(app.staticTexts["오디버려"].exists)
        XCTAssertTrue(app.buttons["app.information"].exists)
        XCTAssertTrue(app.tabBars.buttons["스캔"].isSelected)
    }

    @MainActor
    func testGuideSearchShowsEmptyState() {
        let app = XCUIApplication()
        app.launchArguments += ["-initialTab", "search"]
        app.launch()

        let searchField = app.textFields["search.field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["app.information"].exists)

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
        XCTAssertTrue(app.buttons["app.information"].exists)
        XCTAssertTrue(app.staticTexts["가까운 회수기 찾기"].exists)
        XCTAssertTrue(app.staticTexts["투명 음료 페트병"].exists)

        app.scrollViews["nephron.screen"].swipeUp()
        XCTAssertTrue(app.descendants(matching: .any)["nephron.officialLink"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testCorrectionSheetPreservesRankedAlternatives() {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestScenario", "correction"]
        app.launch()

        XCTAssertTrue(app.buttons["result.correct"].waitForExistence(timeout: 5))
        app.buttons["result.correct"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["result.correctionSheet"].waitForExistence(timeout: 2))
        let firstCandidate = app.buttons["result.correction.recyclable.vinylPackaging"]
        XCTAssertTrue(firstCandidate.exists)
        firstCandidate.tap()
        XCTAssertTrue(app.staticTexts["비닐류"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["result.confirm"].isEnabled)
    }

    @MainActor
    func testImageAnalysisConsentOffersSearchAlternative() {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestScenario", "consent"]
        app.launch()

        XCTAssertTrue(app.buttons["consent.agree"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["consent.search"].exists)
    }

    @MainActor
    func testCameraDeniedStateOffersSettingsAndSearch() {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestScenario", "cameraDenied"]
        app.launch()

        XCTAssertTrue(app.buttons["설정에서 카메라 허용"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["품목 검색 사용"].exists)
    }

    @MainActor
    func testNetworkFailureOffersRetryAndSearch() {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestScenario", "networkFailure"]
        app.launch()

        XCTAssertTrue(app.buttons["scan.retry"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["scan.searchFallback"].exists)
    }
}
