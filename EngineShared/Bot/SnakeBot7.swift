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

fileprivate class CellBuffer {
    let size: UIntVec2
    private var cells: [Cell]

    init(size: UIntVec2) {
        self.size = size
        let count = Int(size.x * size.y)
        self.cells = Array<Cell>(repeating: Cell.empty, count: count)
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

    func stepForward() -> (CellBuffer, IntVec2) {
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
                            log.error("cell is already occupied")
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

        var pickedPosition: IntVec2 = IntVec2.zero

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
                    // IDEA: if a choice is bad, then backtrack and try again with another seed for the random generator
                    if let newPosition: IntVec2 = newPositions1.randomElement() {
                        pickedPosition = newPosition
                        newBuffer.set(cell: cell, at: newPosition)
                    } else {
                        log.error("snake is stuck and unable to move")
                    }
                case .player1:
                    ()
                case .player1Head:
                    ()
                }
            }
        }
        return (newBuffer, pickedPosition)
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
            log.debug("\(prefix)#\(y) = \(prettyRow)")
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

        buffer.dump(prefix: "b0")

        let (buffer2, pickedPosition) = buffer.stepForward()
        buffer2.dump(prefix: "b1")

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
