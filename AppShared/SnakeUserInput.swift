// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

#if os(iOS)
import EngineIOS
#elseif os(macOS)
import EngineMac
#else
#error("Unknown OS")
#endif

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
