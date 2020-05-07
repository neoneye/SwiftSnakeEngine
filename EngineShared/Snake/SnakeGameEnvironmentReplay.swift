// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

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

    internal init(initialGameState: SnakeGameState, foodPositions: [IntVec2], player1Positions: [IntVec2], player2Positions: [IntVec2], player1CauseOfDeath: SnakeCauseOfDeath, player2CauseOfDeath: SnakeCauseOfDeath) {
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
        do {
            let model: SnakeDatasetResult = try SnakeDatasetResult(serializedData: data)
            return try DatasetLoader.snakeGameEnvironmentReplay(model)
        } catch {
            log.error("Unable to load file: \(error)")
            fatalError()
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

    public func step(action: SnakeGameAction) -> SnakeGameState {
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
        let currentIteration: UInt64 = oldGameState.numberOfSteps
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
                    newGameState = newGameState.killPlayer1(.other)
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
                    newGameState = newGameState.killPlayer2(.other)
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
