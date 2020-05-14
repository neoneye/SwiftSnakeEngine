// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

/// Human players can interact with the game state.
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

//        log.debug("level: \(initialGameState.level)")
//        log.debug("player1: \(initialGameState.player1)")
//        log.debug("player2: \(initialGameState.player2)")
//        let initialFoodPosition: String = initialGameState.foodPosition?.debugDescription ?? "No food"
//        log.debug("food position: \(initialFoodPosition)")
    }

    public func reset() -> SnakeGameState {
        stuckSnakeDetector1.reset()
        stuckSnakeDetector2.reset()

        previousGameStates = []

        gameState = self.initialGameState
        gameState = self.placeNewFood(gameState)
        gameState = self.computeNextBotMovement(gameState)
        return gameState
    }

    public func undo() -> SnakeGameState? {
        guard var gameState: SnakeGameState = previousGameStates.popLast() else {
            log.info("Canot step backward. There is no previous state to rewind back to.")
            return nil
        }
        gameState = gameState.clearPendingMovementAndPendingLengthForHumanPlayers()
        gameState = self.placeNewFood(gameState)
        gameState = self.computeNextBotMovement(gameState)

        stuckSnakeDetector1.undo()
        stuckSnakeDetector2.undo()

        self.gameState = gameState
        return gameState
    }

    public func step(action: SnakeGameAction) -> SnakeGameState {
        let oldGameState: SnakeGameState = self.gameState

        var newGameState: SnakeGameState = oldGameState
        newGameState = newGameState.incrementNumberOfSteps()

        do {
            var player: SnakePlayer = newGameState.player1
            if player.isInstalledAndAlive && player.role == .human {
                let movement: SnakeBodyMovement = action.player1
                guard movement != .dontMove else {
                    log.error("Expected human actions to be different from dontMove, but got dontMove!")
                    return oldGameState
                }
                player = player.updatePendingMovement(movement)
                newGameState = newGameState.stateWithNewPlayer1(player)
            }
        }
        do {
            var player: SnakePlayer = newGameState.player2
            if player.isInstalledAndAlive && player.role == .human {
                let movement: SnakeBodyMovement = action.player2
                guard movement != .dontMove else {
                    log.error("Expected human actions to be different from dontMove, but got dontMove!")
                    return oldGameState
                }
                player = player.updatePendingMovement(movement)
                newGameState = newGameState.stateWithNewPlayer2(player)
            }
        }

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
            player = stuckSnakeDetector1.killBotIfStuckInLoop(player)
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
            player = stuckSnakeDetector2.killBotIfStuckInLoop(player)
            newGameState = newGameState.stateWithNewPlayer2(player)
        }

        newGameState = self.placeNewFood(newGameState)
        newGameState = self.computeNextBotMovement(newGameState)

        previousGameStates.append(oldGameState)
        self.gameState = newGameState
        return newGameState
    }

    /// Decide about optimal path to get to the food.
    private func computeNextBotMovement(_ oldGameState: SnakeGameState) -> SnakeGameState {
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

    private func placeNewFood(_ oldGameState: SnakeGameState) -> SnakeGameState {
        if oldGameState.foodPosition != nil {
            return oldGameState
        }
        // IDEA: Generate CSV file with statistics about food eating frequency
        //let steps: UInt64 = self.gameState.numberOfSteps
        //log.debug("place new food: \(steps)")
        return foodGenerator.placeNewFood(oldGameState)
    }
}
