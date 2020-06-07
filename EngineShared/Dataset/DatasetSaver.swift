// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import SwiftProtobuf

extension SnakeCauseOfDeath {
    internal func toSnakeDatasetCauseOfDeath() -> SnakeDatasetCauseOfDeath {
        switch self {
        case .other:
            return SnakeDatasetCauseOfDeath.other
        case .collisionWithWall:
            return SnakeDatasetCauseOfDeath.collisionWithWall
        case .collisionWithItself:
            return SnakeDatasetCauseOfDeath.collisionWithItself
        case .collisionWithOpponent:
            return SnakeDatasetCauseOfDeath.collisionWithOpponent
        case .stuckInALoop:
            return SnakeDatasetCauseOfDeath.stuckInLoop
        case .noMoreFood:
            return SnakeDatasetCauseOfDeath.other
        }
    }
}

extension SnakePlayer {
	internal func toSnakeDatasetPlayer() -> SnakeDatasetPlayer {

        // Flip the position array, so that:
        // The start of the array correspond to the snake head position.
        // The end of the array correspond to the snake tail position.
        let headLast_positionArray: [IntVec2] = self.snakeBody.positionArray()
        let headFirst_positionArray: [IntVec2] = headLast_positionArray.reversed()

		// Positions of all the snake body parts
		var bodyPositions = [SnakeDatasetPosition]()
		for signedPosition: IntVec2 in headFirst_positionArray {
            // IDEA: migrate snake positions to use unsigned integers, so fragile casting can be avoided.
			guard let unsignedPosition: UIntVec2 = signedPosition.uintVec2() else {
				fatalError("Encountered a negative position. \(signedPosition). The snake game is supposed to always use unsigned coordinates.")
			}
			let position = SnakeDatasetPosition.with {
				$0.x = unsignedPosition.x
				$0.y = unsignedPosition.y
			}
			bodyPositions.append(position)
		}

        // This uuid identifies what this player is; a human, or a particular type of bot, or none.
        let uuidString: String = self.role.id.uuidString

        // Conditions resulting in this player's death.
        var datasetAlive: Bool = false
        var datasetCauseOfDeath: SnakeDatasetCauseOfDeath = .other
        if self.isInstalled {
            datasetAlive = self.isInstalledAndAlive
            if self.causesOfDeath.count == 1, let cod: SnakeCauseOfDeath = self.causesOfDeath.first {
                datasetCauseOfDeath = cod.toSnakeDatasetCauseOfDeath()
            }
        }

        let model = SnakeDatasetPlayer.with {
            $0.uuid = uuidString
            $0.alive = datasetAlive
            $0.causeOfDeath = datasetCauseOfDeath
			$0.bodyPositions = bodyPositions
		}
		return model
	}
}

extension SnakeLevel {
	internal func toSnakeDatasetLevel() -> SnakeDatasetLevel {
		// Empty positions in the level
		var emptyPositions = [SnakeDatasetPosition]()
		for signedPosition: IntVec2 in self.emptyPositionArray {
			guard let unsignedPosition: UIntVec2 = signedPosition.uintVec2() else {
				fatalError("All empty positions must be non-negative, but encountered a negative position: \(signedPosition)")
			}
			let position = SnakeDatasetPosition.with {
				$0.x = unsignedPosition.x
				$0.y = unsignedPosition.y
			}
			emptyPositions.append(position)
		}

		// Overall level info
		let model = SnakeDatasetLevel.with {
            $0.uuid = self.id.uuidString
			$0.width = self.size.x
			$0.height = self.size.y
			$0.emptyPositions = emptyPositions
		}
		return model
	}
}

