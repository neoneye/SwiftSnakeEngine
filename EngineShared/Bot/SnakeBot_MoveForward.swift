// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeBot_MoveForward: SnakeBot {
	public static var info = SnakeBotInfo(
        uuid: "ac009b0e-6d2d-4fe5-8dc5-22e3e7c0177d",
        name: "Bot - Always Move Forward"
    )

	required public init() {
	}

	public var plannedPath: [IntVec2] {
		[]
	}

    public var plannedMovement: SnakeBodyMovement {
        .moveForward
    }

	public func compute(level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?) -> SnakeBot {
		self
	}
}
