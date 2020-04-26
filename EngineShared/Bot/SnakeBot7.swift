// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

public class SnakeBot7: SnakeBot {
    public static var info: SnakeBotInfo {
        SnakeBotInfoImpl(
            id: UUID(uuidString: "5b905e9c-58b3-4412-97c1-375787c79560")!,
            humanReadableName: "Cellular Automata"
        )
    }

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

        let buffer = CellBuffer(size: level.size)
        buffer.drawLevel(level)
        buffer.drawOptionalFood(foodPosition)
        buffer.drawPlayer(player)
        // IDEA: drawPlayer(oppositePlayer), so that two-player mode can work. Currently single-player mode only.

        //buffer.dump(prefix: "start")

        let step0: CellBufferStep = buffer.step()
        step0.shuffle()
        //log.debug("initial available positions: \(step0.player0Positions)")

        guard !step0.player1Positions.isEmpty else {
            log.debug("The snake is already dead. There are nowhere for the snake to go!")
            return SnakeBot7(
                iteration: self.iteration + 1,
                plannedMovement: .moveForward
            )
        }

        var foundScore: Int = -1
        var foundPosition: IntVec2 = IntVec2.zero

        let explorer = Explorer(player: player, step0: step0)
        for (index, player0Position) in step0.player1Positions.enumerated() {
            let scoreUnsigned: UInt = explorer.explore(player0Position: player0Position, permutationIndex: UInt(index))
            let score = Int(scoreUnsigned)
            if score > foundScore {
                foundScore = score
                foundPosition = player0Position
            }
        }

        guard foundScore >= 0 else {
            log.debug("Unable to find a path. The snake is dead. There are nowhere for the snake to go!")
            return SnakeBot7(
                iteration: self.iteration + 1,
                plannedMovement: .moveForward
            )
        }
        let pickedPosition: IntVec2 = foundPosition

        guard pickedPosition != player.snakeBody.head.position else {
            log.error("Expected the planned position to be different than the current head position.")
            return SnakeBot7(
                iteration: self.iteration + 1,
                plannedMovement: .moveForward
            )
        }
        guard let pendingMovement: SnakeBodyMovement = player.snakeBody.head.moveToward(pickedPosition) else {
            log.error("The snake cannot go backwards, but the bot planned a backward position.")
            return SnakeBot7(
                iteration: self.iteration + 1,
                plannedMovement: .moveForward
            )
        }
        guard pendingMovement != .dontMove else {
            log.error("Expected moveTowards() to never return 'dontMove', when given two different positions")
            return SnakeBot7(
                iteration: self.iteration + 1,
                plannedMovement: .moveForward
            )
        }

        //log.debug("pendingMovement: \(pendingMovement)")

        return SnakeBot7(
            iteration: self.iteration + 1,
            plannedMovement: pendingMovement
        )
    }
}

fileprivate enum CellType {
    case empty
    case wall
    case food
    case player1
    case player2
    case player1Head
    case player2Head
}

fileprivate struct Cell {
    var cellType: CellType
    var dx: Int
    var dy: Int

    static let empty = Cell(cellType: .empty, dx: 0, dy: 0)
    static let wall = Cell(cellType: .wall, dx: 0, dy: 0)
    static let food = Cell(cellType: .food, dx: 0, dy: 0)
}

fileprivate class CellBufferStep {
    let cellBuffer: CellBuffer
    let previousPlayer1HeadPosition: IntVec2
    var player1Positions: [IntVec2]
    var depth: UInt = 0
    var permutation: UInt = 0

    init(cellBuffer: CellBuffer, previousPlayer1HeadPosition: IntVec2, player1Positions: [IntVec2]) {
        self.cellBuffer = cellBuffer
        self.previousPlayer1HeadPosition = previousPlayer1HeadPosition
        self.player1Positions = player1Positions
    }

    func increment() {
        permutation += 1
    }

    var nextPermutation: UInt {
        return permutation + 1
    }

    func shuffle() {
        player1Positions.shuffle()
    }
}

