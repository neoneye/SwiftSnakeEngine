// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public enum SnakeBodyPartContent: Hashable {
	case empty
	case food
}

public struct SnakeBodyPart: Hashable {
	public var position: IntVec2
	public var content: SnakeBodyPartContent
}

public enum SnakeBodyMovement {
	case dontMove
	case moveForward
	case moveCCW
	case moveCW
}

public enum SnakeBodyAct {
	case doNothing
	case eat
}

public class SnakeBody {
	public let fifo: SnakeFifo<SnakeBodyPart>
	public let head: SnakeHead

	public init(fifo: SnakeFifo<SnakeBodyPart>, head: SnakeHead) {
		self.fifo = fifo
		self.head = head
	}

	public class func empty() -> SnakeBody {
		let head = SnakeHead(position: IntVec2(x: 0, y: 0), direction: SnakeHeadDirection.right)
		let state = SnakeBody(
			fifo: SnakeFifo<SnakeBodyPart>(),
			head: head
		)
		return state
	}

	public func stateForTick(movement: SnakeBodyMovement, act: SnakeBodyAct) -> SnakeBody {
		if movement == .dontMove {
			return self
		}
		let newHead: SnakeHead = self.head.simulateTick(movement: movement)
		let newFifo = SnakeFifo<SnakeBodyPart>(original: self.fifo)

		let content: SnakeBodyPartContent
		switch act {
		case .doNothing:
			content = .empty
		case .eat:
			content = .food
		}

		let snakeBodyPart = SnakeBodyPart(position: newHead.position, content: content)
		switch act {
		case .doNothing:
			newFifo.append(snakeBodyPart)
		case .eat:
			newFifo.appendAndGrow(snakeBodyPart)
		}
		let newState = SnakeBody(
			fifo: newFifo,
			head: newHead
		)
		return newState
	}

	public func bodyAndTailWithoutHead_positionArray() -> [IntVec2] {
		// IDEA: Caching. If it's already computed then no need to compute it again.
		guard !fifo.array.isEmpty else {
			return []
		}
		let bodyPartsWithoutHead: [SnakeBodyPart] = fifo.array.dropLast()
		return bodyPartsWithoutHead.map { $0.position }
	}

	public func bodyAndTailWithoutHead_positionSet() -> Set<IntVec2> {
		// IDEA: Caching. If it's already computed then no need to compute it again.
		return Set<IntVec2>(bodyAndTailWithoutHead_positionArray())
	}

	public func positionArray() -> [IntVec2] {
		return fifo.array.map { $0.position }
	}

	public func contentArray() -> [SnakeBodyPartContent] {
		return fifo.array.map { $0.content }
	}

	public var fifoContentString: String {
		return fifo.array.map { $0.content.shorthand }.joined(separator: "")
	}

	public func positionSet() -> Set<IntVec2> {
		// IDEA: Caching. If it's already computed then no need to compute it again.
		return Set<IntVec2>(positionArray())
	}

	public var isEatingItself: Bool {
		// IDEA: Caching. If it's already computed then no need to compute it again.
		return bodyAndTailWithoutHead_positionSet().contains(head.position)
	}

	public var length: UInt {
		return UInt(fifo.array.count)
	}

	public class func create(position: IntVec2, headDirection: SnakeHeadDirection, length: UInt) -> SnakeBody {
		let n = Int32(length)
		var dx: Int32 = 0
		var dy: Int32 = 0
		switch headDirection {
		case .up:
			dy = -n
		case .left:
			dx = n
		case .right:
			dx = -n
		case .down:
			dy = n
		}

		let startPosition: IntVec2 = position.offsetBy(dx: dx, dy: dy)
		let initialFifo = SnakeFifo<SnakeBodyPart>()
		let snakeBodyPart = SnakeBodyPart(position: startPosition, content: .empty)
		initialFifo.appendAndGrow(snakeBodyPart)
		let initialHead = SnakeHead(
			position: startPosition,
			direction: headDirection
		)
		var state = SnakeBody(
			fifo: initialFifo,
			head: initialHead
		)
		for _ in 0..<n {
			state = state.stateForTick(movement: .moveForward, act: .eat)
		}
		// At this point the snake has a lot of food items inside its stomach, so we have to clear the stomach.
		return state.clearedContentOfStomach()
	}

	/// Clears the content of the stomach, so that there is no food inside the snake
	public func clearedContentOfStomach() -> SnakeBody {
		let fifo: SnakeFifo<SnakeBodyPart> = self.fifo.map {
			SnakeBodyPart(position: $0.position, content: .empty)
		}
		return SnakeBody(fifo: fifo, head: self.head)
	}
}

extension SnakeBody: Equatable {
	public static func == (lhs: SnakeBody, rhs: SnakeBody) -> Bool {
		guard lhs.head == rhs.head else {
			return false
		}
		return lhs.fifo == rhs.fifo
	}
}

extension SnakeBodyPartContent {
	fileprivate var shorthand: String {
		switch self {
		case .empty:
			return "-"
		case .food:
			return "F"
		}
	}
}
