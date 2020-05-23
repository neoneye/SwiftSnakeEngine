// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T3300_SnakeCollisionDetector: XCTestCase {

    enum CreateError: Error {
        case message(message: String)
    }

    func create(player1Positions: [IntVec2], player2Positions: [IntVec2], foodPosition: IntVec2?) throws -> SnakeCollisionDetector {
        // Create level
        let levelBuilder = SnakeLevelBuilder(id: UUID(), size: UIntVec2(x: 10, y: 10))
        levelBuilder.installWallsAroundTheLevel()
        let level: SnakeLevel = levelBuilder.level()

        // Create player 1
        let body1: SnakeBody = try SnakeBodyAdvancedCreate.create(positions: player1Positions, checkEatingItself: false)
        var player1: SnakePlayer = SnakePlayer.create(id: .player1, role: .human)
        player1 = player1.playerWithNewSnakeBody(body1)
        guard player1.isInstalledAndAlive else {
            throw CreateError.message(message: "Inconsistency. At this point player1 should be installed and alive.")
        }

        // Create player 2
        let body2: SnakeBody = try SnakeBodyAdvancedCreate.create(positions: player2Positions, checkEatingItself: false)
        var player2: SnakePlayer = SnakePlayer.create(id: .player2, role: .human)
        player2 = player2.playerWithNewSnakeBody(body2)
        guard player2.isInstalledAndAlive else {
            throw CreateError.message(message: "Inconsistency. At this point player2 should be installed and alive.")
        }

        // Create SnakeCollisionDetector
        let detector: SnakeCollisionDetector = SnakeCollisionDetector.create(level: level, foodPosition: foodPosition, player1: player1, player2: player2)

        detector.process()
        return detector
    }

    func test100_noCollision_eatFood() throws {
        let a: [IntVec2] = [
            IntVec2(x: 4, y: 5),
            IntVec2(x: 5, y: 5),
            IntVec2(x: 6, y: 5),
        ]
        let b: [IntVec2] = [
            IntVec2(x: 8, y: 4),
            IntVec2(x: 8, y: 5),
            IntVec2(x: 8, y: 6),
        ]
        do {
            let detector: SnakeCollisionDetector = try create(player1Positions: a, player2Positions: b, foodPosition: nil)
            XCTAssertEqual(detector.collisionType1, .noCollision)
            XCTAssertEqual(detector.collisionType2, .noCollision)
            XCTAssertFalse(detector.player1EatsFood)
            XCTAssertFalse(detector.player2EatsFood)
        }
        do {
            let detector: SnakeCollisionDetector = try create(player1Positions: a, player2Positions: b, foodPosition: IntVec2(x: 6, y: 5))
            XCTAssertEqual(detector.collisionType1, .noCollision)
            XCTAssertEqual(detector.collisionType2, .noCollision)
            XCTAssertTrue(detector.player1EatsFood)
            XCTAssertFalse(detector.player2EatsFood)
        }
        do {
            let detector: SnakeCollisionDetector = try create(player1Positions: a, player2Positions: b, foodPosition: IntVec2(x: 8, y: 6))
            XCTAssertEqual(detector.collisionType1, .noCollision)
            XCTAssertEqual(detector.collisionType2, .noCollision)
            XCTAssertFalse(detector.player1EatsFood)
            XCTAssertTrue(detector.player2EatsFood)
        }
    }

    func test200_snakeCollisionWithWall() throws {
        let a: [IntVec2] = [
            IntVec2(x: 2, y: 5),
            IntVec2(x: 1, y: 5),
            IntVec2(x: 0, y: 5),
        ]
        let b: [IntVec2] = [
            IntVec2(x: 8, y: 4),
            IntVec2(x: 8, y: 5),
            IntVec2(x: 8, y: 6),
        ]
        do {
            let detector: SnakeCollisionDetector = try create(player1Positions: a, player2Positions: b, foodPosition: nil)
            XCTAssertEqual(detector.collisionType1, .snakeCollisionWithWall)
            XCTAssertEqual(detector.collisionType2, .noCollision)
        }
        do {
            let detector: SnakeCollisionDetector = try create(player1Positions: b, player2Positions: a, foodPosition: nil)
            XCTAssertEqual(detector.collisionType1, .noCollision)
            XCTAssertEqual(detector.collisionType2, .snakeCollisionWithWall)
        }
    }

    func test300_snakeCollisionWithItself() throws {
        let a: [IntVec2] = [
            IntVec2(x: 8, y: 4),
            IntVec2(x: 8, y: 5),
            IntVec2(x: 8, y: 6),
        ]
        let b: [IntVec2] = [
            IntVec2(x: 1, y: 5),
            IntVec2(x: 2, y: 5),
            IntVec2(x: 3, y: 5),
            IntVec2(x: 3, y: 4),
            IntVec2(x: 3, y: 3),
            IntVec2(x: 2, y: 3),
            IntVec2(x: 1, y: 3),
            IntVec2(x: 1, y: 4),
            IntVec2(x: 1, y: 5),
        ]
        do {
            let detector: SnakeCollisionDetector = try create(player1Positions: a, player2Positions: b, foodPosition: nil)
            XCTAssertEqual(detector.collisionType1, .noCollision)
            XCTAssertEqual(detector.collisionType2, .snakeCollisionWithItself)
        }
        do {
            let detector: SnakeCollisionDetector = try create(player1Positions: b, player2Positions: a, foodPosition: nil)
            XCTAssertEqual(detector.collisionType1, .snakeCollisionWithItself)
            XCTAssertEqual(detector.collisionType2, .noCollision)
        }
    }

    func test400_snakeCollisionWithOpponent_soloDestruction() throws {
        let a: [IntVec2] = [
            IntVec2(x: 8, y: 4),
            IntVec2(x: 8, y: 5),
            IntVec2(x: 8, y: 6),
        ]
        let b: [IntVec2] = [
            IntVec2(x: 6, y: 5),
            IntVec2(x: 7, y: 5),
            IntVec2(x: 8, y: 5),
        ]
        do {
            let detector: SnakeCollisionDetector = try create(player1Positions: a, player2Positions: b, foodPosition: nil)
            XCTAssertEqual(detector.collisionType1, .noCollision)
            XCTAssertEqual(detector.collisionType2, .snakeCollisionWithOpponent)
        }
        do {
            let detector: SnakeCollisionDetector = try create(player1Positions: b, player2Positions: a, foodPosition: nil)
            XCTAssertEqual(detector.collisionType1, .snakeCollisionWithOpponent)
            XCTAssertEqual(detector.collisionType2, .noCollision)
        }
    }

    func test401_snakeCollisionWithOpponent_mutualDestruction() throws {
        let a: [IntVec2] = [
            IntVec2(x: 8, y: 3),
            IntVec2(x: 8, y: 4),
            IntVec2(x: 8, y: 5),
        ]
        let b: [IntVec2] = [
            IntVec2(x: 6, y: 5),
            IntVec2(x: 7, y: 5),
            IntVec2(x: 8, y: 5),
        ]
        do {
            let detector: SnakeCollisionDetector = try create(player1Positions: a, player2Positions: b, foodPosition: nil)
            XCTAssertEqual(detector.collisionType1, .snakeCollisionWithOpponent)
            XCTAssertEqual(detector.collisionType2, .snakeCollisionWithOpponent)
        }
        do {
            let detector: SnakeCollisionDetector = try create(player1Positions: b, player2Positions: a, foodPosition: nil)
            XCTAssertEqual(detector.collisionType1, .snakeCollisionWithOpponent)
            XCTAssertEqual(detector.collisionType2, .snakeCollisionWithOpponent)
        }
        do {
            let detector: SnakeCollisionDetector = try create(player1Positions: b, player2Positions: a, foodPosition: IntVec2(x: 8, y: 5))
            XCTAssertEqual(detector.collisionType1, .snakeCollisionWithOpponent)
            XCTAssertEqual(detector.collisionType2, .snakeCollisionWithOpponent)
            XCTAssertFalse(detector.player1EatsFood)
            XCTAssertFalse(detector.player2EatsFood)
        }
    }
}