extension SnakeGameState {
	internal func toSnakeDatasetStep() -> SnakeDatasetStep {
		// Food
		var optionalFoodPosition: SnakeDatasetStep.OneOf_OptionalFoodPosition? = nil
		if let position: UIntVec2 = self.foodPosition?.uintVec2() {
			let foodPosition = SnakeDatasetPosition.with {
				$0.x = position.x
				$0.y = position.y
			}
			optionalFoodPosition = SnakeDatasetStep.OneOf_OptionalFoodPosition.foodPosition(foodPosition)
            log.debug("#\(self.numberOfSteps) saving food position: \(position)")
		}

		// Player A
		var optionalPlayerA: SnakeDatasetStep.OneOf_OptionalPlayerA? = nil
		do {
			let player: SnakePlayer = self.player1
			if player.isInstalled {
				let model: SnakeDatasetPlayer = player.toSnakeDatasetPlayer()
				optionalPlayerA = SnakeDatasetStep.OneOf_OptionalPlayerA.playerA(model)

                let pretty = PrettyPrintArray.simple
                let positions: [IntVec2] = player.snakeBody.positionArray()
                log.debug("#\(self.numberOfSteps) saving player1: \(pretty.format(positions))")
			}
		}

		// Player B
		var optionalPlayerB: SnakeDatasetStep.OneOf_OptionalPlayerB? = nil
		do {
			let player: SnakePlayer = self.player2
			if player.isInstalled {
				let model: SnakeDatasetPlayer = player.toSnakeDatasetPlayer()
				optionalPlayerB = SnakeDatasetStep.OneOf_OptionalPlayerB.playerB(model)

                let pretty = PrettyPrintArray.simple
                let positions: [IntVec2] = player.snakeBody.positionArray()
                log.debug("#\(self.numberOfSteps) saving player2: \(pretty.format(positions))")
			}
		}

		// Model
		let model = SnakeDatasetStep.with {
			$0.optionalFoodPosition = optionalFoodPosition
			$0.optionalPlayerA = optionalPlayerA
			$0.optionalPlayerB = optionalPlayerB
		}
		return model
	}

