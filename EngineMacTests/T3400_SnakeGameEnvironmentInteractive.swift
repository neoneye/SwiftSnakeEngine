// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import XCTest
@testable import EngineMac

class T3400_SnakeGameEnvironmentInteractive: XCTestCase {

    enum CreateError: Error {
        case message(message: String)
    }

    func create(player1Positions: [IntVec2], player2Positions: [IntVec2], foodPosition: IntVec2?) throws -> SnakeGameState {
        // Create level
        let levelBuilder = SnakeLevelBuilder(id: UUID(), size: UIntVec2(x: 10, y: 10))
        levelBuilder.installWallsAroundTheLevel()
        let level: SnakeLevel = levelBuilder.level()

        // Create player 1
        var player1: SnakePlayer = SnakePlayer.create(id: .player1, role: .human)
        if player1Positions.isEmpty {
            player1 = player1.uninstall()
        } else {
            let body: SnakeBody = try SnakeBodyAdvancedCreate.create(positions: player1Positions, checkEatingItself: false)
            player1 = player1.playerWithNewSnakeBody(body)
        }

        // Create player 2
        var player2: SnakePlayer = SnakePlayer.create(id: .player2, role: .human)
        if player2Positions.isEmpty {
            player2 = player2.uninstall()
        } else {
            let body: SnakeBody = try SnakeBodyAdvancedCreate.create(positions: player2Positions, checkEatingItself: false)
            player2 = player2.playerWithNewSnakeBody(body)
        }

        return SnakeGameState(
            level: level,
            foodPosition: foodPosition,
            player1: player1,
            player2: player2,
            foodRandomGenerator_seed: 0,
            numberOfSteps: 0
        )
    }

    func test100_collisionCheckAfterEating_player1Dead_eatingOpponent() throws {
        let player1Positions: [IntVec2] = [
            IntVec2(x: 5, y: 2),
            IntVec2(x: 6, y: 2),
            IntVec2(x: 7, y: 2),
        ]
        let player2Positions: [IntVec2] = [
            IntVec2(x: 8, y: 2),
            IntVec2(x: 8, y: 3),
            IntVec2(x: 8, y: 4),
        ]

        let initialState: SnakeGameState = try create(player1Positions: player1Positions, player2Positions: player2Positions, foodPosition: IntVec2(x: 8, y: 5))

        let environment = SnakeGameEnvironmentInteractive(initialGameState: initialState)
        let state0: SnakeGameState = environment.reset()
        XCTAssertTrue(state0.player1.isInstalledAndAlive)
        XCTAssertTrue(state0.player2.isInstalledAndAlive)
        XCTAssertEqual(state0.player1.snakeBody.head.position, IntVec2(x: 7, y: 2))
        XCTAssertEqual(state0.player2.snakeBody.head.position, IntVec2(x: 8, y: 4))
        XCTAssertEqual(state0.player1.lengthOfInstalledSnake(), 3)
        XCTAssertEqual(state0.player2.lengthOfInstalledSnake(), 3)

        let state1: SnakeGameState = environment.step(action: GameEnvironment_StepAction(player1: .moveForward, player2: .moveForward))
        XCTAssertTrue(state1.player1.isInstalledAndDead)
        XCTAssertTrue(state1.player2.isInstalledAndAlive)
        XCTAssertEqual(state1.player1.snakeBody.head.position, IntVec2(x: 7, y: 2))
        XCTAssertEqual(state1.player2.snakeBody.head.position, IntVec2(x: 8, y: 5))
        XCTAssertEqual(state1.player1.lengthOfInstalledSnake(), 3)
        XCTAssertEqual(state1.player2.lengthOfInstalledSnake(), 4)
    }

    func test101_collisionCheckAfterEating_player2Dead_eatingOpponent() throws {
        let player1Positions: [IntVec2] = [
            IntVec2(x: 8, y: 2),
            IntVec2(x: 8, y: 3),
            IntVec2(x: 8, y: 4),
        ]
        let player2Positions: [IntVec2] = [
            IntVec2(x: 5, y: 2),
            IntVec2(x: 6, y: 2),
            IntVec2(x: 7, y: 2),
        ]

        let initialState: SnakeGameState = try create(player1Positions: player1Positions, player2Positions: player2Positions, foodPosition: IntVec2(x: 8, y: 5))

        let environment = SnakeGameEnvironmentInteractive(initialGameState: initialState)
        let state0: SnakeGameState = environment.reset()
        XCTAssertTrue(state0.player1.isInstalledAndAlive)
        XCTAssertTrue(state0.player2.isInstalledAndAlive)
        XCTAssertEqual(state0.player1.snakeBody.head.position, IntVec2(x: 8, y: 4))
        XCTAssertEqual(state0.player2.snakeBody.head.position, IntVec2(x: 7, y: 2))
        XCTAssertEqual(state0.player1.lengthOfInstalledSnake(), 3)
        XCTAssertEqual(state0.player2.lengthOfInstalledSnake(), 3)

        let state1: SnakeGameState = environment.step(action: GameEnvironment_StepAction(player1: .moveForward, player2: .moveForward))
        XCTAssertTrue(state1.player1.isInstalledAndAlive)
        XCTAssertTrue(state1.player2.isInstalledAndDead)
        XCTAssertEqual(state1.player1.snakeBody.head.position, IntVec2(x: 8, y: 5))
        XCTAssertEqual(state1.player2.snakeBody.head.position, IntVec2(x: 7, y: 2))
        XCTAssertEqual(state1.player1.lengthOfInstalledSnake(), 4)
        XCTAssertEqual(state1.player2.lengthOfInstalledSnake(), 3)
    }
}
