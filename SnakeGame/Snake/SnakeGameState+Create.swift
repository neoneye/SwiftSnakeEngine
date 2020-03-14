// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

extension SnakeGameState {
	public class func create(player1: SnakePlayerRole, player2: SnakePlayerRole, levelName: String) -> SnakeGameState {
		guard let snakeLevel: SnakeLevel = SnakeLevelManager.shared.level(levelName) else {
			fatalError("Cannot find a level with the levelName '\(levelName)'")
		}
		
		var gameState = SnakeGameState.empty()
		gameState = gameState.stateWithNewLevel(snakeLevel)

		do {
            var player = SnakePlayer.create(id: .player1, role: player1)
			let snakeBody = SnakeBody.create(
				position: snakeLevel.player1_initialPosition.intVec2,
				headDirection: snakeLevel.player1_initialHeadDirection,
				length: snakeLevel.player1_initialLength
			)
			player = player.playerWithNewSnakeBody(snakeBody)
			if player.role == .none {
				player = player.uninstall()
			}
			gameState = gameState.stateWithNewPlayer1(player)
		}
		do {
			var player = SnakePlayer.create(id: .player2, role: player2)
			let snakeBody = SnakeBody.create(
				position: snakeLevel.player2_initialPosition.intVec2,
				headDirection: snakeLevel.player2_initialHeadDirection,
				length: snakeLevel.player2_initialLength
			)
			player = player.playerWithNewSnakeBody(snakeBody)
			if player.role == .none {
				player = player.uninstall()
			}
			gameState = gameState.stateWithNewPlayer2(player)
		}
		gameState = gameState.stateWithNewFoodPosition(snakeLevel.initialFoodPosition.intVec2)
		return gameState
	}
}
