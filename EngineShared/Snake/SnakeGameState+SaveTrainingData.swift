// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

extension SnakePlayer {
	fileprivate func toSnakeGameStateModelPlayer() -> SnakeGameStateModelPlayer {

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

        let model = SnakeGameStateModelPlayer.with {
            $0.alive = self.isAlive
			$0.bodyPositions = bodyPositions
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
            $0.uuid = self.id.uuidString
			$0.width = self.size.x
			$0.height = self.size.y
			$0.emptyPositions = emptyPositions
		}
		return model
	}
}

extension SnakeGameState {
	private func toSnakeGameStateStepModel() -> SnakeGameStateStepModel {
		// Food
		var optionalFoodPosition: SnakeGameStateStepModel.OneOf_OptionalFoodPosition? = nil
		if let position: UIntVec2 = self.foodPosition?.uintVec2() {
			let foodPosition = SnakeGameStateModelPosition.with {
				$0.x = position.x
				$0.y = position.y
			}
			optionalFoodPosition = SnakeGameStateStepModel.OneOf_OptionalFoodPosition.foodPosition(foodPosition)
		}

		// Player A
		var optionalPlayerA: SnakeGameStateStepModel.OneOf_OptionalPlayerA? = nil
		do {
			let player: SnakePlayer = self.player1
			if player.isInstalled {
				let model: SnakeGameStateModelPlayer = player.toSnakeGameStateModelPlayer()
				optionalPlayerA = SnakeGameStateStepModel.OneOf_OptionalPlayerA.playerA(model)
			}
		}

		// Player B
		var optionalPlayerB: SnakeGameStateStepModel.OneOf_OptionalPlayerB? = nil
		do {
			let player: SnakePlayer = self.player2
			if player.isInstalled {
				let model: SnakeGameStateModelPlayer = player.toSnakeGameStateModelPlayer()
				optionalPlayerB = SnakeGameStateStepModel.OneOf_OptionalPlayerB.playerB(model)
			}
		}

		// Model
		let model = SnakeGameStateStepModel.with {
			$0.optionalFoodPosition = optionalFoodPosition
			$0.optionalPlayerA = optionalPlayerA
			$0.optionalPlayerB = optionalPlayerB
		}
		return model
	}

	public func saveTrainingData(trainingSessionUUID: UUID) -> URL {
        let levelModel: SnakeGameStateModelLevel = self.level.toSnakeGameStateModelLevel()
        let stepModel: SnakeGameStateStepModel = self.toSnakeGameStateStepModel()
        let model = SnakeGameStateIngameModel.with {
            $0.level = levelModel
            $0.step = stepModel
        }
		let stepIndex: String = "step\(self.numberOfSteps)"

		// Serialize to binary protobuf format
		guard let binaryData: Data = try? model.serializedData() else {
			fatalError("Unable to serialize to a trainingdata file.")
		}
		let temporaryFileUrl: URL = URL.temporaryFile(
			prefixes: ["snakegame", "trainingdata"],
			uuid: trainingSessionUUID,
			suffixes: ["ingame", stepIndex]
		)
		do {
			try binaryData.write(to: temporaryFileUrl)
		} catch {
			fatalError("ERROR: Failed to save trainingdata file at: '\(temporaryFileUrl)', error: \(error)")
		}
		log.debug("Successfully saved \(binaryData.count) bytes of trainingdata at: '\(temporaryFileUrl)'.")
		return temporaryFileUrl
	}
}

public class PostProcessTrainingData {
	private let trainingSessionUUID: UUID
	private let sharedLevel: SnakeGameStateModelLevel
	private init(trainingSessionUUID: UUID, sharedLevel: SnakeGameStateModelLevel) {
		self.trainingSessionUUID = trainingSessionUUID
		self.sharedLevel = sharedLevel
	}

	private func processFile(at url: URL) {
		let model: SnakeGameStateIngameModel
		do {
			let data: Data = try Data(contentsOf: url)
			model = try SnakeGameStateIngameModel(serializedData: data)
		} catch {
			log.error("Unable to load file at url: '\(url)'. \(error)")
			return
		}
		// IDEA: convert into a SnakeGameStateWinnerLooserModelStep
	}

	private func saveResult() {
		let model = SnakeGameResultModel.with {
			$0.level = self.sharedLevel
			// IDEA: assign $0.steps with the accumulated SnakeGameStateWinnerLooserModelStep's
		}

		// Serialize to binary protobuf format
		guard let binaryData: Data = try? model.serializedData() else {
			fatalError("Unable to serialize to a result file.")
		}
		let temporaryFileUrl: URL = URL.temporaryFile(
			prefixes: ["snakegame", "trainingdata"],
			uuid: self.trainingSessionUUID,
			suffixes: ["result"]
		)
		do {
			try binaryData.write(to: temporaryFileUrl)
		} catch {
			fatalError("ERROR: Failed to save result file at: '\(temporaryFileUrl)', error: \(error)")
		}
        log.info("Successfully saved \(binaryData.count) bytes of result at: '\(temporaryFileUrl)'.")
	}

	/// Post processing of all the generated files by a training session.
	///
	/// After the entire game have played out, then swap player A and player B in such way that:
	///
	/// - Player A is the winner.
	///
	/// - Player B is the looser, if there is a player B.
	///
	/// The level data is only stored once. Greatly reducing the size of the training data.
	public class func process(trainingSessionUUID: UUID, urls: [URL]) {
        log.info("will process \(urls.count) files")

		guard urls.count >= 1 else {
			log.error("Expected 1 or more urls for post processing. There is nothing to process!")
			return
		}
		let sharedLevel: SnakeGameStateModelLevel
		let url0: URL = urls.first!
		do {
			let data: Data = try Data(contentsOf: url0)
			let model: SnakeGameStateIngameModel = try SnakeGameStateIngameModel(serializedData: data)
			sharedLevel = model.level
		} catch {
			log.error("Unable to load file at url: '\(url0)'. \(error)")
			return
		}
		let processor = PostProcessTrainingData(trainingSessionUUID: trainingSessionUUID, sharedLevel: sharedLevel)
		for url in urls {
			processor.processFile(at: url)
		}

        log.info("did process \(urls.count) files")

		processor.saveResult()
	}
}
