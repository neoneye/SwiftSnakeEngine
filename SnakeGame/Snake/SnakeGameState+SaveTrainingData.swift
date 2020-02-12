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

		let action: SnakeGameStateModelPlayer.Action
		switch self.pendingMovement {
		case .dontMove:
			action = .die
		case .moveForward:
			action = .moveForward
		case .moveCW:
			action = .moveCw
		case .moveCCW:
			action = .moveCcw
		}

		let model = SnakeGameStateModelPlayer.with {
			$0.headDirection = headDirection
			$0.bodyPositions = bodyPositions
			$0.action = action
		}
		return model
	}
}

extension SnakeLevel {
	fileprivate func toSnakeGameStateModelLevel() -> SnakeGameStateModelLevel {
		// Empty positions in the level
		var emptyPositions = [SnakeGameStateModelPosition]()
		for signedPosition: IntVec2 in self.emptyPositionArray {
			guard let unsignedPosition: UIntVec2 = signedPosition.uintVec2() else {
				fatalError("All empty positions must be non-negative, but encountered a negative position: \(signedPosition)")
			}
			let position = SnakeGameStateModelPosition.with {
				$0.x = unsignedPosition.x
				$0.y = unsignedPosition.y
			}
			emptyPositions.append(position)
		}

		// Overall level info
		let model = SnakeGameStateModelLevel.with {
			$0.levelWidth = self.size.x
			$0.levelHeight = self.size.y
			$0.emptyPositions = emptyPositions
		}
		return model
	}
}

extension SnakeGameState {
	private func toSnakeGameStateIngameModel() -> SnakeGameStateIngameModel {
		let level: SnakeGameStateModelLevel = self.level.toSnakeGameStateModelLevel()

		// Food
		var optionalFoodPosition: SnakeGameStateIngameModel.OneOf_OptionalFoodPosition? = nil
		if let position: UIntVec2 = self.foodPosition?.uintVec2() {
			let foodPosition = SnakeGameStateModelPosition.with {
				$0.x = position.x
				$0.y = position.y
			}
			optionalFoodPosition = SnakeGameStateIngameModel.OneOf_OptionalFoodPosition.foodPosition(foodPosition)
		}

		// Player A
		var optionalPlayerA: SnakeGameStateIngameModel.OneOf_OptionalPlayerA? = nil
		do {
			let player: SnakePlayer = self.player1
			if player.isInstalled {
				let model: SnakeGameStateModelPlayer = player.toSnakeGameStateModelPlayer()
				optionalPlayerA = SnakeGameStateIngameModel.OneOf_OptionalPlayerA.playerA(model)
			}
		}

		// Player B
		var optionalPlayerB: SnakeGameStateIngameModel.OneOf_OptionalPlayerB? = nil
		do {
			let player: SnakePlayer = self.player2
			if player.isInstalled {
				let model: SnakeGameStateModelPlayer = player.toSnakeGameStateModelPlayer()
				optionalPlayerB = SnakeGameStateIngameModel.OneOf_OptionalPlayerB.playerB(model)
			}
		}

		// Model
		let model = SnakeGameStateIngameModel.with {
			$0.level = level
			$0.optionalFoodPosition = optionalFoodPosition
			$0.optionalPlayerA = optionalPlayerA
			$0.optionalPlayerB = optionalPlayerB
		}
		return model
	}

	// IDEA: identify which player did the best.
	// After the entire game have played out, then swap player A and player B in such way that:
	// Player A is the winner.
	// Player B is the looser.
	public func saveTrainingData() {
		let model: SnakeGameStateIngameModel = self.toSnakeGameStateIngameModel()

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
