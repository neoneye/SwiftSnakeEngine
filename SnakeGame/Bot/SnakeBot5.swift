// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

fileprivate struct Constant {
	static let printStats = false
	static let numberOfScenariosToExplore_1playerMode: UInt = 40
	static let numberOfTicksToPredictAhead_1playerMode: UInt = 40
	static let numberOfScenariosToExplore_2playerMode: UInt = 20
	static let numberOfTicksToPredictAhead_2playerMode: UInt = 20
}

fileprivate struct PreviousIterationData {
	let scenarioResult: ScenarioResult
	let snakeHead: SnakeHead
}

public class SnakeBot5: SnakeBot {
	public static var info: SnakeBotInfo {
		SnakeBotInfoImpl(
			humanReadableName: "Monte Carlo 1",
			userDefaultIdentifier: "bot5"
		)
	}

	private let iteration: UInt
	private let previousIterationData: PreviousIterationData?

	private init(iteration: UInt, previousIterationData: PreviousIterationData?) {
		self.iteration = iteration
		self.previousIterationData = previousIterationData
	}

	required public convenience init() {
		self.init(iteration: 0, previousIterationData: nil)
	}

	public func plannedPath() -> [IntVec2] {
		guard let previousIterationData: PreviousIterationData = self.previousIterationData else {
			return []
		}
		var head: SnakeHead = previousIterationData.snakeHead
		var positionArray = [IntVec2]()
		let movements: [SnakeBodyMovement] = previousIterationData.scenarioResult.movements
		for movement in movements {
			head = head.simulateTick(movement: movement)
			positionArray.append(head.position)
		}
		return positionArray
	}

	public func compute(level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?) -> (SnakeBot, SnakeBodyMovement) {
		let t0 = CFAbsoluteTimeGetCurrent()
		let result = takeAction_inner(level: level, player: player, oppositePlayer: oppositePlayer, foodPosition: foodPosition)
		let t1 = CFAbsoluteTimeGetCurrent()
		let elapsed: Double = t1 - t0
		if Constant.printStats {
			log.debug("#\(iteration) total elapsed: \(elapsed)")
		}
		return result
	}

	private func takeAction_inner(level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?) -> (SnakeBot, SnakeBodyMovement) {

		guard player.isInstalled else {
			//log.debug("Do nothing. The player is not installed. It doesn't make sense to run the bot.")
			return (self, .moveForward)
		}
		guard player.isAlive else {
			//log.debug("Do nothing. The player is not alive. It doesn't make sense to run the bot.")
			return (self, .moveForward)
		}

		let emptyPositionSet: Set<IntVec2>
		if oppositePlayer.isInstalled && oppositePlayer.isDead {
			let deadSnakePositionSet: Set<IntVec2> = oppositePlayer.snakeBody.positionSet()
			emptyPositionSet = level.emptyPositionSet.subtracting(deadSnakePositionSet)
		} else {
			emptyPositionSet = level.emptyPositionSet
		}
		let processor = ScenarioResultProcessor(
			iteration: iteration,
			levelSize: level.size,
			emptyPositionSet: emptyPositionSet,
			foodPosition: foodPosition
		)

		if oppositePlayer.isAlive {
			// 2 player mode

			// IDEA: Explore using existing data from the previous iteration.
			// IDEA: Rank the scenarios of the opposite player, pass the best scenarios to next iteration

			// Explore entirely new random scenarios.
			for scenarioIndex: UInt in 0..<Constant.numberOfScenariosToExplore_2playerMode {
				processor.randomWalk2(
					scenarioIndex: scenarioIndex,
					level: level,
					player: player,
					oppositePlayer: oppositePlayer
				)
			}
		} else {
			// 1 player mode
			// Explore using existing data from the previous iteration.
			if let previousIterationData: PreviousIterationData = self.previousIterationData {
				let scenarioResult: ScenarioResult = previousIterationData.scenarioResult
				processor.analyze1(player, scenarioResult, SnakeBodyMovement.moveForward)
				processor.analyze1(player, scenarioResult, SnakeBodyMovement.moveCCW)
				processor.analyze1(player, scenarioResult, SnakeBodyMovement.moveCW)
			}

			// Explore entirely new random scenarios.
			for scenarioIndex: UInt in 0..<Constant.numberOfScenariosToExplore_1playerMode {
				processor.randomWalk1(scenarioIndex: scenarioIndex, player: player)
			}
		}

		// Rank the results
		let scenarioResults: [ScenarioResult] = processor.sorted()

		if Constant.printStats {
			for (scenarioResultIndex, scenarioResult) in scenarioResults.prefix(5).enumerated() {
				log.debug("#\(iteration)  \(scenarioResultIndex): \(scenarioResult)")
			}
		}

		guard let bestScenarioResult: ScenarioResult = scenarioResults.first else {
			log.error("Expected 1 or more scenarioResults, but got 0")
			return (self, .moveForward)
		}

//		log.debug("#\(iteration) first: \(bestScenarioResult)")

		guard let bestMovement: SnakeBodyMovement = bestScenarioResult.movements.first else {
			log.error("Expected bestScenarioResult.movements to be 1 or longer, but got nil")
			return (self, .moveForward)
		}

		let previousIterationData = PreviousIterationData(
			scenarioResult: bestScenarioResult,
			snakeHead: player.snakeBody.head
		)
		let bot = SnakeBot5(
			iteration: self.iteration + 1,
			previousIterationData: previousIterationData
		)
		return (bot, bestMovement)
	}
}

