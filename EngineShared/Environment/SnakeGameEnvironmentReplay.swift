// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

/// Replay the moves of a historic game.
public class SnakeGameEnvironmentReplay: GameEnvironment {
    public let datasetTimestamp: Date
    public let initialGameState: SnakeGameState
    internal let foodPositions: [IntVec2]
    internal let player1Positions: [IntVec2]
    internal let player2Positions: [IntVec2]

    /// Cause of death for player1
    /// - `nil` means that the player is still alive at the end of the replay.
    /// - A non-nil value means that the player dies.
    internal let player1CauseOfDeath: SnakeCauseOfDeath?

    /// Cause of death for player2
    /// - `nil` means that the player is still alive at the end of the replay.
    /// - A non-nil value means that the player dies.
    internal let player2CauseOfDeath: SnakeCauseOfDeath?

    private var previousGameStates: [SnakeGameState] = []
    private var gameState: SnakeGameState

    internal init(datasetTimestamp: Date, initialGameState: SnakeGameState, foodPositions: [IntVec2], player1Positions: [IntVec2], player2Positions: [IntVec2], player1CauseOfDeath: SnakeCauseOfDeath?, player2CauseOfDeath: SnakeCauseOfDeath?) {
        self.datasetTimestamp = datasetTimestamp
        self.initialGameState = initialGameState
        self.foodPositions = foodPositions
        self.player1Positions = player1Positions
        self.player2Positions = player2Positions
        self.player1CauseOfDeath = player1CauseOfDeath
        self.player2CauseOfDeath = player2CauseOfDeath
        self.gameState = initialGameState
    }

    public static func create() -> SnakeGameEnvironmentReplay {
        let resourceName: String = "duel0.snakeDataset"
        do {
            return try DatasetLoader.snakeGameEnvironmentReplay(resourceName: resourceName, verbose: true)
        } catch {
            log.error("Unable to load file: \(error)")
            fatalError()
        }
    }

    public static func create(data: Data) -> SnakeGameEnvironmentReplay {
        do {
            return try DatasetLoader.snakeGameEnvironmentReplay(data: data, verbose: true)
        } catch {
            log.error("Unable to parse data: \(error)")
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
        gameState = gameState.clearPendingMovementAndPendingActForHumanPlayers()
        gameState = self.placeNewFood(gameState)
        gameState = self.prepareNextMovements(gameState)
        self.gameState = gameState
        return gameState
    }

    public var stepControlMode: GameEnvironment_StepControlMode {
        if gameState.player1.pendingMovement != .dontMove {
            //log.debug("player1 is installed an alive. return: stepAutonomous")
            return .stepAutonomous
        }
        if gameState.player2.pendingMovement != .dontMove {
            //log.debug("player2 is installed an alive. return: stepAutonomous")
            return .stepAutonomous
        }
        //log.debug("none of the players are installed an alive. return: reachedTheEnd")
        return .reachedTheEnd
    }

    public func step(action: GameEnvironment_StepAction) -> SnakeGameState {
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
            newGameState = newGameState.stateWithNewPlayer1(player)
        }

        if newGameState.player2.isInstalledAndAlive {
            var player: SnakePlayer = newGameState.player2
            let snakeBody: SnakeBody = player.snakeBody.stateForTick(
                movement: player.pendingMovement,
                act: player.pendingAct
            )
            player = player.playerWithNewSnakeBody(snakeBody)
            newGameState = newGameState.stateWithNewPlayer2(player)
        }

        newGameState = self.placeNewFood(newGameState)
        newGameState = self.prepareNextMovements(newGameState)

        self.gameState = newGameState
        log.debug("step \(oldGameState.numberOfSteps) -> \(newGameState.numberOfSteps)")
        return newGameState
    }

    /// Decide about optimal path to get to the food.
    private func prepareNextMovements(_ oldGameState: SnakeGameState) -> SnakeGameState {
        var newGameState: SnakeGameState = oldGameState
        newGameState = prepareNextMovements_player1(newGameState)
        newGameState = prepareNextMovements_player2(newGameState)
        return newGameState
    }

