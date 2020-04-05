// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeBot_MoveForward: SnakeBot {
	public static var info: SnakeBotInfo {
		SnakeBotInfoImpl(
			humanReadableName: "Bot - Always Move Forward",
			userDefaultIdentifier: "bot_move_forward"
		)
	}

	required public init() {
	}

	public func plannedPath() -> [IntVec2] {
		[]
	}

	public func compute(level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?) -> (SnakeBot, SnakeBodyMovement) {
		return (self, .moveForward)
	}
}
