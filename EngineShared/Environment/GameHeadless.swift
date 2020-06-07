// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class GameHeadless {
	public static func run() {
        let snakeBotType0: SnakeBot.Type = SnakeBotFactory.smartestBotType()
        let bot = SnakePlayerRole.bot(snakeBotType: snakeBotType0)

        let initialGameState = SnakeGameState.create(
            player1: bot,
            player2: bot,
            levelName: "Level 4.csv"
        )
        let environment: GameEnvironment = GameEnvironmentInteractive(initialGameState: initialGameState)

        var gameState: SnakeGameState = environment.reset()

		for iteration in 0..<1000 {
            log.debug("#\(iteration) \(gameState.player1.snakeBody.length) \(gameState.player2.snakeBody.length)")

            let action = GameEnvironment_StepAction(
                player1: .dontMove,
                player2: .dontMove
            )
            gameState = environment.step(action: action)
		}
	}
}

