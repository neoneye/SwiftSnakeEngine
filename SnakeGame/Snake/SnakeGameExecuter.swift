// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeGameExecuter {
	
	/// Decide about optimal path to get to the food
	public class func prepareBotMovements(_ currentGameState: SnakeGameState) -> SnakeGameState {
		var gameState: SnakeGameState = currentGameState
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
	public class func preventHumanCollisions(_ currentGameState: SnakeGameState) -> SnakeGameState {
		var gameState: SnakeGameState = currentGameState

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

	public class func isWaitingForHumanInput(_ gameState: SnakeGameState) -> Bool {
		var waitingForPlayers = false
		if gameState.player1.isAlive && gameState.player1.pendingMovement == .dontMove {
			waitingForPlayers = true
		}
		if gameState.player2.isAlive && gameState.player2.pendingMovement == .dontMove {
			waitingForPlayers = true
		}
		if waitingForPlayers {
			//print("waiting for players")
			return true
		} else {
			return false
		}
	}

	public class func executeStep(_ currentGameState: SnakeGameState) -> SnakeGameState {
		var gameState: SnakeGameState = currentGameState
		let newGameState = SnakeGameExecuter.detectCollision(gameState)
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
			gameState = gameState.stateWithNewPlayer2(player)
		}

		gameState = gameState.incrementNumberOfSteps()
		return gameState
	}


	/// Deal with collision when both the player1 and the player2 is installed
	/// Deal with collision only if either the player1 or player2 is installed
	fileprivate class func detectCollision(_ currentGameState: SnakeGameState) -> SnakeGameState {
		var gameState: SnakeGameState = currentGameState
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
			print("killing player1 because: \(detector.collisionType1)")
			gameState = gameState.killPlayer1()
		}
		if gameState.player2.isAlive && detector.player2Alive == false {
			print("killing player2 because: \(detector.collisionType2)")
			gameState = gameState.killPlayer2()
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
