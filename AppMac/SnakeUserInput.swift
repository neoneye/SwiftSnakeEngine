// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation
import SnakeGame

public enum SnakeUserInput {
	case arrowUp, arrowLeft, arrowRight, arrowDown
}

extension SnakeUserInput {
	public func newMovement(oldDirection: SnakeHeadDirection) -> SnakeBodyMovement {
		return oldDirection.move(desiredHeadDirection: self.headDirection)
	}

	private var headDirection: SnakeHeadDirection {
		switch self {
		case .arrowUp:
			return .up
		case .arrowLeft:
			return .left
		case .arrowRight:
			return .right
		case .arrowDown:
			return .down
		}
	}
}
