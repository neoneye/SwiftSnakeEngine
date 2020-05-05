// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import SwiftProtobuf

/// Replay the moves of a historic game.
public class SnakeGameEnvironmentReplay: SnakeGameEnvironment {
    public let initialGameState: SnakeGameState
    private let foodPositions: [IntVec2]
    private let player1Positions: [IntVec2]
    private let player2Positions: [IntVec2]
    private let player1CauseOfDeath: SnakeCauseOfDeath
    private let player2CauseOfDeath: SnakeCauseOfDeath
    private var previousGameStates: [SnakeGameState] = []
    private var gameState: SnakeGameState

    private init(initialGameState: SnakeGameState, foodPositions: [IntVec2], player1Positions: [IntVec2], player2Positions: [IntVec2], player1CauseOfDeath: SnakeCauseOfDeath, player2CauseOfDeath: SnakeCauseOfDeath) {
        self.initialGameState = initialGameState
        self.foodPositions = foodPositions
        self.player1Positions = player1Positions
        self.player2Positions = player2Positions
        self.player1CauseOfDeath = player1CauseOfDeath
        self.player2CauseOfDeath = player2CauseOfDeath
        self.gameState = initialGameState
    }

    public static func create() -> SnakeGameEnvironmentReplay {
        let data: Data = SnakeDatasetBundle.load("2.snakeDataset")
        let model: SnakeDatasetResult
        do {
            model = try SnakeDatasetResult(serializedData: data)
        } catch {
            log.error("Unable to load file: \(error)")
            fatalError()
        }

        guard model.hasLevel else {
            log.error("Expected the file to contain a 'level' snapshot of the board, but got none.")
            fatalError()
        }
        guard model.hasFirstStep else {
            log.error("Expected the file to contain a 'firstStep' snapshot of the board, but got none.")
            fatalError()
        }
        guard model.hasLastStep else {
            log.error("Expected the file to contain a 'lastStep' snapshot of the board, but got none.")
            fatalError()
        }
        log.debug("successfully loaded file")

        let firstStep: SnakeDatasetStep = model.firstStep
        let lastStep: SnakeDatasetStep = model.lastStep

        let levelBuilder: SnakeLevelBuilder
        do {
            levelBuilder = try DatasetLoader.snakeLevelBuilder(levelModel: model.level)
        } catch {
            log.error("Unable to parse level. \(error)")
            fatalError()
        }

        assignFoodPosition(levelBuilder: levelBuilder, stepModel: firstStep)

        var player1: SnakePlayer?
        if let playerResult: DatasetLoader.SnakePlayerResult = snakePlayerResultWithPlayerA(stepModel: firstStep) {
            if playerResult.isAlive {
                levelBuilder.player1_body = playerResult.snakeBody

                if let role: SnakePlayerRole = SnakePlayerRole.create(uuid: playerResult.uuid) {
                    var player = SnakePlayer.create(id: .player1, role: role)
                    player = player.playerWithNewSnakeBody(playerResult.snakeBody)
                    player1 = player
                }
            }
        }

        var player2: SnakePlayer?
        if let playerResult: DatasetLoader.SnakePlayerResult = snakePlayerResultWithPlayerB(stepModel: firstStep) {
            if playerResult.isAlive {
                levelBuilder.player2_body = playerResult.snakeBody

                if let role: SnakePlayerRole = SnakePlayerRole.create(uuid: playerResult.uuid) {
                    var player = SnakePlayer.create(id: .player2, role: role)
                    player = player.playerWithNewSnakeBody(playerResult.snakeBody)
                    player2 = player
                }
            }
        }

        // IDEA: When the game ends, show the causeOfDeath in the UI.
        var player1CauseOfDeath: SnakeCauseOfDeath = .other
        if let playerResult: DatasetLoader.SnakePlayerResult = snakePlayerResultWithPlayerA(stepModel: lastStep) {
            log.debug("last step for player 1. \(playerResult.isAlive) \(playerResult.causeOfDeath)")
            player1CauseOfDeath = playerResult.causeOfDeath
        }
        var player2CauseOfDeath: SnakeCauseOfDeath = .other
        if let playerResult: DatasetLoader.SnakePlayerResult = snakePlayerResultWithPlayerB(stepModel: lastStep) {
            log.debug("last step for player 2. \(playerResult.isAlive) \(playerResult.causeOfDeath)")
            player2CauseOfDeath = playerResult.causeOfDeath
        }


        let level: SnakeLevel = levelBuilder.level()
        log.debug("level: \(level)")

        // IDEA: check hashes of the loaded level with the level in the file system.

        let foodPositions: [IntVec2] = model.foodPositions.toIntVec2Array()
        let player1Positions: [IntVec2] = model.playerAPositions.toIntVec2Array()
        let player2Positions: [IntVec2] = model.playerBPositions.toIntVec2Array()

        log.debug("level.id: '\(model.level.uuid)'")
        log.debug("food positions.count: \(foodPositions.count)")
        log.debug("player1 positions.count: \(player1Positions.count)")
        log.debug("player2 positions.count: \(player2Positions.count)")

        let pretty = PrettyPrintArray(prefixLength: 10, suffixLength: 2, separator: ",", ellipsis: "...")
        log.debug("player1: \(pretty.format(player1Positions))")
        log.debug("player2: \(pretty.format(player2Positions))")
        log.debug("food: \(pretty.format(foodPositions))")

        if model.hasTimestamp {
            let t: Google_Protobuf_Timestamp = model.timestamp
            let date: Date = t.date
            log.debug("date: \(date)")
        }

        // IDEA: validate positions are inside the level coordinates
        // IDEA: validate that none of the snakes overlap with each other
        // IDEA: validate that the snakes only occupy empty cells
        // IDEA: validate that the food is placed on an empty cell

        guard ValidateDistance.distanceIsOne(player1Positions) else {
            log.error("Invalid player1 positions. All moves must be by a distance of 1 unit.")
            fatalError()
        }
        guard ValidateDistance.distanceIsOne(player2Positions) else {
            log.error("Invalid player2 positions. All moves must be by a distance of 1 unit.")
            fatalError()
        }

        var gameState = SnakeGameState.empty()
        gameState = gameState.stateWithNewLevel(level)

        if let player: SnakePlayer = player1 {
            gameState = gameState.stateWithNewPlayer1(player)
        } else {
            var player = SnakePlayer.create(id: .player1, role: .none)
            player = player.uninstall()
            gameState = gameState.stateWithNewPlayer1(player)
        }

        if let player: SnakePlayer = player2 {
            gameState = gameState.stateWithNewPlayer2(player)
        } else {
            var player = SnakePlayer.create(id: .player2, role: .none)
            player = player.uninstall()
            gameState = gameState.stateWithNewPlayer2(player)
        }

        gameState = gameState.stateWithNewFoodPosition(level.initialFoodPosition.intVec2)

        return SnakeGameEnvironmentReplay(
            initialGameState: gameState,
            foodPositions: foodPositions,
            player1Positions: player1Positions,
            player2Positions: player2Positions,
            player1CauseOfDeath: player1CauseOfDeath,
            player2CauseOfDeath: player2CauseOfDeath
        )
    }

