// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

/// Generate a CSV file with data extracted from the snakeDataset files.
public class DatasetCompiler1 {

    public static func run() {
        let instance = DatasetCompiler1()
        instance.processAllFiles()
    }

    func processAllFiles() {
        let urls: [URL] = try! SnakeDatasetBundle.urls()

        for (index, url) in urls.enumerated() {
            log.debug("process: \(index) of \(urls.count)")
            do {
                try process(url)
            } catch {
                log.error("\(index) of \(urls.count): failed processing file. \(url) error: \(error)")
            }
        }

        // save as csv file

        log.debug("done")
    }

    func process(_ url: URL) throws {
        let environment: GameEnvironmentReplay = try GameEnvironmentReplay.create(url: url)

        var state: SnakeGameState = environment.reset()

        while true {
            log.debug("step: \(state.numberOfSteps)")

            processStep(level: state.level, player: state.player1, oppositePlayer: state.player2, foodPosition: state.foodPosition)
            processStep(level: state.level, player: state.player2, oppositePlayer: state.player1, foodPosition: state.foodPosition)

            let stop: Bool
            switch environment.stepControlMode {
            case .stepRequiresHumanInput:
                log.error("Inconsistency: Expected all steps in the replay data to be for autonomous replay, but this step wants human input.")
                return
            case .stepAutonomous:
                stop = true
            case .reachedTheEnd:
                stop = false
            }
            if stop {
                break
            }
            state = environment.step(action: GameEnvironment_StepAction(player1: .dontMove, player2: .dontMove))
        }



    }

    /// Build a grid of things close to the snake head
    func processStep(level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?) {
        guard player.isInstalledAndAlive else {
            //log.debug("Do nothing. The bot must be installed and alive. It doesn't make sense to run the bot.")
            return
        }

        let headPosition: IntVec2 = player.snakeBody.head.position

        // 9x9 grid with obstacles surrounding the head
        let grid = Array2<CellValue>(size: UIntVec2(x: 9, y: 9), defaultValue: CellValue.empty)

        // Draw the level walls as obstacles
        for y: Int32 in 0...8 {
            for x: Int32 in 0...8 {
                let position: IntVec2 = headPosition.offsetBy(dx: x-4, dy: y-4)
                guard let cell: SnakeLevelCell = level.getValue(position) else {
                    grid[x, y] = .permanentObstacle
                    continue
                }
                if cell == .wall {
                    grid[x, y] = .permanentObstacle
                }
            }
        }

        // Draw players as obstacles
        var playerPositionSet: Set<IntVec2> = player.snakeBody.positionSet()
        if oppositePlayer.isInstalled {
            playerPositionSet.formUnion(oppositePlayer.snakeBody.positionSet())
        }
        for y: Int32 in 0...8 {
            for x: Int32 in 0...8 {
                let position: IntVec2 = headPosition.offsetBy(dx: x-4, dy: y-4)
                if playerPositionSet.contains(position) {
                    grid[x, y] = .movingObstacle
                }
            }
        }

        // If there is food; Determine if the food is inside or outside the 9x9 grid.
        var foodInside: Bool = false
        var foodOutside: Bool = false
        if let fp: IntVec2 = foodPosition {
            let x0: Int32 = headPosition.x - 4
            let x1: Int32 = headPosition.x + 4
            let y0: Int32 = headPosition.y - 4
            let y1: Int32 = headPosition.y + 4
            if fp.x >= x0 && fp.x <= x1 && fp.y >= y0 && fp.y <= y1 {
                foodInside = true
            } else {
                foodOutside = true
            }
        }

        if foodInside {
            for y: Int32 in 0...8 {
                for x: Int32 in 0...8 {
                    let position: IntVec2 = headPosition.offsetBy(dx: x-4, dy: y-4)
                    if position == foodPosition {
                        grid[x, y] = .emptyAndFood
                    }
                }
            }
        }

        let gridString = grid.flipY.format(columnSeparator: " ") { (value, position) in
            "\(value.uint)"
        }
        let newHead: SnakeHead = player.snakeBody.head.simulateTick(movement: player.pendingMovement)
        log.debug("label: \(newHead.direction)")
        log.debug("grid: \(gridString)")

    }

}

fileprivate enum CellValue {
    case emptyAndFood
    case emptyShortestPathForFood
    case empty
    case movingObstaclePlayerTail
    case movingObstacle
    case movingObstacleOpponentPlayerHead
    case permanentObstacle
}

extension CellValue {
    var uint: UInt8 {
        switch self {
        case .emptyAndFood:
            return 0
        case .emptyShortestPathForFood:
            return 20
        case .empty:
            return 30
        case .movingObstaclePlayerTail:
            return 128
        case .movingObstacle:
            return 192
        case .movingObstacleOpponentPlayerHead:
            return 240
        case .permanentObstacle:
            return 255
        }
    }
}
