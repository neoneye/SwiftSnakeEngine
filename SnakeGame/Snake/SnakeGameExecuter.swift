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
	public func prepareBotMovements() -> SnakeGameState {
		var gameState: SnakeGameState = self
		if case SnakePlayerRole.bot = gameState.player1.role {
			if gameState.player1.isAlive && gameState.player1.pendingMovement == .dontMove {
				let (newBotState, pendingMovement) = gameState.player1.bot.takeAction(
					level: gameState.level,
					player: gameState.player1,
					oppositePlayer: gameState.player2,
					foodPosition: gameState.foodPosition
				)
				gameState = gameState.updateBot1(newBotState)
				gameState = gameState.updatePendingMovementForPlayer1(pendingMovement)
			}
		}

		if case SnakePlayerRole.bot = gameState.player2.role {
			if gameState.player2.isAlive && gameState.player2.pendingMovement == .dontMove {
				let (newBotState, pendingMovement) = gameState.player2.bot.takeAction(
					level: gameState.level,
					player: gameState.player2,
					oppositePlayer: gameState.player1,
					foodPosition: gameState.foodPosition
				)
				gameState = gameState.updateBot2(newBotState)
				gameState = gameState.updatePendingMovementForPlayer2(pendingMovement)
			}
		}
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
				print("player1 will collide with something. \(detector.collisionType1). Preventing this movement.")
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
				print("player2 will collide with something. \(detector.collisionType2). Preventing this movement.")
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
			//print("waiting for players")
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
			print("Both players are dead. No need to check for collision between them. 1")
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
            print("killing player1 because: \(collisionType)")
            gameState = gameState.killPlayer1(collisionType.killEvent)
		}
		if gameState.player2.isAlive && detector.player2Alive == false {
            let collisionType: SnakeCollisionType = detector.collisionType2
			print("killing player2 because: \(collisionType)")
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
    func killBotIfStuckInLoop(_ player: SnakePlayer) -> SnakePlayer {
        guard player.isBot && player.isAlive else {
            return player
        }
        self.process(body: player.snakeBody)
        if self.isStuck {
            return player.kill(.stuckInALoop)
        } else {
            return player
        }
    }
}
