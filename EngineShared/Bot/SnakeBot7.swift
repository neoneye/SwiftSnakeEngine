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
        var last_dx: Int = 0
        var last_dy: Int = 0
        for (index, position) in positionArray.enumerated() {
            if index == 0 {
                continue
            }
            let previousPosition: IntVec2 = positionArray[index - 1]
            let dx: Int = Int(position.x - previousPosition.x)
            let dy: Int = Int(position.y - previousPosition.y)
            self.set(cell: Cell(cellType: .player0, dx: dx, dy: dy), at: previousPosition)
            last_dx = dx
            last_dy = dy
        }
        if let position: IntVec2 = positionArray.last {
            self.set(cell: Cell(cellType: .player0Head, dx: last_dx, dy: last_dy), at: position)
        }
    }

    func stepForward() -> CellBuffer {
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
                case .player1:
                    ()
                case .player1Head:
                    ()
                }
            }
        }
        return newBuffer
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

    required public init() {
    }

    public var plannedPath: [IntVec2] {
        []
    }

    public var plannedMovement: SnakeBodyMovement {
        .moveForward
    }

    public func compute(level: SnakeLevel, player: SnakePlayer, oppositePlayer: SnakePlayer, foodPosition: IntVec2?) -> SnakeBot {

        let buffer = CellBuffer(size: level.size)
        buffer.drawLevel(level)
        buffer.drawOptionalFood(foodPosition)
        buffer.drawPlayer(player)

        buffer.dump(prefix: "b0")

        let buffer2 = buffer.stepForward()
        buffer2.dump(prefix: "b1")

        return self
    }
}