fileprivate class CellBuffer {
    let size: UIntVec2
    private var cells: [Cell]

    init(size: UIntVec2) {
        self.size = size
        let count = Int(size.x * size.y)
        self.cells = Array<Cell>(repeating: Cell.empty, count: count)
    }

    func copy() -> CellBuffer {
        let buffer = CellBuffer(size: self.size)
        buffer.cells = Array(self.cells)
        return buffer
    }

    // MARK: - Get cell

    func get(x: Int, y: Int) -> Cell? {
        guard x >= 0 && x < Int(self.size.x) else {
            return nil
        }
        guard y >= 0 && y < Int(self.size.y) else {
            return nil
        }
        let offset: Int = y * Int(size.x) + x
        return cells[offset]
    }

    func get(at position: UIntVec2) -> Cell? {
        return self.get(x: Int(position.x), y: Int(position.y))
    }

    func get(at position: IntVec2) -> Cell? {
        return self.get(x: Int(position.x), y: Int(position.y))
    }

    // MARK: - Set cell

    func set(cell: Cell, x: Int, y: Int) {
        guard x >= 0 && x < Int(self.size.x) else {
            return
        }
        guard y >= 0 && y < Int(self.size.y) else {
            return
        }
        let offset: Int = y * Int(size.x) + x
        cells[offset] = cell
    }

    func set(cell: Cell, at position: UIntVec2) {
        self.set(cell: cell, x: Int(position.x), y: Int(position.y))
    }

    func set(cell: Cell, at position: IntVec2) {
        self.set(cell: cell, x: Int(position.x), y: Int(position.y))
    }

    func drawLevel(_ level: SnakeLevel) {
        for y in 0..<size.y {
            for x in 0..<size.x {
                let position = UIntVec2(x: x, y: y)
                guard let value: SnakeLevelCell = level.getValue(position) else {
                    self.set(cell: Cell.empty, at: position)
                    continue
                }
                switch value {
                case .empty:
                    self.set(cell: Cell.empty, at: position)
                case .wall:
                    self.set(cell: Cell.wall, at: position)
                }
            }
        }
    }

    func drawOptionalFood(_ position: IntVec2?) {
        guard let position: IntVec2 = position else {
            return
        }
        guard let cell: Cell = self.get(at: position) else {
            return
        }
        if cell.cellType != .empty {
            log.error("Problem inserting food. Expected the cell to be empty, but it's non-empty.")
        }
        self.set(cell: Cell.food, at: position)
    }

    func drawPlayer(_ player: SnakePlayer) {
        guard player.isInstalled else {
            return
        }
        let positionArray: [IntVec2] = player.snakeBody.positionArray()
        for (index, position) in positionArray.enumerated() {
            if index == 0 {
                continue
            }
            let previousPosition: IntVec2 = positionArray[index - 1]
            let dx: Int = Int(position.x - previousPosition.x)
            let dy: Int = Int(position.y - previousPosition.y)
            //log.debug("player \(previousPosition) -> \(position)  dx: \(dx)  dy: \(dy)")
            self.set(cell: Cell(cellType: .player1, dx: dx, dy: dy), at: previousPosition)
        }
        if let position: IntVec2 = positionArray.last {
            self.set(cell: Cell(cellType: .player1Head, dx: 0, dy: 0), at: position)
            //log.debug("player head \(position)")
        }
    }

    func step() -> CellBufferStep {
        let newBuffer = CellBuffer(size: self.size)

        // Non-moving items. Preserve their direction (dx, dy)
        for y in 0..<size.y {
            for x in 0..<size.x {
                let position = IntVec2(x: Int32(x), y: Int32(y))
                var cell: Cell = self.get(at: position) ?? Cell.empty
                switch cell.cellType {
                case .wall:
                    ()
                case .food:
                    ()
                default:
                    cell.cellType = .empty
                }
                newBuffer.set(cell: cell, at: position)
            }
        }

        // Body of moving items
        for y in 0..<size.y {
            for x in 0..<size.x {
                let position = IntVec2(x: Int32(x), y: Int32(y))
                let cell: Cell = self.get(at: position) ?? Cell.empty
                switch cell.cellType {
                case .empty:
                    ()
                case .wall:
                    ()
                case .food:
                    ()
                case .player1:
                    let newPosition: IntVec2 = position.offsetBy(dx: Int32(cell.dx), dy: Int32(cell.dy))
                    if let existingCell: Cell = newBuffer.get(at: newPosition) {
                        if existingCell.cellType == .empty {
                            var newCell: Cell = existingCell
                            newCell.cellType = cell.cellType
                            newBuffer.set(cell: newCell, at: newPosition)
                        } else {
                            log.error("cell is already occupied \(position) -> \(newPosition)  dx: \(cell.dx)  dy: \(cell.dy)   cellType: \(existingCell.cellType)")
                        }
                    } else {
                        log.error("new position is outside buffer")
                    }
                case .player1Head:
                    ()
                case .player2:
                    // IDEA: draw the opposite player, so it becomes a two-player bot. Currently it's single player only.
                    ()
                case .player2Head:
                    ()
                }
            }
        }

        var player1Positions = [IntVec2]()
        var previousPlayer1HeadPosition = IntVec2.zero

        // Head of moving items, check for collisions
        for y in 0..<size.y {
            for x in 0..<size.x {
                let position = IntVec2(x: Int32(x), y: Int32(y))
                let cell: Cell = self.get(at: position) ?? Cell.empty
                switch cell.cellType {
                case .empty:
                    ()
                case .wall:
                    ()
                case .food:
                    ()
                case .player1:
                    ()
                case .player1Head:
                    let newPositions0: [IntVec2] = [
                        position.offsetBy(dx:  0, dy: -1),
                        position.offsetBy(dx:  0, dy:  1),
                        position.offsetBy(dx: -1, dy:  0),
                        position.offsetBy(dx:  1, dy:  0)
                    ]
                    let newPositions1: [IntVec2] = newPositions0.filter { (newPosition) in
                        var isPossibleMove: Bool = false
                        if let existingCell: Cell = newBuffer.get(at: newPosition) {
                            if existingCell.cellType == .empty {
                                isPossibleMove = true
                            }
                            if existingCell.cellType == .food {
                                isPossibleMove = true
                            }
                        }
                        return isPossibleMove
                    }
                    previousPlayer1HeadPosition = position
                    player1Positions = newPositions1
                case .player2:
                    ()
                case .player2Head:
                    // IDEA: draw the opposite player, so it becomes a two-player bot. Currently it's single player only.
                    // IDEA: determine the best choices available for the opposite player.
                    ()
                }
            }
        }

        return CellBufferStep(
            cellBuffer: newBuffer,
            previousPlayer1HeadPosition: previousPlayer1HeadPosition,
            player1Positions: player1Positions
        )
    }

    func dump(prefix: String) {
        for yflipped in 0..<Int(size.y) {
            let y = Int(size.y) - yflipped - 1
            var row = [String]()
            for x in 0..<Int(size.x) {
                guard let cell: Cell = self.get(x: x, y: y) else {
                    continue
                }
                let s: String
                switch cell.cellType {
                case .empty:
                    s = "⬜️"
                case .wall:
                    s = "⬛️"
                case .food:
                    s = "🔴"
                case .player1:
                    s = "🟨"
                case .player2:
                    s = "🟦"
                case .player1Head:
                    s = "🟡"
                case .player2Head:
                    s = "🔵"
                }
                row.append(s)
            }
            let ymod10: Int = y % 10
            let prettyRow = row.joined(separator: "")
            log.debug("\(prefix) \(ymod10)\(prettyRow)")
        }
    }
}

