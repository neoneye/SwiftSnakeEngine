// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T2002_SnakeHead: XCTestCase {

    func test0_moveToward_nearestNeighbour() {
        let position_center = IntVec2(x: 100, y: 200)
        let position_up     = IntVec2(x: 100, y: 201)
        let position_down   = IntVec2(x: 100, y: 199)
        let position_left   = IntVec2(x:  99, y: 200)
        let position_right  = IntVec2(x: 101, y: 200)
        do {
            let head = SnakeHead(position: position_center, direction: .up)
            XCTAssertEqual(head.moveToward(position_up), .moveForward)
            XCTAssertNil(head.moveToward(position_down))
            XCTAssertEqual(head.moveToward(position_left), .moveCCW)
            XCTAssertEqual(head.moveToward(position_right), .moveCW)
            XCTAssertEqual(head.moveToward(position_center), .dontMove)
        }
        do {
            let head = SnakeHead(position: position_center, direction: .down)
            XCTAssertNil(head.moveToward(position_up))
            XCTAssertEqual(head.moveToward(position_down), .moveForward)
            XCTAssertEqual(head.moveToward(position_left), .moveCW)
            XCTAssertEqual(head.moveToward(position_right), .moveCCW)
            XCTAssertEqual(head.moveToward(position_center), .dontMove)
        }
        do {
            let head = SnakeHead(position: position_center, direction: .left)
            XCTAssertEqual(head.moveToward(position_up), .moveCW)
            XCTAssertEqual(head.moveToward(position_down), .moveCCW)
            XCTAssertEqual(head.moveToward(position_left), .moveForward)
            XCTAssertNil(head.moveToward(position_right))
            XCTAssertEqual(head.moveToward(position_center), .dontMove)
        }
        do {
            let head = SnakeHead(position: position_center, direction: .right)
            XCTAssertEqual(head.moveToward(position_up), .moveCCW)
            XCTAssertEqual(head.moveToward(position_down), .moveCW)
            XCTAssertNil(head.moveToward(position_left))
            XCTAssertEqual(head.moveToward(position_right), .moveForward)
            XCTAssertEqual(head.moveToward(position_center), .dontMove)
        }
    }

    func test1_moveToward_diagonal() {
        let position_center = IntVec2(x: 100, y: 200)
        do {
            let position_up_left = position_center.offsetBy(dx: -1, dy: 1)
            let position_up_right = position_center.offsetBy(dx: 1, dy: 1)
            let position_up_up_left = position_center.offsetBy(dx: -1, dy: 2)
            let position_up_up_right = position_center.offsetBy(dx: 1, dy: 2)
            let position_up_left_left = position_center.offsetBy(dx: -2, dy: 1)
            let position_up_right_right = position_center.offsetBy(dx: 2, dy: 1)

            let head = SnakeHead(position: position_center, direction: .up)
            XCTAssertEqual(head.moveToward(position_up_left), .moveForward)
            XCTAssertEqual(head.moveToward(position_up_right), .moveForward)
            XCTAssertEqual(head.moveToward(position_up_up_left), .moveForward)
            XCTAssertEqual(head.moveToward(position_up_up_right), .moveForward)
            XCTAssertEqual(head.moveToward(position_up_left_left), .moveCCW)
            XCTAssertEqual(head.moveToward(position_up_right_right), .moveCW)
        }
        do {
            let position_down_left = position_center.offsetBy(dx: -1, dy: -1)
            let position_down_right = position_center.offsetBy(dx: 1, dy: -1)
            let position_down_down_left = position_center.offsetBy(dx: -1, dy: -2)
            let position_down_down_right = position_center.offsetBy(dx: 1, dy: -2)
            let position_down_left_left = position_center.offsetBy(dx: -2, dy: -1)
            let position_down_right_right = position_center.offsetBy(dx: 2, dy: -1)

            let head = SnakeHead(position: position_center, direction: .down)
            XCTAssertEqual(head.moveToward(position_down_left), .moveForward)
            XCTAssertEqual(head.moveToward(position_down_right), .moveForward)
            XCTAssertEqual(head.moveToward(position_down_down_left), .moveForward)
            XCTAssertEqual(head.moveToward(position_down_down_right), .moveForward)
            XCTAssertEqual(head.moveToward(position_down_left_left), .moveCW)
            XCTAssertEqual(head.moveToward(position_down_right_right), .moveCCW)
        }
        do {
            let position_left_up = position_center.offsetBy(dx: -1, dy: 1)
            let position_left_down = position_center.offsetBy(dx: -1, dy: -1)
            let position_left_left_up = position_center.offsetBy(dx: -2, dy: 1)
            let position_left_left_down = position_center.offsetBy(dx: -2, dy: -1)
            let position_left_up_up = position_center.offsetBy(dx: -1, dy: 2)
            let position_left_down_down = position_center.offsetBy(dx: -1, dy: -2)

            let head = SnakeHead(position: position_center, direction: .left)
            XCTAssertEqual(head.moveToward(position_left_up), .moveForward)
            XCTAssertEqual(head.moveToward(position_left_down), .moveForward)
            XCTAssertEqual(head.moveToward(position_left_left_up), .moveForward)
            XCTAssertEqual(head.moveToward(position_left_left_down), .moveForward)
            XCTAssertEqual(head.moveToward(position_left_up_up), .moveCW)
            XCTAssertEqual(head.moveToward(position_left_down_down), .moveCCW)
        }
        do {
            let position_right_up = position_center.offsetBy(dx: 1, dy: 1)
            let position_right_down = position_center.offsetBy(dx: 1, dy: -1)
            let position_right_left_up = position_center.offsetBy(dx: 2, dy: 1)
            let position_right_left_down = position_center.offsetBy(dx: 2, dy: -1)
            let position_right_up_up = position_center.offsetBy(dx: 1, dy: 2)
            let position_right_down_down = position_center.offsetBy(dx: 1, dy: -2)

            let head = SnakeHead(position: position_center, direction: .right)
            XCTAssertEqual(head.moveToward(position_right_up), .moveForward)
            XCTAssertEqual(head.moveToward(position_right_down), .moveForward)
            XCTAssertEqual(head.moveToward(position_right_left_up), .moveForward)
            XCTAssertEqual(head.moveToward(position_right_left_down), .moveForward)
            XCTAssertEqual(head.moveToward(position_right_up_up), .moveCCW)
            XCTAssertEqual(head.moveToward(position_right_down_down), .moveCW)
        }
    }
}