	public func saveTrainingData(trainingSessionUUID: UUID) -> URL {
        let levelModel: SnakeDatasetLevel = self.level.toSnakeDatasetLevel()
        let stepModel: SnakeDatasetStep = self.toSnakeDatasetStep()
        let model = SnakeDatasetIngame.with {
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

// IDEA: Determine the winner: the longest snake, or the longest lived snake, or a combo?
// IDEA: pass on which player won/loose.
public class PostProcessTrainingData {
	private let level: SnakeDatasetLevel
    private let stepArray: [SnakeDatasetStep]

	internal init(level: SnakeDatasetLevel, stepArray: [SnakeDatasetStep]) {
		self.level = level
        self.stepArray = stepArray
	}

    /// SnakeDatasetResult serialized to Data
	internal func toData() -> Data {
        guard let firstStep: SnakeDatasetStep = self.stepArray.first,
            let lastStep: SnakeDatasetStep = self.stepArray.last else {
            fatalError("Expected the stepArray to be non-empty, but it's empty. Cannot create result file.")
        }
        var foodPositions: [SnakeDatasetPosition] = []
        for step in stepArray {
            foodPositions.append(step.foodPosition)
        }

        // Extract all "head positions" for "Player A"
        var playerAPositions: [SnakeDatasetPosition] = []
        for (index, step) in stepArray.enumerated() {
            guard case .playerA(let player)? = step.optionalPlayerA else {
                if index >= 1 {
                    log.error("Expected player A, but got none. Index#\(index).")
                }
                break
            }
            guard let headPosition: SnakeDatasetPosition = player.bodyPositions.first else {
                log.error("Expected player A bodyPositions to be non-empty, but it's empty. Index: \(index).")
                break
            }
            let previousPosition: SnakeDatasetPosition? = playerAPositions.last
            guard previousPosition != headPosition else {
                log.debug("Player A is dead. The position is no longer changing. Index: \(index)")
                break
            }
            playerAPositions.append(headPosition)
        }

        // Extract all "head positions" for "Player B"
        var playerBPositions: [SnakeDatasetPosition] = []
        for (index, step) in stepArray.enumerated() {
            guard case .playerB(let player)? = step.optionalPlayerB else {
                if index >= 1 {
                    log.error("Expected player B, but got none. Index#\(index).")
                }
                break
            }
            guard let headPosition: SnakeDatasetPosition = player.bodyPositions.first else {
                log.error("Expected player B bodyPositions to be non-empty, but it's empty. Index: \(index).")
                break
            }
            let previousPosition: SnakeDatasetPosition? = playerBPositions.last
            guard previousPosition != headPosition else {
                log.debug("Player B is dead. The position is no longer changing. Index: \(index)")
                break
            }
            playerBPositions.append(headPosition)
        }

        // Discard the first head position,
        // Since the initial snake body, has a its head position at the same position.
        // We are only interested in saving the movements of the snake.
        // We are not interested in a snake that doesn't move in the first step.
        if !playerAPositions.isEmpty {
            playerAPositions.removeFirst(1)
        }
        if !playerBPositions.isEmpty {
            playerBPositions.removeFirst(1)
        }

        let positions1: [UIntVec2] = playerAPositions.toUIntVec2Array()
        let positions2: [UIntVec2] = playerBPositions.toUIntVec2Array()

        let pretty = PrettyPrintArray.simple
        log.debug("Post processing. all move positions for player1: \(pretty.format(positions1))")
        log.debug("Post processing. all move positions for player2: \(pretty.format(positions2))")


        let date = Date()

        log.debug("level.uuid: '\(self.level.uuid)'")
        log.debug("foodPositions.count: \(foodPositions.count)")
        log.debug("playerAPositions.count: \(playerAPositions.count)")
        log.debug("playerBPositions.count: \(playerBPositions.count)")
        log.debug("timestamp: \(date)")

		let model = SnakeDatasetResult.with {
			$0.level = self.level
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
        return binaryData
    }

    func saveToTempoaryFile(trainingSessionUUID: UUID) {
        let binaryData: Data = self.toData()
		let temporaryFileUrl: URL = URL.temporaryFile(
			prefixes: ["snakegame", "trainingdata"],
			uuid: trainingSessionUUID,
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
        log.info("will process \(urls.count) files")
        let snakeDatasetIngameArray: [SnakeDatasetIngame] = urls.compactMap {
            loadSnakeDatasetIngame(contentsOf: $0)
        }
        guard snakeDatasetIngameArray.count == urls.count else {
            log.error("There was a problem processing one or more files.")
            return
        }
        log.info("did process \(urls.count) files")

        let sharedLevel: SnakeDatasetLevel = snakeDatasetIngameArray.first!.level
        for snakeDatasetIngame: SnakeDatasetIngame in snakeDatasetIngameArray {
            guard snakeDatasetIngame.level.isEqualTo(message: sharedLevel) else {
                log.error("Inconsistent level info. Expected all the files in a session to refer to the same level.")
                return
            }
        }
        let stepArray: [SnakeDatasetStep] = snakeDatasetIngameArray.map { $0.step }

        log.info("will postprocess")
		let processor = PostProcessTrainingData(level: sharedLevel, stepArray: stepArray)

		processor.saveToTempoaryFile(trainingSessionUUID: trainingSessionUUID)
        log.info("did postprocess")
	}

    private class func loadSnakeDatasetIngame(contentsOf url: URL) -> SnakeDatasetIngame? {
        let model: SnakeDatasetIngame
        do {
            let data: Data = try Data(contentsOf: url)
            model = try SnakeDatasetIngame(serializedData: data)
        } catch {
            log.error("Unable to load file at url: '\(url)'. \(error)")
            return nil
        }
        guard model.hasLevel else {
            log.error("Expected the file to have a reference to level, but got none. '\(url)'")
            return nil
        }
        guard model.hasStep else {
            log.error("Expected the file to 'step' instance, but got nil. url: '\(url)'")
            return nil
        }
        return model
    }

}