extension SnakeBodyMovement {
	fileprivate var shorthand: String {
		switch self {
		case .dontMove:
			return "#"
		case .moveForward:
			return "-"
		case .moveCCW:
			return "<"
		case .moveCW:
			return ">"
		}
	}
}

fileprivate class ScenarioResult {
	let movements: [SnakeBodyMovement]
	let ticksUntilFood: UInt?
	let ticksUntilDeath: UInt?
	let areaSize: UInt
	let estimatedDistanceToFood: UInt?

	init(movements: [SnakeBodyMovement], ticksUntilFood: UInt?, ticksUntilDeath: UInt?, areaSize: UInt, estimatedDistanceToFood: UInt?) {
		self.movements = movements
		self.ticksUntilFood = ticksUntilFood
		self.ticksUntilDeath = ticksUntilDeath
		self.areaSize = areaSize
		self.estimatedDistanceToFood = estimatedDistanceToFood
	}

	/// The utility function of this bot.
	static func mycompare(lhs: ScenarioResult, rhs: ScenarioResult) -> Bool {
		// Maximize life-length.
		// If both scenarios have the same value, then fall through and consider other paramters.
		if let ticksUntilDeath0: UInt = lhs.ticksUntilDeath, let ticksUntilDeath1: UInt = rhs.ticksUntilDeath {
			if ticksUntilDeath0 == ticksUntilDeath1 {
				// fall through
			} else {
				return ticksUntilDeath0 > ticksUntilDeath1
			}
		} else {
			if lhs.ticksUntilDeath == nil && rhs.ticksUntilDeath != nil {
				return true
			}
			if lhs.ticksUntilDeath != nil && rhs.ticksUntilDeath == nil {
				return false
			}
		}

		// Minimize precise distance to food.
		// If both scenarios have the same value, then fall through and consider other paramters.
		if let ticksUntilFood0: UInt = lhs.ticksUntilFood, let ticksUntilFood1: UInt = rhs.ticksUntilFood {
			if ticksUntilFood0 == ticksUntilFood1 {
				// fall through
			} else {
				return ticksUntilFood0 < ticksUntilFood1
			}
		} else {
			if lhs.ticksUntilFood != nil {
				return true
			}
			if rhs.ticksUntilFood != nil {
				return false
			}
		}

		// Minimize estimated distance to food.
		// If both scenarios have the same value, then fall through and consider other paramters.
		if let estimatedDistanceToFood0: UInt = lhs.estimatedDistanceToFood, let estimatedDistanceToFood1: UInt = rhs.estimatedDistanceToFood {
			if estimatedDistanceToFood0 == estimatedDistanceToFood1 {
				// fall through
			} else {
				return estimatedDistanceToFood0 < estimatedDistanceToFood1
			}
		} else {
			if lhs.estimatedDistanceToFood != nil {
				return true
			}
			if rhs.estimatedDistanceToFood != nil {
				return false
			}
		}

		// Maximize the room available for the snake to move around inside.
		// If both scenarios have the same value, then fall through and consider other paramters.
		if lhs.areaSize == rhs.areaSize {
			// fall through
		} else {
			return lhs.areaSize > rhs.areaSize
		}

		// Both scenarios are nearly identical.
		// Pick the "lhs" scenario as the preferred one.
		return false
	}

	var movementSummaryString: String {
		movements.map { $0.shorthand }.joined(separator: "")
	}
}

