// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T3200_SnakeLevelManager: XCTestCase {

    func test_levelForId() {
        let uuid = UUID(uuidString: "cdeeadf2-31c9-48f4-852f-778b58086dd0")!
        guard let level: SnakeLevel = SnakeLevelManager.shared.level(id: uuid) else {
            XCTFail("Unable to locate level with uuid: '\(uuid)'")
            return
        }
        do {
            let body: SnakeBody = level.player1_body
            XCTAssertEqual(body.head.position, IntVec2(x: 12, y: 3))
            XCTAssertEqual(body.head.direction, SnakeHeadDirection.right)
            XCTAssertEqual(body.length, 9)
        }
        do {
            let body: SnakeBody = level.player2_body
            XCTAssertEqual(body.head.position, IntVec2(x: 2, y: 7))
            XCTAssertEqual(body.head.direction, SnakeHeadDirection.left)
            XCTAssertEqual(body.length, 9)
        }
        do {
            let foodPosition: UIntVec2 = level.initialFoodPosition
            XCTAssertEqual(foodPosition, UIntVec2(x: 13, y: 2))
        }
    }

}
