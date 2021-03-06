// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

fileprivate struct PreviousIterationData {
	let root: RootNode
}

public class SnakeBot6: SnakeBot {
	public static var info = SnakeBotInfo(
        uuid: "cfc36470-2ecd-4372-9946-84ac60806e27",
        name: "Monte Carlo 2"
    )

    private let debug_graphvizExport = false
    private let debug_prettyPath = false
	private let iteration: UInt
    public let plannedMovement: SnakeBodyMovement
    public let plannedPath: [IntVec2]

	private let previousIterationData: PreviousIterationData?

	private init(iteration: UInt, plannedMovement: SnakeBodyMovement, plannedPath: [IntVec2], previousIterationData: PreviousIterationData?) {
		self.iteration = iteration
        self.plannedMovement = plannedMovement
        self.plannedPath = plannedPath
		self.previousIterationData = previousIterationData
	}

	required public convenience init() {
        self.init(iteration: 0, plannedMovement: .dontMove, plannedPath: [], previousIterationData: nil)
	}

	public func compute(level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?) -> SnakeBot {
        guard player.isInstalledAndAlive else {
            //log.debug("Do nothing. The bot must be installed and alive. It doesn't make sense to run the bot.")
			return SnakeBot6()
		}

        //log.debug("#\(iteration)  head.position: \(player.snakeBody.head.position)")

		var countKeep: Int = 0
		var countRemove: Int = 0
		var countInsert: Int = 0

		let root = RootNode()
		if let data: PreviousIterationData = self.previousIterationData {
			let countAll: Int = Int(data.root.nodeCount)
			countRemove = countAll

			var subtreeNode: Node? = data.root.child

			// Find the new position of the player in tree.
			// Find the new position of the oppositePlayer in tree.
			// Find food in the tree.
			// Attach that node onto the new root node.
			// Explore the unexplored paths.

            if let moveNode: MoveNode = subtreeNode as? MoveNode, moveNode.playerId == 0 {
                let findPosition: IntVec2 = player.snakeBody.head.position
                var foundMatchingChoice: Bool = false
                for choice: MoveNodeChoice in moveNode.choices {
                    if choice.position == findPosition {
                        subtreeNode = choice.child
                        foundMatchingChoice = true
                        //log.debug("foundMatchingChoice for player0")
                        break
                    }
                }
                if !foundMatchingChoice {
                    subtreeNode = nil
                    log.error("Unable to reuse subtree from previous iteration. player0")
                }
            }

            if let moveNode: MoveNode = subtreeNode as? MoveNode, moveNode.playerId == 1 {
                let findPosition: IntVec2 = oppositePlayer.snakeBody.head.position
                var foundMatchingChoice: Bool = false
                for choice: MoveNodeChoice in moveNode.choices {
                    if choice.position == findPosition {
                        subtreeNode = choice.child
                        foundMatchingChoice = true
                        //log.debug("foundMatchingChoice for player1")
                        break
                    }
                }
                if !foundMatchingChoice {
                    subtreeNode = nil
                    log.error("Unable to reuse subtree from previous iteration. player1")
                }
            }

            // IDEA: combine the FoodNodeChoice trees into a single tree.
            // The trees will share one or more nodes in top of the tree.
            // The trees have already been computed, so it's wasteful to discard the tree.
			if let foodNode: FoodNode = subtreeNode as? FoodNode {
				// IDEA: After every food pickup, I get recomputation of the path.
				// It seems that passing the foodchoice subtree to the next iteration messes up things.

				if let fp: IntVec2 = foodPosition {
					// Find FoodNodeChoice that is nearest the new food position
					// log.debug("find shortest path to the new food position. Reuse as much as possible from the previous iteration.")
					//
					// IDEA: Consider non-permanent obstacles when estimating the distance, eg. snake itself, snake opponent.
					// Don't rely on manhattan distance, since it doesn't consider obstacles, such as: Wall/snake.
					// Instead use a distance map, with the paths that are reachable from the snake head.
					// The level has its cells grouped into clusters, A, B, C, D, E...
					// Precompute distances between all cluster pairs. AB=1, AF=7, DJ=3
					// If the foodPosition and snakehead is inside the same cluster then use manhattan distance.
					// If the foodPosition and snakehead is inside different clusters then use distance from the precomputed lookup table.
					let choicesSorted: [FoodNodeChoice] = foodNode.choices.sorted { (lhs, rhs) -> Bool in
						let distance0: UInt32 = level.estimateDistance(position0: lhs.position.intVec2, position1: fp)
						let distance1: UInt32 = level.estimateDistance(position0: rhs.position.intVec2, position1: fp)
						return distance0 < distance1
					}
					// Determine max depth of the player0 tree
					for choice: FoodNodeChoice in choicesSorted.prefix(5) {
						let visitor = FindMaxDepth()
						choice.accept(visitor)
						log.debug("depth: unexplored=\(visitor.highestNumberOfMoves_unexplored) kill=\(visitor.highestNumberOfMoves_kill)")
						// IDEA: pick the safest route where the snake survives.
						// avoid the routes that causes certain death for the snake.
					}
					if let choice: FoodNodeChoice = choicesSorted.first {
						let distance: UInt32 = level.estimateDistance(position0: choice.position.intVec2, position1: fp)
						var allDistances: [UInt32] = foodNode.choices.map {
							level.estimateDistance(position0: $0.position.intVec2, position1: fp)
						}
						allDistances.sort()
						log.debug("picked food subtree. distance \(distance)  of  \(allDistances)")

						subtreeNode = choice.child
						// Currently the best choice survies and all the other choices gets discarded.
						// IDEA: Keep the 2nd best and 3rd best FoodNodeChoice's around and use them as a fallback.
						if subtreeNode is MoveNode {
							log.debug("successfully extracted the nearest FoodNodeChoice")
						} else {
							subtreeNode = nil
							log.error("unable to extract the nearest food node choice")
						}

					} else {
						subtreeNode = nil
						log.error("Expected FoodNode.choices to contain 1 or more choices, but got an empty array. Unable to extract the nearest food node choice")
					}
				} else {
					// IDEA: when the foodPosition is nil, then pick a random FoodNodeChoice.child
					subtreeNode = nil
					log.error("expects the foodPosition to always be non-nil, but got nil. Cannot find nearest subtree.")
				}
			}

			if let actualSubtreeNode: Node = subtreeNode {
				countKeep = Int(actualSubtreeNode.nodeCount)
				countRemove = countAll - countKeep
				root.child = actualSubtreeNode
				actualSubtreeNode.parent = root
//                log.debug("Successfully reused subtree from previous iteration")
			} else {
				log.error("unable to reuse subtree from previous iteration!")
			}
		}
        let minorSeed: UInt = 0
		let majorSeed: UInt = iteration * 100
        let seed: UInt64 = UInt64(majorSeed + minorSeed)
		let visitor_buildTree = BuildTreeVisitor(
            iteration: iteration,
			level: level,
			player: player,
			oppositePlayer: oppositePlayer,
			foodPosition: foodPosition,
			seed: seed
		)
		root.accept(visitor_buildTree)
		//visitor_buildTree.printStats()

		let countAll: UInt = root.nodeCount
		countInsert = Int(countAll) - countKeep

//		log.debug("#\(iteration)   Remove: \(countRemove)   Keep: \(countKeep)   Insert: \(countInsert)")
//		log.debug("\(iteration);\(countRemove);\(countKeep);\(countInsert)")

		let visitor_clearTheBest = ClearTheBestNodes()
		root.accept(visitor_clearTheBest)

		let visitor_countProblems = CountProblemsWithNodes()
		root.accept(visitor_countProblems)
		if visitor_countProblems.isError {
			log.error("inconsistency in tree. \(visitor_countProblems)")
		}

		guard let scenario: Scenario = visitor_buildTree.bestScenario() else {
			log.error("unable to find the best scenario")
            return SnakeBot6(
                iteration: self.iteration + 1,
                plannedMovement: .moveForward,
                plannedPath: [],
                previousIterationData: nil
            )
		}

		scenario.flagTheBestNodes()

		// IDEA: rank the best possible paths for opposite player
		// IDEA: compare the choice that the opposite player just made with the best choice we computed
		// IDEA: optimize the planned path, so that it has fewer turns.

		var bestMovement: SnakeBodyMovement = .moveForward
		if let movement: SnakeBodyMovement = scenario.movements.first {
			bestMovement = movement
		}

		var head: SnakeHead = player.snakeBody.head
		var positionArray = [IntVec2]()
        positionArray.append(head.position)
		for movement: SnakeBodyMovement in scenario.movements {
			head = head.simulateTick(movement: movement)
			positionArray.append(head.position)
		}
		let plannedPath: [IntVec2] = positionArray

		if debug_prettyPath {
            let prettyMovements: String = PrettyPlannedPath.process(node: scenario.destinationNode, snakeHead: player.snakeBody.head)

			let nf = NumberFormatter()
			nf.formatWidth = 6
			let iteration_string: String = nf.string(from: NSNumber(value: iteration)) ?? ""
			let countRemove_string: String = nf.string(from: NSNumber(value: countRemove)) ?? ""
			let countKeep_string: String = nf.string(from: NSNumber(value: countKeep)) ?? ""
			let countInsert_string: String = nf.string(from: NSNumber(value: countInsert)) ?? ""

			let aliveDead: String = scenario.certainDeath ? "DIE" : "   "
			log.debug("\(iteration_string) \(countRemove_string) \(countKeep_string) \(countInsert_string) \(aliveDead) \(prettyMovements)")
		}

        if debug_graphvizExport {
            let visitor_graphvizExport = GraphvizExport()
            root.accept(visitor_graphvizExport)
            let s: String = visitor_graphvizExport.result()
            sendGraphvizData(iteration: self.iteration, dotfile: s, foodPosition: foodPosition)
        }

		let previousIterationData = PreviousIterationData(
			root: root
		)
		return SnakeBot6(
			iteration: self.iteration + 1,
            plannedMovement: bestMovement,
            plannedPath: plannedPath,
			previousIterationData: previousIterationData
		)
	}

