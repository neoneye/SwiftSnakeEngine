// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import SwiftProtobuf

extension SnakePlayer {
	internal func toSnakeGameStateModelPlayer() -> SnakeGameStateModelPlayer {

        // Flip the position array, so that:
        // The start of the array correspond to the snake head position.
        // The end of the array correspond to the snake tail position.
        let headLast_positionArray: [IntVec2] = self.snakeBody.positionArray()
        let headFirst_positionArray: [IntVec2] = headLast_positionArray.reversed()

		// Positions of all the snake body parts
		var bodyPositions = [SnakeGameStateModelPosition]()
		for signedPosition: IntVec2 in headFirst_positionArray {
			guard let unsignedPosition: UIntVec2 = signedPosition.uintVec2() else {
				fatalError("Encountered a negative position. \(signedPosition). The snake game is supposed to always use unsigned coordinates.")
			}
			let position = SnakeGameStateModelPosition.with {
				$0.x = unsignedPosition.x
				$0.y = unsignedPosition.y
			}
			bodyPositions.append(position)
		}

        // This uuid identifies what this player is; a human, or a particular type of bot, or none.
        let uuidString: String = self.role.id.uuidString

        let model = SnakeGameStateModelPlayer.with {
            $0.uuid = uuidString
            $0.alive = self.isAlive
			$0.bodyPositions = bodyPositions
		}
		return model
	}
}

extension SnakeLevel {
	internal func toSnakeGameStateModelLevel() -> SnakeGameStateModelLevel {
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
    private var stepArray: [SnakeGameStateStepModel] = []

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
        guard model.hasLevel else {
            log.error("Expected the file to have a reference to level, but got none. '\(url)'")
            return
        }
        guard model.hasStep else {
            log.error("Expected the file to 'step' instance, but got nil. url: '\(url)'")
            return
        }
        guard model.level.isEqualTo(message: self.sharedLevel) else {
            log.error("Inconsistent level info. Expected all the files in a session to refer to the same level. '\(url)'")
            return
        }
        stepArray.append(model.step)
	}

	private func saveResult() {
        guard let firstStep: SnakeGameStateStepModel = self.stepArray.first,
            let lastStep: SnakeGameStateStepModel = self.stepArray.last else {
            fatalError("Expected the stepArray to be non-empty, but it's empty. Cannot create result file.")
        }
        var foodPositions: [SnakeGameStateModelPosition] = []
        for step in stepArray {
            foodPositions.append(step.foodPosition)
        }

        // Extract "head positions" for "Player A"
        var playerAPositions: [SnakeGameStateModelPosition] = []
        for (index, step) in stepArray.enumerated() {
            guard case .playerA(let player)? = step.optionalPlayerA else {
                if index >= 1 {
                    log.error("Expected player A, but got none. Index#\(index).")
                }
                break
            }
            guard player.alive else {
                log.debug("Player A is dead.  Index: \(index)")
                break
            }
            guard let headPosition: SnakeGameStateModelPosition = player.bodyPositions.first else {
                log.error("Expected player A bodyPositions to be non-empty, but it's empty. Index: \(index).")
                break
            }
            playerAPositions.append(headPosition)
        }

        // Extract "head positions" for "Player B"
        var playerBPositions: [SnakeGameStateModelPosition] = []
        for (index, step) in stepArray.enumerated() {
            guard case .playerB(let player)? = step.optionalPlayerB else {
                if index >= 1 {
                    log.error("Expected player B, but got none. Index#\(index).")
                }
                break
            }
            guard player.alive else {
                log.debug("Player B is dead.  Index: \(index)")
                break
            }
            guard let headPosition: SnakeGameStateModelPosition = player.bodyPositions.first else {
                log.error("Expected player B bodyPositions to be non-empty, but it's empty. Index: \(index).")
                break
            }
            playerBPositions.append(headPosition)
        }

        let date = Date()

        log.debug("level.uuid: '\(self.sharedLevel.uuid)'")
        log.debug("foodPositions.count: \(foodPositions.count)")
        log.debug("playerAPositions.count: \(playerAPositions.count)")
        log.debug("playerBPositions.count: \(playerBPositions.count)")
        log.debug("timestamp: \(date)")

		let model = SnakeGameResultModel.with {
			$0.level = self.sharedLevel
            $0.firstStep = firstStep
            $0.lastStep = lastStep
            $0.foodPositions = foodPositions
            $0.playerAPositions = playerAPositions
            $0.playerBPositions = playerBPositions
            $0.timestamp = Google_Protobuf_Timestamp(date: date)
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
