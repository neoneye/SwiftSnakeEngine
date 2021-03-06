// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.

public enum SnakeHeadDirection: Hashable {
	case up, down, left, right
}

extension SnakeHeadDirection {
    public var rotatedCCW: SnakeHeadDirection {
        switch self {
        case .up:
            return .left
        case .left:
            return .down
        case .right:
            return .up
        case .down:
            return .right
        }
    }

    public var rotatedCW: SnakeHeadDirection {
		switch self {
		case .up:
			return .right
		case .left:
			return .up
		case .right:
			return .down
		case .down:
			return .left
		}
	}

    public var arrow: String {
        switch self {
        case .up:
            return "↑"
        case .left:
            return "←"
        case .right:
            return "→"
        case .down:
            return "↓"
        }
    }

    public var pointingTriangle: String {
        switch self {
        case .up:
            return "▲"
        case .left:
            return "◀"
        case .right:
            return "▶"
        case .down:
            return "▼"
        }
    }
}

extension SnakeHeadDirection: CustomStringConvertible {
    public var description: String {
        return self.arrow
    }
}
