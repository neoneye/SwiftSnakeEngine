// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import SnakeGame

class T3100_StuckSnakeDetector: XCTestCase {
    func test0_isStuck() {
        let detector = StuckSnakeDetectorForwardHistory(humanReadableName: "TestPlayer")
        let body = SnakeBody.create(position: IntVec2(x: 10, y: 10), headDirection: .right, length: 3)
        do {
            XCTAssertFalse(detector.isStuck)
            detector.append(body)
            XCTAssertFalse(detector.isStuck)
            detector.append(body)
            XCTAssertFalse(detector.isStuck)
            detector.append(body)
            XCTAssertFalse(detector.isStuck)
            detector.append(body)
            XCTAssertTrue(detector.isStuck, "Encountering the same pattern over and over, must trigger isStuck")
        }

        // Check that reset does reset things.
        detector.reset()
        XCTAssertFalse(detector.isStuck)
        detector.append(body)
        XCTAssertFalse(detector.isStuck)
    }

    func test1_undo() {
        let detector = StuckSnakeDetector(humanReadableName: "TestPlayer")

        // Undoing when there is no data, should not do anything.
        detector.undo()
        XCTAssertFalse(detector.isStuck)

        let body = SnakeBody.create(position: IntVec2(x: 10, y: 10), headDirection: .right, length: 3)
        do {
            XCTAssertFalse(detector.isStuck)
            detector.append(body)
            XCTAssertFalse(detector.isStuck)
            detector.append(body)
            XCTAssertFalse(detector.isStuck)
            detector.append(body)
            XCTAssertFalse(detector.isStuck)
            detector.append(body)
            XCTAssertTrue(detector.isStuck, "Encountering the same pattern over and over, must trigger isStuck")
        }

        // Remove the last event that caused the snake to get stuck
        // And check that it's not unstuck.
        detector.undo()
        XCTAssertFalse(detector.isStuck, "After undoing the last event, the snake must now be unstuck")

        // Append the same event that caused the snake to get stuck
        // And check that it's now again stuck.
        detector.append(body)
        XCTAssertTrue(detector.isStuck, "Encountering the same pattern over and over, must trigger isStuck")
    }
}
