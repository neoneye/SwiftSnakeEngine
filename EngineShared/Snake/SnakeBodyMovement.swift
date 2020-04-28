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