    static func assignFoodPosition(levelBuilder: SnakeLevelBuilder, stepModel: SnakeDatasetStep) {
        guard case .foodPosition(let foodPositionModel)? = stepModel.optionalFoodPosition else {
            log.error("Expected file to contain a food position for the first step, but got none.")
            fatalError()
        }
        levelBuilder.initialFoodPosition = UIntVec2(x: foodPositionModel.x, y: foodPositionModel.y)
    }

    private static func snakePlayerResultWithPlayerA(stepModel: SnakeDatasetStep) -> DatasetLoader.SnakePlayerResult? {
        guard case .playerA(let player)? = stepModel.optionalPlayerA else {
            log.error("Expected player A, but got none.")
            return nil
        }
        do {
            return try DatasetLoader.snakePlayerResult(playerModel: player)
        } catch {
            log.error("Unable to parse player A. \(error)")
            return nil
        }
    }

    private static func snakePlayerResultWithPlayerB(stepModel: SnakeDatasetStep) -> DatasetLoader.SnakePlayerResult? {
        guard case .playerB(let player)? = stepModel.optionalPlayerB else {
            log.error("Expected player B, but got none.")
            return nil
        }
        do {
            return try DatasetLoader.snakePlayerResult(playerModel: player)
        } catch {
            log.error("Unable to parse player B. \(error)")
            return nil
        }
    }

    public func reset() -> SnakeGameState {
        previousGameStates = []

        var gameState: SnakeGameState = self.initialGameState
        gameState = self.placeNewFood(gameState)
        gameState = self.prepareNextMovements(gameState)
        self.gameState = gameState
        return gameState
    }

    public func undo() -> SnakeGameState? {
        guard var gameState: SnakeGameState = previousGameStates.popLast() else {
            log.info("Canot step backward. There is no previous state to rewind back to.")
            return nil
        }
        gameState = gameState.clearPendingMovementAndPendingLengthForHumanPlayers()
        gameState = self.placeNewFood(gameState)
        gameState = self.prepareNextMovements(gameState)
        self.gameState = gameState
        return gameState
    }

