// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

fileprivate struct Constant {
	static let printStats = false
	static let printVerbose = false
}

public class SnakeBot4: SnakeBot {
	public static var info: SnakeBotInfo {
		SnakeBotInfoImpl(
			humanReadableName: "Bot - Tree search",
			userDefaultIdentifier: "bot4"
		)
	}

	private let iteration: UInt

	private init(iteration: UInt) {
		self.iteration = iteration
	}

	required public convenience init() {
		self.init(iteration: 0)
	}

	public func plannedPath() -> [IntVec2] {
		[]
	}

	public func takeAction(level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?) -> (SnakeBot, SnakeBodyMovement) {
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
		let scope_t0 = CFAbsoluteTimeGetCurrent()

//		if iteration > 0 {
//			log.debug("---")
//		}

		guard player.isInstalled else {
			//log.debug("Do nothing. The player is not installed. It doesn't make sense to run the bot.")
			return (self, .moveForward)
		}
		guard player.isAlive else {
			//log.debug("Do nothing. The player is not alive. It doesn't make sense to run the bot.")
			return (self, .moveForward)
		}

//		log.debug("#\(iteration) -")

		let level_emptyPositionSet: Set<IntVec2> = level.emptyPositionSet

		// IDEA: This is being computed over and over. This is overkill, since the food position rarely changes.
		// A faster approach would be to re-compute this only when the food position changes.
		let distanceToFoodMap: SnakeLevelDistanceMap = SnakeLevelDistanceMap.create(level: level, initialPosition: foodPosition)

		// IDEA: Computing ChoiceNodes over and over takes time. Caching of the choice nodes to the next "takeAction",
		// so that less time is spent on allocating the same memory over and over.
		let rootChoice = ParentChoiceNode.create(depth: 9)
//		log.debug("nodeCount: \(rootChoice.nodeCount)")
		rootChoice.assignMovements()

		var nodes: [LeafChoiceNode] = rootChoice.leafNodes()
//		log.debug("nodes: \(nodes.count)")

		let scope_t1 = CFAbsoluteTimeGetCurrent()
		if Constant.printStats {
			let elapsed: Double = scope_t1 - scope_t0
			log.debug("#\(iteration) setup: \(elapsed)")
		}

		// Discard poor choices where the snake impacts a wall
		var count_collisionWithWall: Int = 0
		var elapsed_collisionWithWall: Double = 0
		do {
			let t0 = CFAbsoluteTimeGetCurrent()
			rootChoice.checkCollisionWithWall(level_emptyPositionSet: level_emptyPositionSet, snakeHead: player.snakeBody.head)
			let t1 = CFAbsoluteTimeGetCurrent()
			let count0: Int = nodes.count
			nodes.removeAll { $0.collisionWithWall }
			let count1: Int = nodes.count
			count_collisionWithWall = count0 - count1
			elapsed_collisionWithWall = t1 - t0
		}
		if Constant.printStats {
			log.debug("#\(iteration) collisions with wall: \(count_collisionWithWall)   elapsed: \(elapsed_collisionWithWall)")
		}

		// Discard choices that causes the snake to eat itself
		// Discard choices where the snake first eats food, and grows longer, and afterwards eats itself
		var count_collisionWithSelf: Int = 0
		var elapsed_collisionWithSelf: Double = 0
		do {
			let t0 = CFAbsoluteTimeGetCurrent()
			rootChoice.checkCollisionWithSelf(snakeBody: player.snakeBody, foodPosition: foodPosition)
			let t1 = CFAbsoluteTimeGetCurrent()
			let count0: Int = nodes.count
			nodes.removeAll { $0.collisionWithSelf }
			let count1: Int = nodes.count
			count_collisionWithSelf = count0 - count1
			elapsed_collisionWithSelf = t1 - t0
		}
		if Constant.printStats {
			log.debug("#\(iteration) collisions with self: \(count_collisionWithSelf)   elapsed: \(elapsed_collisionWithSelf)")
		}


		// Estimate distances to the food
		// Prefer the choices that gets the snake closer to the food
		let count_estimateDistanceToFood: Int = nodes.count
		var elapsed_estimateDistanceToFood: Double = 0
		do {
			let t0 = CFAbsoluteTimeGetCurrent()
			let currentHead: SnakeHead = player.snakeBody.head
			for node: ChoiceNode in nodes {
				var head: SnakeHead = currentHead
				var distanceToFood: UInt32 = UInt32.max
				var distanceToFoodIgnoringAnyObstacles: UInt32 = UInt32.max
				var hasFood = true
				let currentFoodPosition: IntVec2 = foodPosition ?? IntVec2.zero
				for (numberOfTicks, movement) in node.movements.enumerated() {
					let snakeBodyMovement: SnakeBodyMovement = movement.snakeBodyMovement
					head = head.simulateTick(movement: snakeBodyMovement)
					if hasFood && head.position == currentFoodPosition {
						distanceToFood = UInt32(numberOfTicks)
						hasFood = false
//						log.debug("choice leads directly to food \(distanceToFood)")
					}
					if hasFood {
						let d: UInt32 = 10000 + currentFoodPosition.manhattanDistance(head.position) * 10000 + UInt32(numberOfTicks)
						if distanceToFoodIgnoringAnyObstacles > d {
							distanceToFoodIgnoringAnyObstacles = d
						}
					}
				}
				let lastPosition: IntVec2 = head.position


//				// Experiments computing a SnakeLevelDistanceMap that also considers the snake body. However it's incredibly slow.
//				var distanceToFoodIgnoringSelf: UInt32 = UInt32.max
//				if hasFood {
//					var body: SnakeBody = player.snakeBody
//					var hasFood2: Bool = (foodPosition != nil)
//					for (numberOfTicks, movement) in node.movements.enumerated() {
//						let snakeBodyMovement: SnakeBodyMovement = movement.snakeBodyMovement
//						let head: SnakeHead = body.head.simulateTick(movement: snakeBodyMovement)
//						let act: SnakeBodyAct
//						if hasFood2 && head.position == foodPosition {
//							act = .eat
//							hasFood2 = false
//						} else {
//							act = .doNothing
//						}
//						body = body.stateForTick(movement: snakeBodyMovement, act: act)
//
//					}
//					var emptyPositionsSet = level_emptyPositionSet
//					emptyPositionsSet.subtract(body.positionSet())
//					let distanceToFoodMap2 = SnakeLevelDistanceMap.create(levelSize: level.size, emptyPositionSet: emptyPositionsSet, optionalFoodPosition: foodPosition)
//
//					let lastPosition2: IntVec2 = body.head.position
//					if hasFood2 {
//						if let cell: DistanceToFoodCell = distanceToFoodMap2.getValue(lastPosition) {
//							switch cell {
//							case .distance(let steps):
//								distanceToFoodIgnoringSelf = steps
//							case .obscured:
//								()
//							}
//						}
//					}
//
//				}

				// Optimally the the distanceToFoodMap should be computed for every tick in the simulation.
				// And the distanceToFoodMap should be used for estimating. However this is a expensive computation.
				// When there is no distanceToFood, then I'm relying on distanceToFoodIgnoringSelf and this gives a terrible estimate.
				// IDEA: A less expensive operaion could be to compute the distance to food considering original self.

				var distanceToFoodIgnoringSelf: UInt32 = UInt32.max
				if hasFood {
					if let cell: SnakeLevelDistanceMapCell = distanceToFoodMap.getValue(lastPosition) {
						switch cell {
						case .distance(let steps):
							distanceToFoodIgnoringSelf = steps
						case .obscured:
							()
						}
					}
				}

				var distance: UInt32 = UInt32.max
				if distanceToFood < UInt32.max {
					distance = distanceToFood
				} else {
					if distanceToFoodIgnoringSelf < UInt32.max {
						distance = 100 + distanceToFoodIgnoringSelf * 100
					} else {
						if distanceToFoodIgnoringAnyObstacles < UInt32.max {
							distance = distanceToFoodIgnoringAnyObstacles
						}
					}
				}

				node.setEstimatedDistanceToFood(distance: distance)
			}
			let t1 = CFAbsoluteTimeGetCurrent()
			elapsed_estimateDistanceToFood = t1 - t0
			nodes.sort {
				$0.estimatedDistanceToFood < $1.estimatedDistanceToFood
			}
		}
		if Constant.printStats {
			log.debug("#\(iteration) estimate distance to food: \(count_estimateDistanceToFood)   elapsed: \(elapsed_estimateDistanceToFood)")
			printEstimatedDistancesToFood(nodes: nodes)
		}


		// Compute alive/death risk for each of the choices.
		// Minimize risk of death.
		//
		// Compute the number of ticks to get to the food.
		// Minimize the number of ticks.
		//
		// Minimize the number of turns.
		//
		// Maximize the number of available choices after following a full sequence of movements.
		// If there are 3 candidate choices, then compare the number of open choices after following each of the candidate movements.
		// Pick the path with the most number of open choices.
		//
		// Take a longer route, in order to make room near the food.
		//
		// Determine most likely areas where new food will be placed.
		// After picking up the food, then simulate using the likely next food position.
		//
		// Simulate choices of the opponent, the same way as for the player itself.
		//
		// Do an intersection of the opponent nodes with the player nodes.
		//
		// Avoid eating the opponent snake, since it's poisonous.


		// Discard the choices that leads to the food,
		// that also causes the snake to get trapped a few ticks later.
		// Do this by simulating the entire snake and check for collisions.
		var numberOfDeaths: UInt = 0
		var nodeWithMetadataArray = [LeafChoiceNodeWithMetaData]()
		for (nodeIndex, node) in nodes.enumerated() {
			if nodeIndex == 5 && numberOfDeaths < 5 {
				break
			}
			if nodeIndex == 10 && numberOfDeaths < 10 {
				break
			}
			if nodeIndex == 20 && numberOfDeaths < 20 {
				break
			}
			if nodeIndex == 40 && numberOfDeaths < 40 {
				break
			}
			if nodeIndex == 80 && numberOfDeaths < 80 {
				break
			}
			guard nodeIndex < 160 else {
				break
			}

			var body: SnakeBody = player.snakeBody
			var hasFood: Bool = (foodPosition != nil)
			for movement in node.movements {
				let snakeBodyMovement: SnakeBodyMovement = movement.snakeBodyMovement
				let head: SnakeHead = body.head.simulateTick(movement: snakeBodyMovement)
				let act: SnakeBodyAct
				if hasFood && head.position == foodPosition {
					act = .eat
					hasFood = false
				} else {
					act = .doNothing
				}
				body = body.stateForTick(movement: snakeBodyMovement, act: act)
			}

			var availablePositions: Set<IntVec2> = Set<IntVec2>(level_emptyPositionSet)
			let snakePositions: Set<IntVec2> = body.positionSet()
			availablePositions.subtract(snakePositions)
			availablePositions.insert(body.head.position)

			let snakeLength: UInt = body.length
			let areaSize: UInt = MeasureAreaSize.compute(positionSet: availablePositions, startPosition: body.head.position)
			let insufficientRoom: Bool = snakeLength > areaSize
			let prettyMovements: String = node.movements.map { $0.shorthand }.joined(separator: "")

			if insufficientRoom {
				if Constant.printVerbose {
					log.debug("#\(iteration) choice#\(nodeIndex)  \(prettyMovements)  areaSize: \(areaSize)  snakeLength: \(snakeLength)   DEATH. Insufficient room for snake!")
				}
				numberOfDeaths += 1
				// IDEA: Keep track of all the certain death cases, so they can be prioritized.
				// This is useful when there are no "alive case". In this case we still want to pick the most optimal case.
			} else {
				if Constant.printVerbose {
					log.debug("#\(iteration) choice#\(nodeIndex)  \(prettyMovements)  areaSize: \(areaSize)  snakeLength: \(snakeLength)")
				}
				let nodeWithMetadata = LeafChoiceNodeWithMetaData(
					leafChoiceNode: node,
					areaSize: areaSize,
					snakeLength: snakeLength
				)
				nodeWithMetadataArray.append(nodeWithMetadata)
			}
		}
		// IDEA: Prioritize based on areaSize, snakeLength, risk.
		// nodeWithMetadataArray.sort { $0.areaSize < $1.areaSize }

		let optimalNodes: [LeafChoiceNode] = nodeWithMetadataArray.map { $0.leafChoiceNode }

		var pendingMovement: SnakeBodyMovement = .moveForward

		// Pick the first
		for node: ChoiceNode in optimalNodes {
			guard let movement: ChoiceMovement = node.movements.first else {
				continue
			}
			//log.debug("#\(iteration) pick the first: \(node.estimatedDistanceToFood)")
			let snakeBodyMovement: SnakeBodyMovement = movement.snakeBodyMovement
			pendingMovement = snakeBodyMovement
			break
		}

		let bot = SnakeBot4(
			iteration: self.iteration + 1
		)
		return (bot, pendingMovement)
	}

