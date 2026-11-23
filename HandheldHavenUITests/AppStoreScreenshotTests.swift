import XCTest
import UIKit

/// Captures App Store screenshots of the real app (Guideline 2.3.3).
/// Lives on the app-store-screenshots branch only. Does not change app behavior.
final class AppStoreScreenshotTests: XCTestCase {
    private var app: XCUIApplication!
    private var outputDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        let path = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"]
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("screens").path
        outputDirectory = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["-HandheldHavenUITesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        settle()
    }

    func testCaptureAppStoreScreenshots() throws {
        tab("Browse")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "BLIND BUYER'S GUIDE")).firstMatch.waitForExistence(timeout: 15))
        try capture("01-browse")

        tapRow("GPD WIN SERIES")
        try capture("02-chapter")

        tapRow("GPD Win (original)")
        XCTAssertTrue(app.staticTexts["HARDWARE"].waitForExistence(timeout: 10))
        try capture("03-device")
        app.buttons["Add to Compare"].tap()
        settle()
        goBack()
        tapRow("GPD Win 2")
        XCTAssertTrue(app.buttons["Add to Compare"].waitForExistence(timeout: 10))
        app.buttons["Add to Compare"].tap()
        settle()

        tab("Compare")
        XCTAssertTrue(app.switches["Show only differences"].waitForExistence(timeout: 10))
        try capture("04-compare")

        tab("Search")
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Project Kennan")
        XCTAssertTrue(app.staticTexts["resultCount"].waitForExistence(timeout: 10))
        dismissKeyboard()
        try capture("05-search")

        tab("Browse")
        scrollToTop()
        for _ in 0..<3 where app.navigationBars.buttons.count > 0 && !app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "BLIND BUYER'S GUIDE")).firstMatch.exists {
            goBack()
        }
        scrollToTop()
        tapRow("BLIND BUYER'S GUIDE")
        XCTAssertTrue(app.staticTexts["WHAT TO AVOID"].waitForExistence(timeout: 10))
        try capture("06-buyers-guide")
    }

    // MARK: - Capture

    private func capture(_ name: String) throws {
        settle()
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "\(prefix)-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        let url = outputDirectory.appendingPathComponent("\(prefix)-\(name).png")
        try shot.pngRepresentation.write(to: url)
        print("Wrote \(url.path)")
    }

    private var prefix: String {
        UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
    }

    private func tab(_ name: String) {
        let bar = app.tabBars.buttons[name]
        if bar.waitForExistence(timeout: 8) {
            bar.tap()
        } else {
            let any = app.buttons.matching(NSPredicate(format: "label == %@", name)).firstMatch
            XCTAssertTrue(any.waitForExistence(timeout: 5), "tab \(name)")
            any.tap()
        }
        settle()
    }

    private func rowCandidates(_ p: String) -> [XCUIElement] {
        let pred = NSPredicate(format: "label BEGINSWITH %@", p)
        return [app.buttons.matching(pred).firstMatch, app.cells.matching(pred).firstMatch]
    }

    private func tapRow(_ p: String) {
        let deadline = Date().addingTimeInterval(6)
        var element = rowCandidates(p).first(where: \.exists)
        while element == nil && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            element = rowCandidates(p).first(where: \.exists)
        }
        var swipes = 0
        while element?.isHittable != true && swipes < 20 {
            app.swipeUp()
            swipes += 1
            element = rowCandidates(p).first(where: \.exists)
        }
        XCTAssertTrue(element?.exists == true, "row starting with \(p)")
        element?.tap()
        settle()
    }

    private func goBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        settle()
    }

    private func scrollToTop() {
        for _ in 0..<4 { app.swipeDown() }
    }

    private func dismissKeyboard() {
        for key in ["Search", "search", "Done"] where app.keyboards.buttons[key].exists {
            app.keyboards.buttons[key].tap()
            return
        }
    }

    private func settle() {
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
    }
}
