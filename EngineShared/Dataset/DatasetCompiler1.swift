// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

/// Generate a CSV file with data extracted from the snakeDataset files.
public class DatasetCompiler1 {
    private var valueRows = [String]()

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

        log.debug("done. rows: \(valueRows.count)")

        let url: URL = URL.temporaryFile(prefixes: ["snake", "dataset"], uuid: nil, suffixes: [])
        let csvString = valueRows.joined(separator: "\n")
        guard let data: Data = csvString.data(using: .utf8) else {
            log.error("unable to create data from csv string")
            fatalError()
        }
        log.debug("writing \(data.count) bytes to file at: \(url)")
        do {
            try data.write(to: url)
        } catch {
            log.error("unable to write to file. error: \(error)")
        }
        log.debug("done")
    }

    func process(_ url: URL) throws {
        var rowsPlayer1 = [String]()
        var rowsPlayer2 = [String]()

        let environment: GameEnvironmentReplay = try GameEnvironmentReplay.create(url: url)

        var state: SnakeGameState = environment.reset()

        while true {
            if (state.numberOfSteps % 100) == 0 {
                log.debug("step: \(state.numberOfSteps)")
            }

            if let s: String = processStep(level: state.level, player: state.player1, oppositePlayer: state.player2, foodPosition: state.foodPosition) {
                rowsPlayer1.append(s)
            }
            if let s: String = processStep(level: state.level, player: state.player2, oppositePlayer: state.player1, foodPosition: state.foodPosition) {
                rowsPlayer2.append(s)
            }

            let stop: Bool
            switch environment.stepControlMode {
            case .stepRequiresHumanInput:
                log.error("Inconsistency: Expected all steps in the replay data to be for autonomous replay, but this step wants human input.")
                return
            case .stepAutonomous:
                stop = false
            case .reachedTheEnd:
                stop = true
            }
            if stop {
                break
            }
            state = environment.step(action: GameEnvironment_StepAction(player1: .dontMove, player2: .dontMove))
        }

//        log.debug("rows player1: \(rowsPlayer1.count)")
//        log.debug("rows player2: \(rowsPlayer2.count)")

        // At this point the replay of have reached the end.
        // The players may be still alive, or dead.
        // Remove the last 20 steps, so that the last sequence of unfortunate decisions gets eliminated.
        let n: Int = 20
        if rowsPlayer1.count > n {
            rowsPlayer1.removeLast(n)
            valueRows += rowsPlayer1
        }
        if rowsPlayer2.count > n {
            rowsPlayer2.removeLast(n)
            valueRows += rowsPlayer2
        }
    }

    /// Build a grid of things close to the snake head
    func processStep(level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?) -> String? {
        guard player.isInstalledAndAlive else {
            //log.debug("Do nothing. The bot must be installed and alive. It doesn't make sense to run the bot.")
            return nil
        }

        let headPosition: IntVec2 = player.snakeBody.head.position

        // 9x9 grid with obstacles surrounding the head
        let grid = Array2<CellValue>(size: UIntVec2(x: 9, y: 9), defaultValue: CellValue.empty)

        // Draw the level walls as obstacles
        for y: Int32 in 0...8 {
            for x: Int32 in 0...8 {
                let position: IntVec2 = headPosition.offsetBy(dx: x-4, dy: y-4)
                guard let cell: SnakeLevelCell = level.getValue(position) else {
                    // Treat positions outside the level as obstacles.
                    grid[x, y] = .obstacle
                    continue
                }
                if cell == .wall {
                    grid[x, y] = .obstacle
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
                    grid[x, y] = .obstacle
                }
            }
        }

        var fields: [String] = []

        do {
            let newHead: SnakeHead = player.snakeBody.head.simulateTick(movement: player.pendingMovement)
            let direction: SnakeHeadDirection = newHead.direction
            fields.append(direction.csvLabel)
        }

        // Relative position to the food
        if let fp: IntVec2 = foodPosition {
            let diff = headPosition.subtract(fp)
            fields.append("\(diff.x),\(diff.y)")
        } else {
            fields.append("X,X")
        }

        // Relative position to the opponent player
        if oppositePlayer.isInstalledAndAlive {
            let diff = headPosition.subtract(oppositePlayer.snakeBody.head.position)
            fields.append("\(diff.x),\(diff.y)")
        } else {
            fields.append("X,X")
        }

        // Obstacles around the snake head
        do {
            let columnString = grid.flipY.format(columnSeparator: ",", rowSeparator: ",") { (value, position) in
                "\(value.uint)"
            }
            fields.append(columnString)
            //log.debug("csv row: \(columnString)")
        }

        let fieldsJoined: String = fields.joined(separator: ",")

//        log.debug("fields: \(fieldsJoined)")

        return fieldsJoined
    }

}

fileprivate enum CellValue {
    case empty
    case obstacle
}

extension CellValue {
    fileprivate var uint: UInt8 {
        switch self {
        case .empty:
            return 0
        case .obstacle:
            return 1
        }
    }
}

extension SnakeHeadDirection {
    fileprivate var csvLabel: String {
        switch self {
        case .up:
            return "U"
        case .left:
            return "L"
        case .right:
            return "R"
        case .down:
            return "D"
        }
    }
}