	private func printEstimatedDistancesToFood(nodes: ChoiceNodeArray) {
		var dict = [Int: ChoiceNodeArray]()
		for node: ChoiceNode in nodes {
			let key: Int = Int(node.estimatedDistanceToFood)
			var value: ChoiceNodeArray = dict[key] ?? ChoiceNodeArray()
			value.append(node)
			dict[key] = value
		}

		typealias KeyValuePair = (Int, ChoiceNodeArray)
		var keyValuePairs = [KeyValuePair]()
		for (key, value) in dict {
			let keyValuePair: KeyValuePair = (key, value)
			keyValuePairs.append(keyValuePair)
		}
		keyValuePairs.sort { $0.0 < $1.0 }

		var pairs = [String]()
		for (index, tupple) in keyValuePairs.enumerated() {
			guard index < 5 else {
				break
			}
			let distance: Int = tupple.0
			let numberOfChoices: Int = tupple.1.count
			let pair = "\(distance)=\(numberOfChoices)"
			pairs.append(pair)
		}
		let prettyPairsJoined: String = pairs.joined(separator: " ")
		log.debug("#\(iteration) estimated distance to food: \(prettyPairsJoined)")
	}
}

extension SnakeBot4: CustomDebugStringConvertible {
	public var debugDescription: String {
		return "SnakeBot4 \(iteration)"
	}
}

