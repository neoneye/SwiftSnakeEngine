// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import SnakeGame

class T3100_StuckSnakeDetector: XCTestCase {
    func test1() {
        let detector = StuckSnakeDetector(humanReadableName: "TestPlayer")
        let body = SnakeBody.create(position: IntVec2(x: 10, y: 10), headDirection: .right, length: 3)
        XCTAssertFalse(detector.isStuck)
        detector.process(body: body)
        XCTAssertFalse(detector.isStuck)
        detector.process(body: body)
        XCTAssertFalse(detector.isStuck)
        detector.process(body: body)
        XCTAssertFalse(detector.isStuck)
        detector.process(body: body)
        XCTAssertTrue(detector.isStuck)
        detector.reset()
        detector.process(body: body)
        XCTAssertFalse(detector.isStuck)
    }
}
