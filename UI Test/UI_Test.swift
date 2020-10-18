// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest

class UI_Test: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    func test0_launch() throws {
        snapshot("0Launch")
    }

    func test1_selectLevel0() throws {
        let app = XCUIApplication()
        // level 0 is already preselected via UserDefaults
        app.buttons["Select Level 0"].tap()
        guard app.buttons["IngameViewPauseButton"].waitForExistence(timeout: 2) else {
            XCTFail()
            return
        }
        snapshot("1Level0")
    }

    func test2_selectLevel3() throws {
        let app = XCUIApplication()
        app.buttons["Select Level 3"].tap()
        app.buttons["Select Level 3"].tap()
        guard app.buttons["IngameViewPauseButton"].waitForExistence(timeout: 2) else {
            XCTFail()
            return
        }
        snapshot("2Level3")
    }

    func test3_selectLevel4() throws {
        let app = XCUIApplication()
        app.buttons["Select Level 4"].tap()
        app.buttons["Select Level 4"].tap()
        guard app.buttons["IngameViewPauseButton"].waitForExistence(timeout: 2) else {
            XCTFail()
            return
        }
        snapshot("3Level4")
    }
}
