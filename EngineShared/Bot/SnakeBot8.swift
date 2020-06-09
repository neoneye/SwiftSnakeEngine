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

        let headPosition: IntVec2 = player.snakeBody.head.position

        // 9x9 grid with obstacles surrounding the head
        let grid = Array2<Bool>(size: UIntVec2(x: 9, y: 9), defaultValue: false)

        // Draw the level walls as obstacles
        for y: Int32 in 0...8 {
            for x: Int32 in 0...8 {
                let position: IntVec2 = headPosition.offsetBy(dx: x-4, dy: y-4)
                guard let cell: SnakeLevelCell = level.getValue(position) else {
                    grid.setValue(true, at: IntVec2(x: x, y: y))
                    continue
                }
                if cell == .wall {
                    grid.setValue(true, at: IntVec2(x: x, y: y))
                }
            }
        }

        // Draw players as obstacles
        var playerPositionSet: Set<IntVec2> = player.snakeBody.positionSet()
        if oppositePlayer.isInstalledAndAlive {
            playerPositionSet.formUnion(oppositePlayer.snakeBody.positionSet())
        }
        for y: Int32 in 0...8 {
            for x: Int32 in 0...8 {
                let position: IntVec2 = headPosition.offsetBy(dx: x-4, dy: y-4)
                if playerPositionSet.contains(position) {
                    grid.setValue(true, at: IntVec2(x: x, y: y))
                }
            }
        }

        let gridString = grid.flipY.format(columnSeparator: " ") { (value, position) in
            value ? "*" : "-"
        }
        log.debug("grid: \(gridString)")

        let pendingMovement: SnakeBodyMovement = .moveForward

        return SnakeBot8(
            iteration: self.iteration + 1,
            plannedMovement: pendingMovement
        )
    }
}
