// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeFoodGenerator {
	private var randomNumberGenerator: SeededGenerator

	public init() {
		self.randomNumberGenerator = SeededGenerator(seed: 0)
	}

	public func placeNewFood(_ currentGameState: SnakeGameState) -> SnakeGameState {
		var gameState: SnakeGameState = currentGameState
		guard gameState.foodPosition == nil else {
//			log.debug("there is already food")
			return gameState
		}
		let emptyPositionsArray: [IntVec2] = gameState.level.emptyPositionArray
		var snakePositionSet = Set<IntVec2>()
		if gameState.player1.isInstalled {
			let positionSet: Set<IntVec2> = gameState.player1.snakeBody.positionSet()
			snakePositionSet.formUnion(positionSet)
		}
		if gameState.player2.isInstalled {
			let positionSet: Set<IntVec2> = gameState.player2.snakeBody.positionSet()
			snakePositionSet.formUnion(positionSet)
		}

		var foodPositionsArray: [IntVec2] = emptyPositionsArray
		foodPositionsArray.removeAll { snakePositionSet.contains($0) }

        self.randomNumberGenerator.seed = gameState.foodRandomGenerator_seed

		let positionOrNil: IntVec2? = foodPositionsArray.randomElement(using: &randomNumberGenerator)
		gameState = gameState.updateFoodRandomGenerator(
			seed: randomNumberGenerator.seed,
			count: 0
		)

		guard let position: IntVec2 = positionOrNil else {
            log.info("You won. There are no more available food positions!")
            gameState = gameState.killPlayer1(.noMoreFood)
            gameState = gameState.killPlayer2(.noMoreFood)
			return gameState
		}
		gameState = gameState.stateWithNewFoodPosition(position)
		return gameState
	}
}
