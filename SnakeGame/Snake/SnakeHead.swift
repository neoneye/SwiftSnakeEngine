// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

public struct SnakeHead {
	public let position: IntVec2
	public let direction: SnakeHeadDirection

	public func simulateTick(movement: SnakeBodyMovement) -> SnakeHead {
		var newHeadDirection: SnakeHeadDirection = self.direction
		switch movement {
		case .dontMove:
			return self
		case .moveForward:
			()
		case .moveCCW:
			newHeadDirection = self.direction.rotatedCCW
		case .moveCW:
			newHeadDirection = self.direction.rotatedCW
		}

		var newHeadPosition: IntVec2 = self.position
		switch newHeadDirection {
		case .up:
			newHeadPosition.y += 1
		case .left:
			newHeadPosition.x -= 1
		case .right:
			newHeadPosition.x += 1
		case .down:
			newHeadPosition.y -= 1
		}

		return SnakeHead(position: newHeadPosition, direction: newHeadDirection)
	}
}

extension SnakeHead: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.direction == rhs.direction && lhs.position == rhs.position
	}
}
