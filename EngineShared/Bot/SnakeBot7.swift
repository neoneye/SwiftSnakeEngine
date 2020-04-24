// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import Foundation

fileprivate enum CellType {
    case empty
    case wall
    case food
    case player0
    case player1
}

fileprivate struct Cell {
    var cellType: CellType

    static let empty = Cell(cellType: .empty)
    static let wall = Cell(cellType: .wall)
    static let food = Cell(cellType: .food)
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

        let size: UIntVec2 = level.size

        var cells = [Cell]()

        for y in 0..<size.y {
            for x in 0..<size.x {
                let position = UIntVec2(x: x, y: y)
                guard let value: SnakeLevelCell = level.getValue(position) else {
                    cells.append(Cell.empty)
                    continue
                }
                switch value {
                case .empty:
                    cells.append(Cell.empty)
                case .wall:
                    cells.append(Cell.wall)
                }
            }
        }

        if let position: IntVec2 = foodPosition {
            if position.x >= 0 && position.x < size.x {
                if position.y >= 0 && position.y < size.y {
                    let offset: Int = Int(position.y) * Int(size.x) + Int(position.x)
                    if cells[offset].cellType != .empty {
                        log.error("Problem inserting food. Expected the cell to be empty, but it's non-empty.")
                    }
                    cells[offset] = Cell.food
                }
            }
        }

        if player.isInstalled {
            let positionArray: [IntVec2] = player.snakeBody.positionArray()
            for (index, position) in positionArray.enumerated() {
                if index == 0 {
                    continue
                }
                guard position.x >= 0 && position.x < size.x else {
                    log.error("Expected position.x to be inside level, but it's outside.")
                    continue
                }
                guard position.y >= 0 && position.y < size.y else {
                    log.error("Expected position.y to be inside level, but it's outside.")
                    continue
                }
                let offset: Int = Int(position.y) * Int(size.x) + Int(position.x)
                let previousPosition: IntVec2 = positionArray[index - 1]
                let diffx: Int32 = position.x - previousPosition.x
                let diffy: Int32 = position.y - previousPosition.y
                cells[offset] = Cell(cellType: .player0)
            }
        }

        for y in 0..<size.y {
            var row = [String]()
            for x in 0..<size.x {
                let offset: Int = Int(y) * Int(size.x) + Int(x)
                let cell = cells[offset]
                let s: String
                switch cell.cellType {
                case .empty:
                    s = "e"
                case .wall:
                    s = "w"
                case .food:
                    s = "f"
                case .player0:
                    s = "0"
                case .player1:
                    s = "1"
                }
                row.append(s)
            }
            let prettyRow = row.joined(separator: "")
            log.debug("row: \(y) = \(prettyRow)")
        }

        return self
    }
}
