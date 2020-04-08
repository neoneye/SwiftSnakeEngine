// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

public enum SnakeBodyMovement {
    case dontMove
    case moveCCW
    case moveForward
    case moveCW
}

extension SnakeBodyMovement: Comparable {
    private var sortOrder: UInt {
        switch self {
            case .dontMove:
                return 0
            case .moveCCW:
                return 1
            case .moveForward:
                return 2
            case .moveCW:
                return 3
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.sortOrder < rhs.sortOrder
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.sortOrder == rhs.sortOrder
    }
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