fileprivate enum ChoiceMovement {
	case moveForward
	case moveCCW
	case moveCW

	var snakeBodyMovement: SnakeBodyMovement {
		switch self {
		case .moveForward:
			return .moveForward
		case .moveCCW:
			return .moveCCW
		case .moveCW:
			return .moveCW
		}
	}

	var shorthand: String {
		switch self {
		case .moveForward:
			return "-"
		case .moveCCW:
			return "<"
		case .moveCW:
			return ">"
		}
	}
}

fileprivate protocol ChoiceNode {
	var movements: [ChoiceMovement] { get }
	var collisionWithWall: Bool { get }
	var collisionWithSelf: Bool { get }
	var estimatedDistanceToFood: UInt32 { get }
	var nodeCount: UInt { get }
	func assignMovements_inner(movements: [ChoiceMovement])
	func allNodes() -> [ChoiceNode]
	func leafNodes() -> [LeafChoiceNode]
	func recursiveFlag_collisionWithWall()
	func recursiveFlag_collisionWithSelf()
	func getNode0() -> ChoiceNode?
	func getNode1() -> ChoiceNode?
	func getNode2() -> ChoiceNode?
	func setEstimatedDistanceToFood(distance: UInt32)
}

extension ChoiceNode {
	// IDEA: Move to a RootChoiceNode which hold all the root functions
	fileprivate func assignMovements() {
		self.assignMovements_inner(movements: [])
	}
}


