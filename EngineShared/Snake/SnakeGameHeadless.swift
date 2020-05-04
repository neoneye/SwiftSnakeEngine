// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeGameHeadless {
    private let environment: SnakeGameEnvironment = SnakeGameEnvironmentInteractive()

	public init() {}

	private func step(_ currentGameState: SnakeGameState) -> SnakeGameState {
		let state0 = environment.placeNewFood(currentGameState)
        let state1 = environment.computeNextBotMovement(state0)
		let state2 = environment.executeStep(state1)
        let state3 = environment.endOfStep(state2)
		return state3
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

