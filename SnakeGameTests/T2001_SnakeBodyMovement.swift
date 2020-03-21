// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import SnakeGame

class T2001_SnakeBodyMovement: XCTestCase {
    func test0_comparable() {
        let expected: [SnakeBodyMovement] = [.dontMove, .moveCCW, .moveForward, .moveCW]
        let actual: [SnakeBodyMovement] = expected.reversed().sorted()
        XCTAssertEqual(actual, expected)
    }
}
