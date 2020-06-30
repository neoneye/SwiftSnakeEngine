// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

/// Generate a CSV file with data extracted from the `.snakeDataset` files.
///
/// # There are 86 columns in the CSV file
/// - 1 column with the label: up, left, right, down.
/// - 2 columns with relative position to the food.
/// - 2 columns with relative position to the opponent.
/// - 81 columns with a 9x9 grid with obstacles around the snake head.
///
/// # Problem with this CSV file format
/// The relative position to the food, does not consider the scenario
/// when there is a big obstacle between the snake and the food,
/// and the snake have to take a longer route to get to the food.
/// This makes the AI think that it's getting closer to the target,
/// when it's not making any progress.
///
/// # Ideas for future CSV files
/// Ideas for columns that will add more value to the training data.
/// - Prefer games that are completed faster, than games that take lots of unnecessary steps.
/// - 81 columns with 9x9 grid with obstacles around the opponent snake head.
/// - Increase the grid size from 9x9 to 11x11 or even bigger.
/// - Compute shortest path the to food for all the edge cells of the 9x9 grid.
/// - Store the score of the `StuckSnakeDetector`, so that repeating patterns are punished.
/// - One-hot encoding of the last 10 moves of both players.
/// - Relative position of the snake tail for both players.
/// - Snake length of both players.
/// - Size of the open area reachable. If it's big, then there is less risk of being trapped.
/// - Label column for the moves that is optimal for the opponent player.
/// - When there is only 1 choice available, then store the number of steps until more choices becomes available.
/// - Distinguish between permanent obstacles (walls) and snake obstacles (player 1, player 2).
/// - For each grid cell store the direction of snake movement. (1,0) = right, (0,-1) = down.
public class DatasetCompiler1 {
    private var csvRows = [String]()
    private let gridRadius: UInt32 = 4

    public static func run() {
        let instance = DatasetCompiler1()
        instance.processAllFiles()
    }

    func processAllFiles() {
        csvRows = [self.headerRow]

        // Process input files
        let urls: [URL] = try! SnakeDatasetBundle.urls()
        for (index, url) in urls.enumerated() {
            log.debug("process: \(index) of \(urls.count)")
            do {
                try processFile(url)
            } catch {
                log.error("\(index) of \(urls.count): failed processing file. \(url) error: \(error)")
            }
        }

        // Save the result as csv file

        log.debug("done. rows: \(csvRows.count)")

        let url: URL = URL.temporaryFile(prefixes: ["snake", "dataset"], uuid: nil, suffixes: [], pathExtension: "csv")
        let csvString = csvRows.joined(separator: "\n")
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

    func processFile(_ url: URL) throws {
        var rowsPlayer1 = [String]()
        var rowsPlayer2 = [String]()

        let environment: GameEnvironmentReplay = try GameEnvironmentReplay.create(url: url)

        var state: SnakeGameState = environment.reset()

        while true {
            if (state.numberOfSteps % 100) == 0 {
                log.debug("step: \(state.numberOfSteps)")
            }

            if let s: String = convertStepToString(state: state, playerId: .player1) {
                rowsPlayer1.append(s)
            }
            if let s: String = convertStepToString(state: state, playerId: .player2) {
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
            csvRows += rowsPlayer1
        }
        if rowsPlayer2.count > n {
            rowsPlayer2.removeLast(n)
            csvRows += rowsPlayer2
        }
    }

    /// Build a grid of things close to the snake head
    func convertStepToString(state: SnakeGameState, playerId: SnakePlayerId) -> String? {
        let player: SnakePlayer
        let oppositePlayer: SnakePlayer
        switch playerId {
        case .player1:
            player = state.player1
            oppositePlayer = state.player2
        case .player2:
            player = state.player2
            oppositePlayer = state.player1
        }

        guard player.isInstalledAndAlive else {
            //log.debug("Do nothing. The bot must be installed and alive. It doesn't make sense to run the bot.")
            return nil
        }

        let headPosition: IntVec2 = player.snakeBody.head.position

        // NxN grid with obstacles surrounding the snake head
        let grid: Array2<GridCell> = state.grid(radius: gridRadius, center: headPosition)

        var fields: [String] = []

        do {
            let newHead: SnakeHead = player.snakeBody.head.simulateTick(movement: player.pendingMovement)
            let direction: SnakeHeadDirection = newHead.direction
            fields.append(direction.csvLabel)
        }

        // Relative position to the food
        if let fp: IntVec2 = state.foodPosition {
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

    var headerRow: String {
        var fields: [String] = []

        fields.append("label")

        // Relative position to the food
        fields.append("foodx,foody")

        // Relative position to the opponent player
        fields.append("opponentx,opponenty")

        // Obstacles around the snake head
        do {
            let size: UInt32 = gridRadius * 2 + 1
            let grid = Array2<Bool>(size: UIntVec2(x: size, y: size), defaultValue: false)
            let columnString = grid.flipY.format(columnSeparator: ",", rowSeparator: ",") { (value, position) in
                "cell\(position.x)\(position.y)"
            }
            fields.append(columnString)
            //log.debug("csv row: \(columnString)")
        }

        let fieldsJoined: String = fields.joined(separator: ",")
        return fieldsJoined
    }
}

extension GridCell {
    fileprivate var uint: UInt8 {
        switch self {
        case .empty:
            return 0
        case .wall:
            return 1
        case .player1:
            return 1
        case .player2:
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