    func sendGraphvizData(iteration: UInt, dotfile: String, foodPosition: IntVec2?) {
        let iterationString: String = "Iteration: \(iteration)"
        let foodPositionString: String
        if let position = foodPosition {
            foodPositionString = "Food: \(position.x),\(position.y)"
        } else {
            foodPositionString = "Food: None"
        }
        var rows = [String]()
        rows.append(iterationString)
        rows.append(foodPositionString)
        let preformattedText: String = rows.joined(separator: "\n")

        Dashboard.shared.sendGraphvizData(
            uuid: UUID(),
            preformattedText: preformattedText,
            dotfile: dotfile
        )
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

fileprivate class Node {
	weak var parent: Node?
	var isBest: Bool = false

	func accept(_ visitor: Visitor) {
		fatalError()
	}

	var parentNodeArray: NodeArray {
		var array = NodeArray()
		var currentNode: Node = self
		array.append(currentNode)
		while true {
			guard let parentNode: Node = currentNode.parent else {
				break
			}
			currentNode = parentNode
			array.append(currentNode)
		}
		return array
	}
}

fileprivate typealias NodeArray = [Node]

extension Node {
	var nodeCount: UInt {
		let visitor = CountNumberOfNodes()
		self.accept(visitor)
		return visitor.count
	}
}

fileprivate protocol Visitor {
	func visit(_ node: RootNode)
	func visit(_ node: LeafNode)
	func visit(_ node: FoodNode)
	func visit(_ node: FoodNodeChoice)
	func visit(_ node: MoveNode)
	func visit(_ node: MoveNodeChoice)
	func visit(_ node: KillNode)
}

/// Some node's have just one child node
fileprivate protocol HasOneChild {
	var child: Node? { get }
}

fileprivate protocol ReplaceChild {
	func replaceChild(_ child: Node)
}

fileprivate typealias NodeWithReplaceChild = Node & HasOneChild & ReplaceChild

/// Some node's have a variable number of child nodes
fileprivate protocol HasMultipleChildren {
	var children: [Node] { get }
}

/// The root of the tree.
fileprivate class RootNode: Node, HasOneChild, ReplaceChild {
	var child: Node?

	override func accept(_ visitor: Visitor) {
		visitor.visit(self)
	}

	func replaceChild(_ child: Node) {
		self.child = child
	}
}

/// We have reached a leaf of the tree. There are no children.
fileprivate class LeafNode: Node {
	override func accept(_ visitor: Visitor) {
		visitor.visit(self)
	}
}

fileprivate class FoodNodeChoice: Node, HasOneChild, ReplaceChild {
	let position: UIntVec2
	var child: Node?

	init(position: UIntVec2) {
		self.position = position
	}

	override func accept(_ visitor: Visitor) {
		visitor.visit(self)
	}

	func replaceChild(_ child: Node) {
		self.child = child
	}
}

/// Simulate insertion of food at several positions.
fileprivate class FoodNode: Node, HasMultipleChildren {
	var choices: [FoodNodeChoice] = []

	var children: [Node] {
		choices
	}

	override func accept(_ visitor: Visitor) {
		visitor.visit(self)
	}
}

fileprivate class MoveNodeChoice: Node, HasOneChild, ReplaceChild {
	let playerId: UInt
	let movement: SnakeBodyMovement
	let position: IntVec2
	var child: Node?

	init(playerId: UInt, movement: SnakeBodyMovement, position: IntVec2) {
		self.playerId = playerId
		self.movement = movement
		self.position = position
	}

	override func accept(_ visitor: Visitor) {
		visitor.visit(self)
	}

	func replaceChild(_ child: Node) {
		self.child = child
	}
}

/// Simulate that the player moves counterclockwise, forward, clockwise.
fileprivate class MoveNode: Node, HasMultipleChildren {
	let playerId: UInt
	var choices: [MoveNodeChoice]
	var needsExploringPermanentObstacles = true

	class func create(playerId: UInt) -> MoveNode {
		let node = MoveNode(playerId: playerId)
		return node
	}

	private init(playerId: UInt) {
		self.playerId = playerId
		self.choices = []
	}

	var children: [Node] {
		choices
	}

	override func accept(_ visitor: Visitor) {
		visitor.visit(self)
	}
}

fileprivate enum KillNodeCause {
	case unspecified
	case collisionWithSelf
	case collisionWithOpponent
}

/// The player dies because of collision with wall or itself.
fileprivate class KillNode: Node, HasOneChild, ReplaceChild {
	var child: Node?
	var playerId: UInt = 0
	var cause: KillNodeCause = KillNodeCause.unspecified

	override func accept(_ visitor: Visitor) {
		visitor.visit(self)
	}

	func replaceChild(_ child: Node) {
		self.child = child
	}
}

fileprivate class Scenario {
	let destinationNode: Node
	let movements: [SnakeBodyMovement]
	let certainDeath: Bool
	let numberOfFoodsEaten: Int
	let distanceToFood: UInt32

	init(destinationNode: Node, movements: [SnakeBodyMovement], certainDeath: Bool, numberOfFoodsEaten: Int, distanceToFood: UInt32) {
		self.destinationNode = destinationNode
		self.movements = movements
		self.certainDeath = certainDeath
		self.numberOfFoodsEaten = numberOfFoodsEaten
		self.distanceToFood = distanceToFood
	}

	func flagTheBestNodes() {
        // IDEA: Currently the best nodes are flagged with a boolean.
        // A faster approach may be to construct an IndexPath.
        // For nodes with multiple children, then it's easier to determine
        // which child that is the best, since an IndexPath have an index.
        // So there will not be any looping through the childern and looking at the isBest boolean.

		var node: Node = self.destinationNode
		node.isBest = true
//		var count: UInt = 0
		while true {
			guard let parentNode: Node = node.parent else {
				break
			}
			node = parentNode
			node.isBest = true
//			count += 1
		}
//		log.debug("count: \(count)")
	}

	/// The utility function of this bot.
	static func mycompare(lhs: Scenario, rhs: Scenario) -> Bool {
		// IDEA: Two-player mode: Sort the best scenarios for the opponent as well.
		// Deal with the places with conflict of interest between the two players.

		// IDEA: It's terrible to quickly get to the food, and afterwards realize
		// there isn't sufficient room to move around.
		// Hypothsis: Prefer doing the unsafe movements in the beginning.
		// and the safer movements towards the end.
		// This way there will be more room around the snake when eating the food.

		if lhs.certainDeath && !rhs.certainDeath {
			return false
		}
		if !lhs.certainDeath && rhs.certainDeath {
			return true
		}

		let count0: Int = lhs.movements.count
		let count1: Int = rhs.movements.count
		if count0 > count1 {
			return true
		}
		if count0 < count1 {
			return false
		}

		// IDEA: There are way too many foodpickups. The best paths gets preferred.
		// These simulated food drops are by a small likelyhood.
		// Instead of picking a single food drop, it would be more accurate
		// to consider multiple choices for a single FoodNode.
		if lhs.numberOfFoodsEaten > rhs.numberOfFoodsEaten {
			return true
		}
		if lhs.numberOfFoodsEaten < rhs.numberOfFoodsEaten {
			return false
		}

		if lhs.distanceToFood < rhs.distanceToFood {
			return true
		} else {
			return false
		}
	}

	var movementSummaryString: String {
		movements.map { $0.shorthand }.joined(separator: "")
	}
}

// IDEA: Store confidence in each of the nodes.
fileprivate class BuildTreeVisitor: Visitor {
    private let iteration: UInt

    // Use random generator with a seed for reproducable results
	private var randomNumberGenerator: SeededGenerator

	private let level: SnakeLevel
	private var foodPosition: IntVec2?

	/// Array where index0 is Player A, index1 is PlayerB
	private var player: [SnakePlayer]

	/// Array where index0 is Player A, index1 is PlayerB
	/// When visiting the children of a `MoveNode`, this happens:
	/// Before the `numberOfMoves` is incremented for the player.
	/// Visiting the children of the `MoveNode`.
	/// After the `numberOfMoves` is restored.
	private var numberOfMoves: [UInt] = [0, 0]

	private var numberOfFoodsEaten: Int
	private var movements: [SnakeBodyMovement]
	/// Keep track of the best paths so far.
	private var scenarios: [Scenario]

	init(iteration: UInt, level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?, seed: UInt64) {
        self.iteration = iteration
		self.level = level
		self.player = [player, oppositePlayer]
		self.foodPosition = foodPosition
		self.numberOfFoodsEaten = 0
		self.movements = []
		self.scenarios = []
		self.randomNumberGenerator = SeededGenerator(seed: seed)
	}

	func bestScenario() -> Scenario? {
		let sortedScenarios: [Scenario] = self.scenarios.sorted { Scenario.mycompare(lhs: $0, rhs: $1) }
		return sortedScenarios.first
	}

	func printStats() {
		let scenariosCount: Int = self.scenarios.count
		log.debug("scenariosCount: \(scenariosCount)")
	}

	func visit(_ node: RootNode) {
		// At the root, it's always player A that moves first.
		processChildNode(node, playerId: 0)
	}

	func appendScenario(node: Node, certainDeath: Bool) {
		let distanceToFood: UInt32
		if let fp: IntVec2 = self.foodPosition {
			// IDEA: use the playerid, instead of a hardcoded value
			// IDEA: Consider non-permanent obstacles when estimating the distance, eg. snake itself, snake opponent.
			distanceToFood = level.estimateDistance(position0: self.player[0].snakeBody.head.position, position1: fp)
		} else {
			distanceToFood = UInt32.max
		}
		let scenario = Scenario(
			destinationNode: node,
			movements: Array(self.movements),
			certainDeath: certainDeath,
			numberOfFoodsEaten: numberOfFoodsEaten,
			distanceToFood: distanceToFood
		)
		self.scenarios.append(scenario)
	}

	func visit(_ node: LeafNode) {
		appendScenario(node: node, certainDeath: false)
	}

	func visit(_ node: FoodNode) {
		//log.debug("FoodNode  depth: \(currentDepth)  \(movements)")

		let originalNumberOfFoodsEaten: Int = numberOfFoodsEaten
		defer {
			numberOfFoodsEaten = originalNumberOfFoodsEaten
		}
		let newNumberOfFoodsEaten: Int = originalNumberOfFoodsEaten + 1

		let isTwoPlayer: Bool = self.player[1].isInstalled

		var foodPositionSet: Set<IntVec2> = level.emptyPositionSet
		for p: SnakePlayer in self.player {
			guard p.isInstalled else {
				continue
			}
			let playerPositionSet: Set<IntVec2> = p.snakeBody.positionSet()
			foodPositionSet.subtract(playerPositionSet)
		}

		// IDEA: count the choices and determine the probablility for moveCCW, moveForward, moveCW.

		// IDEA: The number of food's eaten in the best scenario, should match the
		// current frequency of foods. If there are way too many foods eaten in best scenario,
		// then it's unrealistic. If there are too few foods eaten, then the best scenario
		// may take a less optimal path, and should try optimize the path.

		// place food at random position
		// IDEA: After having placed food several places, then analyze the choices
		// Are there many paths that leads to the food.
		// Is it risky. Is it safe.
		// IDEA: pick a random choice, branching factor parameter.
		// IDEA: vary the number of choices, depending on "numberOfFoodsEaten"
		// IDEA: place at least 1 food in all clusters, so that we always are certain
		// to have a choice in the local neighbourhood. Less risk of getting trapped.
		var limit: Int = 6

		// IDEA: use the current playerid for lookup in `numberOfMoves` array
		let numberOfMoves: UInt = self.numberOfMoves[0]
		if originalNumberOfFoodsEaten <= 1 {
			if numberOfMoves <= 3 {
				limit = 16
			} else {
				if numberOfMoves <= 4 {
					limit = 6
				} else {
					if numberOfMoves <= 5 {
						limit = 4
					} else {
						if numberOfMoves <= 6 {
							limit = 3
						} else {
							limit = 2
						}
					}
				}
			}
		} else {
			if originalNumberOfFoodsEaten <= 2 {
				limit = 6
			} else {
				if originalNumberOfFoodsEaten <= 3 {
					limit = 4
				} else {
					if originalNumberOfFoodsEaten <= 4 {
						limit = 3
					} else {
						if originalNumberOfFoodsEaten <= 6 {
							limit = 2
						} else {
							limit = 1
						}
					}
				}
			}
		}

		if isTwoPlayer {
			if originalNumberOfFoodsEaten <= 1 {
				if numberOfMoves <= 3 {
					limit = 6
				} else {
					limit = 3
				}
			} else {
				if numberOfMoves <= 3 {
					limit = 2
				} else {
					limit = 1
				}
			}
		}

		var newChoices: [FoodNodeChoice] = []
		newChoices.reserveCapacity(limit)

		// Append existing choices
		for choice: FoodNodeChoice in node.choices {
			let position: IntVec2 = choice.position.intVec2
			guard foodPositionSet.contains(position) else {
				//log.debug("Discarding a previous FoodNodeChoice with a position outside the reachable area!  position: \(position)")
				continue
			}
			newChoices.append(choice)
			foodPositionSet.remove(position)
		}

		// Goal: we want always to be able to reproduce problems.
		// For this reason we sort the food positions, since we want things to be deterministic.
		// Given the same seed to the random generator, the same food position will be selected.
		// We trade slow performance, and instead gets a deterministic bot.
		var foodPositions: [IntVec2] = foodPositionSet.sorted()

		// Append new choices
		while newChoices.count < limit {
			let n: Int = foodPositions.count
			guard let index: Int = (0..<n).randomElement(using: &randomNumberGenerator) else {
				//log.debug("Exhausted all available food positions.")
				break
			}
			let position0: IntVec2 = foodPositions[index]
			guard let position1: UIntVec2 = position0.uintVec2() else {
				log.error("Inconsistent food position. Expected non-negative coordinates, but got negative. position: \(position0).")
				break
			}
			let choice: FoodNodeChoice = FoodNodeChoice(position: position1)
			newChoices.append(choice)
			choice.parent = node
			foodPositions.remove(at: index)
		}

		// Sort the choices by their xy position.
		newChoices.sort {
			$0.position < $1.position
		}

		node.choices = newChoices

		for choice: FoodNodeChoice in newChoices {
			numberOfFoodsEaten = newNumberOfFoodsEaten
			choice.accept(self)
		}
	}

	func visit(_ node: FoodNodeChoice) {
		let originalFoodPosition: IntVec2? = self.foodPosition
		self.foodPosition = node.position.intVec2
		// IDEA: compute a distance map to the food
		defer {
			self.foodPosition = originalFoodPosition
		}

		// After eating food. It's always player A that moves first.
		processChildNode(node, playerId: 0)
	}

	func visit(_ node: MoveNode) {
		let playerIdUInt: UInt = node.playerId
		let playerId: Int = Int(playerIdUInt)

		let originalNumberOfMoves: UInt = self.numberOfMoves[playerId]
		let newNumberOfMoves: UInt = originalNumberOfMoves + 1
		self.numberOfMoves[playerId] = newNumberOfMoves
		defer {
			self.numberOfMoves[playerId] = originalNumberOfMoves
		}

		// IDEA: take special care when isEmpty_moveForwardCCW == false or isEmpty_moveForwardCW == false
		// In these cases each choice needs to determine the amount of space reachable.
		// If the space is smaller than the snake can fit inside, then make another choice.
		// So that the snake doesn't get trapped in death-spirals or confined mazes.
		// IDEA: we are about to hit a wall, determine size of the reachable area
		// if !isEmpty_forward && isEmpty_ccw && isEmpty_cw { do something }

		// IDEA: Determine risk. If all the neighbouring cells are empty, then it's pretty safe.
		// IDEA: If there already are some MoveNodeChoice's, then update the choices.
		// IDEA: If there are no choices, then create choices.

		// IDEA: As data gets reused from previous iterations, then grow the tree
		// IDEA: for depth==0, then expore all 3 branches: ccw, forward, cw.
		// IDEA: for depth==1, then expore all 3 branches: ccw, forward, cw.
		// IDEA: for depth==2, then expore 2 random branches, eg, ccw and cw.
		// IDEA: for depth==2, then expore 1 random branch, eg, forward.

		// IDEA: pick a random choice, branching factor parameter.
		// IDEA: sort children
		// IDEA: caching: save the iteration number in the node, if there is a mismatch, then it needs to be recomputed.

		// IDEA: revisit the best child from the planned path. Should I set a boolean on the best child?
		// Store the parent node for all nodes. Save the LeafNode together with the best scenarios.
		// When finding the best scenario, then walk the parent nodes back to the root node.
		// For all the 3 best scenarios, increment a counter of all the nodes. bit2 = best, bit1 = 2nd best, bit0 = 3rd best.
		// Afterwards clear all the counters.
		// Afterwards expand the tree.


		// Discard the terrible choices that causes hitting a wall
		if node.needsExploringPermanentObstacles {
			node.needsExploringPermanentObstacles = false

			let playerForNode: SnakePlayer = self.player[playerId]
			let snakeBody: SnakeBody = playerForNode.snakeBody
			let currentHead: SnakeHead = snakeBody.head

			var choices: [MoveNodeChoice] = []
			choices.reserveCapacity(3)

			func checkAndAppendChoice(_ movement: SnakeBodyMovement) {
				let newHead: SnakeHead = currentHead.simulateTick(movement: movement)
				let newHeadPosition: IntVec2 = newHead.position
				let level_isEmpty: Bool = level.emptyPositionSet.contains(newHeadPosition)
				guard level_isEmpty else {
					return
				}
				let choice = MoveNodeChoice(playerId: playerIdUInt, movement: movement, position: newHeadPosition)
				choice.parent = node
				choices.append(choice)
			}

            // IDEA: This checkAndAppendChoice() approach, discards nodes if we collide with a wall.
            // For the early stages of the game this works fine.
            // However when the snake eats the very last food, then there is only a wall to collide with.
            // These wall nodes would be discarded, and not be considerable as a possibility.
            // It's better NOT to discard the nodes. Make use of a KillNodeCause.collisionWithWall for these nodes.

			checkAndAppendChoice(.moveCCW)
			checkAndAppendChoice(.moveForward)
			checkAndAppendChoice(.moveCW)

			node.choices = choices
		}

		// IDEA: When the snake have reached a dead end, where there are no ways to go.
		// Then add this as a scenario and replace itself with a KillNode,
		// so that we know this is a bad way, but may be the way to go if we are near the end of the game.

		let availableChoices: NodeArray = node.choices
		let bestNode: Node? = availableChoices.first { $0.isBest }
		var nonBestNodes: NodeArray = availableChoices.filter { !$0.isBest }

		var limit: Int = 3
		if newNumberOfMoves < 3 {
			limit = 3
		} else {
			if newNumberOfMoves < 5 {
				limit = 2
			} else {
				limit = 1
			}
		}


		nonBestNodes.shuffle(using: &randomNumberGenerator)
		nonBestNodes = NodeArray(nonBestNodes.prefix(limit))

		bestNode?.accept(self)
		for choice in nonBestNodes {
			choice.accept(self)
		}
	}

	func visit(_ node: MoveNodeChoice) {
		let playerId: UInt = node.playerId
		let originalPlayer: SnakePlayer = self.player[Int(playerId)]
		let originalFoodPosition: IntVec2? = self.foodPosition
		let originalMovements: [SnakeBodyMovement] = Array(self.movements)

		defer {
			self.player[Int(playerId)] = originalPlayer
			self.foodPosition = originalFoodPosition
			self.movements = originalMovements
		}

		// IDEA: append to the current player movements
		// so for player B, we also keep track of its most optimal movements.
		if playerId == 0 {
			self.movements.append(node.movement)
		}

        // IDEA: Detect if the snake is chasing its own tail.
        // Is the new head position the same as the previous tail position.
        // I'm experiencing that the snake eats almost all the food, except for the very last food.
        // The snake rather wants to chase its own tail, than eat the last remaining piece of food.
        // In this case, then the snake should go for the food, so that the game can be finished.

		let originalSnakeBody: SnakeBody = originalPlayer.snakeBody

		// Currently there is no edge case handling.
		// IDEA: In two-player mode, then both playerA and playerB can pick up the food
		// In the case where playerA eats the food, then we still want playerB to make its move.
		// In the case where playerB eats the food, then we still want playerA to make its move.
		if node.position == originalFoodPosition {
			let newSnakeBody: SnakeBody = originalSnakeBody.stateForTick(movement: node.movement, act: .eat)
			// IDEA: is eating near head or near the tail? percentage, or index from head, or index from tail?
			if newSnakeBody.isEatingItself {
				self.player[Int(playerId)] = originalPlayer.playerWithNewSnakeBody(newSnakeBody)
				self.foodPosition = nil
				if let existingChildNode: KillNode = node.child as? KillNode {
					// If the child already is a KillNode, then keep the subtree, and traverse the subtree.
					// IDEA: if any of KillNode parameters have changed, then discard the subtree.
					existingChildNode.cause = KillNodeCause.collisionWithSelf
					existingChildNode.playerId = playerId
					existingChildNode.accept(self)
					return
				} else {
					// If the child is different than the KillNode, then replace the entire subtree with a KillNode.
					let newChildNode: KillNode = KillNode()
					node.child = newChildNode
					newChildNode.parent = node
					newChildNode.cause = KillNodeCause.collisionWithSelf
					newChildNode.playerId = playerId
					newChildNode.accept(self)
					return
				}
			}

			self.player[Int(playerId)] = originalPlayer.playerWithNewSnakeBody(newSnakeBody)
			self.foodPosition = nil
			if let existingChildNode: FoodNode = node.child as? FoodNode {
				// If the child already is a FoodNode, then keep the subtree, and traverse the subtree.
				existingChildNode.accept(self)
				return
			} else {
				// If the child is different than the FoodNode, then replace the entire subtree with a FoodNode.
				let newChildNode: FoodNode = FoodNode()
				node.child = newChildNode
				newChildNode.parent = node
				newChildNode.accept(self)
				return
			}
		}
		// IDEA: If this move is crossing the best path, then copy/paste the best path subtree
		// and attach it as a child. Then there is no need to do exploration of this subtree.
		// In tight places, when crossing best path in such way that the new route gets longer,
		// and the snake gets perfectly curled up, then we get more control of where the food can be inserted.
		// In tight places, when crossing best path in such way that the new route gets shorter,
		// then it we get less control of where the food gets inserted, and new food may be inserted
		// at hard to reach places, where the snake have to uncurl itself.
		// To quickly determine if the snake is crossing the best path, perhaps use: Set<IntVec2>
		// On a big map with a short snake, it makes good sense to take the shortest path.
		// In a 2 player mode, it's important to get to the food before the opponent player.
		do {
			let newSnakeBody: SnakeBody = originalSnakeBody.stateForTick(movement: node.movement, act: .doNothing)
			// IDEA: Do risk estimation. Determine if we are eating near head (risky) or near the tail (less risky) 
			if newSnakeBody.isEatingItself {
				self.player[Int(playerId)] = originalPlayer.playerWithNewSnakeBody(newSnakeBody)
				self.foodPosition = nil
				if let existingChildNode: KillNode = node.child as? KillNode {
					// If the child already is a KillNode, then keep the subtree, and traverse the subtree.
					// IDEA: if any of KillNode parameters have changed, then discard the subtree.
					existingChildNode.cause = KillNodeCause.collisionWithSelf
					existingChildNode.playerId = playerId
					existingChildNode.accept(self)
					return
				} else {
					// If the child is different than the KillNode, then replace the entire subtree with a KillNode.
					let newChildNode: KillNode = KillNode()
					node.child = newChildNode
					newChildNode.parent = node
					newChildNode.cause = KillNodeCause.collisionWithSelf
					newChildNode.playerId = playerId
					newChildNode.accept(self)
					return
				}
			}

			// Check for collision with the opponent snake.
			let opponentPlayerId: UInt = self.nextInstalledPlayerId(playerId)
			if opponentPlayerId != playerId {
				let opponentPlayer: SnakePlayer = self.player[Int(opponentPlayerId)]
				let opponentPositionSet: Set<IntVec2> = opponentPlayer.snakeBody.positionSet()
				if opponentPositionSet.contains(node.position) {
					let newChildNode: KillNode = KillNode()
					node.child = newChildNode
					newChildNode.parent = node
					newChildNode.cause = KillNodeCause.collisionWithOpponent
					newChildNode.playerId = playerId
					newChildNode.accept(self)
					return
				}
			}

			self.player[Int(playerId)] = originalPlayer.playerWithNewSnakeBody(newSnakeBody)
			self.foodPosition = originalFoodPosition
			let nextPlayerId: UInt = self.nextAlivePlayerId(playerId)
			processChildNode(node, playerId: nextPlayerId)
		}
	}

	func visit(_ node: KillNode) {
		let playerId: UInt = node.playerId
		//log.debug("KillNode  depth: \(currentDepth)  \(movements)")
		// IDEA: hitting a wall is certain death
		// IDEA: hitting the snake at the oldest part, is a temporary obstacle and is less likely certain death
		// IDEA: hitting the snake at a newer part, is almost a permanent obstacle and is highly likely certain death
		if playerId == 0 {
			// If the player being controlled by this bot dies,
			// then it makes no sense to continue simulating the dead player.
			// It makes more sense to register this as a scenario leading to certain death.
			appendScenario(node: node, certainDeath: true)
			return
		}

		// In multiplayer mode, then deal with oppositePlayer and traverse the subtree.
		// IDEA: when playerB dies, we are still interested in simulating playerA.
		// Currently we stop growing when playerB dies.
//		let nextPlayerId: UInt = self.nextPlayerId(playerId)
//		processChildNode(node, playerId: nextPlayerId)
		appendScenario(node: node, certainDeath: false)
	}

    // player[0] must always be installed. Otherwise we cannot perform simulation.
    // player[1] is optional.
    //
    // As long as player[0] is alive it makes sense to continue simulation.
    // If player[0] is dead, then it makes sense to terminate the simulation.
    // player[1] is optional. If it's alive then simulate it. If it's dead, then don't simulate it.
	func isInstalledAndAlivePlayerId(_ playerId: UInt) -> Bool {
		return self.player[Int(playerId)].isInstalledAndAlive
	}

	func nextAlivePlayerId(_ playerId: UInt) -> UInt {
		let isTwoPlayer: Bool = self.player[1].isInstalled

		if !isTwoPlayer {
			return 0
		}
		var newPlayerId: UInt
		newPlayerId = (playerId + 1) % UInt(self.player.count)
		if isInstalledAndAlivePlayerId(newPlayerId) {
			return newPlayerId
		}
		newPlayerId = (newPlayerId + 1) % UInt(self.player.count)
		if isInstalledAndAlivePlayerId(newPlayerId) {
			return newPlayerId
		}

		log.error("nextAlivePlayerId() Cannot find a suitable new playerId.  playerId: \(playerId)")
		fatalError("Cannot find a suitable new playerId")
	}

	func nextInstalledPlayerId(_ playerId: UInt) -> UInt {
		guard player[0].isInstalled else {
			log.error("Assuming that playerA is always installed, since this is the player that this bot is simulating.")
			return 0
		}
		let isTwoPlayer: Bool = self.player[1].isInstalled

		if !isTwoPlayer {
			return 0
		}
		let newPlayerId: UInt = (playerId + 1) % UInt(self.player.count)
		return newPlayerId
	}

	func processChildNode(_ node: NodeWithReplaceChild, playerId: UInt) {
		// If there already is a non-nil and non-leaf child, then keep this subtree, and traverse this subtree.
		// Otherwise replace the entire subtree with a new child node.
		if let existingChildNode: Node = node.child {
			if !(existingChildNode is LeafNode) {
				existingChildNode.accept(self)
				return
			}
		}

		let isTwoPlayer: Bool = player[1].isInstalled

		let limit: UInt
		if isTwoPlayer {
			// In a 2 player game, use narrow simulations
			limit = 17
		} else {
			// In a 1 player game, use deep simulations
			limit = 37
		}

		let numberOfMoves: UInt = self.numberOfMoves[Int(playerId)]
		let childNode: Node
		if numberOfMoves < limit {
			let moveNode = MoveNode.create(playerId: playerId)
			childNode = moveNode
		} else {
			childNode = LeafNode()
		}
		node.replaceChild(childNode)
		childNode.parent = node

		childNode.accept(self)
	}
}

fileprivate class CountNumberOfNodes: Visitor {
	public private(set) var count: UInt = 0

	func visit(_ node: RootNode) {
		count += 1
		node.child?.accept(self)
	}

	func visit(_ node: LeafNode) {
		count += 1
	}

	func visit(_ node: FoodNode) {
		count += 1
		for choice in node.choices {
			choice.accept(self)
		}
	}

	func visit(_ node: FoodNodeChoice) {
		count += 1
		node.child?.accept(self)
	}

	func visit(_ node: MoveNode) {
		count += 1
		for child in node.children {
			child.accept(self)
		}
	}

	func visit(_ node: MoveNodeChoice) {
		count += 1
		node.child?.accept(self)
	}

	func visit(_ node: KillNode) {
		count += 1
		node.child?.accept(self)
	}
}

fileprivate class CountProblemsWithNodes: Visitor {
	public private(set) var countNilParent: UInt = 0
	public private(set) var countWrongParent: UInt = 0

	var isError: Bool {
		return (countNilParent > 0) || (countWrongParent > 0)
	}

	func check(_ parentNode: Node, _ childNodeOrNil: Node?) {
		guard let childNode: Node = childNodeOrNil else {
			return
		}
		guard let childParentNode: Node = childNode.parent else {
			countNilParent += 1
			log.error("Expected childNode.parent to be non-nil, but got nil.   parentNode: \(type(of: parentNode))  childNode: \(type(of: childNode))")
			return
		}
		guard childParentNode === parentNode else {
			countWrongParent += 1
			log.error("Expected childNode.parent to be pointing at the parent, but it points to the wrong instance.   parentNode: \(type(of: parentNode))  childNode: \(type(of: childNode))")
			return
		}
	}

	func visit(_ node: RootNode) {
		check(node, node.child)
		node.child?.accept(self)
	}

	func visit(_ node: LeafNode) {
		// this node has no children
	}

	func visit(_ node: FoodNode) {
		for choice in node.choices {
			check(node, choice)
			choice.accept(self)
		}
	}

	func visit(_ node: FoodNodeChoice) {
		check(node, node.child)
		node.child?.accept(self)
	}

	func visit(_ node: MoveNode) {
		for child in node.children {
			check(node, child)
			child.accept(self)
		}
	}

	func visit(_ node: MoveNodeChoice) {
		check(node, node.child)
		node.child?.accept(self)
	}

	func visit(_ node: KillNode) {
		check(node, node.child)
		node.child?.accept(self)
	}
}

extension CountProblemsWithNodes: CustomStringConvertible {
	fileprivate var description: String {
		return "\(countNilParent),\(countWrongParent)"
	}
}

fileprivate class ClearTheBestNodes: Visitor {

	func visit(_ node: RootNode) {
		node.isBest = false
		node.child?.accept(self)
	}

	func visit(_ node: LeafNode) {
		node.isBest = false
	}

	func visit(_ node: FoodNode) {
		node.isBest = false
		for choice in node.choices {
			choice.accept(self)
		}
	}

	func visit(_ node: FoodNodeChoice) {
		node.isBest = false
		node.child?.accept(self)
	}

	func visit(_ node: MoveNode) {
		node.isBest = false
		for child in node.children {
			child.accept(self)
		}
	}

	func visit(_ node: MoveNodeChoice) {
		node.isBest = false
		node.child?.accept(self)
	}

	func visit(_ node: KillNode) {
		node.isBest = false
		node.child?.accept(self)
	}
}

fileprivate class PrettyPlannedPath: Visitor {
    var head: SnakeHead
	var items = [String]()

    private init(head: SnakeHead) {
        self.head = head
    }

    class func process(node: Node, snakeHead: SnakeHead) -> String {
		let reversedParentNodeArray: NodeArray = node.parentNodeArray.reversed()
        let visitor = PrettyPlannedPath(head: snakeHead)
		for n: Node in reversedParentNodeArray {
			n.accept(visitor)
		}
		return visitor.items.joined(separator: "")
	}

	func visit(_ node: RootNode) {
//		items.append("R")
	}

	func visit(_ node: LeafNode) {
		items.append("L")
	}

	func visit(_ node: FoodNode) {
//		items.append("F")
	}

	func visit(_ node: FoodNodeChoice) {
		items.append("○")
	}

	func visit(_ node: MoveNode) {
//		items.append("M")
	}

	func visit(_ node: MoveNodeChoice) {
		// Only interested in player A. Ignore player B
		guard node.playerId == 0 else {
			return
		}
        let s: String = PrettyPlannedPath.humanReadable(movement: node.movement, direction: head.direction)
        items.append(s)
        head = head.simulateTick(movement: node.movement)
	}

    private class func humanReadable(movement: SnakeBodyMovement, direction: SnakeHeadDirection) -> String {
        switch movement {
        case .dontMove:
            return "*"
        case .moveForward:
            return "∙"
        case .moveCCW:
            return direction.rotatedCCW.pointingTriangle
        case .moveCW:
            return direction.rotatedCW.pointingTriangle
        }
    }

	func visit(_ node: KillNode) {
		// Only interested in player A. Ignore player B
		guard node.playerId == 0 else {
			return
		}
		items.append("KILL\(node.cause)")
	}
}

fileprivate class FindMaxDepth: Visitor {
	var numberOfMoves: UInt
	var highestNumberOfMoves_unexplored: UInt
	var highestNumberOfMoves_kill: UInt

	init() {
		self.numberOfMoves = 0
		self.highestNumberOfMoves_unexplored = 0
		self.highestNumberOfMoves_kill = 0
	}

	func visit(_ node: RootNode) {
		node.child?.accept(self)
	}

	func visit(_ node: LeafNode) {
		if self.numberOfMoves >= highestNumberOfMoves_unexplored {
			self.highestNumberOfMoves_unexplored = self.numberOfMoves
		}
	}

	func visit(_ node: FoodNode) {
		for choice in node.choices {
			choice.accept(self)
		}
	}

	func visit(_ node: FoodNodeChoice) {
		node.child?.accept(self)
	}

	func visit(_ node: MoveNode) {
		if node.playerId == 0 {
			visit_player0(node)
		} else {
			visit_opponentPlayer(node)
		}
	}

	func visit_player0(_ node: MoveNode) {
		let originalNumberOfMoves: UInt = self.numberOfMoves
		let newNumberOfMoves: UInt = originalNumberOfMoves + 1
		self.numberOfMoves = newNumberOfMoves
		defer {
			self.numberOfMoves = originalNumberOfMoves
		}

		for child in node.children {
			child.accept(self)
		}
	}

	func visit_opponentPlayer(_ node: MoveNode) {
		for child in node.children {
			child.accept(self)
		}
	}

	func visit(_ node: MoveNodeChoice) {
		node.child?.accept(self)
	}

	func visit(_ node: KillNode) {
		// Only interested in when player A dies. We don't care when player B dies.
		if node.playerId != 0 {
			node.child?.accept(self)
			return
		}

		// We know that player A dies.
		if self.numberOfMoves >= self.highestNumberOfMoves_kill {
			self.highestNumberOfMoves_kill = self.numberOfMoves
		}

		// no purpose traversing the subtree of this node, since we know that player A dies.
	}
}

fileprivate class GraphvizExport: Visitor {
    var rows = [String]()
    var nodeId: String = "node0"
    var currentIndex: UInt = 0
    let maxDepth: UInt = 5
    var depth: UInt = 0

    func result() -> String {
        var rows = [String]()
        rows.append("/*")
        rows.append("USAGE:")
        rows.append("PROMPT> dot -Tsvg demo.dot -o demo.svg")
        rows.append("*/")
        rows.append("digraph {")
        rows.append("  bgcolor=\"#ffffff00\";") // Transparent background in the generated SVG
        rows.append("  graph [fontname = \"helvetica\"];")
        rows.append("  node [fontname = \"helvetica\"];")
        rows.append("  edge [fontname = \"helvetica\"];")
        rows += self.rows.map { "  \($0)" }
        rows.append("}")
        return rows.joined(separator: "\n")
    }

    func generateId() -> String {
        currentIndex += 1
        return "node\(currentIndex)"
    }

    func edge(_ fromId: String, _ toId: String) {
        rows.append("\(fromId) -> \(toId);")
    }

    func nodeWithLabel(_ nodeId: String, label: String) {
        rows.append("\(nodeId) [label=\"\(label)\"];")
    }

    func visit(_ node: RootNode) {
        rows.append("\(self.nodeId) [shape=plaintext, label=\"Start\"];")
        node.child?.accept(self)
    }

    func visit(_ node: LeafNode) {
        let originalNodeId: String = self.nodeId
        let originalDepth: UInt = self.depth
        self.nodeId = generateId()
        self.depth += 1
        defer {
            self.nodeId = originalNodeId
            self.depth = originalDepth
        }
        nodeWithLabel(self.nodeId, label: "Leaf")
        edge(originalNodeId, self.nodeId)

        guard self.depth < self.maxDepth else {
            return
        }
    }

    func visit(_ node: FoodNode) {
        let originalNodeId: String = self.nodeId
        let originalDepth: UInt = self.depth
        self.nodeId = generateId()
        self.depth += 1
        defer {
            self.nodeId = originalNodeId
            self.depth = originalDepth
        }
        let numberOfChoices: Int = node.choices.count
        nodeWithLabel(self.nodeId, label: "Eat \(numberOfChoices)")
        edge(originalNodeId, self.nodeId)

        guard self.depth < self.maxDepth else {
            return
        }

        typealias ChoiceCountPair = (FoodNodeChoice, UInt)
        let choiceCountPairs: [ChoiceCountPair] = node.choices.map { (choice: FoodNodeChoice) in
            let visitor = FindMaxDepth()
            choice.accept(visitor)
            var count: UInt = visitor.numberOfMoves
            if choice.isBest {
                count = 10000
            }
            return (choice, count)
        }

        let choiceCountPairsSorted: [ChoiceCountPair] = choiceCountPairs.sorted { $0.1 > $1.1 }

        let bestChoiceCountPairs: ArraySlice<ChoiceCountPair> = choiceCountPairsSorted.prefix(1)

        for choiceCountPair in bestChoiceCountPairs {
            let foodNodeChoice: FoodNodeChoice = choiceCountPair.0
            let foodNodeChoice_childNode: Node? = foodNodeChoice.child
            foodNodeChoice_childNode?.accept(self)
        }
    }

    func visit(_ node: FoodNodeChoice) {
        let originalNodeId: String = self.nodeId
        let originalDepth: UInt = self.depth
        self.nodeId = generateId()
        self.depth += 1
        defer {
            self.nodeId = originalNodeId
            self.depth = originalDepth
        }
        nodeWithLabel(self.nodeId, label: "FC")
        edge(originalNodeId, self.nodeId)

        guard self.depth < self.maxDepth else {
            return
        }

        node.child?.accept(self)
    }

    func visit(_ node: MoveNode) {
        let originalNodeId: String = self.nodeId
        let originalDepth: UInt = self.depth
        self.nodeId = generateId()
        self.depth += 1
        defer {
            self.nodeId = originalNodeId
            self.depth = originalDepth
        }

        let choices: [MoveNodeChoice] = node.choices.sorted { $0.movement < $1.movement }
        let choiceNodeIds: [String] = choices.map { choice in self.generateId() }

        edge(originalNodeId, "\(self.nodeId):n")

        let isBest: Bool = node.isBest

        var choiceItems: [String] = []
        for (index, choice) in choices.enumerated() {
            let choiceNodeId: String = choiceNodeIds[index]

            let label: String
            switch choice.movement {
            case .dontMove:
                label = "DontMove"
            case .moveCCW:
                label = "ccw"
            case .moveForward:
                label = "fwd"
            case .moveCW:
                label = "cw"
            }
            choiceItems.append("<\(choiceNodeId)> \(label)")
        }

        let joinedChoiceItems: String = choiceItems.joined(separator: "|")
        let nodeLabel = "Move"
        let fillcolor: String
        if node.playerId == 0 {
            if isBest {
                fillcolor = "lightgreen"
            } else {
                fillcolor = "\"#d7f0d0\""
            }
        } else {
            if isBest {
                fillcolor = "lightblue"
            } else {
                fillcolor = "\"#d3def0\""
            }
        }
        // peripheries=3,

        let bordercolor: String
        let fontcolor: String
        if isBest {
            bordercolor = "black"
            fontcolor = "black"
        } else {
            bordercolor = "\"#c0c0b0\""
            fontcolor = "gray"
        }

        rows.append("\(self.nodeId) [shape=record, style=filled, color=\(bordercolor), fillcolor=\(fillcolor), fontcolor=\(fontcolor), label=\"{ \(nodeLabel) |{\(joinedChoiceItems)}}\"];")

        guard self.depth < self.maxDepth else {
            return
        }

        let moveNodeId: String = self.nodeId
        for (index, choice) in choices.enumerated() {
            let childNodeId: String = choiceNodeIds[index]
            self.nodeId = "\(moveNodeId):\(childNodeId)"
            choice.child?.accept(self)
        }
    }

    func visit(_ node: MoveNodeChoice) {
        log.error("Expecting MoveNodeChoice to always have a MoveNode as its parent.")
    }

    func visit(_ node: KillNode) {
        let originalNodeId: String = self.nodeId
        let originalDepth: UInt = self.depth
        self.nodeId = generateId()
        self.depth += 1
        defer {
            self.nodeId = originalNodeId
            self.depth = originalDepth
        }
        nodeWithLabel(self.nodeId, label: "Kill")
        edge(originalNodeId, self.nodeId)

        guard self.depth < self.maxDepth else {
            return
        }

        node.child?.accept(self)
    }
}

