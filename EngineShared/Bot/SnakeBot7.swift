// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

fileprivate enum CellType {
    case empty
    case wall
    case food
    case player0
    case player1
    case player0Head
    case player1Head
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
    var player0Positions: [IntVec2]
    var depth: UInt = 0
    var permutation: UInt = 0

    init(cellBuffer: CellBuffer, player0Positions: [IntVec2]) {
        self.cellBuffer = cellBuffer
        self.player0Positions = player0Positions
    }

    func increment() {
        permutation += 1
    }

    var nextPermutation: UInt {
        return permutation + 1
    }

    func shuffle() {
        player0Positions.shuffle()
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
            self.set(cell: Cell(cellType: .player0, dx: dx, dy: dy), at: previousPosition)
        }
        if let position: IntVec2 = positionArray.last {
            self.set(cell: Cell(cellType: .player0Head, dx: 0, dy: 0), at: position)
        }
    }

    func step() -> CellBufferStep {
        let newBuffer = CellBuffer(size: self.size)

        // Non-moving items
        for y in 0..<size.y {
            for x in 0..<size.x {
                let position = IntVec2(x: Int32(x), y: Int32(y))
                let cell: Cell = self.get(at: position) ?? Cell.empty
                let keep: Bool
                switch cell.cellType {
                case .wall:
                    keep = true
                case .food:
                    keep = true
                default:
                    keep = false
                }
                if keep {
                    newBuffer.set(cell: cell, at: position)
                }
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
                case .player0:
                    let newPosition: IntVec2 = position.offsetBy(dx: Int32(cell.dx), dy: Int32(cell.dy))
                    if let existingCell: Cell = newBuffer.get(at: newPosition) {
                        if existingCell.cellType == .empty {
                            newBuffer.set(cell: cell, at: newPosition)
                        } else {
                            log.error("cell is already occupied \(cell.dx) \(cell.dy)   cellType: \(existingCell.cellType)")
                        }
                    } else {
                        log.error("new position is outside buffer")
                    }
                case .player0Head:
                    ()
                case .player1:
                    ()
                case .player1Head:
                    ()
                }
            }
        }

        var player0Positions = [IntVec2]()

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
                case .player0:
                    ()
                case .player0Head:
                    let newPositions0: [IntVec2] = [
                        position.offsetBy(dx: Int32(0), dy: Int32(-1)),
                        position.offsetBy(dx: Int32(0), dy: Int32(1)),
                        position.offsetBy(dx: Int32(-1), dy: Int32(0)),
                        position.offsetBy(dx: Int32(1), dy: Int32(0))
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
                    player0Positions = newPositions1
                case .player1:
                    ()
                case .player1Head:
                    ()
                }
            }
        }

        return CellBufferStep(
            cellBuffer: newBuffer,
            player0Positions: player0Positions
        )
    }

    func dump(prefix: String) {
        for y in 0..<Int(size.y) {
            let yflipped = Int(size.y) - y - 1
            var row = [String]()
            for x in 0..<Int(size.x) {
                guard let cell: Cell = self.get(x: x, y: yflipped) else {
                    continue
                }
                let s: String
                switch cell.cellType {
                case .empty:
                    s = "_"
                case .wall:
                    s = "w"
                case .food:
                    s = "f"
                case .player0:
                    s = "0"
                case .player1:
                    s = "1"
                case .player0Head:
                    s = "0"
                case .player1Head:
                    s = "1"
                }
                row.append(s)
            }
            let prettyRow = row.joined(separator: "")
            log.debug("\(prefix) = \(prettyRow)")
        }
    }
}

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

//        buffer.dump(prefix: "b0")

        var foundDepth: Int = -1
        var foundPosition: IntVec2 = IntVec2.zero

        var stack = Array<CellBufferStep>()
        let step0: CellBufferStep = buffer.step()
        //log.debug("before")
        stack.append(step0)
        //step0.cellBuffer.dump(prefix: "step0")

        var currentDepth: UInt = 0
        var currentRootPermutation: UInt = 0
        var buffer2: CellBuffer = buffer
        //log.debug("start")
        for i in 0..<10 {
            if let lastStep: CellBufferStep = stack.last {

                // pop from stack, when all choices have been explored
                if lastStep.permutation >= lastStep.player0Positions.count {
                    //log.debug("\(i) pop   \(lastStep.permutation) >= \(lastStep.player0Positions.count)")
                    stack.removeLast()
                    continue
                }

                currentDepth = lastStep.depth
                buffer2 = lastStep.cellBuffer.copy()
                let position: IntVec2 = lastStep.player0Positions[Int(lastStep.permutation)]
                buffer2.set(cell: Cell(cellType: .player0Head, dx: 0, dy: 0), at: position)
                if stack.count == 1 {
                    //log.debug("currentRootPermutation = \(currentRootPermutation)")
                    currentRootPermutation = lastStep.permutation
                }
                lastStep.increment()
            }

            let step: CellBufferStep = buffer2.step()
            step.shuffle()
            //step.cellBuffer.dump(prefix: "step\(i+1)")

            step.depth = currentDepth + 1
            if step.player0Positions.count >= 2 {
                stack.append(step)
            }

            guard let newPosition: IntVec2 = step.player0Positions.first else {
                // Reached a dead end. Back track, and explore another permutation.
                //log.debug("\(i) reached a dead end")
                continue
            }

            if Int(step.depth) > foundDepth {
                foundDepth = Int(step.depth)
                if let firstStep = stack.first {
                    let count: Int = firstStep.player0Positions.count
                    //log.debug("found: \(foundDepth)  index \(currentRootPermutation) of \(count)")
                    foundPosition = firstStep.player0Positions[Int(currentRootPermutation)]
                }
            }

            buffer2 = step.cellBuffer.copy()
            buffer2.set(cell: Cell(cellType: .player0Head, dx: 0, dy: 0), at: newPosition)
            //log.debug("\(i) append")
        }

        var pickedPosition: IntVec2 = player.snakeBody.head.position
        if foundDepth >= 0 {
            pickedPosition = foundPosition
        }

        let dx: Int32 = player.snakeBody.head.position.x - pickedPosition.x
        let dy: Int32 = player.snakeBody.head.position.y - pickedPosition.y
        var pendingMovement: SnakeBodyMovement = .moveForward
        switch player.snakeBody.head.direction {
        case .up:
            if dy > 0 {
                pendingMovement = .moveCW
            }
            if dy < 0 {
                pendingMovement = .moveForward
            }
            if dx > 0 {
                pendingMovement = .moveCCW
            }
            if dx < 0 {
                pendingMovement = .moveCW
            }
        case .down:
            if dy > 0 {
                pendingMovement = .moveForward
            }
            if dy < 0 {
                pendingMovement = .moveCW
            }
            if dx > 0 {
                pendingMovement = .moveCW
            }
            if dx < 0 {
                pendingMovement = .moveCCW
            }
        case .left:
            if dy > 0 {
                pendingMovement = .moveCCW
            }
            if dy < 0 {
                pendingMovement = .moveCW
            }
            if dx > 0 {
                pendingMovement = .moveForward
            }
            if dx < 0 {
                pendingMovement = .moveCCW
            }
        case .right:
            if dy > 0 {
                pendingMovement = .moveCW
            }
            if dy < 0 {
                pendingMovement = .moveCCW
            }
            if dx > 0 {
                pendingMovement = .moveCCW
            }
            if dx < 0 {
                pendingMovement = .moveForward
            }
        }


        return SnakeBot7(
            iteration: self.iteration + 1,
            plannedMovement: pendingMovement
        )
    }
}
