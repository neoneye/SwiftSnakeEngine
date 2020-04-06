// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeGameExecuter {
    private var stuckSnakeDetector1 = StuckSnakeDetector(humanReadableName: "Player1")
    private var stuckSnakeDetector2 = StuckSnakeDetector(humanReadableName: "Player2")

    public init() {}

    public func reset() {
        stuckSnakeDetector1.reset()
        stuckSnakeDetector2.reset()
    }

    public func undo() {
        stuckSnakeDetector1.undo()
        stuckSnakeDetector2.undo()
    }

    public func executeStep(_ currentGameState: SnakeGameState) -> SnakeGameState {
        var gameState: SnakeGameState = currentGameState
        let newGameState = gameState.detectCollision()
        gameState = newGameState

        if gameState.player1.isAlive {
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

        if gameState.player2.isAlive {
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

        gameState = gameState.incrementNumberOfSteps()
        return gameState
    }
}

extension SnakeGameState {
	/// Decide about optimal path to get to the food
	public func computeNextBotMovement() -> SnakeGameState {
        var computePlayer1 = false
		if case SnakePlayerRole.bot = self.player1.role {
			if self.player1.isAlive && self.player1.pendingMovement == .dontMove {
                computePlayer1 = true
            }
        }
        var computePlayer2 = false
        if case SnakePlayerRole.bot = self.player2.role {
            if self.player2.isAlive && self.player2.pendingMovement == .dontMove {
                computePlayer2 = true
            }
        }

        guard computePlayer1 || computePlayer2 else {
            // No need to compute next movement for the bots.
            return self
        }
        //log.debug("will compute")

        var gameState: SnakeGameState = self
        if computePlayer1 {
            let newBotState = gameState.player1.bot.compute(
                level: gameState.level,
                player: gameState.player1,
                oppositePlayer: gameState.player2,
                foodPosition: gameState.foodPosition
            )
            let pendingMovement: SnakeBodyMovement = newBotState.plannedMovement
            gameState = gameState.updateBot1(newBotState)
            gameState = gameState.updatePendingMovementForPlayer1(pendingMovement)
            //log.debug("player1: \(pendingMovement)")
		}

		if computePlayer2 {
            let newBotState = gameState.player2.bot.compute(
                level: gameState.level,
                player: gameState.player2,
                oppositePlayer: gameState.player1,
                foodPosition: gameState.foodPosition
            )
            let pendingMovement: SnakeBodyMovement = newBotState.plannedMovement
            gameState = gameState.updateBot2(newBotState)
            gameState = gameState.updatePendingMovementForPlayer2(pendingMovement)
            //log.debug("player2: \(pendingMovement)")
		}

        //log.debug("did compute")
		return gameState
	}

	/// Checks the human inputs and prevent humans from colliding with walls/snakes
	public func preventHumanCollisions() -> SnakeGameState {
		var gameState: SnakeGameState = self

		if gameState.player1.role == .human && gameState.player1.isAlive && gameState.player1.pendingMovement != .dontMove {
			let detector = SnakeCollisionDetector.create(
				level: gameState.level,
				foodPosition: gameState.foodPosition,
				player1: gameState.player1,
				player2: gameState.player2
			)
			detector.process()
			if detector.player1Alive == false {
                log.info("player1 will collide with something. \(detector.collisionType1). Preventing this movement.")
				gameState = gameState.updatePendingMovementForPlayer1(.dontMove)
			}
		}
		if gameState.player2.role == .human && gameState.player2.isAlive && gameState.player2.pendingMovement != .dontMove {
			let detector = SnakeCollisionDetector.create(
				level: gameState.level,
				foodPosition: gameState.foodPosition,
				player1: gameState.player1,
				player2: gameState.player2
			)
			detector.process()
			if detector.player2Alive == false {
                log.info("player2 will collide with something. \(detector.collisionType2). Preventing this movement.")
				gameState = gameState.updatePendingMovementForPlayer2(.dontMove)
			}
		}
		return gameState
	}

	public func isWaitingForHumanInput() -> Bool {
		var waitingForPlayers = false
		if self.player1.isAlive && self.player1.pendingMovement == .dontMove {
			waitingForPlayers = true
		}
		if self.player2.isAlive && self.player2.pendingMovement == .dontMove {
			waitingForPlayers = true
		}
		if waitingForPlayers {
			//log.debug("waiting for players")
			return true
		} else {
			return false
		}
	}

	/// Deal with collision when both the player1 and the player2 is installed
	/// Deal with collision only if either the player1 or player2 is installed
	fileprivate func detectCollision() -> SnakeGameState {
		var gameState: SnakeGameState = self
		if gameState.player1.isDead && gameState.player2.isDead {
			log.debug("Both players are dead. No need to check for collision between them. 1")
			return gameState
		}

		let detector = SnakeCollisionDetector.create(
			level: gameState.level,
			foodPosition: gameState.foodPosition,
			player1: gameState.player1,
			player2: gameState.player2
		)
		detector.process()

		if gameState.player1.isAlive && detector.player1Alive == false {
            let collisionType: SnakeCollisionType = detector.collisionType1
            log.info("killing player1 because: \(collisionType)")
            gameState = gameState.killPlayer1(collisionType.killEvent)
		}
		if gameState.player2.isAlive && detector.player2Alive == false {
            let collisionType: SnakeCollisionType = detector.collisionType2
            log.info("killing player2 because: \(collisionType)")
			gameState = gameState.killPlayer2(collisionType.killEvent)
		}

		if detector.player1EatsFood {
			gameState = gameState.stateWithNewFoodPosition(nil)
			var player: SnakePlayer = gameState.player1
			player = player.updatePendingAct(.eat)
			gameState = gameState.stateWithNewPlayer1(player)
		}
		if detector.player2EatsFood {
			gameState = gameState.stateWithNewFoodPosition(nil)
			var player: SnakePlayer = gameState.player2
			player = player.updatePendingAct(.eat)
			gameState = gameState.stateWithNewPlayer2(player)
		}
		return gameState
	}
}

extension SnakeCollisionType {
    /// Convert from a `CollisionType` to its corresponding `KillEvent`.
    fileprivate var killEvent: SnakePlayerKillEvent {
        switch self {
        case .noCollision:
            fatalError("Inconsistency. A collision happened, but no collision is registered. Should never happen!")
        case .snakeCollisionWithWall:
            return .collisionWithWall
        case .snakeCollisionWithOpponent:
            return .collisionWithOpponent
        case .snakeCollisionWithItself:
            return .collisionWithItself
        }
    }
}

extension StuckSnakeDetector {
    /// While playing as a human, I find it annoying to get killed because
    /// I'm doing the same patterns over and over.
    /// So this "stuck in loop" detection only applies to bots.
    fileprivate func killBotIfStuckInLoop(_ player: SnakePlayer) -> SnakePlayer {
        guard player.isBot && player.isAlive else {
            return player
        }
        self.append(player.snakeBody)
        if self.isStuck {
            return player.kill(.stuckInALoop)
        } else {
            return player
        }
    }
}