    private func prepareNextMovements_player1(_ oldGameState: SnakeGameState) -> SnakeGameState {
        let currentIteration: UInt64 = oldGameState.numberOfSteps
        var newGameState: SnakeGameState = oldGameState

        // Reset pending actions for player
        do {
            var player: SnakePlayer = newGameState.player1
            player = player.clearPendingMovementAndPendingAct()
            newGameState = newGameState.stateWithNewPlayer1(player)
        }

        guard newGameState.player1.isInstalledAndAlive else {
            return newGameState
        }

        guard currentIteration < player1Positions.count else {
            if let causeOfDeath: SnakeCauseOfDeath = self.player1CauseOfDeath {
                log.debug("Player1 is dead. Reached end of player1Positions array. \(causeOfDeath)")
                newGameState = newGameState.killPlayer1(causeOfDeath)
                return newGameState
            } else {
                log.debug("Player1 is still alive at the end of the game. Reached end of player1Positions array.")
                return newGameState
            }
        }

        let position: IntVec2 = player1Positions[Int(currentIteration)]
        let head: SnakeHead = newGameState.player1.snakeBody.head
        let movement: SnakeBodyMovement = head.moveToward(position) ?? SnakeBodyMovement.dontMove
        //log.debug("move from \(head.position) to \(position)   movement: \(movement)")
        if movement == .dontMove {
            log.error("Killing player1. The snake is supposed to move, but doesn't. Iteration: \(currentIteration)")
            newGameState = newGameState.killPlayer1(.other)
        } else {
            //log.debug("#\(currentIteration) player1: movement \(movement)")
            newGameState = newGameState.updatePendingMovementForPlayer1(movement)
        }

        return newGameState
    }

    private func prepareNextMovements_player2(_ oldGameState: SnakeGameState) -> SnakeGameState {
        let currentIteration: UInt64 = oldGameState.numberOfSteps
        var newGameState: SnakeGameState = oldGameState

        // Reset pending actions for player
        do {
            var player: SnakePlayer = newGameState.player2
            player = player.clearPendingMovementAndPendingAct()
            newGameState = newGameState.stateWithNewPlayer2(player)
        }

        guard newGameState.player2.isInstalledAndAlive else {
            return newGameState
        }

        guard currentIteration < player2Positions.count else {
            if let causeOfDeath: SnakeCauseOfDeath = self.player2CauseOfDeath {
                log.debug("Player2 is dead. Reached end of player2Positions array. \(causeOfDeath)")
                newGameState = newGameState.killPlayer2(causeOfDeath)
                return newGameState
            } else {
                log.debug("Player2 is still alive at the end of the game. Reached end of player2Positions array.")
                return newGameState
            }
        }
        
        let position: IntVec2 = player2Positions[Int(currentIteration)]
        let head: SnakeHead = newGameState.player2.snakeBody.head
        let movement: SnakeBodyMovement = head.moveToward(position) ?? SnakeBodyMovement.dontMove
        //log.debug("move from \(head.position) to \(position)   movement: \(movement)")
        if movement == .dontMove {
            log.error("Killing player2. The snake is supposed to move, but doesn't. Iteration: \(currentIteration)")
            newGameState = newGameState.killPlayer2(.other)
        } else {
            //log.debug("#\(currentIteration) player2: movement \(movement)")
            newGameState = newGameState.updatePendingMovementForPlayer2(movement)
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
            //log.debug("#\(currentIteration) food is unchanged. position: \(position)")
            return oldGameState
        }
        let length1: UInt = oldGameState.player1.lengthOfInstalledSnake()
        let length2: UInt = oldGameState.player2.lengthOfInstalledSnake()
        log.debug("#\(currentIteration) placing new food at \(position)   player1.length: \(length1)  player2.length: \(length2)")
        return oldGameState.stateWithNewFoodPosition(position)
    }
}