extension ScenarioResult: CustomStringConvertible {
	var description: String {
		let ticksUntilDeathString: String
		if let ticks = ticksUntilDeath {
			ticksUntilDeathString = "\(ticks)"
		} else {
			ticksUntilDeathString = "-"
		}

		let ticksUntilFoodString: String
		if let ticks = ticksUntilFood {
			ticksUntilFoodString = "\(ticks)"
		} else {
			ticksUntilFoodString = "-"
		}

		let estimatedDistanceToFoodString: String
		if let distance = estimatedDistanceToFood {
			estimatedDistanceToFoodString = "\(distance)"
		} else {
			estimatedDistanceToFoodString = "-"
		}

		return "\(movementSummaryString) \(ticksUntilDeathString) \(ticksUntilFoodString) \(estimatedDistanceToFoodString)"
	}
}

fileprivate class ScenarioResultProcessor {
	let iteration: UInt
	let levelSize: UIntVec2
	let foodPosition: IntVec2?
	let emptyPositionSet: Set<IntVec2>
	var scenarioResults = [ScenarioResult]()

	init(iteration: UInt, levelSize: UIntVec2, emptyPositionSet: Set<IntVec2>, foodPosition: IntVec2?) {
		self.iteration = iteration
		self.levelSize = levelSize
		self.emptyPositionSet = emptyPositionSet
		self.foodPosition = foodPosition
	}

	/// 1player mode: Explore using existing data from the the previous iteration
	func analyze1(_ player: SnakePlayer, _ previousIterationScenarioResult: ScenarioResult, _ extraMovement: SnakeBodyMovement) {
		var snakeBody: SnakeBody = player.snakeBody
		var currentFoodPosition: IntVec2? = foodPosition

		var candidateMovements = [SnakeBodyMovement]()
		var ticksUntilFood: UInt? = nil
		var ticksUntilDeath: UInt? = nil

		var plannedMovements: ArraySlice<SnakeBodyMovement> = previousIterationScenarioResult.movements.dropFirst()
		plannedMovements.append(extraMovement)
		for (tickIndex, snakeBodyMovement) in plannedMovements.enumerated() {
			let newHead: SnakeHead = snakeBody.head.simulateTick(movement: snakeBodyMovement)
			guard self.emptyPositionSet.contains(newHead.position) else {
//				log.debug("#\(iteration) snake collided with wall")
				ticksUntilDeath = UInt(tickIndex)
				break
			}
			let act: SnakeBodyAct
			if newHead.position == currentFoodPosition {
				act = .eat
				currentFoodPosition = nil
				ticksUntilFood = UInt(tickIndex)
			} else {
				act = .doNothing
			}
			snakeBody = snakeBody.stateForTick(movement: snakeBodyMovement, act: act)

			candidateMovements.append(snakeBodyMovement)

			if snakeBody.isEatingItself {
//				log.debug("#\(iteration) snake is eating itself")
				ticksUntilDeath = UInt(tickIndex)
				break
			}
		}

		var areaSize: UInt = 0
		if ticksUntilDeath == nil {
			var availablePositions: Set<IntVec2> = self.emptyPositionSet
			let snakePositions: Set<IntVec2> = snakeBody.positionSet()
			availablePositions.subtract(snakePositions)
			availablePositions.insert(snakeBody.head.position)
			areaSize = MeasureAreaSize.compute(positionSet: availablePositions, startPosition: snakeBody.head.position)
		}

		var estimatedDistanceToFood: UInt? = nil
		if ticksUntilDeath == nil && ticksUntilFood == nil {
			let lastHeadPosition: IntVec2 = snakeBody.head.position
			var emptyPositionsSet = self.emptyPositionSet
			emptyPositionsSet.subtract(snakeBody.positionSet())
			emptyPositionsSet.insert(lastHeadPosition)
			let distanceMap = SnakeLevelDistanceMap.create(levelSize: levelSize, emptyPositionSet: emptyPositionsSet, initialPosition: currentFoodPosition)
			if let cell: SnakeLevelDistanceMapCell = distanceMap.getValue(lastHeadPosition) {
				switch cell {
				case .distance(let steps):
					estimatedDistanceToFood = UInt(steps)
				case .obscured:
					()
				}
			}
		}

		let scenarioResult = ScenarioResult(
			movements: candidateMovements,
			ticksUntilFood: ticksUntilFood,
			ticksUntilDeath: ticksUntilDeath,
			areaSize: areaSize,
			estimatedDistanceToFood: estimatedDistanceToFood
		)
		scenarioResults.append(scenarioResult)
	}

	/// 1player mode: Explore entirely new random scenarios
	func randomWalk1(scenarioIndex: UInt, player: SnakePlayer) {
		let seed: UInt64 = UInt64(scenarioIndex + iteration * 100)
		var randomNumberGenerator = SeededGenerator(seed: seed)

		var snakeBody: SnakeBody = player.snakeBody
		var currentFoodPosition: IntVec2? = foodPosition

		var candidateMovements = [SnakeBodyMovement]()
		var ticksUntilFood: UInt? = nil
		var ticksUntilDeath: UInt? = nil
		for tickIndex: UInt in 0..<Constant.numberOfTicksToPredictAhead_1playerMode {

			let currentHead: SnakeHead = snakeBody.head

			var availableMovements = [SnakeBodyMovement]()
			func check(_ movement: SnakeBodyMovement) {
				let newHead: SnakeHead = currentHead.simulateTick(movement: movement)
				if self.emptyPositionSet.contains(newHead.position) {
					availableMovements.append(movement)
				}
			}
			// IDEA: When checking if a path is obscured, then remember if it's
			// obscured by a permanent wall or by a temporary moving object.
			// This way a risk factor can be computed, so that high-risk paths can be avoided.
			check(SnakeBodyMovement.moveForward)
			check(SnakeBodyMovement.moveCCW)
			check(SnakeBodyMovement.moveCW)
			guard let snakeBodyMovement: SnakeBodyMovement = availableMovements.randomElement(using: &randomNumberGenerator) else {
				//log.debug("#\(iteration) no move choices available")
				ticksUntilDeath = tickIndex
				break
			}

			let newHead: SnakeHead = currentHead.simulateTick(movement: snakeBodyMovement)
			let act: SnakeBodyAct
			if newHead.position == currentFoodPosition {
				act = .eat
				currentFoodPosition = nil
				ticksUntilFood = tickIndex
			} else {
				act = .doNothing
			}
			snakeBody = snakeBody.stateForTick(movement: snakeBodyMovement, act: act)

			candidateMovements.append(snakeBodyMovement)

			guard !snakeBody.isEatingItself else {
				//log.debug("#\(iteration) snake is eating itself")
				ticksUntilDeath = tickIndex
				break
			}
		}

		var areaSize: UInt = 0
		if ticksUntilDeath == nil {
			var availablePositions: Set<IntVec2> = self.emptyPositionSet
			let snakePositions: Set<IntVec2> = snakeBody.positionSet()
			availablePositions.subtract(snakePositions)
			availablePositions.insert(snakeBody.head.position)
			// IDEA: Is this areaSize computed correct. I often experience that the snake curls up into an unescapable vortex.
			// This may be because the areaSize is computed incorrect. Maybe I shouldn't include the head position
			// as an available position. In this case the snake is busy eating itself.
			areaSize = MeasureAreaSize.compute(positionSet: availablePositions, startPosition: snakeBody.head.position)
		}


		var estimatedDistanceToFood: UInt? = nil
		if ticksUntilDeath == nil && ticksUntilFood == nil {
			let lastHeadPosition: IntVec2 = snakeBody.head.position
			var emptyPositionsSet = self.emptyPositionSet
			emptyPositionsSet.subtract(snakeBody.positionSet())
			emptyPositionsSet.insert(lastHeadPosition)
			let distanceMap = SnakeLevelDistanceMap.create(levelSize: levelSize, emptyPositionSet: emptyPositionsSet, initialPosition: currentFoodPosition)
			if let cell: SnakeLevelDistanceMapCell = distanceMap.getValue(lastHeadPosition) {
				switch cell {
				case .distance(let steps):
					estimatedDistanceToFood = UInt(steps)
				case .obscured:
					()
				}
			}
		}


		let scenarioResult = ScenarioResult(
			movements: candidateMovements,
			ticksUntilFood: ticksUntilFood,
			ticksUntilDeath: ticksUntilDeath,
			areaSize: areaSize,
			estimatedDistanceToFood: estimatedDistanceToFood
		)
		scenarioResults.append(scenarioResult)
	}

	/// 2player mode: Explore entirely new random scenarios
	func randomWalk2(scenarioIndex: UInt, level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer) {
		let seed: UInt64 = UInt64(scenarioIndex + iteration * 100)
		var randomNumberGenerator = SeededGenerator(seed: seed)

		var snakeBody0: SnakeBody = player.snakeBody
		var snakeBody1: SnakeBody = oppositePlayer.snakeBody
		var currentFoodPosition: IntVec2? = foodPosition

		var candidateMovements = [SnakeBodyMovement]()
		var ticksUntilFood: UInt? = nil
		var ticksUntilDeath: UInt? = nil
		for tickIndex: UInt in 0..<Constant.numberOfTicksToPredictAhead_2playerMode {

			let currentHead0: SnakeHead = snakeBody0.head
			let currentHead1: SnakeHead = snakeBody1.head

			var oppositePlayerAlive: Bool = oppositePlayer.isAlive

			var availableMovements0 = [SnakeBodyMovement]()
			var availableMovements1 = [SnakeBodyMovement]()
			func check0(_ movement: SnakeBodyMovement) {
				let newHead: SnakeHead = currentHead0.simulateTick(movement: movement)
				let position: IntVec2 = newHead.position
				guard self.emptyPositionSet.contains(position) else {
					return
				}
				guard !snakeBody1.positionSet().contains(position) else {
					return
				}
				availableMovements0.append(movement)
			}
			func check1(_ movement: SnakeBodyMovement) {
				let newHead: SnakeHead = currentHead1.simulateTick(movement: movement)
				let position: IntVec2 = newHead.position
				guard self.emptyPositionSet.contains(position) else {
					return
				}
				guard !snakeBody0.positionSet().contains(position) else {
					return
				}
				availableMovements1.append(movement)
			}
			check0(SnakeBodyMovement.moveForward)
			check0(SnakeBodyMovement.moveCCW)
			check0(SnakeBodyMovement.moveCW)
			check1(SnakeBodyMovement.moveForward)
			check1(SnakeBodyMovement.moveCCW)
			check1(SnakeBodyMovement.moveCW)
			guard let snakeBodyMovement0: SnakeBodyMovement = availableMovements0.randomElement(using: &randomNumberGenerator) else {
				//log.debug("#\(iteration) no move choices available")
				ticksUntilDeath = tickIndex
				break
			}
			let snakeBodyMovement1: SnakeBodyMovement
			if let snakeBodyMovement: SnakeBodyMovement = availableMovements1.randomElement(using: &randomNumberGenerator) {
				snakeBodyMovement1 = snakeBodyMovement
			} else {
				oppositePlayerAlive = false
				snakeBodyMovement1 = .dontMove
			}


			var clearFoodPosition: Bool = false
			let newHead0: SnakeHead = currentHead0.simulateTick(movement: snakeBodyMovement0)
			let act0: SnakeBodyAct
			if newHead0.position == currentFoodPosition {
				act0 = .eat
				ticksUntilFood = tickIndex
				clearFoodPosition = true
			} else {
				act0 = .doNothing
			}
			snakeBody0 = snakeBody0.stateForTick(movement: snakeBodyMovement0, act: act0)

			let newHead1: SnakeHead = currentHead1.simulateTick(movement: snakeBodyMovement1)
			let act1: SnakeBodyAct
			if newHead1.position == currentFoodPosition {
				act1 = .eat
				clearFoodPosition = true
			} else {
				act1 = .doNothing
			}
			snakeBody1 = snakeBody1.stateForTick(movement: snakeBodyMovement1, act: act1)

			let detector = SnakeCollisionDetector(
				level: level,
				foodPosition: currentFoodPosition,
				player1Installed: true,
				player2Installed: true,
				player1Body: snakeBody0,
				player2Body: snakeBody1,
				player1Alive: true,
				player2Alive: oppositePlayerAlive
			)
			detector.process()

			candidateMovements.append(snakeBodyMovement0)

			if detector.player1Alive == false {
				//log.debug("killing player1 because: \(detector.collisionType1)")
				ticksUntilDeath = tickIndex
				break
			}
			if oppositePlayerAlive && detector.player2Alive == false {
				//log.debug("killing player2 because: \(detector.collisionType2)")
				oppositePlayerAlive = false
			}

			if clearFoodPosition {
				currentFoodPosition = nil
			}
		}

		var areaSize: UInt = 0
		if ticksUntilDeath == nil {
			var availablePositions: Set<IntVec2> = self.emptyPositionSet
			availablePositions.subtract(snakeBody1.positionSet())
			let snakePositions: Set<IntVec2> = snakeBody0.positionSet()
			availablePositions.subtract(snakePositions)
			availablePositions.insert(snakeBody0.head.position)
			areaSize = MeasureAreaSize.compute(positionSet: availablePositions, startPosition: snakeBody0.head.position)
		}


		var estimatedDistanceToFood: UInt? = nil
		if ticksUntilDeath == nil && ticksUntilFood == nil {
			let lastHeadPosition: IntVec2 = snakeBody0.head.position
			var emptyPositionsSet = self.emptyPositionSet
			emptyPositionsSet.subtract(snakeBody1.positionSet())
			emptyPositionsSet.subtract(snakeBody0.positionSet())
			emptyPositionsSet.insert(lastHeadPosition)
			let distanceMap = SnakeLevelDistanceMap.create(levelSize: levelSize, emptyPositionSet: emptyPositionsSet, initialPosition: currentFoodPosition)
			if let cell: SnakeLevelDistanceMapCell = distanceMap.getValue(lastHeadPosition) {
				switch cell {
				case .distance(let steps):
					estimatedDistanceToFood = UInt(steps)
				case .obscured:
					()
				}
			}
		}


		let scenarioResult = ScenarioResult(
			movements: candidateMovements,
			ticksUntilFood: ticksUntilFood,
			ticksUntilDeath: ticksUntilDeath,
			areaSize: areaSize,
			estimatedDistanceToFood: estimatedDistanceToFood
		)
		scenarioResults.append(scenarioResult)
	}

	func sorted() -> [ScenarioResult] {
		/// The most optimal choices are in the begining and the worst towards the end.
		return scenarioResults.sorted { ScenarioResult.mycompare(lhs: $0, rhs: $1) }
	}
}