fileprivate class Explorer {
    let player: SnakePlayer
    let step0: CellBufferStep

    init(player: SnakePlayer, step0: CellBufferStep) {
        self.player = player
        self.step0 = step0
    }

    /// Returns the max depth score that the snake can go.
    func explore(player0Position: IntVec2, permutationIndex: UInt) -> UInt {
        var foundDepthScore: UInt = 0

        var stack = Array<CellBufferStep>()
        stack.append(step0)

        var currentDepth: UInt = 0
        var buffer: CellBuffer = step0.cellBuffer.copy()
        //log.debug("start")
        for i in 0..<3 {
            _ = i
            if let lastStep: CellBufferStep = stack.last {

                // pop from stack, when all choices have been explored
                if lastStep.permutation >= lastStep.player1Positions.count {
                    //log.debug("\(i) pop   \(lastStep.permutation) >= \(lastStep.player0Positions.count)")
                    stack.removeLast()
                    continue
                }

                currentDepth = lastStep.depth
                buffer = lastStep.cellBuffer.copy()
                let oldPosition: IntVec2 = lastStep.previousPlayer1HeadPosition
                let newPosition: IntVec2 = lastStep.player1Positions[Int(lastStep.permutation)]

                let dx: Int = Int(newPosition.x - oldPosition.x)
                let dy: Int = Int(newPosition.y - oldPosition.y)
                //log.debug("update direction for cell at: \(oldPosition)  dx: \(dx)  dy: \(dy)")
                buffer.set(cell: Cell(cellType: .player1, dx: dx, dy: dy), at: oldPosition)
                //log.debug("insert head at: \(newPosition)")
                buffer.set(cell: Cell(cellType: .player1Head, dx: 0, dy: 0), at: newPosition)
                lastStep.increment()
//                buffer2.dump(prefix: "step\(i+1)")
            }

            let step: CellBufferStep = buffer.step()
            step.shuffle()
            //log.debug("available positions: \(step.player0Positions)")
            //step.cellBuffer.dump(prefix: "step\(i+1)")

            step.depth = currentDepth + 1
            if step.player1Positions.count >= 2 {
                stack.append(step)
            }

            guard let newPosition: IntVec2 = step.player1Positions.first else {
                // Reached a dead end. Back track, and explore another permutation.
                //log.debug("\(i) reached a dead end. Will backtrack.")
                continue
            }

            let newDepthScore = step.depth * 3 + UInt(step.player1Positions.count)
            // IDEA: if this path leads to certain death, then this new+better score should be ignored.
            // IDEA: determine the distance to the food.
            // IDEA: determine risk of bumping into the opponent player.
            if newDepthScore > foundDepthScore {
                foundDepthScore = newDepthScore
                //log.debug("new depth: \(newDepthScore)")
            }

            do {
                buffer = step.cellBuffer.copy()
                let oldPosition: IntVec2 = step.previousPlayer1HeadPosition
                let dx: Int = Int(newPosition.x - oldPosition.x)
                let dy: Int = Int(newPosition.y - oldPosition.y)
                //log.debug("update direction for cell at: \(oldPosition)  dx: \(dx)  dy: \(dy)")
                buffer.set(cell: Cell(cellType: .player1, dx: dx, dy: dy), at: oldPosition)
                //log.debug("insert head at: \(newPosition)")
                buffer.set(cell: Cell(cellType: .player1Head, dx: 0, dy: 0), at: newPosition)
            }
            //log.debug("\(i) append")
        }

        return foundDepthScore
    }
}
