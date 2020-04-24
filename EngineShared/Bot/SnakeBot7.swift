// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeBot7: SnakeBot {
    public static var info: SnakeBotInfo {
        SnakeBotInfoImpl(
            id: UUID(uuidString: "5b905e9c-58b3-4412-97c1-375787c79560")!,
            humanReadableName: "Cellular Automata"
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
