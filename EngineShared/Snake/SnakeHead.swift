// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

public struct SnakeHead: Hashable {
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

    /// Determine the best move that will get the snake closer to the new position.
    ///
    /// The snake cannot go backwards, so if the newPosition is behind the snake, then `nil` is returned.
    /// In such case it's up to the player (human or bot) to determine an alternative movement.
    ///
    /// If the `newPosition` is the same as the current position, then `dontMove` is returned.
    public func moveToward(_ newPosition: IntVec2) -> SnakeBodyMovement? {
        let dx: Int32 = self.position.x - newPosition.x
        let dy: Int32 = self.position.y - newPosition.y
        let dxx: Int32 = dx * dx
        let dyy: Int32 = dy * dy
        guard dxx > 0 || dyy > 0 else {
            return .dontMove
        }
        switch self.direction {
        case .up:
            if dy < 0 && dyy >= dxx {
                return .moveForward
            }
            if dx > 0 {
                return .moveCCW
            }
            if dx < 0 {
                return .moveCW
            }
        case .down:
            if dy > 0 && dyy >= dxx {
                return .moveForward
            }
            if dx > 0 {
                return .moveCW
            }
            if dx < 0 {
                return .moveCCW
            }
        case .left:
            if dx > 0 && dxx >= dyy {
                return .moveForward
            }
            if dy > 0 {
                return .moveCCW
            }
            if dy < 0 {
                return .moveCW
            }
        case .right:
            if dx < 0 && dxx >= dyy {
                return .moveForward
            }
            if dy > 0 {
                return .moveCW
            }
            if dy < 0 {
                return .moveCCW
            }
        }
        // The snake cannot go backwards. In this case `nil` is returned.
        return nil
    }
}