fileprivate class LeafChoiceNode: ChoiceNode {
	var movements: [ChoiceMovement] = []
	var collisionWithWall: Bool = false
	var collisionWithSelf: Bool = false
	var estimatedDistanceToFood: UInt32 = UInt32.max

	var nodeCount: UInt {
		return 1
	}

	func assignMovements_inner(movements: [ChoiceMovement]) {
		self.movements = movements
	}

	func allNodes() -> [ChoiceNode] {
		return [self]
	}

	func leafNodes() -> [LeafChoiceNode] {
		return [self]
	}

	func recursiveFlag_collisionWithWall() {
		collisionWithWall = true
	}

	func recursiveFlag_collisionWithSelf() {
		collisionWithSelf = true
	}

	func getNode0() -> ChoiceNode? {
		return nil
	}

	func getNode1() -> ChoiceNode? {
		return nil
	}

	func getNode2() -> ChoiceNode? {
		return nil
	}

	func setEstimatedDistanceToFood(distance: UInt32) {
		estimatedDistanceToFood = distance
	}
}

fileprivate class ParentChoiceNode: ChoiceNode {
	let node0: ChoiceNode
	let node1: ChoiceNode
	let node2: ChoiceNode
	var movements: [ChoiceMovement] = []
	var collisionWithWall: Bool = false
	var collisionWithSelf: Bool = false
	var estimatedDistanceToFood: UInt32 = UInt32.max

	init(node0: ChoiceNode, node1: ChoiceNode, node2: ChoiceNode) {
		self.node0 = node0
		self.node1 = node1
		self.node2 = node2
	}

	var nodeCount: UInt {
		let count0: UInt = node0.nodeCount
		let count1: UInt = node1.nodeCount
		let count2: UInt = node2.nodeCount
		return 1 + count0 + count1 + count2
	}

	func assignMovements_inner(movements: [ChoiceMovement]) {
		self.movements = movements
		node0.assignMovements_inner(movements: movements + [.moveCW])
		node1.assignMovements_inner(movements: movements + [.moveForward])
		node2.assignMovements_inner(movements: movements + [.moveCCW])
	}

	func allNodes() -> [ChoiceNode] {
		let nodes0: [ChoiceNode] = node0.allNodes()
		let nodes1: [ChoiceNode] = node1.allNodes()
		let nodes2: [ChoiceNode] = node2.allNodes()
		let nodes: [ChoiceNode] = [self] + nodes0 + nodes1 + nodes2
		return nodes
	}

	func leafNodes() -> [LeafChoiceNode] {
		let leafNodes0: [LeafChoiceNode] = node0.leafNodes()
		let leafNodes1: [LeafChoiceNode] = node1.leafNodes()
		let leafNodes2: [LeafChoiceNode] = node2.leafNodes()
		let leafNodes: [LeafChoiceNode] = leafNodes0 + leafNodes1 + leafNodes2
		return leafNodes
	}

	func recursiveFlag_collisionWithWall() {
		collisionWithWall = true
		node0.recursiveFlag_collisionWithWall()
		node1.recursiveFlag_collisionWithWall()
		node2.recursiveFlag_collisionWithWall()
	}

	func recursiveFlag_collisionWithSelf() {
		collisionWithSelf = true
		node0.recursiveFlag_collisionWithSelf()
		node1.recursiveFlag_collisionWithSelf()
		node2.recursiveFlag_collisionWithSelf()
	}

	func getNode0() -> ChoiceNode? {
		return node0
	}

	func getNode1() -> ChoiceNode? {
		return node1
	}

	func getNode2() -> ChoiceNode? {
		return node2
	}

	func setEstimatedDistanceToFood(distance: UInt32) {
		estimatedDistanceToFood = distance
	}
}

