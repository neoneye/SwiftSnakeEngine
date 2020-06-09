// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeBot8: SnakeBot {
    public static var info = SnakeBotInfo(
        uuid: "ce015558-3705-45e5-9b16-7f79757d2a51",
        name: "Experimental"
    )

    public let plannedMovement: SnakeBodyMovement
    private let iteration: UInt

    private init(iteration: UInt, plannedMovement: SnakeBodyMovement) {
        self.iteration = iteration
        self.plannedMovement = plannedMovement
    }

    required public convenience init() {
        self.init(iteration: 0, plannedMovement: .dontMove)
    }

    public var plannedPath: [IntVec2] {
        []
    }

    public func compute(level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?) -> SnakeBot {
        guard player.isInstalledAndAlive else {
            //log.debug("Do nothing. The bot must be installed and alive. It doesn't make sense to run the bot.")
            return SnakeBot8()
        }

        let pendingMovement: SnakeBodyMovement = .moveForward

        return SnakeBot8(
            iteration: self.iteration + 1,
            plannedMovement: pendingMovement
        )
    }
}
