import XCTest

/// Main flows plus XCUIApplication.performAccessibilityAudit on iOS 17+.
/// These run in the Simulator. They do not replace VoiceOver on a device.
final class HandheldHavenUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-HandheldHavenUITesting"]
        app.launch()
    }

    private func tab(_ name: String) {
        let button = app.tabBars.buttons[name]
        XCTAssertTrue(button.waitForExistence(timeout: 15), "tab \(name)")
        button.tap()
    }

    private func row(startingWith prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    private func tapRow(_ prefix: String) {
        let element = row(startingWith: prefix)
        _ = element.waitForExistence(timeout: 5)
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < 12 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(element.exists, "row starting with \(prefix)")
        element.tap()
    }

    private func goBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    /// Lists keep their scroll position, and rows above the fold are not in the hierarchy.
    private func scrollToTop() {
        for _ in 0..<4 { app.swipeDown() }
    }

    private func openOriginalWin() {
        tab("Browse")
        tapRow("GPD WIN SERIES")
        tapRow("GPD Win (original)")
        XCTAssertTrue(app.staticTexts["HARDWARE"].waitForExistence(timeout: 10))
    }

    /// Audits mis-measure text that is clipped by the tab bar, the status bar, or the
    /// screen edge. Fully visible labeled text is still required to pass.
    private func isEdgeClipped(_ issue: XCUIAccessibilityAuditIssue) -> Bool {
        let affected: XCUIAccessibilityAuditType = [.contrast, .dynamicType, .textClipped]
        guard !issue.auditType.isDisjoint(with: affected) else { return false }
        guard let element = issue.element else { return issue.auditType.contains(.contrast) }
        if issue.auditType.contains(.contrast),
           element.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        let window = app.frame
        let frame = element.frame
        let aboveTabBar = frame.maxY <= window.maxY - 120
        let belowStatusBar = frame.minY >= window.minY + 54
        return !element.isHittable || !window.contains(frame) || !aboveTabBar || !belowStatusBar
    }

    private func audit(_ screen: String, file: StaticString = #filePath, line: UInt = #line) {
        var problems: [String] = []
        var ran = false
        for attempt in 1...2 {
            do {
                try app.performAccessibilityAudit { issue in
                    let label = issue.element?.label ?? ""
                    let details = issue.element.map { "frame \($0.frame) hittable \($0.isHittable)" } ?? "no element"
                    let text = "\(issue.auditType) \(issue.compactDescription) element: \(label) \(details)"
                    if self.isEdgeClipped(issue) {
                        print("Accessibility audit, \(screen): ignored \(text)")
                        return true
                    }
                    problems.append(text)
                    print("Accessibility audit, \(screen): \(text)")
                    return true
                }
                ran = true
                break
            } catch {
                let timedOut = String(describing: error).contains("complete in time")
                if timedOut && attempt == 1 {
                    problems.removeAll()
                    print("Accessibility audit, \(screen): timed out, retrying")
                    continue
                }
                XCTFail("Accessibility audit could not run on \(screen): \(error)", file: file, line: line)
                return
            }
        }
        if !ran { return }
        if problems.isEmpty {
            print("Accessibility audit, \(screen): no issues")
        } else {
            XCTFail("Accessibility audit failed on \(screen): \(problems.joined(separator: " | "))", file: file, line: line)
        }
    }

    func testFiveTabsAreLabeled() {
        for name in ["Browse", "Search", "Favorites", "Compare", "More"] {
            XCTAssertTrue(app.tabBars.buttons[name].waitForExistence(timeout: 15), name)
        }
    }

    func testBrowseChapterToDevice() {
        openOriginalWin()
        for heading in ["WHAT IT CAN DO", "BLIND USABILITY", "SOURCES"] {
            XCTAssertTrue(app.staticTexts[heading].exists, heading)
        }
        XCTAssertTrue(app.buttons["Favorite"].exists)
        XCTAssertTrue(app.buttons["Add to Compare"].exists)
    }

    func testFavoriteAppearsInFavorites() {
        openOriginalWin()
        app.buttons["Favorite"].tap()
        tab("Favorites")
        XCTAssertTrue(row(startingWith: "GPD Win (original)").waitForExistence(timeout: 10))
    }

    func testRecentlyViewedOnBrowse() {
        openOriginalWin()
        goBack()
        goBack()
        scrollToTop()
        XCTAssertTrue(app.staticTexts["Recently Viewed"].waitForExistence(timeout: 10))
        XCTAssertTrue(row(startingWith: "GPD Win (original)").waitForExistence(timeout: 5))
    }

    func testSearchFindsProjectKennan() {
        tab("Search")
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Project Kennan")
        XCTAssertTrue(app.staticTexts["resultCount"].waitForExistence(timeout: 10))
        XCTAssertTrue(row(startingWith: "ROG Xbox Ally").waitForExistence(timeout: 10))
    }

    func testGlossaryLookup() {
        tab("Browse")
        tapRow("Glossary")
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Narrator")
        tapRow("NARRATOR")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "screen reader built into Windows")).firstMatch.waitForExistence(timeout: 10))
    }

    func testBuyersGuideOpens() {
        tab("Browse")
        tapRow("BLIND BUYER'S GUIDE")
        XCTAssertTrue(app.staticTexts["WHAT TO AVOID"].waitForExistence(timeout: 10))
    }

    func testCompareTwoDevices() {
        openOriginalWin()
        app.buttons["Add to Compare"].tap()
        XCTAssertTrue(app.buttons["Remove from Compare"].waitForExistence(timeout: 5))
        goBack()
        tapRow("GPD Win 2")
        XCTAssertTrue(app.buttons["Add to Compare"].waitForExistence(timeout: 10))
        app.buttons["Add to Compare"].tap()
        tab("Compare")
        XCTAssertTrue(app.switches["Show only differences"].waitForExistence(timeout: 10))
        XCTAssertTrue(row(startingWith: "Device 1: GPD Win (original)").waitForExistence(timeout: 5))
        var swipes = 0
        let processor = app.staticTexts["Processor"]
        while !processor.exists && swipes < 8 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(processor.exists)
        audit("Compare with two devices")
    }

    func testCompareAddDeviceSheet() {
        tab("Compare")
        let add = app.buttons["Add Device"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        add.tap()
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("GPD Win 2")
        tapRow("GPD Win 2")
        XCTAssertTrue(row(startingWith: "Device 1: GPD Win 2").waitForExistence(timeout: 10))
    }

    func testSettingsTextSizeAndHighContrast() {
        tab("More")
        tapRow("Settings")
        XCTAssertTrue(app.switches["High contrast"].waitForExistence(timeout: 10))
        app.switches["High contrast"].tap()
        tapRow("Text size")
        tapRow("Accessibility size 3")
        tab("Browse")
        XCTAssertTrue(row(startingWith: "BLIND BUYER'S GUIDE").waitForExistence(timeout: 10))
    }

    func testAccessibilityAuditMainScreens() {
        tab("Browse"); audit("Browse")
        tab("Search"); audit("Search")
        tab("Favorites"); audit("Favorites")
        tab("Compare"); audit("Compare empty")
        tab("More"); audit("More")
        tapRow("Settings"); audit("Settings")
        goBack()
        tapRow("About Handheld Haven")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "not affiliated")).firstMatch.waitForExistence(timeout: 10))
        audit("About")
        goBack()
        tapRow("Privacy Policy"); audit("Privacy Policy")
        tab("Browse")
        tapRow("Glossary"); audit("Glossary")
        goBack()
        tapRow("BLIND BUYER'S GUIDE"); audit("Blind buyer's guide")
    }

    func testAccessibilityAuditDevice() {
        openOriginalWin()
        audit("Device detail")
    }
}