extension ParentChoiceNode {
	// IDEA: Move to a RootChoiceNode which hold all the root functions
	fileprivate static func create(depth: UInt) -> ChoiceNode {
		guard depth >= 2 else {
			let ci = LeafChoiceNode()
			return ci
		}
		let node0: ChoiceNode = create(depth: depth - 1)
		let node1: ChoiceNode = create(depth: depth - 1)
		let node2: ChoiceNode = create(depth: depth - 1)
		let ci = ParentChoiceNode(node0: node0, node1: node1, node2: node2)
		return ci
	}
}



/// Detect collision with wall
///
/// Originally this code looped over all the leaf-nodes and checked for collision with walls. This was slow.
///
/// Now paths that share the same beginning, are being ruled out. So much fewer paths needs to be checked.
/// This code starts with the top-level node, then moves on to the next nested level.
extension ChoiceNode {
	fileprivate func checkCollisionWithWall(level_emptyPositionSet: Set<IntVec2>, snakeHead: SnakeHead) {
		getNode0()?.checkCollisionWithWall_inner(level_emptyPositionSet: level_emptyPositionSet, movement: .moveCW, snakeHead: snakeHead)
		getNode1()?.checkCollisionWithWall_inner(level_emptyPositionSet: level_emptyPositionSet, movement: .moveForward, snakeHead: snakeHead)
		getNode2()?.checkCollisionWithWall_inner(level_emptyPositionSet: level_emptyPositionSet, movement: .moveCCW, snakeHead: snakeHead)
	}

