// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

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