    public func step(_ currentGameState: SnakeGameState) -> SnakeGameState {
        let oldGameState = self.gameState
        previousGameStates.append(oldGameState)

        var newGameState: SnakeGameState = oldGameState
        newGameState = newGameState.incrementNumberOfSteps()
        newGameState = newGameState.detectCollision()

        if newGameState.player1.isInstalledAndAlive {
            var player: SnakePlayer = newGameState.player1
            let snakeBody: SnakeBody = player.snakeBody.stateForTick(
                movement: player.pendingMovement,
                act: player.pendingAct
            )
            player = player.playerWithNewSnakeBody(snakeBody)
            player = player.updatePendingMovement(.dontMove)
            player = player.updatePendingAct(.doNothing)
//            player = stuckSnakeDetector1.killBotIfStuckInLoop(player)
            newGameState = newGameState.stateWithNewPlayer1(player)
        }

        if newGameState.player2.isInstalledAndAlive {
            var player: SnakePlayer = newGameState.player2
            let snakeBody: SnakeBody = player.snakeBody.stateForTick(
                movement: player.pendingMovement,
                act: player.pendingAct
            )
            player = player.playerWithNewSnakeBody(snakeBody)
            player = player.updatePendingMovement(.dontMove)
            player = player.updatePendingAct(.doNothing)
//            player = stuckSnakeDetector2.killBotIfStuckInLoop(player)
            newGameState = newGameState.stateWithNewPlayer2(player)
        }

        newGameState = self.placeNewFood(newGameState)
        newGameState = self.prepareNextMovements(newGameState)

        self.gameState = newGameState
        return newGameState
    }

    /// Decide about optimal path to get to the food.
    private func prepareNextMovements(_ oldGameState: SnakeGameState) -> SnakeGameState {
        let currentIteration: UInt64 = oldGameState.numberOfSteps + 1
        var newGameState: SnakeGameState = oldGameState

        if newGameState.player1.isInstalledAndAlive {
            if currentIteration >= player1Positions.count {
                log.debug("Player1 is dead. Reached end of player1Positions array. \(self.player1CauseOfDeath)")
                newGameState = newGameState.killPlayer1(self.player1CauseOfDeath)
            } else {
                let position: IntVec2 = player1Positions[Int(currentIteration)]
                let head: SnakeHead = newGameState.player1.snakeBody.head
                let movement: SnakeBodyMovement = head.moveToward(position) ?? SnakeBodyMovement.dontMove
                //log.debug("move from \(head.position) to \(position)   movement: \(movement)")
                if movement == .dontMove {
                    log.error("Killing player1. The snake is supposed to move, but doesn't. Iteration: \(currentIteration)")
                    newGameState = newGameState.killPlayer1(.killAfterAFewTimeSteps)
                } else {
//                    log.debug("#\(currentIteration) player1: movement \(movement)")
                    newGameState = newGameState.updatePendingMovementForPlayer1(movement)
                }
            }
        }

        if newGameState.player2.isInstalledAndAlive {
            if currentIteration >= player2Positions.count {
                log.debug("Player2 is dead. Reached end of player2Positions array. \(self.player2CauseOfDeath)")
                newGameState = newGameState.killPlayer2(self.player2CauseOfDeath)
            } else {
                let position: IntVec2 = player2Positions[Int(currentIteration)]
                let head: SnakeHead = newGameState.player2.snakeBody.head
                let movement: SnakeBodyMovement = head.moveToward(position) ?? SnakeBodyMovement.dontMove
                //log.debug("move from \(head.position) to \(position)   movement: \(movement)")
                if movement == .dontMove {
                    log.error("Killing player2. The snake is supposed to move, but doesn't. Iteration: \(currentIteration)")
                    newGameState = newGameState.killPlayer2(.killAfterAFewTimeSteps)
                } else {
//                    log.debug("#\(currentIteration) player2: movement \(movement)")
                    newGameState = newGameState.updatePendingMovementForPlayer2(movement)
                }
            }
        }

        return newGameState
    }

    private func placeNewFood(_ oldGameState: SnakeGameState) -> SnakeGameState {
        let currentIteration: UInt64 = oldGameState.numberOfSteps
        guard currentIteration < foodPositions.count else {
            log.debug("Reached end of foodPositions array.  Iteration: \(currentIteration)")
            return oldGameState
        }
        let position: IntVec2 = foodPositions[Int(currentIteration)]
        guard position != oldGameState.foodPosition else {
//            log.debug("#\(currentIteration) food is unchanged. position: \(position)")
            return oldGameState
        }
        let length1: UInt = oldGameState.player1.lengthOfInstalledSnake()
        let length2: UInt = oldGameState.player2.lengthOfInstalledSnake()
        log.debug("#\(currentIteration) placing new food at \(position)   player1.length: \(length1)  player2.length: \(length2)")
        return oldGameState.stateWithNewFoodPosition(position)
    }
}
