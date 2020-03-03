// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import SnakeGame

class T2000_SnakeHeadDirection: XCTestCase {
    func test0_description() {
        let directions: [SnakeHeadDirection] = [.up, .left, .right, .down]
        let actual: String = directions.map { "\($0)" }.joined(separator: " ")
        XCTAssertEqual(actual, "↑ ← → ↓")
    }

    func test1_rotatedCCW() {
        do {
            let actual = SnakeHeadDirection.up.rotatedCCW
            XCTAssertEqual(actual, .left)
        }
        do {
            let actual = SnakeHeadDirection.up.rotatedCCW.rotatedCCW
            XCTAssertEqual(actual, .down)
        }
        do {
            let actual = SnakeHeadDirection.left.rotatedCCW.rotatedCCW
            XCTAssertEqual(actual, .right)
        }
        do {
            let actual = SnakeHeadDirection.up.rotatedCCW.rotatedCCW.rotatedCCW.rotatedCCW
            XCTAssertEqual(actual, .up)
        }
        do {
            let actual = SnakeHeadDirection.left.rotatedCCW.rotatedCCW.rotatedCCW.rotatedCCW
            XCTAssertEqual(actual, .left)
        }
    }

    func test2_rotatedCW() {
        do {
            let actual = SnakeHeadDirection.up.rotatedCW
            XCTAssertEqual(actual, .right)
        }
        do {
            let actual = SnakeHeadDirection.up.rotatedCW.rotatedCW
            XCTAssertEqual(actual, .down)
        }
        do {
            let actual = SnakeHeadDirection.left.rotatedCW.rotatedCW
            XCTAssertEqual(actual, .right)
        }
        do {
            let actual = SnakeHeadDirection.up.rotatedCW.rotatedCW.rotatedCW.rotatedCW
            XCTAssertEqual(actual, .up)
        }
        do {
            let actual = SnakeHeadDirection.left.rotatedCW.rotatedCW.rotatedCW.rotatedCW
            XCTAssertEqual(actual, .left)
        }
    }
}
