// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeGameHeadless {
	private let foodGenerator = SnakeFoodGenerator()
    private let gameExecuter = SnakeGameExecuter()

	public init() {}

	private func step(_ currentGameState: SnakeGameState) -> SnakeGameState {
		let state0 = foodGenerator.placeNewFood(currentGameState)
        let state1 = gameExecuter.computeNextBotMovement(state0)
		let state2 = gameExecuter.executeStep(state1)
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

