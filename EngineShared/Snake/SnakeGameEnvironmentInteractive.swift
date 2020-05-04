// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeGameEnvironmentInteractive: SnakeGameEnvironment {
    private let initialGameState: SnakeGameState
    private var stuckSnakeDetector1 = StuckSnakeDetector(humanReadableName: "Player1")
    private var stuckSnakeDetector2 = StuckSnakeDetector(humanReadableName: "Player2")
    private var foodGenerator: SnakeFoodGenerator = SnakeFoodGenerator()
    private var gameState: SnakeGameState
    private var previousGameStates: [SnakeGameState] = []

    public init(initialGameState: SnakeGameState) {
        self.initialGameState = initialGameState
        self.gameState = initialGameState

        log.debug("level: \(initialGameState.level)")
        log.debug("player1: \(initialGameState.player1)")
        log.debug("player2: \(initialGameState.player2)")
        let initialFoodPosition: String = initialGameState.foodPosition?.debugDescription ?? "No food"
        log.debug("food position: \(initialFoodPosition)")
    }

    public func reset() -> SnakeGameState {
        stuckSnakeDetector1.reset()
        stuckSnakeDetector2.reset()

        previousGameStates = []

        gameState = self.initialGameState
        gameState = self.placeNewFood(gameState)
        return gameState
    }

    public func undo() -> SnakeGameState? {
        guard var state: SnakeGameState = previousGameStates.popLast() else {
            log.info("Canot step backward. There is no previous state to rewind back to.")
            return nil
        }
        state = state.clearPendingMovementAndPendingLengthForHumanPlayers()

        stuckSnakeDetector1.undo()
        stuckSnakeDetector2.undo()

        self.gameState = state
        return state
    }

    public func step(_ currentGameState: SnakeGameState) -> SnakeGameState {
        previousGameStates.append(currentGameState)

        var gameState: SnakeGameState = currentGameState
        let newGameState = gameState.detectCollision()
        gameState = newGameState

        if gameState.player1.isInstalledAndAlive {
            var player: SnakePlayer = gameState.player1
            let snakeBody: SnakeBody = player.snakeBody.stateForTick(
                movement: player.pendingMovement,
                act: player.pendingAct
            )
            player = player.playerWithNewSnakeBody(snakeBody)
            player = player.updatePendingMovement(.dontMove)
            player = player.updatePendingAct(.doNothing)
            player = stuckSnakeDetector1.killBotIfStuckInLoop(player)
            gameState = gameState.stateWithNewPlayer1(player)
        }

        if gameState.player2.isInstalledAndAlive {
            var player: SnakePlayer = gameState.player2
            let snakeBody: SnakeBody = player.snakeBody.stateForTick(
                movement: player.pendingMovement,
                act: player.pendingAct
            )
            player = player.playerWithNewSnakeBody(snakeBody)
            player = player.updatePendingMovement(.dontMove)
            player = player.updatePendingAct(.doNothing)
            player = stuckSnakeDetector2.killBotIfStuckInLoop(player)
            gameState = gameState.stateWithNewPlayer2(player)
        }

        return gameState
    }

    public func computeNextBotMovement(_ oldGameState: SnakeGameState) -> SnakeGameState {
        let oldPlayer1: SnakePlayer = oldGameState.player1
        let oldPlayer2: SnakePlayer = oldGameState.player2

        var computePlayer1 = false
        if case SnakePlayerRole.bot = oldPlayer1.role {
            if oldPlayer1.isInstalledAndAlive && oldPlayer1.pendingMovement == .dontMove {
                computePlayer1 = true
            }
        }
        var computePlayer2 = false
        if case SnakePlayerRole.bot = oldPlayer2.role {
            if oldPlayer2.isInstalledAndAlive && oldPlayer2.pendingMovement == .dontMove {
                computePlayer2 = true
            }
        }

        guard computePlayer1 || computePlayer2 else {
            // No need to compute next movement for the bots.
            return oldGameState
        }
        //log.debug("will compute")

        var newGameState: SnakeGameState = oldGameState
        if computePlayer1 {
            let newBotState = newGameState.player1.bot.compute(
                level: newGameState.level,
                player: newGameState.player1,
                oppositePlayer: newGameState.player2,
                foodPosition: newGameState.foodPosition
            )
            let pendingMovement: SnakeBodyMovement = newBotState.plannedMovement
            newGameState = newGameState.updateBot1(newBotState)
            newGameState = newGameState.updatePendingMovementForPlayer1(pendingMovement)
            //log.debug("player1: \(pendingMovement)")
        }

        if computePlayer2 {
            let newBotState = newGameState.player2.bot.compute(
                level: newGameState.level,
                player: newGameState.player2,
                oppositePlayer: newGameState.player1,
                foodPosition: newGameState.foodPosition
            )
            let pendingMovement: SnakeBodyMovement = newBotState.plannedMovement
            newGameState = newGameState.updateBot2(newBotState)
            newGameState = newGameState.updatePendingMovementForPlayer2(pendingMovement)
            //log.debug("player2: \(pendingMovement)")
        }

        //log.debug("did compute")
        return newGameState
    }

    public func placeNewFood(_ oldGameState: SnakeGameState) -> SnakeGameState {
        if oldGameState.foodPosition != nil {
            return oldGameState
        }
        // IDEA: Generate CSV file with statistics about food eating frequency
        //let steps: UInt64 = self.gameState.numberOfSteps
        //log.debug("place new food: \(steps)")
        return foodGenerator.placeNewFood(oldGameState)
    }

    static let printNumberOfSteps = false

    public func endOfStep(_ oldGameState: SnakeGameState) -> SnakeGameState {
        let step0: UInt64 = oldGameState.numberOfSteps
        let newGameState: SnakeGameState = oldGameState.incrementNumberOfSteps()
        let step1: UInt64 = newGameState.numberOfSteps
        if Self.printNumberOfSteps {
            log.debug("----------- numberOfSteps \(step0) -> \(step1) -----------")
        }
        return newGameState
    }
}