	private func checkCollisionWithWall_inner(level_emptyPositionSet: Set<IntVec2>, movement: ChoiceMovement, snakeHead: SnakeHead) {
		let newSnakeHead: SnakeHead = snakeHead.simulateTick(movement: movement.snakeBodyMovement)
		guard level_emptyPositionSet.contains(newSnakeHead.position) else {
			recursiveFlag_collisionWithWall()
			return
		}
		getNode0()?.checkCollisionWithWall_inner(level_emptyPositionSet: level_emptyPositionSet, movement: .moveCW, snakeHead: newSnakeHead)
		getNode1()?.checkCollisionWithWall_inner(level_emptyPositionSet: level_emptyPositionSet, movement: .moveForward, snakeHead: newSnakeHead)
		getNode2()?.checkCollisionWithWall_inner(level_emptyPositionSet: level_emptyPositionSet, movement: .moveCCW, snakeHead: newSnakeHead)
	}
}

/// Detect collision with self, is the snake eating itself
///
/// Originally this code looped over all the leaf-nodes and checked for collision with the snake itself. This was slow.
///
/// Now paths that share the same beginning, are being ruled out. So much fewer paths needs to be checked.
/// This code starts with the top-level node, then moves on to the next nested level.
///
/// IDEA: The `SnakeBody.isEatingItself` is slow. And it gets called many times.
/// Internally it does conversions from Array to Set.
/// Optimizing this may speed things up.
extension ChoiceNode {
	fileprivate func checkCollisionWithSelf(snakeBody: SnakeBody, foodPosition: IntVec2?) {
		getNode0()?.checkCollisionWithSelf_inner(movement: .moveCW, snakeBody: snakeBody, foodPosition: foodPosition)
		getNode1()?.checkCollisionWithSelf_inner(movement: .moveForward, snakeBody: snakeBody, foodPosition: foodPosition)
		getNode2()?.checkCollisionWithSelf_inner(movement: .moveCCW, snakeBody: snakeBody, foodPosition: foodPosition)
	}

	private func checkCollisionWithSelf_inner(movement: ChoiceMovement, snakeBody: SnakeBody, foodPosition: IntVec2?) {
		guard !self.collisionWithWall else {
			return
		}

		var body: SnakeBody = snakeBody
		var hasFood: Bool = (foodPosition != nil)

		let snakeBodyMovement: SnakeBodyMovement = movement.snakeBodyMovement
		let head: SnakeHead = body.head.simulateTick(movement: snakeBodyMovement)
		let act: SnakeBodyAct
		if hasFood && head.position == foodPosition {
			act = .eat
			hasFood = false
			// IDEA: The exact same computation is being done later for every leaf node, when determining the distance to the food.
			// This is inefficient of time doing it on the leaf nodes. It's much fewer computations doing recursively.
			// recursively set distance to food, to save computations.
		} else {
			act = .doNothing
		}
		body = body.stateForTick(movement: snakeBodyMovement, act: act)

		if body.isEatingItself {
			recursiveFlag_collisionWithSelf()
			return
		}

		let newFoodPosition: IntVec2?
		if hasFood {
			newFoodPosition = foodPosition
		} else {
			newFoodPosition = nil
		}

		// IDEA: in case the food hasn't been eaten. Then the distance to food map have to be recomputed.
		// This is painfully slow. The entire snake body simulation have to be done all over.
		// Maybe a faster solution is to store the snake body in the leaf nodes,
		// so the distance to the food can be computed.
		// Maybe compute the distance to food map, here in this function. So that there is no allocations of variable sizes.

		getNode0()?.checkCollisionWithSelf_inner(movement: .moveCW, snakeBody: body, foodPosition: newFoodPosition)
		getNode1()?.checkCollisionWithSelf_inner(movement: .moveForward, snakeBody: body, foodPosition: newFoodPosition)
		getNode2()?.checkCollisionWithSelf_inner(movement: .moveCCW, snakeBody: body, foodPosition: newFoodPosition)
	}
}

fileprivate typealias ChoiceNodeArray = [ChoiceNode]


fileprivate class LeafChoiceNodeWithMetaData {
	let leafChoiceNode: LeafChoiceNode
	let areaSize: UInt
	let snakeLength: UInt

	init(leafChoiceNode: LeafChoiceNode, areaSize: UInt, snakeLength: UInt) {
		self.leafChoiceNode = leafChoiceNode
		self.areaSize = areaSize
		self.snakeLength = snakeLength
	}
}
