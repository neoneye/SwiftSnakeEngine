// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

extension SnakePlayer {
	fileprivate func toSnakeGameStateModelPlayer() -> SnakeGameStateModelPlayer {

		// Direction of the snake head
		let headDirection: SnakeGameStateModelPlayer.HeadDirection
		switch self.snakeBody.head.direction {
		case .up:
			headDirection = .up
		case .left:
			headDirection = .left
		case .right:
			headDirection = .right
		case .down:
			headDirection = .down
		}

		// Positions of all the snake body parts
		var bodyPositions = [SnakeGameStateModelPosition]()
		for signedPosition: IntVec2 in self.snakeBody.positionArray() {
			guard let unsignedPosition: UIntVec2 = signedPosition.uintVec2() else {
				fatalError("Encountered a negative position. \(signedPosition). The snake game is supposed to always use unsigned coordinates.")
			}
			let position = SnakeGameStateModelPosition.with {
				$0.x = unsignedPosition.x
				$0.y = unsignedPosition.y
			}
			bodyPositions.append(position)
		}

		// IDEA: determine quality/risk of each action
		// did the action cause the snake to die in near future.
		// did the action cause the opponent snake to die in near future.

		let model = SnakeGameStateModelPlayer.with {
			$0.headDirection = headDirection
			$0.bodyPositions = bodyPositions
		}
		return model
	}
}

extension SnakeGameState {
	private func toSnakeGameStateModel() -> SnakeGameStateModel {
		// Food
		let optionalFoodPosition: SnakeGameStateModel.OneOf_OptionalFoodPosition?
		if let position: UIntVec2 = self.foodPosition?.uintVec2() {
			let foodPosition = SnakeGameStateModelPosition.with {
				$0.x = position.x
				$0.y = position.y
			}
			optionalFoodPosition = SnakeGameStateModel.OneOf_OptionalFoodPosition.foodPosition(foodPosition)
		} else {
			optionalFoodPosition = nil
		}

		// IDEA: determine which player is doing best.
		// Swap player1 and player2, so that the best comes first.
		// Do this after the entire game have played out, and distinguish between overall winners/loosers?

		// Model
		let model = SnakeGameStateModel.with {
			$0.levelWidth = self.level.size.x
			$0.levelHeight = self.level.size.y
			$0.optionalFoodPosition = optionalFoodPosition
		}
		return model
	}

	public func saveTrainingData() {
		let model: SnakeGameStateModel = self.toSnakeGameStateModel()

		// Serialize to binary protobuf format
		if let binaryData: Data = try? model.serializedData() {
			let temporaryFileUrl: URL = URL.temporaryFile(with: "snakegame-trainingdata")
			do {
				try binaryData.write(to: temporaryFileUrl)
			} catch {
				print("ERROR: Failed to save trainingdata file at: '\(temporaryFileUrl)', error: \(error)")
				fatalError()
			}
			print("Successfully saved a trainingdata file at: '\(temporaryFileUrl)'.")
		} else {
			print("ERROR: unable to serialize to a trainingdata file.")
		}
	}
}
