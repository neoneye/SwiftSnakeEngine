// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeGameHeadless {
    private let environment: SnakeGameEnvironment

	public init() {
        let snakeBotType0: SnakeBot.Type = SnakeBotFactory.smartestBotType()
        let bot = SnakePlayerRole.bot(snakeBotType: snakeBotType0)

        let gameState = SnakeGameState.create(
            player1: bot,
            player2: bot,
            levelName: "Level 4.csv"
        )
        environment = SnakeGameEnvironmentInteractive(initialGameState: gameState)
    }

	private func step(_ currentGameState: SnakeGameState) -> SnakeGameState {
		let state0 = environment.placeNewFood(currentGameState)
		let state1 = environment.step(state0)
        let state2 = environment.endOfStep(state1)
		return state2
	}

	public func run() {
        let snakeBotType0: SnakeBot.Type = SnakeBotFactory.smartestBotType()
		let bot = SnakePlayerRole.bot(snakeBotType: snakeBotType0)

		var gameState = SnakeGameState.create(
			player1: bot,
			player2: bot,
			levelName: "Level 4.csv"
		)

		for iteration in 0..<1000 {
            log.debug("#\(iteration) \(gameState.player1.snakeBody.length) \(gameState.player2.snakeBody.length)")
			gameState = step(gameState)
		}
	}
}

