// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import SnakeGame

class T2000_SnakeHead: XCTestCase {
    func test0_snakeHeadDirection_description() {
        let directions: [SnakeHeadDirection] = [.up, .left, .right, .down]
        let actual: String = directions.map { "\($0)" }.joined(separator: " ")
        XCTAssertEqual(actual, "↑ ← → ↓")
    }
}
