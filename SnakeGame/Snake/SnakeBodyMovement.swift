// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

public enum SnakeBodyMovement {
    case dontMove
    case moveForward
    case moveCCW
    case moveCW
}

extension SnakeHeadDirection {
    public func move(desiredHeadDirection: SnakeHeadDirection) -> SnakeBodyMovement {
        switch desiredHeadDirection {
        case .up:
            return self.moveUp
        case .left:
            return self.moveLeft
        case .right:
            return self.moveRight
        case .down:
            return self.moveDown
        }
    }

    private var moveUp: SnakeBodyMovement {
        switch self {
        case .up:
            return .moveForward
        case .left:
            return .moveCW
        case .right:
            return .moveCCW
        case .down:
            return .dontMove
        }
    }

    private var moveLeft: SnakeBodyMovement {
        switch self {
        case .up:
            return .moveCCW
        case .left:
            return .moveForward
        case .right:
            return .dontMove
        case .down:
            return .moveCW
        }
    }

    private var moveRight: SnakeBodyMovement {
        switch self {
        case .up:
            return .moveCW
        case .left:
            return .dontMove
        case .right:
            return .moveForward
        case .down:
            return .moveCCW
        }
    }

    private var moveDown: SnakeBodyMovement {
        switch self {
        case .up:
            return .dontMove
        case .left:
            return .moveCCW
        case .right:
            return .moveCW
        case .down:
            return .moveForward
        }
    }
}
