// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeBot7: SnakeBot {
    public static var info: SnakeBotInfo {
        SnakeBotInfoImpl(
            humanReadableName: "Cellular Automata",
            userDefaultIdentifier: "bot7"
        )
    }

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
