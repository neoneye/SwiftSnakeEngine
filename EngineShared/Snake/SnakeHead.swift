// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

public struct SnakeHead: Hashable {
	public let position: IntVec2
	public let direction: SnakeHeadDirection

    public init(position: IntVec2, direction: SnakeHeadDirection) {
        self.position = position
        self.direction = direction
    }

    /// Create a `SnakeHead` instance using two neighbouring positions.
    ///
    /// The coordinate system have its origin in the bottom/left corner.
    ///
    /// - parameter headPosition: The position of the snake head.
    /// - parameter directionPosition: Used for determining the direction the snake head is pointing.
    /// - returns: `nil` if the two positions aren't neighbours.
    public static func create(headPosition: IntVec2, directionPosition: IntVec2) -> SnakeHead? {
        let diff: IntVec2 = headPosition.subtract(directionPosition)
        let xx: Int32 = abs(diff.x)
        let yy: Int32 = abs(diff.y)
        guard xx + yy == 1 else {
            // If the positions are the same, then it's impossible to determine the direction.
            // If the positions are diagonally, then it becomes too messy determining what the direction may be.
            // If the positions are too far away, then for simplicity sake, `nil` is returned.
            return nil
        }
        let direction: SnakeHeadDirection
        if yy != 0 {
            direction = (diff.y > 0) ? .down : .up
        } else {
            direction = (diff.x > 0) ? .left : .right
        }
        return SnakeHead(position: headPosition, direction: direction)
    }

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

    /// Move the snake according to user input: arrow up/down/left/right.
    ///
    /// The snake cannot go backwards, so if the `direction`  is in the opposite of the head direction, then `dontMove` is returned.
    ///
    /// - parameter direction: The new direction of the snake head.
    /// - returns: `dontMove` if the the two directions are opposites.
    public func moveToward(direction: SnakeHeadDirection) -> SnakeBodyMovement {
        let dx: Int32
        let dy: Int32
        switch direction {
        case .up:
            (dx, dy) = (0, 1)
        case .down:
            (dx, dy) = (0, -1)
        case .left:
            (dx, dy) = (-1, 0)
        case .right:
            (dx, dy) = (1, 0)
        }
        let newPosition: IntVec2 = self.position.offsetBy(dx: dx, dy: dy)
        let movement: SnakeBodyMovement = self.moveToward(newPosition) ?? SnakeBodyMovement.dontMove
        return movement
    }
}
