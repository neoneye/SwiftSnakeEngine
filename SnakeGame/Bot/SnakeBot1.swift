// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeBot1: SnakeBot {
	public static var info: SnakeBotInfo {
		SnakeBotInfoImpl(
			humanReadableName: "Bot - Shortest Path",
			userDefaultIdentifier: "bot1"
		)
	}

	public let futurePlannedPath: [IntVec2]

	fileprivate init(futurePlannedPath: [IntVec2]) {
		self.futurePlannedPath = futurePlannedPath
	}

	required public convenience init() {
		self.init(futurePlannedPath: [])
	}

	public func plannedPath() -> [IntVec2] {
		return futurePlannedPath
	}

	public func takeAction(level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?) -> (SnakeBot, SnakeBodyMovement) {

		guard player.isInstalled else {
			//print("Do nothing. The player is not installed. It doesn't make sense to run the bot.")
			return (self, .moveForward)
		}
		guard player.isAlive else {
			//print("Do nothing. The player is not alive. It doesn't make sense to run the bot.")
			return (self, .moveForward)
		}
		guard let foodPosition: IntVec2 = foodPosition else {
			print("no food position. Cannot find shortest path")
			return (self, .moveForward)
		}

		var plannedPath: [IntVec2] = self.futurePlannedPath

		// distance to opposite player head shortest path
		// if too close, then avoid

		let emptyPositionsArray: [IntVec2] = level.emptyPositionArray
		let snakePositionsArray: [IntVec2] = player.snakeBody.positionArray()
		let snakePositionsSet = Set<IntVec2>(snakePositionsArray)

		let oppositePlayer_snakePositionSet: Set<IntVec2>
		if oppositePlayer.isInstalled {
			oppositePlayer_snakePositionSet = oppositePlayer.snakeBody.positionSet()
		} else {
			oppositePlayer_snakePositionSet = Set<IntVec2>()
		}

		var availablePositionsPlusHead: [IntVec2] = emptyPositionsArray
		availablePositionsPlusHead.removeAll { snakePositionsSet.contains($0) }
		availablePositionsPlusHead.append(player.snakeBody.head.position)
		availablePositionsPlusHead.removeAll { oppositePlayer_snakePositionSet.contains($0) }
		if plannedPath.isEmpty {
			plannedPath = ComputeShortestPath.compute(
				availablePositions: availablePositionsPlusHead,
				startPosition: player.snakeBody.head.position,
				targetPosition: foodPosition
			)
		}

		let path: [IntVec2] = Array(plannedPath)
		if !plannedPath.isEmpty {
			plannedPath.removeFirst()
		}

		guard path.count >= 2 else {

			var availablePositions: [IntVec2] = emptyPositionsArray
			availablePositions.removeAll { snakePositionsSet.contains($0) }
			availablePositions.removeAll { oppositePlayer_snakePositionSet.contains($0) }

			let currentHead: SnakeHead = player.snakeBody.head
			var countCCW: UInt = 0
			var countCW: UInt = 0
			var positionCCW = IntVec2(x: 0, y: 0)
			var positionCW = IntVec2(x: 0, y: 0)
			do {
				let newHead: SnakeHead = currentHead.simulateTick(movement: .moveCCW)
				countCCW = MeasureAreaSize.compute(positionArray: availablePositions, startPosition: newHead.position)
				positionCCW = newHead.position
			}
			do {
				let newHead: SnakeHead = currentHead.simulateTick(movement: .moveCW)
				countCW = MeasureAreaSize.compute(positionArray: availablePositions, startPosition: newHead.position)
				positionCW = newHead.position
			}
			print("fill at \(player.snakeBody.head.position)  countCCW: \(countCCW) countCW: \(countCW)     positionCCW: \(positionCCW) positionCW: \(positionCW)")

			let pendingMovement: SnakeBodyMovement
			if countCW == 0 && countCCW == 0 {
				pendingMovement = .moveForward
			} else {
				if countCW > countCCW {
					pendingMovement = .moveCW
				} else {
					pendingMovement = .moveCCW
				}
			}

			let bot = SnakeBot1(futurePlannedPath: plannedPath)
			return (bot, pendingMovement)
		}
		let position0: IntVec2 = player.snakeBody.head.position
		let position1: IntVec2 = path[1]
		let dx: Int = Int(position0.x) - Int(position1.x)
		let dy: Int = Int(position0.y) - Int(position1.y)
		let distance: Int = dx * dx + dy * dy
		//		print("dx: \(dx)  dy: \(dy)  distance: \(distance)")
		guard distance == 1 else {
			print("ERROR: way too long distance to nearest neighbour. dx: \(dx)  dy: \(dy)  distance: \(distance)")
			let bot = SnakeBot1(futurePlannedPath: plannedPath)
			return (bot, .moveForward)
		}

		var pendingMovement: SnakeBodyMovement = .moveForward
		switch player.snakeBody.head.direction {
		case .up:
			if dy > 0 {
				pendingMovement = .moveCW
			}
			if dy < 0 {
				pendingMovement = .moveForward
			}
			if dx > 0 {
				pendingMovement = .moveCCW
			}
			if dx < 0 {
				pendingMovement = .moveCW
			}
		case .down:
			if dy > 0 {
				pendingMovement = .moveForward
			}
			if dy < 0 {
				pendingMovement = .moveCW
			}
			if dx > 0 {
				pendingMovement = .moveCW
			}
			if dx < 0 {
				pendingMovement = .moveCCW
			}
		case .left:
			if dy > 0 {
				pendingMovement = .moveCCW
			}
			if dy < 0 {
				pendingMovement = .moveCW
			}
			if dx > 0 {
				pendingMovement = .moveForward
			}
			if dx < 0 {
				pendingMovement = .moveCCW
			}
		case .right:
			if dy > 0 {
				pendingMovement = .moveCW
			}
			if dy < 0 {
				pendingMovement = .moveCCW
			}
			if dx > 0 {
				pendingMovement = .moveCCW
			}
			if dx < 0 {
				pendingMovement = .moveForward
			}
		}

		let bot = SnakeBot1(futurePlannedPath: plannedPath)
		return (bot, pendingMovement)
	}
}

extension SnakeBot1: CustomDebugStringConvertible {
	public var debugDescription: String {
		return "SnakeBot1 \(futurePlannedPath)"
	}
}
